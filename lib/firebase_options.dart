import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          '이 플랫폼의 FirebaseOptions가 설정되지 않았습니다.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBuUFauGZNENryact4-9d7mDEJvjHyuPCk',
    appId: '1:516031766053:web:a717cc5b231e31ca61e9cc',
    messagingSenderId: '516031766053',
    projectId: 'if-app-b2854',
    authDomain: 'if-app-b2854.firebaseapp.com',
    storageBucket: 'if-app-b2854.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ANDROID_API_KEY',
    appId: 'REPLACE_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_PROJECT_ID',
    storageBucket: 'REPLACE_PROJECT_ID.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_IOS_API_KEY',
    appId: 'REPLACE_IOS_APP_ID',
    messagingSenderId: 'REPLACE_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_PROJECT_ID',
    storageBucket: 'REPLACE_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'com.example.ifApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_MACOS_API_KEY',
    appId: 'REPLACE_MACOS_APP_ID',
    messagingSenderId: 'REPLACE_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_PROJECT_ID',
    storageBucket: 'REPLACE_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'com.example.ifApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WINDOWS_API_KEY',
    appId: 'REPLACE_WINDOWS_APP_ID',
    messagingSenderId: 'REPLACE_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_PROJECT_ID',
    authDomain: 'REPLACE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REPLACE_PROJECT_ID.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REPLACE_LINUX_API_KEY',
    appId: 'REPLACE_LINUX_APP_ID',
    messagingSenderId: 'REPLACE_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_PROJECT_ID',
    authDomain: 'REPLACE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REPLACE_PROJECT_ID.firebasestorage.app',
  );
}
