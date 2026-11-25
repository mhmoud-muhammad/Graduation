import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/app_theme.dart';
import '../../core/messages.dart';
import '../../services/search_service.dart';
import '../../services/services.dart';
import 'search_results_screen.dart';

/// الجزء المشترك من تسلسلي البحث بالكتابة وبالصورة بعد جلب بيانات
/// الصيدليات المتوفر فيها الدواء:
/// طلب إذن الموقع ← "هل تسمح بالوصول إلى موقعك؟"
/// - رفض: عرض الصيدليات مع السعر والكمية والموقع والشكل الصيدلاني دون ترتيب
/// - سماح: حساب المسافة وترتيب الصيدليات حسب الأقرب ثم عرضها.
Future<void> showSearchResults(
  BuildContext context,
  RawSearch raw, {
  required String query,
}) async {
  final loc = Services.I.location;
  var allowed = await loc.hasPermission();
  if (!allowed && context.mounted) allowed = await _askLocation(context);
  Position? me;
  if (allowed) me = await loc.requestAndGet();
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SearchResultsScreen(
        outcome: SearchService.arrange(raw, me),
        query: query,
      ),
    ),
  );
}

Future<bool> _askLocation(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(
        Icons.location_on_outlined,
        color: AppColors.primary,
        size: 40,
      ),
      title: const Text(Msg.askLocation, textAlign: TextAlign.center),
      content: const Text(
        Msg.askLocationDetails,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('رفض'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('السماح'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
