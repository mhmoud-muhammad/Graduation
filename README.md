# دوائي — تطبيق البحث عن الأدوية في الصيدليات (مشروع زها)

تطبيق موبايل (Flutter) يساعد المستخدم على معرفة الصيدليات التي يتوفر فيها الدواء
**بالكتابة** (الاسم التجاري أو العلمي) أو **بالصورة** (عبوة الدواء أو الروشتة من المعرض
أو بالكاميرا)، مع عرض السعر والكمية والموقع والشكل الصيدلاني، وترتيب الصيدليات حسب
الأقرب عند السماح بالموقع، وعرضها على الخريطة. ويتيح للصيدلي تسجيل صيدلية أو أكثر
وتعديل بياناتها، وإضافة الأدوية وتعديل أسعارها وكمياتها وحذفها.

## الهوية البصرية

الألوان مأخوذة بالقيمة من تصاميم الفصل الرابع ومعرّفة في `lib/core/app_theme.dart`:
الأزرار `#0B9AA2`، الترويسات `#00A19C`، النصوص الكحلية `#16246B`، خلفية الواجهة الرئيسية
`#B1D3F8`، بطاقات لوحة الصيدلي `#BBDCF6`، بطاقات أدوية صيدليتي `#DFF1F3`، بطاقة الدواء في
النتائج `#C5E8E2`، زر تسجيل الخروج `#127FA8`، وزر الحذف `#C62828`.
الرسومات التوضيحية (الكبسولة، مبنى الصيدلية، القوارير، الكبسولات، صورة الصيدلي) مقتطعة من
التصاميم نفسها وموجودة في `assets/images/`.

- العملة الافتراضية: **الجنيه السوداني (ج.س)** — `AppConfig.currency`.
- الموقع الافتراضي للخريطة: **مدينة عطبرة** (17.7022, 33.9869) — `AppConfig.defaultLat/defaultLng`.

## التقنيات

| المكوّن | التقنية |
|---|---|
| التطبيق | Flutter / Dart (واجهات عربية RTL بخط Cairo) |
| المصادقة | Firebase Authentication (بريد وكلمة مرور، دون تخزين كلمات المرور في قاعدة البيانات) |
| قاعدة البيانات | Cloud Firestore + قواعد أمان `firestore.rules` |
| تحليل الصور | Google Gemini عبر **Firebase AI Logic** (`firebase_ai`) — بدون مفتاح API داخل التطبيق |
| الموقع والخرائط | Geolocator + Google Maps for Flutter |

## المتطلبات الوظيفية

| الرمز | المتطلب | الكود |
|---|---|---|
| FR-01 | إنشاء حساب بالاسم والبريد والهاتف وكلمة المرور ونوع الحساب، ورقم ترخيص مزاولة المهنة للصيدلي | `screens/auth/register_screen.dart` |
| FR-02 | تسجيل الدخول عبر Firebase Authentication | `screens/auth/login_screen.dart` |
| FR-03 | التوجيه حسب نوع الحساب وتسجيل الخروج | `screens/auth/auth_gate.dart`, `screens/auth/logout.dart` |
| FR-04 | البحث بالاسم العلمي أو التجاري | `screens/user/text_search_screen.dart` |
| FR-05/06/07 | صورة العبوة أو الروشتة من المعرض، أو تصوير العبوة بالكاميرا | `screens/user/image_search_screen.dart` |
| FR-08 | تسجيل بيانات الصيدلية وموقعها وتعديلها | `screens/pharmacist/pharmacy_info_screen.dart` |
| FR-09 | إضافة دواء بالاسم العلمي والتجاري والسعر والكمية والشكل الصيدلاني | `screens/pharmacist/add_medicine_screen.dart` |
| FR-10 | تعديل سعر الدواء وكميته | `screens/pharmacist/update_medicine_screen.dart` |
| FR-11 | حذف دواء بعد تأكيد العملية | `screens/pharmacist/update_medicine_screen.dart` |
| FR-12 | عرض أدوية الصيدلية | `screens/pharmacist/my_medicines_screen.dart` |
| FR-13 | تحليل الصورة بـ Gemini ومطابقتها مع الأدوية | `services/gemini_service.dart`, `SearchService.findByAnalysis` |
| FR-14 | عرض النتائج (الصيدلية، السعر، الكمية، الشكل الصيدلاني) أو رسالة عدم الوجود/عدم التوفر | `screens/user/search_results_screen.dart` |
| FR-15 | طلب إذن الموقع والترتيب حسب القرب، والعرض دون ترتيب عند الرفض | `screens/user/search_flow.dart`, `services/offer_ranking.dart` |
| FR-16 | عرض الصيدليات على الخريطة | `screens/user/map_screen.dart` |

