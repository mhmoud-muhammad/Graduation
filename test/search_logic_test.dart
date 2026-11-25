import 'package:dawai/models/availability.dart';
import 'package:dawai/models/medicine.dart';
import 'package:dawai/models/pharmacy.dart';
import 'package:dawai/models/search_models.dart';
import 'package:dawai/services/gemini_service.dart';
import 'package:dawai/services/offer_ranking.dart';
import 'package:dawai/services/search_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

Pharmacy pharmacy(String id, {double lat = 15.5, double lng = 32.5}) =>
    Pharmacy(
      pharmacyId: id,
      ownerId: 'owner',
      pharmacyName: id,
      latitude: lat,
      longitude: lng,
    );

Availability stock(String ph, String med, {double price = 10, int qty = 5}) =>
    Availability(
      availabilityId: '${ph}_$med',
      medicineId: med,
      pharmacyId: ph,
      price: price,
      quantity: qty,
    );

PharmacyOffer offer(String id, {double? km, double price = 10, int qty = 5}) =>
    PharmacyOffer(
      pharmacy: pharmacy(id),
      availability: stock(id, 'm', price: price, qty: qty),
      distanceKm: km,
    );

Position at(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026),
  accuracy: 1,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  group('rankOffers (FR-15)', () {
    test('عند السماح بالموقع: الأقرب أولاً', () {
      final r = rankOffers([
        offer('far', km: 3.8),
        offer('near', km: 1.2),
        offer('mid', km: 2.5),
      ], byDistance: true);
      expect(r.map((o) => o.pharmacy.pharmacyId), ['near', 'mid', 'far']);
    });

    test('عند رفض الموقع: تُعرض دون ترتيب', () {
      final r = rankOffers([
        offer('b', price: 13),
        offer('a', price: 12),
        offer('c', price: 20),
      ], byDistance: false);
      expect(r.map((o) => o.pharmacy.pharmacyId), ['b', 'a', 'c']);
    });

    test('استبعاد الصيدليات التي نفدت كميتها', () {
      final r = rankOffers([offer('a', qty: 0), offer('b')], byDistance: false);
      expect(r.map((o) => o.pharmacy.pharmacyId), ['b']);
    });
  });

  group('SearchService.arrange', () {
    const panadol = Medicine(
      medicineId: 'm1',
      tradeName: 'Panadol',
      scientificName: 'Paracetamol',
      pharmaceuticalForm: 'أقراص',
    );
    const amoxil = Medicine(
      medicineId: 'm2',
      tradeName: 'Amoxil',
      scientificName: 'Amoxicillin',
      pharmaceuticalForm: 'كبسولات',
    );
    final raw = RawSearch(
      [amoxil, panadol],
      [stock('near', 'm1'), stock('far', 'm1')],
      {
        'near': pharmacy('near', lat: 15.51, lng: 32.56),
        'far': pharmacy('far', lat: 15.70, lng: 32.56),
      },
    );

    test('مع الموقع: حساب المسافة والترتيب حسب الأقرب', () {
      final out = SearchService.arrange(raw, at(15.50, 32.56));
      expect(out.sortedByDistance, isTrue);
      final p = out.results.first;
      expect(p.medicine.pharmaceuticalForm, 'أقراص');
      expect(p.offers.map((o) => o.pharmacy.pharmacyId), ['near', 'far']);
      expect(p.offers.first.distanceKm, lessThan(p.offers.last.distanceKm!));
    });

    test('بدون موقع: لا مسافة ولا ترتيب حسب القرب', () {
      final out = SearchService.arrange(raw, null);
      expect(out.sortedByDistance, isFalse);
      expect(
        out.results.first.offers.every((o) => o.distanceKm == null),
        isTrue,
      );
    });

    test('الدواء المتوفر يظهر قبل غير المتوفر', () {
      final out = SearchService.arrange(raw, null);
      expect(out.results.map((r) => r.medicine.medicineId), ['m1', 'm2']);
      expect(out.results.last.offers, isEmpty);
    });
  });

  group('GeminiService.parse (FR-13)', () {
    test('قراءة الأسماء والشكل الصيدلاني من JSON داخل ```json', () {
      final a = GeminiService.parse('''```json
{"readable": true, "tradeNames": ["Panadol", "Panadol"],
 "scientificNames": ["Paracetamol"], "pharmaceuticalForms": ["أقراص"]}
```''');
      expect(a.readable, isTrue);
      expect(a.tradeNames, ['Panadol']);
      expect(a.allNames, ['Panadol', 'Paracetamol']);
      expect(a.forms, ['أقراص']);
    });

    test('رد غير صالح = صورة غير واضحة', () {
      expect(GeminiService.parse('لا أعرف').readable, isFalse);
      expect(GeminiService.parse(null).readable, isFalse);
      expect(GeminiService.parse('{"readable": false}').isEmpty, isTrue);
    });
  });

  test('مفتاح هوية الدواء يشمل الشكل الصيدلاني', () {
    expect(
      Medicine.identityKey('Panadol', 'Paracetamol', 'أقراص'),
      isNot(Medicine.identityKey('Panadol', 'Paracetamol', 'شراب')),
    );
  });
}
