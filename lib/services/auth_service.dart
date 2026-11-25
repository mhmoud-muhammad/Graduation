import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'network_service.dart';
import 'user_repository.dart';

/// إدارة الحسابات عبر Firebase Authentication (FR-01, FR-02, FR-03).
class AuthService {
  AuthService(this._auth, this._users);

  final FirebaseAuth _auth;
  final UserRepository _users;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// تسلسل تسجيل الدخول: إرسال البيانات للتحقق منها عبر Firebase
  /// Authentication ← ثم يقرأ AuthGate نوع الحساب من users ويوجّه المستخدم.
  Future<void> signIn(String email, String password) => Net.guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  /// تسلسل إنشاء حساب: التحقق من البيانات ← إنشاء الحساب في Firebase
  /// Authentication ← حفظ بيانات المستخدم ونوع حسابه في users ←
  /// "تم إنشاء الحساب بنجاح" وتوجيهه إلى شاشة تسجيل الدخول (لذلك نُنهي
  /// الجلسة التي ينشئها Firebase تلقائياً بعد الإنشاء).
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserType userType,
    String? phone,
    String? licenseNumber,
  }) async {
    final cred = await Net.guard(
      () => _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
    final user = cred.user!;
    try {
      await user.updateDisplayName(name.trim());
      await Net.guard(
        () => _users.create(
          AppUser(
            userId: user.uid,
            name: name.trim(),
            email: email.trim(),
            phone: phone?.trim(),
            userType: userType,
            licenseNumber: licenseNumber?.trim(),
          ),
        ),
      );
    } catch (_) {
      // لا نترك حساباً بدون وثيقة مستخدم.
      await user.delete().catchError((_) {});
      await _auth.signOut();
      rethrow;
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      Net.guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  /// تسلسل تسجيل الخروج: طلب إنهاء الجلسة ← (ضعف الإنترنت: تعذر تسجيل
  /// الخروج) ← تم إنهاء الجلسة بنجاح ← الانتقال إلى شاشة تسجيل الدخول.
  Future<void> signOut() async {
    await Net.ensureOnline();
    await _auth.signOut();
  }
}
