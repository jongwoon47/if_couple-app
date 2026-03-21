class AppConfig {
  static const String authApiBaseUrl =
      String.fromEnvironment('AUTH_API_BASE_URL', defaultValue: '');
  /// 번역 API URL. Gemini 사용 시 Firebase Cloud Functions의 translate URL로 설정.
  /// (API 키는 Functions 쪽에만 두고, 앱에는 이 URL만 넣으면 됨.)
  /// 예: https://asia-northeast3-PROJECT_ID.cloudfunctions.net/translate
  static const String translateApiUrl =
      String.fromEnvironment('TRANSLATE_API_URL', defaultValue: '');
  static const String translateSystemPrompt = String.fromEnvironment(
    'TRANSLATE_SYSTEM_PROMPT',
    defaultValue: 'Translate Korean to Japanese naturally for couples.',
  );

  /// Google Maps Geocoding(역지오코딩)용. 웹·동일 키로 빌드 시:
  /// `flutter run --dart-define=GOOGLE_MAPS_API_KEY=...`
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  static bool get hasAuthApiBaseUrl => authApiBaseUrl.trim().isNotEmpty;
  static bool get hasTranslateApiUrl => translateApiUrl.trim().isNotEmpty;
  static bool get hasGoogleMapsApiKey => googleMapsApiKey.trim().isNotEmpty;
}
