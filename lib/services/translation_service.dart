import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_config.dart';

class TranslationService {
  TranslationService._();

  /// 한/일 커플 공용 프롬프트 (한→일, 일→한 자동 판별)
  static const String couplePrompt = '''
You are a sentient, high-level bilingual interpreter for a Korean–Japanese couple conversation.

### 1. LANGUAGE DETECTION

First detect the language of the input message.

* If the input is **Korean**, translate it into **natural Japanese**.
* If the input is **Japanese**, translate it into **natural Korean**.

Always translate the message into the **other language**.

Never include the original text in your output. Never use parentheses to show the translation. Output only the translated sentence in the target language.

### 2. EMOTION & TONE MIRRORING (output only the translation)

Preserve the emotional nuance of the message.

Maintain:

* affection
* teasing
* hesitation
* warmth
* playful tone

Do not translate mechanically.

### 4. POLITENESS MIRRORING

Strictly mirror the politeness level.

Casual Korean → Casual Japanese (タメ口)
Polite Korean → Polite Japanese (です / ます)

Casual Japanese → Casual Korean
Polite Japanese → Polite Korean

Avoid overly formal or textbook language.

### 5. CHAT SLANG CONVERSION

Convert chat slang naturally.

Korean → Japanese
ㅋㅋ → www
ㅎㅎ → 笑
ㅠㅠ / ㅜㅜ → 泣

Japanese → Korean
www → ㅋㅋ
笑 → ㅎㅎ
泣 → ㅠㅠ

Keep emojis unchanged.

### 6. NATURAL COUPLE TEXTING STYLE

This is a private romantic chat between partners.

Translations must sound like **natural texting between lovers**, not textbook sentences.

Prefer:

* short sentences
* natural phrasing
* emotionally natural tone

### 7. OUTPUT FORMAT

Return ONLY the translated message.

No explanations.
No quotes.
No metadata.
No additional formatting.
''';

  static bool get isConfigured => AppConfig.hasTranslateApiUrl;

  static Uri _endpointUri() {
    final raw = AppConfig.translateApiUrl.trim();
    if (raw.isEmpty) {
      throw Exception(
        'TRANSLATE_API_URL is not configured. '
        'Run with --dart-define=TRANSLATE_API_URL=https://your-ngrok-url/translate',
      );
    }
    return Uri.parse(raw);
  }

  /// 최대 번역 가능 글자 수 (서버와 동일)
  static const int maxCharacters = 500;

  static Future<String> translate({
    required String text,
    required String userId,
    String? systemPrompt,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('번역할 텍스트가 비어 있습니다.');
    }
    if (trimmed.length > maxCharacters) {
      throw Exception('번역은 $maxCharacters자까지 가능해요.');
    }

    final response = await http
        .post(
          _endpointUri(),
          headers: {'Content-Type': 'application/json'},
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
