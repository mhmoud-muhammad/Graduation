/// رسائل النظام كما وردت في مخططات التسلسل وأوصاف حالات الاستخدام
/// (الفصل الثالث)، مجمّعة في مكان واحد ليطابق سلوك التطبيق التحليل.
abstract final class Msg {
  // ---------------------------------------------------------- عام
  static const retry = 'إعادة المحاولة';
  static const cancel = 'إلغاء';
  static const back = 'رجوع';

  // ---------------------------------------------------------- تسجيل الدخول
  static const loginNetwork =
      'تعذر تسجيل الدخول، الرجاء إعادة المحاولة عند توفر اتصال';
  static const loginInvalid = 'البيانات غير صحيحة، قم بتصحيحها';

  // ---------------------------------------------------------- إنشاء حساب
  static const registerNetwork =
      'فشلت عملية إنشاء الحساب، الرجاء المحاولة مرة أخرى عند توفر اتصال';
  static const registerInvalid =
      'البيانات غير صحيحة أو البريد الإلكتروني مستخدم مسبقاً، قم بتصحيحها';
  static const registerSuccess =
      'تم إنشاء الحساب بنجاح، يمكنك الآن تسجيل الدخول';

  // ---------------------------------------------------------- تسجيل الخروج
  static const logoutConfirm = 'هل تريد تسجيل الخروج؟';
  static const logoutNetwork =
      'تعذر تسجيل الخروج، الرجاء المحاولة عند توفر الإنترنت';

  // ---------------------------------------------------------- البحث
  static const searchNetwork =
      'تعثرت العملية، الرجاء إعادة المحاولة عند توفر الاتصال';
  static const imageNetwork =
      'تعثرت العملية بسبب ضعف الإنترنت، الرجاء إعادة المحاولة';
  static const medicineNotAvailable = 'الدواء غير متوفر';
  static const medicineNotAvailableNow =
      'الدواء غير متوفر حالياً في أي صيدلية مسجلة';
  static const imageUnclear = 'الصورة غير واضحة، قم بتحميل صورة أوضح';
  static const askLocation = 'هل تسمح بالوصول إلى موقعك؟';
  static const askLocationDetails =
      'لترتيب الصيدليات حسب الأقرب إليك. يُستخدم موقعك وقت البحث فقط '
      'ولا يُحفظ.';
  static const locationDenied =
      'لم يتم السماح بالوصول إلى الموقع، لذلك تُعرض الصيدليات دون ترتيب حسب القرب';

  // ---------------------------------------------------------- الصيدلي
  static const operationNetwork =
      'تعذرت العملية، الرجاء إعادة المحاولة عند توفر اتصال';
  static const invalidOrIncomplete =
      'البيانات غير صحيحة أو غير مكتملة، الرجاء تصحيح البيانات';
  static const incomplete = 'البيانات غير مكتملة، الرجاء تصحيح البيانات';
  static const savedSuccess = 'تم الحفظ بنجاح';
  static const pickLocation = 'حدد موقع الصيدلية على الخريطة';
  static const addSuccess = 'تمت الإضافة بنجاح';
  static const updateNotFound = 'الدواء غير متوفر لذا لا يمكن تعديله';
  static const updateInvalid =
      'البيانات غير صحيحة، الرجاء مراجعة المدخلات والمحاولة مجدداً';
  static const updateSuccess = 'تم تعديل السعر أو الكمية في قائمة الأدوية';
  static const deleteNotFound = 'هذا الدواء غير موجود لذا لا يمكن حذفه';
  static const deleteConfirm = 'هل تريد حذف هذا الدواء من قائمة الصيدلية؟';
  static const deleteSuccess = 'تم حذف الدواء من قائمة الأدوية';
  static const needPharmacy = 'سجّل بيانات الصيدلية أولاً';
  static const notInPharmacy =
      'هذا الدواء غير موجود في قائمة الصيدلية لذا لا يمكن تعديله أو حذفه';
}
