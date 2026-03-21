import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 모바일·데스크톱: 임시 파일로 저장 후 공유 시트(갤러리·파일로 저장 등)
Future<void> saveImageBytes(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final safeName = fileName.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
  final path = '${dir.path}/$safeName';
  final f = File(path);
  await f.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path)],
      text: '이미지 저장',
    ),
  );
}
