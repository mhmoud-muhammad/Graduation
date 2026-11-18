import 'package:firebase_auth/firebase_auth.dart';

/// تحويل أخطاء Firebase إلى رسائل عربية مفهومة.
String friendlyError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'تم إيقاف هذا الحساب';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم مسبقاً';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، استخدم 6 أحرف على الأقل';
      case 'network-request-failed':
        return 'تعذر الاتصال بالإنترنت';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      case 'operation-not-allowed':
        return 'تسجيل الدخول بالبريد غير مفعّل في Firebase Console';
    }
    return e.message ?? 'حدث خطأ في المصادقة';
  }
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'ليس لديك صلاحية لتنفيذ هذه العملية';
      case 'unavailable':
        return 'الخدمة غير متاحة حالياً، تحقق من الاتصال';
    }
    return e.message ?? 'حدث خطأ في قاعدة البيانات';
  }
  if (e is AppException) return e.message;
  return 'حدث خطأ غير متوقع';
}

class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}
