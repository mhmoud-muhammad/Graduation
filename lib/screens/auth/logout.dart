import 'package:flutter/material.dart';

import '../../core/messages.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';

/// تسلسل تسجيل الخروج (المستخدم / الصيدلي): الضغط على "تسجيل الخروج" ←
/// "هل تريد تسجيل الخروج؟" ← تأكيد ← طلب إنهاء الجلسة:
/// - ضعف الإنترنت: "تعذر تسجيل الخروج، الرجاء المحاولة عند توفر الإنترنت"
///   مع إعادة المحاولة
/// - تم إنهاء الجلسة بنجاح ← الانتقال إلى شاشة تسجيل الدخول.
Future<void> confirmAndSignOut(BuildContext context) async {
  final ok = await confirmDialog(
    context,
    title: 'تسجيل الخروج',
    message: Msg.logoutConfirm,
    confirmLabel: 'تسجيل الخروج',
  );
  if (!ok || !context.mounted) return;
  final done = await runWithRetry(
    context,
    Services.I.auth.signOut,
    networkMessage: Msg.logoutNetwork,
    errorTitle: 'تعذر تسجيل الخروج',
  );
  if (done && context.mounted) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}
