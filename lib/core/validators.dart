abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? required(String? v, [String field = 'هذا الحقل']) =>
      (v == null || v.trim().isEmpty) ? '$field مطلوب' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    if (!_email.hasMatch(v.trim())) return 'صيغة البريد الإلكتروني غير صحيحة';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
    if (v.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  static String? optionalPhone(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final digits = v.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 7) return 'رقم الهاتف غير صحيح';
    return null;
  }

  static String? price(String? v) {
    final x = double.tryParse((v ?? '').trim());
    if (x == null) return 'أدخل سعراً صحيحاً';
    if (x < 0) return 'السعر لا يمكن أن يكون سالباً';
    return null;
  }

  static String? quantity(String? v) {
    final x = int.tryParse((v ?? '').trim());
    if (x == null) return 'أدخل كمية صحيحة (عدد صحيح)';
    if (x < 0) return 'الكمية لا يمكن أن تكون سالبة';
    return null;
  }

  static String? latitude(String? v) {
    final x = double.tryParse((v ?? '').trim());
    if (x == null || x < -90 || x > 90) return 'خط العرض بين -90 و 90';
    return null;
  }

  static String? longitude(String? v) {
    final x = double.tryParse((v ?? '').trim());
    if (x == null || x < -180 || x > 180) return 'خط الطول بين -180 و 180';
    return null;
  }
}
