import 'package:cloud_firestore/cloud_firestore.dart';

/// كيان الصيدليات (Pharmacies) — مجموعة `pharmacies/{pharmacyId}`.
///
/// لكل صيدلي صيدلية واحدة، ويُستخدم معرّف الصيدلي نفسه كمعرّف للصيدلية
/// لتسهيل قواعد الأمان، مع الاحتفاظ بالحقل ownerId كمفتاح أجنبي.
class Pharmacy {
  const Pharmacy({
    required this.pharmacyId,
    required this.ownerId,
    required this.pharmacyName,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.updatedAt,
  });

  final String pharmacyId;
  final String ownerId;
  final String pharmacyName;
  final String? address;
  final String? phone;
  final double latitude;
  final double longitude;
  final DateTime? updatedAt;

  factory Pharmacy.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Pharmacy(
      pharmacyId: doc.id,
      ownerId: (d['ownerId'] as String?) ?? '',
      pharmacyName: (d['pharmacyName'] as String?) ?? '',
      address: d['address'] as String?,
      phone: d['phone'] as String?,
      latitude: (d['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (d['longitude'] as num?)?.toDouble() ?? 0,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'pharmacyId': pharmacyId,
    'ownerId': ownerId,
    'pharmacyName': pharmacyName.trim(),
    'address': _nullIfEmpty(address),
    'phone': _nullIfEmpty(phone),
    'latitude': latitude,
    'longitude': longitude,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static String? _nullIfEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}
