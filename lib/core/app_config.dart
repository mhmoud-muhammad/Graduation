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

  /// الموقع الافتراضي للخريطة: مدينة عطبرة (عند عدم توفر موقع المستخدم).
  static const double defaultLat = 17.7022;
  static const double defaultLng = 33.9869;

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
