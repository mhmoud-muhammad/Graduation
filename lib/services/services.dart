import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'gemini_service.dart';
import 'location_service.dart';
import 'medicine_repository.dart';
import 'pharmacy_repository.dart';
import 'search_service.dart';
import 'user_repository.dart';

/// حاوية بسيطة للخدمات (تُنشأ مرة واحدة بعد تهيئة Firebase).
class Services {
  Services._() {
    final db = FirebaseFirestore.instance;
    users = UserRepository(db);
    auth = AuthService(FirebaseAuth.instance, users);
    pharmacies = PharmacyRepository(db);
    medicines = MedicineRepository(db);
    location = LocationService();
    gemini = GeminiService();
    search = SearchService(medicines, pharmacies);
  }

  static Services? _instance;
  static Services get I => _instance ??= Services._();

  late final UserRepository users;
  late final AuthService auth;
  late final PharmacyRepository pharmacies;
  late final MedicineRepository medicines;
  late final LocationService location;
  late final GeminiService gemini;
  late final SearchService search;
}
