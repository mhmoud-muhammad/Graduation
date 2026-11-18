// ⚠️ ملف مؤقت: يُستبدل تلقائياً عند تشغيل الأمر التالي داخل مجلد المشروع:
//
//     dart pub global activate flutterfire_cli
//     flutterfire configure --project=<FIREBASE_PROJECT_ID> --platforms=android,ios
//
// ويمكن أيضاً تمرير القيم وقت البناء بدون تعديل الملف:
//   flutter run --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... \
//     --dart-define=FIREBASE_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=...
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('الويب غير مدعوم في هذا المشروع.');
    }
    if (_apiKey.isEmpty || _projectId.isEmpty) {
      throw UnsupportedError(
        'لم يتم إعداد Firebase بعد. شغّل flutterfire configure (انظر README.md).',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('هذه المنصة غير مدعومة.');
    }
  }

  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: _appId,
  );
  static const String _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: '$_projectId.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: _iosAppId,
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: '$_projectId.firebasestorage.app',
    iosBundleId: 'com.zaha.dawai',
  );
}
