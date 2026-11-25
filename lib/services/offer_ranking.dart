import '../models/search_models.dart';

/// يستبعد الصيدليات التي نفدت كميتها. عند توفر موقع المستخدم تُرتب حسب
/// الأقرب، وعند رفض الإذن تُعرض كما هي دون ترتيب حسب القرب (FR-15).
List<PharmacyOffer> rankOffers(
  Iterable<PharmacyOffer> offers, {
  required bool byDistance,
}) {
  final list = offers.where((o) => o.availability.inStock).toList();
  if (byDistance) {
    list.sort((a, b) {
      final da = a.distanceKm, db = b.distanceKm;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
  }
  return list;
}
