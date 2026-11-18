# دوائي — تطبيق البحث عن الأدوية في الصيدليات (مشروع زها)

تطبيق موبايل (Flutter) يساعد المستخدم على معرفة الصيدليات التي يتوفر فيها الدواء
**بالكتابة** (الاسم التجاري أو العلمي أو الباركود) أو **بالصورة** (عبوة الدواء أو
الروشتة من المعرض أو بالكاميرا) مع عرض السعر والكمية والمسافة، وترتيب الصيدليات
حسب الأقرب، وعرضها على الخريطة. ويتيح للصيدلي تسجيل صيدليته وموقعها وإدارة أدويتها.

## التقنيات

| المكوّن | التقنية |
|---|---|
| التطبيق | Flutter / Dart (واجهات عربية RTL بخط Cairo) |
| المصادقة | Firebase Authentication (بريد وكلمة مرور) |
| قاعدة البيانات | Cloud Firestore + قواعد أمان `firestore.rules` |
| تحليل الصور | Gemini عبر **Firebase AI Logic** (`firebase_ai`) — بدون مفتاح API داخل التطبيق |
| الموقع والخرائط | Geolocator + Google Maps for Flutter |

## المتطلبات المنفذة

| الرمز | المتطلب | المكان في الكود |
|---|---|---|
| FR-01 | إنشاء حساب مع نوع الحساب | `screens/auth/register_screen.dart` |
| FR-02 | تسجيل الدخول عبر Firebase Auth | `screens/auth/login_screen.dart` |
| FR-03 | التوجيه حسب نوع الحساب وتسجيل الخروج | `screens/auth/auth_gate.dart` |
| FR-04 | البحث بالاسم العلمي/التجاري/الباركود | `screens/user/text_search_screen.dart` |
| FR-05/06/07 | البحث بصورة العبوة أو الروشتة (معرض/كاميرا) | `screens/user/image_search_screen.dart`, `services/gemini_service.dart` |
| — | نتائج البحث مرتبة حسب القرب + الخريطة | `screens/user/search_results_screen.dart`, `screens/user/map_screen.dart` |
| FR-08 | بيانات الصيدلية وموقعها على الخريطة | `screens/pharmacist/pharmacy_info_screen.dart` |
| FR-09 | إضافة دواء | `screens/pharmacist/add_medicine_screen.dart` |
| FR-10 | تعديل السعر والكمية أو الحذف | `screens/pharmacist/edit_medicine_screen.dart` |
| NFR-03 | تقييد الكتابة على مالك الصيدلية | `firestore.rules` |
| NFR-04 | فصل الواجهات عن منطق العمل والبيانات | `lib/models`, `lib/services`, `lib/screens` |
| NFR-05 | Android 6.0 (API 23) فما فوق + iOS | `android/app/build.gradle.kts`, `ios/` |

## هيكل المشروع

```
lib/
├── main.dart / app.dart          تهيئة Firebase والثيم والاتجاه العربي
├── firebase_options.dart         يُولَّد بـ flutterfire configure
├── core/                         الإعدادات، الثيم، التحقق، تطبيع النص العربي
├── models/                       AppUser, Pharmacy, Medicine, Availability
├── services/                     المصادقة، المستودعات، البحث، Gemini، الموقع
├── widgets/                      عناصر واجهة مشتركة
└── screens/
    ├── auth/                     الدخول، إنشاء الحساب، التوجيه
    ├── user/                     الرئيسية، البحث بالكتابة/بالصورة، النتائج، الخريطة
    └── pharmacist/               لوحة الصيدلي، بيانات الصيدلية، إدارة الأدوية
```

## قاعدة البيانات (Firestore)

| المجموعة | المعرّف | الحقول |
|---|---|---|
| `users` | UID من Auth | `userId, name, email, phone, userType (user/pharmacist), createdAt` |
| `pharmacies` | = UID الصيدلي | `pharmacyId, ownerId, pharmacyName, address, phone, latitude, longitude, updatedAt` |
| `medicines` | تلقائي | `medicineId, scientificName, tradeName, barcode, form, searchKeys[], identityKey, createdAt` |
| `availability` | `{pharmacyId}_{medicineId}` | `availabilityId, medicineId, pharmacyId, price, quantity, updatedAt` |

- `searchKeys`: بادئات الاسمين بأحرف صغيرة بعد توحيد الحروف العربية (أ/إ/آ→ا، ة→ه، ى→ي)،
  فيكفي كتابة جزء من بداية الاسم مثل `بارا` أو `pana`.
- عند إضافة دواء يبحث النظام عنه في `medicines` بالباركود ثم بالاسمين، وينشئه إن لم يوجد،
  ثم يحفظ سجل التوفر في `availability`.
- صور البحث تُرسل إلى Gemini للتحليل فقط ولا تُحفظ.

---

## خطوات التشغيل والربط مع Firebase

### 1) المتطلبات
- Flutter SDK (الإصدار المستقر الحالي) — `flutter doctor`
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
1. أنشئ حساباً بنوع **صيدلي** → «بيانات الصيدلية» → أدخل الاسم وحدد الموقع → حفظ.
2. «إدارة الأدوية» → «إضافة دواء» (مثال: `Panadol` / `Paracetamol` / السعر 12.5 / الكمية 50).
3. سجّل الخروج وأنشئ حساباً بنوع **مستخدم** → «البحث بالكتابة» → اكتب `pana` أو `باراسيتامول`،
   أو «البحث بالصورة» وصوّر العبوة.

> لتغيير نموذج Gemini بدون تعديل الكود:
> `flutter run --dart-define=GEMINI_MODEL=<model-name>` (الافتراضي في `lib/core/app_config.dart`).

## الاختبارات
```bash
flutter test
```
تغطي تطبيع النص العربي ومفاتيح البحث، وترتيب الصيدليات حسب القرب/السعر، وقراءة رد Gemini.
