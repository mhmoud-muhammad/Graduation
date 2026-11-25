import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

/// خطأ في التطبيق برسالة عربية جاهزة للعرض.
class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// تعذر الاتصال بالإنترنت أو بالخادم (NFR-06).
class NetworkException extends AppException {
  NetworkException([super.message = 'تعذر الاتصال بالإنترنت']);
}

/// هل الخطأ ناتج عن ضعف أو انقطاع الاتصال؟
bool isNetworkError(Object e) {
  if (e is NetworkException) return true;
  if (e is TimeoutException || e is SocketException) return true;
  if (e is FirebaseAuthException) {
    return e.code == 'network-request-failed' || e.code == 'too-many-requests';
  }
  if (e is FirebaseException) {
    return const {
      'unavailable',
      'deadline-exceeded',
      'network-request-failed',
    }.contains(e.code);
  }
  return false;
}

/// سبب تفصيلي يظهر تحت رسالة المخطط.
String friendlyError(Object e) {
  if (e is AppException) return e.message;
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
  if (e is TimeoutException || e is SocketException) {
    return 'تعذر الاتصال بالإنترنت';
  }
  return 'حدث خطأ غير متوقع';
}
