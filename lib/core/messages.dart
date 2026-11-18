/// رسائل النظام كما وردت حرفياً في مخططات التسلسل (Sequence Diagrams)
/// في الفصل الثالث، حتى يطابق سلوك التطبيق التحليل.
abstract final class Msg {
  // مخطط تسلسل تسجيل الدخول (المستخدم / الصيدلي)
  static const invalidReenter = 'البيانات غير صحيحة، الرجاء إعادة الإدخال';

  // مخطط تسلسل إنشاء حساب المستخدم
  static const invalidRetry = 'البيانات غير صحيحة، الرجاء إعادة المحاولة';
  static const accountCreated = 'تم إنشاء الحساب وحفظه';

  // مخطط تسلسل الصيدلي (إدارة الصيدلية والأدوية)
  static const pharmacySaved = 'تم حفظ بيانات الصيدلية';
  static const medicineAdded = 'تمت إضافة الدواء بنجاح';
  static const medicineUpdated = 'تم تحديث البيانات بنجاح';
  static const medicineDeleted = 'تم حذف الدواء بنجاح';

  // مخطط تسلسل البحث بالصورة
  static const imageNotRecognized =
      'لم يتم التعرف على اسم الدواء من الصورة، جرّب صورة أوضح أو ابحث بالكتابة';

  static const back = 'رجوع';
}
