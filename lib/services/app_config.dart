class AppConfig {
  static const String authApiBaseUrl =
      String.fromEnvironment('AUTH_API_BASE_URL', defaultValue: 'https://asia-northeast3-if-app-b2854.cloudfunctions.net');

  /// 카카오 네이티브 앱 키 (모바일 SDK). `--dart-define=KAKAO_NATIVE_APP_KEY=...`
  static const String kakaoNativeAppKey =
      String.fromEnvironment('KAKAO_NATIVE_APP_KEY', defaultValue: 'eb3ddf87e0dd88fcf3db85c3384519d8');

  /// LINE Login 채널 ID (모바일 SDK). `--dart-define=LINE_CHANNEL_ID=...`
  static const String lineChannelId =
      String.fromEnvironment('LINE_CHANNEL_ID', defaultValue: '2009342913');
  /// 첫 번역(번역 보기): 집 PC Gemma 등. `--dart-define=TRANSLATE_API_URL=...` 로 덮어쓰기 가능
  static const String translateApiUrl = String.fromEnvironment(
    'TRANSLATE_API_URL',
    defaultValue:
        'https://uncapsuled-tanja-improvingly.ngrok-free.dev/translate',
  );

  /// 재번역: Gemini(Cloud Functions 등). `--dart-define=TRANSLATE_RETRANSLATE_API_URL=...`
  /// 기본값은 기존 단일 번역 엔드포인트와 동일.
  static const String translateRetranslateApiUrl = String.fromEnvironment(
    'TRANSLATE_RETRANSLATE_API_URL',
    defaultValue: 'https://translate-bicdqwxmuq-du.a.run.app',
  );
  static const String translateSystemPrompt = String.fromEnvironment(
    'TRANSLATE_SYSTEM_PROMPT',
    defaultValue:
        'Korean↔Japanese couple chat. Korean names and vocatives (…아/…야): use katakana from Korean sounds (준혁→ジュンヒョク); never replace with unrelated Japanese names like ヒカル. Output only the translation.',
  );

  /// Google Maps Geocoding(역지오코딩)용. 웹·동일 키로 빌드 시:
  /// `flutter run --dart-define=GOOGLE_MAPS_API_KEY=...`
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: 'AIzaSyBkqTE6RYT2J8rzT7JT0xajWmsDVh6EA6I');

  static bool get hasAuthApiBaseUrl => authApiBaseUrl.trim().isNotEmpty;
  static bool get hasTranslateApiUrl => translateApiUrl.trim().isNotEmpty;
  static bool get hasTranslateRetranslateApiUrl =>
      translateRetranslateApiUrl.trim().isNotEmpty;
  static bool get hasGoogleMapsApiKey => googleMapsApiKey.trim().isNotEmpty;
}
