import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/firebase_errors.dart';
import '../core/messages.dart';

/// نمط موجات الخلفية كما في التصاميم.
enum WaveStyle {
  /// موجات زرقاء فاتحة (الدخول، البحث، إضافة دواء).
  blue,

  /// موجات فيروزية في الأسفل (إنشاء حساب، بيانات الصيدلية).
  teal,
}

/// خلفية بموجات كما في التصميم.
class WaveBackground extends StatelessWidget {
  const WaveBackground({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.color = AppColors.background,
    this.style = WaveStyle.blue,
    this.gradient,
  });

  final Widget child;
  final bool top;
  final bool bottom;
  final Color color;
  final WaveStyle style;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final colors = style == WaveStyle.teal
        ? const [Color(0xFFBFE9EA), Color(0xFF8ED8D5), Color(0xFF3DB8B4)]
        : const [AppColors.waveLight, Color(0xFFBCDDF4), AppColors.wave];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
      ),
      child: Stack(
        children: [
          if (top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: CustomPaint(
                painter: _WavePainter(flip: true, colors: colors),
              ),
            ),
          if (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 130,
              child: CustomPaint(
                painter: _WavePainter(flip: false, colors: colors),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.flip, required this.colors});
  final bool flip;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    void wave(Color c, double amp, double base, double phase) {
      final p = Path();
      final w = size.width, h = size.height;
      double y(double x) => base + amp * math.sin(x / w * 2 * math.pi + phase);
      if (flip) {
        p.moveTo(0, 0);
        for (double x = 0; x <= w; x += 4) {
          p.lineTo(x, h - y(x));
        }
        p.lineTo(w, 0);
      } else {
        p.moveTo(0, h);
        for (double x = 0; x <= w; x += 4) {
          p.lineTo(x, y(x));
        }
        p.lineTo(w, h);
      }
      p.close();
      canvas.drawPath(p, Paint()..color = c);
    }

    wave(colors[0].withValues(alpha: 0.8), 14, size.height * 0.30, 0);
    wave(colors[1].withValues(alpha: 0.8), 12, size.height * 0.52, 1.6);
    wave(colors[2].withValues(alpha: 0.75), 10, size.height * 0.72, 3.1);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.flip != flip || old.colors != colors;
}

/// أيقونة التطبيق (الكبسولة والعدسة).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// شعار شاشة الدخول: الكبسولة + كلمة "دوائي".
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo_pill.png', height: 86),
        const Text(
          'دوائي',
          style: TextStyle(
            fontSize: 52,
            height: 1.5,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const Text(
          'ابحث عن أدويتك بسهولة',
          style: TextStyle(fontSize: 17, color: Color(0xFF4A5568)),
        ),
      ],
    );
  }
}

/// رسم توضيحي من التصاميم (assets/images).
class Illustration extends StatelessWidget {
  const Illustration(this.name, {super.key, this.height, this.radius = 0});
  final String name;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.asset(
      'assets/images/$name.png',
      height: height,
      fit: BoxFit.contain,
    ),
  );
}

/// ترويسة فيروزية بحافة سفلية منحنية (نتائج البحث، لوحة الصيدلي، أدوية
/// صيدليتي، بيانات الصيدلية، تحديث الدواء).
class TealHeader extends StatelessWidget {
  const TealHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBack = true,
    this.backStyle = BackStyle.plain,
    this.curve = 34,
    this.titleSize = 26,
    this.alignStart = false,
    this.endWidget,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;
  final BackStyle backStyle;
  final double curve;
  final double titleSize;
  final bool alignStart;

  /// عنصر في الطرف الأيسر بدلاً من زر الرجوع (مثل صورة الصيدلي).
  final Widget? endWidget;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final canPop = showBack && Navigator.of(context).canPop();
    Widget? back;
    if (canPop) {
      back = backStyle == BackStyle.circle
          ? Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: AppColors.header,
                onPressed: () => Navigator.maybePop(context),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              color: Colors.white,
              onPressed: () => Navigator.maybePop(context),
            );
    }
    final texts = Column(
      crossAxisAlignment: alignStart
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            textAlign: alignStart ? TextAlign.start : TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
    return ClipPath(
      clipper: _HeaderClipper(curve),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, top + 10, 12, curve + 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF06ABA5), AppColors.header],
          ),
        ),
        child: Row(
          children: [
            if (trailing != null && alignStart) ...[
              trailing!,
              const SizedBox(width: 14),
            ],
            if (!alignStart) SizedBox(width: 48, child: trailing),
            Expanded(child: texts),
            endWidget ?? SizedBox(width: 52, child: back),
          ],
        ),
      ),
    );
  }
}

enum BackStyle { plain, circle }

class _HeaderClipper extends CustomClipper<Path> {
  _HeaderClipper(this.curve);
  final double curve;

  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height)
    ..quadraticBezierTo(
      size.width / 2,
      size.height - curve * 2,
      size.width,
      size.height,
    )
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(covariant _HeaderClipper old) => old.curve != curve;
}

/// صندوق أيقونة فاتح بجانب الحقول (شاشة بيانات الصيدلية).
class IconBox extends StatelessWidget {
  const IconBox(this.icon, {super.key, this.size = 52});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.iconBox,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: AppColors.header, size: size * 0.55),
  );
}

/// زر رئيسي يعرض مؤشر تحميل أثناء التنفيذ.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 10)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );
    return FilledButton(
      style: color == null
          ? null
          : FilledButton.styleFrom(backgroundColor: color),
      onPressed: loading ? null : onPressed,
      child: child,
    );
  }
}

/// حالة فارغة / رسالة في منتصف الشاشة.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppColors.sky,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// عنوان قسم مع أيقونة.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
          if (icon != null) Icon(icon, color: AppColors.primary, size: 28),
        ],
      ),
    );
  }
}

/// تسمية حقل فوق مربع الإدخال (كما في شاشة بيانات الصيدلية).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 12, right: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
    ),
  );
}

/// رسالة خطأ بنص المخطط مع زر "رجوع" للعودة وتصحيح البيانات.
Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  String? reason,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
      title: Text(title, textAlign: TextAlign.center),
      content: reason == null || reason == title
          ? null
          : Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(140, 46)),
          onPressed: () => Navigator.pop(ctx),
          child: const Text(Msg.back),
        ),
      ],
    ),
  );
}

/// رسالة ضعف الاتصال مع زر "إعادة المحاولة" (NFR-06). تعيد true للإعادة.
Future<bool> showRetryDialog(BuildContext context, String message) async {
  final again = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.wifi_off, color: AppColors.danger, size: 40),
      title: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(Msg.cancel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(150, 46)),
          icon: const Icon(Icons.refresh),
          label: const Text(Msg.retry),
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  return again ?? false;
}

/// ينفذ [action] كما في مخططات التسلسل: عند ضعف الاتصال تظهر [networkMessage]
/// مع "إعادة المحاولة"، وعند أي خطأ آخر تظهر [errorTitle] مع السبب.
/// تعيد true عند النجاح.
Future<bool> runWithRetry(
  BuildContext context,
  Future<void> Function() action, {
  required String networkMessage,
  required String errorTitle,
}) async {
  while (true) {
    try {
      await action();
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      if (isNetworkError(e)) {
        final again = await showRetryDialog(context, networkMessage);
        if (again && context.mounted) continue;
        return false;
      }
      await showErrorDialog(
        context,
        title: errorTitle,
        reason: friendlyError(e),
      );
      return false;
    }
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.navy,
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(90, 44),
            backgroundColor: destructive ? AppColors.danger : null,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}
