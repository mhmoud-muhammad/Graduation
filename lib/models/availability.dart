import 'package:cloud_firestore/cloud_firestore.dart';

/// كيان توفر الأدوية (MedicineAvailability) — مجموعة `availability`.
///
/// حلقة الوصل بين الدواء والصيدلية: السعر والكمية وتاريخ آخر تحديث.
/// معرّف السجل = `{pharmacyId}_{medicineId}` (سجل واحد لكل دواء في كل صيدلية).
class Availability {
  const Availability({
    required this.availabilityId,
    required this.medicineId,
    required this.pharmacyId,
    required this.price,
    required this.quantity,
    this.updatedAt,
  });

  final String availabilityId;
  final String medicineId;
  final String pharmacyId;
  final double price;
  final int quantity;
  final DateTime? updatedAt;

  bool get inStock => quantity > 0;

  static String idFor(String pharmacyId, String medicineId) =>
      '${pharmacyId}_$medicineId';

  factory Availability.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Availability(
      availabilityId: doc.id,
      medicineId: (d['medicineId'] as String?) ?? '',
      pharmacyId: (d['pharmacyId'] as String?) ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0,
      quantity: (d['quantity'] as num?)?.toInt() ?? 0,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'availabilityId': availabilityId,
    'medicineId': medicineId,
    'pharmacyId': pharmacyId,
    'price': price,
    'quantity': quantity,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
