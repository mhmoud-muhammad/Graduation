import 'package:geolocator/geolocator.dart';

import '../models/medicine.dart';
import '../models/search_models.dart';
import 'location_service.dart';
import 'medicine_repository.dart';
import 'offer_ranking.dart';
import 'pharmacy_repository.dart';

/// منطق البحث: مطابقة الأدوية ثم تحديد الصيدليات المتوفر فيها وترتيبها.
class SearchService {
  SearchService(this._medicines, this._pharmacies, this._location);

  final MedicineRepository _medicines;
  final PharmacyRepository _pharmacies;
  final LocationService _location;

  /// البحث النصي (FR-04).
  Future<List<MedicineSearchResult>> searchText(String query) async {
    final meds = await _medicines.searchByText(query);
    return _withOffers(meds);
  }

  /// البحث بالمعلومات المستخرجة من الصورة (FR-05, FR-06, FR-07).
  Future<List<MedicineSearchResult>> searchAnalysis(ImageAnalysis a) async {
    final found = <String, Medicine>{};
    for (final b in a.barcodes) {
      for (final m in await _medicines.findByBarcode(b)) {
        found[m.medicineId] = m;
      }
    }
    for (final name in a.allNames) {
      for (final m in await _medicines.searchByText(name, limit: 5)) {
        found[m.medicineId] = m;
      }
    }
    return _withOffers(found.values.toList());
  }

  Future<List<MedicineSearchResult>> _withOffers(List<Medicine> meds) async {
    if (meds.isEmpty) return const [];
    final availabilityFuture = _medicines.availabilityForMedicines(
      meds.map((m) => m.medicineId),
    );
    final positionFuture = _location.current();
    final availability = await availabilityFuture;
    final Position? me = await positionFuture;
    final pharmacies = await _pharmacies.getByIds(
      availability.map((a) => a.pharmacyId),
    );

    final out = <MedicineSearchResult>[];
    for (final m in meds) {
      final offers = <PharmacyOffer>[];
      for (final a in availability.where((a) => a.medicineId == m.medicineId)) {
        final p = pharmacies[a.pharmacyId];
        if (p == null) continue;
        offers.add(
          PharmacyOffer(
            pharmacy: p,
            availability: a,
            distanceKm: me == null
                ? null
                : LocationService.distanceKm(
                    me.latitude,
                    me.longitude,
                    p.latitude,
                    p.longitude,
                  ),
          ),
        );
      }
      out.add(MedicineSearchResult(medicine: m, offers: rankOffers(offers)));
    }
    // الأدوية المتوفرة أولاً.
    out.sort(
      (a, b) =>
          (b.offers.isNotEmpty ? 1 : 0).compareTo(a.offers.isNotEmpty ? 1 : 0),
    );
    return out;
  }
}
