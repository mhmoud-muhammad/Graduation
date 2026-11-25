/// إعدادات عامة للتطبيق.
abstract final class AppConfig {
  static const String appName = 'دوائي';

  /// نموذج Gemini المستخدم لتحليل صور العبوات والروشتات (عبر Firebase AI Logic).
  /// يمكن تغييره بدون تعديل الكود: --dart-define=GEMINI_MODEL=...
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash-lite',
  );

  /// رمز العملة المعروض بجانب الأسعار (جنيه سوداني).
  static const String currency = 'ج.س';

  /// موقع افتراضي للخريطة (الخرطوم) عند عدم توفر موقع المستخدم.
  static const double defaultLat = 15.5007;
  static const double defaultLng = 32.5599;

  /// الأشكال الصيدلانية المتاحة عند إضافة دواء (FR-09).
  static const List<String> pharmaceuticalForms = [
    'أقراص',
    'كبسولات',
    'شراب',
    'حقن',
    'مرهم',
    'كريم',
    'قطرات',
    'بخاخ',
    'فوار',
    'تحاميل',
    'أخرى',
  ];

  /// مهلة العمليات الشبكية قبل اعتبار الاتصال ضعيفاً (NFR-06).
  static const Duration networkTimeout = Duration(seconds: 15);
}
