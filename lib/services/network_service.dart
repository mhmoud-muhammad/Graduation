import 'dart:async';
import 'dart:io';

import '../core/app_config.dart';
import '../core/firebase_errors.dart';

/// التحقق من الاتصال بالإنترنت قبل العمليات الشبكية (NFR-06).
///
/// Firestore يحفظ الكتابات محلياً وينتظر عند انقطاع الاتصال بدلاً من
/// إرجاع خطأ، لذلك نتحقق من الاتصال أولاً ونضع مهلة لكل عملية حتى يظهر
/// للمستخدم رسالة واضحة مع إمكانية إعادة المحاولة.
abstract final class Net {
  static const _probeHosts = ['firestore.googleapis.com', 'google.com'];

  static Future<bool> isOnline() async {
    for (final host in _probeHosts) {
      try {
        final r = await InternetAddress.lookup(
          host,
        ).timeout(const Duration(seconds: 5));
        if (r.isNotEmpty && r.first.rawAddress.isNotEmpty) return true;
      } catch (_) {
        // جرّب العنوان التالي.
      }
    }
    return false;
  }

  static Future<void> ensureOnline() async {
    if (!await isOnline()) throw NetworkException();
  }

  /// يتحقق من الاتصال ثم ينفذ [op] بمهلة؛ تجاوز المهلة = ضعف اتصال.
  static Future<T> guard<T>(
    Future<T> Function() op, {
    Duration? timeout,
  }) async {
    await ensureOnline();
    try {
      return await op().timeout(timeout ?? AppConfig.networkTimeout);
    } on TimeoutException {
      throw NetworkException();
    }
  }
}
