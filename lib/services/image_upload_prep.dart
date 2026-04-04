import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// 업로드 전 리사이즈·JPEG 압축으로 전송 크기·시간을 줄입니다.
/// (HEIC·고해상도 등 `image_picker`만으로는 줄지 않는 경우 대비)
Future<({Uint8List bytes, String fileExtension})> prepareImageForUpload(
  List<int> raw,
  String originalFileName, {
  int maxSide = 1600,
  int quality = 72,
}) async {
  final u8 = raw is Uint8List ? raw : Uint8List.fromList(raw);
  try {
    final out = await FlutterImageCompress.compressWithList(
      u8,
      minWidth: maxSide,
      minHeight: maxSide,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    if (out.isNotEmpty) {
      return (bytes: Uint8List.fromList(out), fileExtension: 'jpg');
    }
  } catch (_) {
    // 데스크톱·미지원 환경 등: 원본 그대로
  }
  return (bytes: u8, fileExtension: _fallbackExt(originalFileName));
}

String _fallbackExt(String name) {
  final parts = name.split('.');
  final e = parts.length > 1 ? parts.last.toLowerCase() : '';
  if (e == 'png' || e == 'gif' || e == 'webp' || e == 'jpeg') return e;
  return 'jpg';
}
