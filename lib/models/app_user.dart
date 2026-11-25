import 'package:cloud_firestore/cloud_firestore.dart';

/// نوع الحساب: مستخدم عادي أو صيدلي.
enum UserType {
  user('user', 'مستخدم'),
  pharmacist('pharmacist', 'صيدلي');

  const UserType(this.value, this.label);
  final String value;
  final String label;

  static UserType fromValue(String? v) =>
      v == UserType.pharmacist.value ? UserType.pharmacist : UserType.user;
}

/// كيان المستخدمين (Users) — مجموعة `users/{userId}`.
///
/// لا تُخزَّن كلمة المرور هنا؛ تتولاها Firebase Authentication (NFR-03).
class AppUser {
  const AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.userType,
    this.phone,
    this.licenseNumber,
    this.createdAt,
  });

  final String userId;
  final String name;
  final String email;
  final String? phone;
  final UserType userType;

  /// رقم ترخيص مزاولة المهنة (للصيدلي فقط — FR-01).
  final String? licenseNumber;
  final DateTime? createdAt;

  bool get isPharmacist => userType == UserType.pharmacist;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return AppUser(
      userId: doc.id,
      name: (d['name'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      phone: d['phone'] as String?,
      userType: UserType.fromValue(d['userType'] as String?),
      licenseNumber: d['licenseNumber'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() => {
    'userId': userId,
    'name': name,
    'email': email,
    'phone': (phone == null || phone!.isEmpty) ? null : phone,
    'userType': userType.value,
    if (isPharmacist) 'licenseNumber': licenseNumber,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