| الرمز | المتطلب غير الوظيفي | التنفيذ |
|---|---|---|
| NFR-01 | واجهات عربية RTL، البحث في خطوتين أو ثلاث | `app.dart` (locale ar) |
| NFR-02 | سرعة البحث | فهرس `searchKeys` (بادئات الاسمين) لبحث Firestore المباشر |
| NFR-03 | الأمان | Firebase Auth + `firestore.rules` (الكتابة لمالك الصيدلية فقط، المستخدم العادي لا يعدّل الصيدليات أو الأدوية) |
| NFR-04 | فصل الطبقات | `lib/models` ← `lib/services` ← `lib/screens` |
| NFR-05 | Android 8.0 فما فوق + iOS | `minSdk = 26`، ومجلد `ios/` |
| NFR-06 | رسالة واضحة مع **إعادة المحاولة** عند ضعف الاتصال | `services/network_service.dart`, `runWithRetry` في `widgets/common.dart` |
| NFR-07 | الموقع يُستخدم وقت البحث فقط ولا يُخزَّن | `services/location_service.dart` |

## هيكل المشروع

```
lib/
├── main.dart / app.dart          تهيئة Firebase والثيم والاتجاه العربي
├── firebase_options.dart         يُولَّد بـ flutterfire configure
├── core/                         الإعدادات، الثيم، رسائل المخططات، التحقق، تطبيع النص
├── models/                       AppUser, Pharmacy, Medicine, Availability
├── services/                     المصادقة، المستودعات، البحث، Gemini، الموقع، الاتصال
├── widgets/                      عناصر واجهة مشتركة (رسائل الخطأ وإعادة المحاولة)
└── screens/
    ├── auth/                     الدخول، إنشاء الحساب، التوجيه، تسجيل الخروج
    ├── user/                     الرئيسية، البحث بالكتابة/بالصورة، النتائج، الخريطة
    └── pharmacist/               لوحة الصيدلي، بيانات الصيدلية، إضافة دواء،
                                  تحديث بيانات الأدوية، أدوية صيدليتي
```

## قاعدة البيانات (Firestore)

| المجموعة | المعرّف | الحقول |
|---|---|---|
| `users` | UID من Auth | `userId, name, email, phone, userType (user/pharmacist), licenseNumber (للصيدلي), createdAt` |
| `pharmacies` | تلقائي | `pharmacyId, ownerId, pharmacyName, address, phone, latitude, longitude, updatedAt` |
| `medicines` | تلقائي | `medicineId, tradeName, scientificName, pharmaceuticalForm` + حقلان تقنيان للبحث: `searchKeys, identityKey` |
| `availability` | `{pharmacyId}_{medicineId}` | `availabilityId, medicineId, pharmacyId, price, quantity, updatedAt` |

**العلاقات (ERD):**
- «يدير»: الصيدلي (`userType = pharmacist`) ← صيدلية أو أكثر عبر `ownerId` (واحد إلى متعدد).
- «تسجل توفر»: الصيدلية ← سجلات توفر متعددة عبر `pharmacyId`.
- «متوفر في»: الدواء ← سجلات توفر في صيدليات مختلفة عبر `medicineId`.

مثال: «بنادول» متوفر في صيدليتين بسعرين مختلفين ← يُحفظ مرة واحدة في `medicines` وسجلان في `availability`.
وعند حذف دواء من صيدلية يُحذف سجل التوفر فقط ويبقى الدواء العام لبقية الصيدليات.

## مطابقة مخططات التسلسل والنشاط (الفصل الثالث)

رسائل النظام مأخوذة من المخططات ومجمّعة في `lib/core/messages.dart`،
وكل دالة منفذة عليها تعليق بخطوات المخطط الذي تطبقه.

