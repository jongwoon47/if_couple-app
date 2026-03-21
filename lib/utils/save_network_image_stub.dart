import 'dart:typed_data';

/// 플랫폼별 구현으로 대체됨 (conditional import)
Future<void> saveImageBytes(Uint8List bytes, String fileName) async {
  throw UnsupportedError('이 플랫폼에서는 이미지 저장을 지원하지 않아요.');
}
