import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'gemini_service.dart';
import 'location_service.dart';
import 'medicine_repository.dart';
import 'pharmacy_repository.dart';
import 'search_service.dart';
import 'user_repository.dart';

/// حاوية بسيطة للخدمات. كل خدمة تُنشأ عند أول استخدام لها فقط
/// (خدمة الموقع مثلاً لا تحتاج تهيئة Firebase).
class Services {
  Services._();

  static Services? _instance;
  static Services get I => _instance ??= Services._();

  late final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final UserRepository users = UserRepository(_db);
  late final AuthService auth = AuthService(FirebaseAuth.instance, users);
  late final PharmacyRepository pharmacies = PharmacyRepository(_db);
  late final MedicineRepository medicines = MedicineRepository(_db);
  late final LocationService location = LocationService();
  late final GeminiService gemini = GeminiService();
  late final SearchService search = SearchService(medicines, pharmacies);
}
