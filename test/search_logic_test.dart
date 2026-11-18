import 'package:dawai/models/availability.dart';
import 'package:dawai/models/pharmacy.dart';
import 'package:dawai/models/search_models.dart';
import 'package:dawai/services/gemini_service.dart';
import 'package:dawai/services/offer_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

PharmacyOffer offer(String id, {double? km, double price = 10, int qty = 5}) =>
    PharmacyOffer(
      pharmacy: Pharmacy(
        pharmacyId: id,
        ownerId: id,
        pharmacyName: id,
        latitude: 0,
        longitude: 0,
      ),
      availability: Availability(
        availabilityId: '${id}_m',
        medicineId: 'm',
        pharmacyId: id,
        price: price,
        quantity: qty,
      ),
      distanceKm: km,
    );

void main() {
  group('rankOffers', () {
    test('الأقرب أولاً', () {
      final r = rankOffers([
        offer('far', km: 3.8),
        offer('near', km: 1.2),
        offer('mid', km: 2.5),
      ]);
      expect(r.map((o) => o.pharmacy.pharmacyId), ['near', 'mid', 'far']);
    });

    test('بدون موقع: الأرخص أولاً', () {
      final r = rankOffers([offer('a', price: 13), offer('b', price: 12.5)]);
      expect(r.first.pharmacy.pharmacyId, 'b');
    });

    test('استبعاد الصيدليات التي نفدت كميتها', () {
      final r = rankOffers([offer('a', qty: 0), offer('b')]);
      expect(r.map((o) => o.pharmacy.pharmacyId), ['b']);
    });
  });

  group('GeminiService.parse', () {
    test('قراءة JSON داخل ```json', () {
      final a = GeminiService.parse('''```json
{"readable": true, "tradeNames": ["Panadol", "Panadol"],
 "scientificNames": ["Paracetamol"], "barcodes": ["6281012345678"]}
```''');
      expect(a.readable, isTrue);
      expect(a.tradeNames, ['Panadol']);
      expect(a.allNames, ['Panadol', 'Paracetamol']);
      expect(a.barcodes, ['6281012345678']);
    });

    test('رد غير صالح = صورة غير مقروءة', () {
      expect(GeminiService.parse('لا أعرف').readable, isFalse);
      expect(GeminiService.parse(null).readable, isFalse);
      expect(GeminiService.parse('{"readable": false}').isEmpty, isTrue);
    });
  });
}
