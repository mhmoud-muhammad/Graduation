import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'user_repository.dart';

/// إدارة الحسابات عبر Firebase Authentication (FR-01, FR-02, FR-03).
class AuthService {
  AuthService(this._auth, this._users);

  final FirebaseAuth _auth;
  final UserRepository _users;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// ينشئ الحساب في Authentication ثم يحفظ بياناته ونوعه في مجموعة users.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserType userType,
    String? phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    try {
      await cred.user!.updateDisplayName(name.trim());
      await _users.create(
        AppUser(
          userId: uid,
          name: name.trim(),
          email: email.trim(),
          phone: phone?.trim(),
          userType: userType,
        ),
      );
    } catch (_) {
      // لا نترك حساباً بدون وثيقة مستخدم.
      await cred.user!.delete().catchError((_) {});
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();
}
