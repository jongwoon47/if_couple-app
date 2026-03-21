import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase_options.dart';

/// Firebase 콘솔 기본 버킷이 `*.firebasestorage.app` 인 경우에도
/// [FirebaseStorage.instance] 가 예전 `*.appspot.com` 으로 요청하면
/// CORS를 맞춰 둔 버킷과 어긋날 수 있습니다.
/// [DefaultFirebaseOptions]의 `storageBucket`을 항상 명시합니다.
///
/// Firebase.initializeApp() 이 끝난 뒤에만 사용하세요.
FirebaseStorage getAppFirebaseStorage() {
  final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
  if (bucket == null || bucket.isEmpty) {
    return FirebaseStorage.instance;
  }
  return FirebaseStorage.instanceFor(
    app: Firebase.app(),
    bucket: bucket,
  );
}
