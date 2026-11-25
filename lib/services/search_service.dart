import 'package:geolocator/geolocator.dart';

import '../models/availability.dart';
import '../models/medicine.dart';
import '../models/pharmacy.dart';
import '../models/search_models.dart';
import 'location_service.dart';
import 'medicine_repository.dart';
import 'network_service.dart';
import 'offer_ranking.dart';
import 'pharmacy_repository.dart';

/// بيانات البحث الخام قبل ترتيبها حسب الموقع.
class RawSearch {
  const RawSearch(this.medicines, this.availability, this.pharmacies);
  final List<Medicine> medicines;
  final List<Availability> availability;
  final Map<String, Pharmacy> pharmacies;

  bool get isEmpty => medicines.isEmpty;
}

/// منطق البحث كما في مخططات التسلسل: البحث في medicines ← الاستعلام عن
/// التوفر في availability ← (طلب إذن الموقع) ← حساب المسافة والترتيب.
class SearchService {
  SearchService(this._medicines, this._pharmacies);

  final MedicineRepository _medicines;
  final PharmacyRepository _pharmacies;

  /// البحث بالكتابة (FR-04).
  Future<RawSearch> findByText(String query) =>
      Net.guard(() async => _collect(await _medicines.searchByText(query)));

  /// البحث بالمعلومات المستخرجة من الصورة (FR-05..07, FR-13).
  Future<RawSearch> findByAnalysis(ImageAnalysis a) => Net.guard(() async {
    final found = <String, Medicine>{};
    for (final name in a.allNames) {
      for (final m in await _medicines.searchByText(name, limit: 5)) {
        found[m.medicineId] = m;
      }
    }
    return _collect(found.values.toList());
  });

  Future<RawSearch> _collect(List<Medicine> meds) async {
    if (meds.isEmpty) return const RawSearch([], [], {});
    final availability = await _medicines.availabilityForMedicines(
      meds.map((m) => m.medicineId),
    );
    final pharmacies = await _pharmacies.getByIds(
      availability.map((a) => a.pharmacyId),
    );
    return RawSearch(meds, availability, pharmacies);
  }

  /// يبني النتائج؛ عند توفر [me] تُحسب المسافة وتُرتب الصيدليات حسب الأقرب.
  static SearchOutcome arrange(RawSearch raw, Position? me) {
    final results = <MedicineSearchResult>[];
    for (final m in raw.medicines) {
      final offers = <PharmacyOffer>[
        for (final a in raw.availability.where(
          (a) => a.medicineId == m.medicineId,
        ))
          if (raw.pharmacies[a.pharmacyId] case final p?)
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
      ];
      results.add(
        MedicineSearchResult(
          medicine: m,
          offers: rankOffers(offers, byDistance: me != null),
        ),
      );
    }
    // الأدوية المتوفرة أولاً.
    results.sort(
      (a, b) =>
          (b.offers.isNotEmpty ? 1 : 0).compareTo(a.offers.isNotEmpty ? 1 : 0),
    );
    return SearchOutcome(results: results, sortedByDistance: me != null);
  }
}
