import 'package:http/http.dart' as http;

import 'save_network_image_stub.dart'
    if (dart.library.html) 'save_network_image_web.dart'
    if (dart.library.io) 'save_network_image_io.dart' as platform_save;

/// Firebase Storage 등 HTTPS URL에서 이미지를 받아 저장합니다.
/// - 웹: 브라우저 다운로드
/// - 그 외: 공유 시트로 저장/공유
Future<void> downloadImageFromUrl(
  String url, {
  String? fileName,
}) async {
  final uri = Uri.parse(url);
  final resp = await http.get(uri);
  if (resp.statusCode != 200) {
    throw Exception('이미지를 받지 못했어요 (HTTP ${resp.statusCode})');
  }
  final name = fileName ?? _guessFileName(uri);
  await platform_save.saveImageBytes(resp.bodyBytes, name);
}

String _guessFileName(Uri uri) {
  final segs = uri.pathSegments;
  if (segs.isNotEmpty) {
    final last = segs.last;
    if (last.contains('.') && last.length < 120) {
      return last.split('?').first;
    }
  }
  return 'chat_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
}
