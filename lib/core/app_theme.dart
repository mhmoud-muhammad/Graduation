import 'package:flutter/material.dart';

/// ألوان الهوية البصرية مأخوذة بالقيمة من تصاميم الفصل الرابع (المعدّل).
abstract final class AppColors {
  /// الأزرار الرئيسية (دخول، بحث، إنشاء الحساب...).
  static const Color primary = Color(0xFF0B9AA2);
  static const Color primaryDark = Color(0xFF087F86);

  /// ترويسة الشاشات الخضراء (نتائج البحث، لوحة الصيدلي، بيانات الصيدلية...).
  static const Color header = Color(0xFF00A19C);

  /// النصوص والعناوين الكحلية.
  static const Color navy = Color(0xFF16246B);
  static const Color navySoft = Color(0xFF1F3A7A);

  /// خلفية الواجهة الرئيسية وشريطها العلوي.
  static const Color homeBg = Color(0xFFB1D3F8);
  static const Color homeBar = Color(0xFFDFECFC);

  /// زر تسجيل الخروج في الواجهة الرئيسية.
  static const Color logoutBlue = Color(0xFF127FA8);

  /// موجات الخلفية.
  static const Color wave = Color(0xFFA0CDEE);
  static const Color waveLight = Color(0xFFD6EAF8);
  static const Color waveTeal = Color(0xFF7FD3CF);

  /// خلفيات فاتحة.
  static const Color background = Color(0xFFEEF6FD);
  static const Color registerBg = Color(0xFFEFF6FA);
  static const Color beige = Color(0xFFF5F3EF);

  /// بطاقات.
  static const Color dashCard = Color(0xFFBBDCF6);
  static const Color mintCard = Color(0xFFDFF1F3);
  static const Color resultCard = Color(0xFFC5E8E2);
  static const Color iconBox = Color(0xFFCEECF2);
  static const Color fieldTint = Color(0xFFE3F1F5);

  /// اسم مستعار قديم لبعض الشاشات.
  static const Color sky = waveLight;
  static const Color skyDeep = wave;

  static const Color border = Color(0xFFD5DEE6);
  static const Color success = Color(0xFF2E9E4F);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerDark = Color(0xFFB2201F);
  static const Color directions = Color(0xFF1A5FD0);
  static const Color muted = Color(0xFF6B7C8F);
}

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.navy,
      surface: Colors.white,
      error: AppColors.danger,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    );
    const buttonText = TextStyle(
      fontFamily: 'Cairo',
      fontSize: 19,
      fontWeight: FontWeight.w800,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        prefixIconColor: AppColors.navySoft,
        suffixIconColor: AppColors.primary,
        hintStyle: const TextStyle(color: Color(0xFF5E6B7A), fontSize: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 2,
          shadowColor: AppColors.primaryDark.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          backgroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shadowColor: AppColors.navy.withValues(alpha: 0.14),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
