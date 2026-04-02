import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';

class TranslationService {
  TranslationService._();

  /// 한/일 커플 공용 프롬프트 (한→일, 일→한 자동 판별)
  static const String couplePrompt = '''
You are a bilingual interpreter for a Korean–Japanese couple chat.

TASK:
Detect the language of the input message.

If the message is Korean → translate it into natural Japanese.
If the message is Japanese → translate it into natural Korean.

Always translate to the opposite language.
Never repeat the original language.

NAMES AND VOCATIVES (STRICT — do not skip):
- Korean messages often call the partner by name: …아, …야, …오빠, …자기, etc.
- Keep the SAME person. Write Korean names in katakana from Korean pronunciation (e.g. 준혁 → ジュンヒョク, 민수 → ミンス).
- NEVER replace a Korean name with a different Japanese given name. For example: 준혁아 must NOT become ヒカル, 翔, or any unrelated name — use ジュンヒョク plus natural Japanese address (e.g. ジュンヒョク、ジュンくん), not a name swap.
- Japanese names in the message → keep reading consistent; do not substitute Korean names for them.

OUTPUT RULES:
- Output ONLY the translated sentence.
- Do not include the original text.
- No explanations, no quotes.

STYLE:
This is a private romantic chat between partners.
Keep the emotional nuance and natural texting style.

POLITENESS:
Mirror the politeness level.

SLANG CONVERSION:
Korean → Japanese
ㅋㅋ → www
ㅎㅎ → 笑
ㅠㅠ / ㅜㅜ → 泣

Japanese → Korean
www → ㅋㅋ
笑 → ㅎㅎ
泣 → ㅠㅠ
''';

  /// 첫 번역(번역 보기) — 집 Gemma 서버
  static bool get isPrimaryConfigured => AppConfig.hasTranslateApiUrl;

  /// 재번역 — Gemini(클라우드)
  static bool get isRetranslateConfigured =>
      AppConfig.hasTranslateRetranslateApiUrl;

  static Uri _endpointUri({required bool retranslate}) {
    final raw = retranslate
        ? AppConfig.translateRetranslateApiUrl.trim()
        : AppConfig.translateApiUrl.trim();
    if (raw.isEmpty) {
      throw Exception(
        retranslate
            ? 'TRANSLATE_RETRANSLATE_API_URL is not configured.'
            : 'TRANSLATE_API_URL is not configured.',
      );
    }
    return Uri.parse(raw);
  }

  /// ngrok 무료 호스트는 비브라우저 클라이언트에 경고 HTML을 줄 수 있어 우회 헤더 추가
  static Map<String, String> _translateRequestHeaders(String idToken, Uri uri) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
    final host = uri.host.toLowerCase();
    if (host.contains('ngrok')) {
      headers['ngrok-skip-browser-warning'] = 'true';
    }
    return headers;
  }

  /// 최대 번역 가능 글자 수 (서버와 동일)
  static const int maxCharacters = 500;

  /// [retranslate] true → Gemini(재번역 URL), false → 첫 번역(Gemma 등)
  static Future<String> translate({
    required String text,
    required String userId,
    String? systemPrompt,
    bool retranslate = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('번역할 텍스트가 비어 있습니다.');
    }
    if (trimmed.length > maxCharacters) {
      throw Exception('번역은 $maxCharacters자까지 가능해요.');
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('로그인 정보가 없어 번역할 수 없어요.');
    }
    final idToken = await currentUser.getIdToken();
    if (idToken == null || idToken.trim().isEmpty) {
      throw Exception('인증 토큰을 가져오지 못했어요. 다시 로그인해 주세요.');
    }

    final uri = _endpointUri(retranslate: retranslate);
    final response = await http
        .post(
          uri,
          headers: _translateRequestHeaders(idToken, uri),
          body: jsonEncode({
            'text': trimmed,
            'system_prompt':
                (systemPrompt ?? AppConfig.translateSystemPrompt).trim(),
            'user_id': userId,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 429) {
      Map<String, dynamic>? map;
      try {
        map = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {}
      final msg = map?['message'] as String?;
      throw Exception(msg ?? '요청 한도를 초과했어요. 잠시 후 다시 시도해 주세요.');
    }
    if (response.statusCode == 400) {
      Map<String, dynamic>? map;
      try {
        map = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {}
      final msg = map?['message'] as String?;
      if (map?['error'] == 'text_too_long') {
        throw Exception(msg ?? '번역은 $maxCharacters자까지 가능해요.');
      }
      throw Exception(msg ?? '잘못된 요청이에요.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('번역 서버 호출 실패 (${response.statusCode})');
    }

    Map<String, dynamic> map;
    try {
      map = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        '번역 서버 응답이 JSON이 아닙니다. (HTML/에러 페이지일 수 있음)',
      );
    }
    final translated = (map['translated'] ?? '').toString().trim();
    if (translated.isEmpty) {
      throw Exception('번역 서버 응답에 translated 값이 없습니다.');
    }
    return translated;
  }
}