| المخطط | التسلسل في التطبيق |
|---|---|
| تسجيل الدخول (المستخدم/الصيدلي) | إدخال البريد وكلمة المرور ← دخول ← ضعف الإنترنت: «تعذر تسجيل الدخول…» + إعادة المحاولة ← بيانات خاطئة: «البيانات غير صحيحة، قم بتصحيحها» ← صحيحة: قراءة نوع الحساب من `users` وفتح واجهة البحث أو لوحة الصيدلي |
| إنشاء حساب (المستخدم/الصيدلي) | إدخال البيانات ونوع الحساب ← إنشاء الحساب ← ضعف الاتصال: «فشلت عملية إنشاء الحساب…» ← بريد مستخدم/بيانات خاطئة: رسالة ثم التصحيح ← إنشاء الحساب في Auth وحفظه في `users` ← «تم إنشاء الحساب بنجاح» والتوجيه إلى **شاشة تسجيل الدخول** |
| تسجيل الخروج | الضغط على تسجيل الخروج ← «هل تريد تسجيل الخروج؟» ← تأكيد ← ضعف الإنترنت: «تعذر تسجيل الخروج…» + إعادة المحاولة ← إنهاء الجلسة والانتقال لشاشة الدخول |
| البحث بالكتابة | إدخال الاسم ← بحث ← ضعف الإنترنت: «تعثرت العملية…» + إعادة المحاولة ← غير موجود في `medicines`: «الدواء غير متوفر» ← موجود: البحث في `availability` ← «هل تسمح بالوصول إلى موقعك؟» ← رفض: العرض دون ترتيب / سماح: حساب المسافة والترتيب حسب الأقرب |
| البحث بالصورة | رفع صورة أو التقاطها ← ضعف الإنترنت: رسالة + إعادة المحاولة ← Gemini: «الصورة غير واضحة، قم بتحميل صورة أوضح» ← إرجاع معلومات الدواء والشكل الصيدلاني ← البحث في `medicines` ثم `availability` ← طلب إذن الموقع ← العرض |
| حفظ / تعديل بيانات الصيدلية | إدخال البيانات ← **تسجيل** أو **تعديل** ← ضعف الإنترنت: رسالة + إعادة المحاولة ← غير مكتملة (الاسم أو الموقع): رسالة دون حفظ ← الحفظ في `pharmacies` ← «تم الحفظ بنجاح» |
| إضافة دواء | إدخال الأسماء والشكل الصيدلاني والسعر والكمية ← فارغ أو سالب: رسالة ← البحث في `medicines` وإنشاؤه إن لم يوجد ← حفظ سجل التوفر في `availability` ← «تمت الإضافة بنجاح» |
| تعديل دواء | إدخال اسم الدواء ← غير موجود: «…لا يمكن تعديله» ← عرض بياناته ← تعديل السعر أو الكمية ← قيم سالبة: رسالة ← تحديث `availability` ← «تم تعديل السعر أو الكمية في قائمة الأدوية» |
| حذف دواء | إدخال اسم الدواء ← غير موجود: «…لا يمكن حذفه» ← عرض بياناته ← حذف ← تأكيد ← حذف سجل التوفر من `availability` ← «تم حذف الدواء من قائمة الأدوية» |
| نشاط المستخدم | الدخول ← البحث بالكتابة ← البحث بالصورة ← تسجيل الخروج |
| نشاط الصيدلي | الدخول ← تسجيل بيانات الصيدلية ← تعديلها ← إضافة دواء ← تعديل سعره أو كميته ← حذف دواء ← تسجيل الخروج |

---

## خطوات التشغيل والربط مع Firebase

### 1) المتطلبات
- Flutter SDK 3.47 أو أحدث (Dart 3.13+) — `flutter doctor`
- هاتف Android 8.0 أو أحدث للتجربة
- حساب Firebase و Node.js (لأداة `firebase`)

### 2) إنشاء مشروع Firebase وتفعيل الخدمات
من [Firebase Console](https://console.firebase.google.com):
1. **Create project**.
2. **Authentication → Sign-in method →** فعّل **Email/Password**.
3. **Firestore Database → Create database** (Production mode).
4. **AI Logic → Get started →** اختر **Gemini Developer API** (مجاني ضمن الحدود).

### 3) ربط التطبيق بالمشروع
```bash
npm install -g firebase-tools
```
```bash
firebase login
```
```bash
dart pub global activate flutterfire_cli
```
```bash
flutterfire configure --project=<FIREBASE_PROJECT_ID> --platforms=android,ios
```
سيستبدل الأمر الأخير الملف `lib/firebase_options.dart` بقيم مشروعك ويسجّل تطبيقي
Android (`com.zaha.dawai`) و iOS.

### 4) نشر قواعد الأمان
```bash
firebase deploy --only firestore:rules,firestore:indexes --project <FIREBASE_PROJECT_ID>
```

### 5) مفتاح Google Maps
من [Google Cloud Console](https://console.cloud.google.com/google/maps-apis) لنفس المشروع:
فعّل **Maps SDK for Android** و **Maps SDK for iOS** وأنشئ مفتاح API، ثم:
- **Android**: أضف السطر التالي إلى `android/local.properties` (لا يُرفع إلى Git):
  ```
  MAPS_API_KEY=ضع_المفتاح_هنا
  ```
- **iOS**: انسخ `ios/Flutter/MapsKey.xcconfig.example` إلى `ios/Flutter/MapsKey.xcconfig` وضع المفتاح.

### 6) التشغيل
```bash
flutter pub get
```
```bash
flutter run
```
بناء APK:
```bash
flutter build apk --release
```

### 7) تجربة النظام
1. أنشئ حساباً بنوع **صيدلي** (مع رقم الترخيص) ← يعود التطبيق لشاشة الدخول ← سجّل الدخول.
2. «بيانات الصيدلية» ← أدخل الاسم وحدد الموقع ← **تسجيل**.
3. «إضافة دواء» (مثال: `Panadol` / `Paracetamol` / السعر 15 / الكمية 50 / أقراص).
4. سجّل الخروج وأنشئ حساباً بنوع **مستخدم** ← «البحث بالكتابة» ← اكتب `pana` أو `باراسيتامول`،
   أو «البحث بالصورة» وصوّر العبوة ← اسمح بالوصول للموقع لترتيب الصيدليات حسب الأقرب.

> لتغيير نموذج Gemini بدون تعديل الكود:
> `flutter run --dart-define=GEMINI_MODEL=<model-name>` (الافتراضي في `lib/core/app_config.dart`).

## الاختبارات
```bash
flutter test
```
تغطي تطبيع النص العربي ومفاتيح البحث، وترتيب الصيدليات حسب القرب أو عرضها دون ترتيب عند رفض الموقع، وبناء نتائج البحث، وقراءة رد Gemini.
