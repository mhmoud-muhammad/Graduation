import '../models/search_models.dart';

/// ترتيب الصيدليات: الأقرب أولاً عند توفر موقع المستخدم، وإلا الأرخص.
/// الصيدليات التي نفدت كميتها لا تُعرض.
List<PharmacyOffer> rankOffers(Iterable<PharmacyOffer> offers) {
  final list = offers.where((o) => o.availability.inStock).toList();
  list.sort((a, b) {
    final da = a.distanceKm, db = b.distanceKm;
    if (da != null && db != null && da != db) return da.compareTo(db);
    if (da != null && db == null) return -1;
    if (da == null && db != null) return 1;
    return a.availability.price.compareTo(b.availability.price);
  });
  return list;
}
