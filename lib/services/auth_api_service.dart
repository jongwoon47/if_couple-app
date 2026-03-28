import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_config.dart';

class AuthApiService {
  static bool get isConfigured => AppConfig.hasAuthApiBaseUrl;

  static Uri _baseUri(String path) {
    final base = AppConfig.authApiBaseUrl.trim();
    if (base.isEmpty) {
      throw Exception(
        'AUTH_API_BASE_URL is not configured. '
        'Run with --dart-define=AUTH_API_BASE_URL=https://your-api-domain',
      );
    }
    return Uri.parse('$base$path');
  }

  /// 카카오 네이티브 SDK에서 받은 액세스 토큰 → Firebase Custom Token (authKakaoExchange)
  static Future<String> exchangeKakaoAccessToken({
    required String accessToken,
  }) async {
    final uri = _baseUri('/authKakaoExchange');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': accessToken}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Kakao token exchange failed (${response.statusCode})');
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final token = map['firebaseCustomToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('firebaseCustomToken is missing in API response');
    }
    return token;
  }

  /// LINE 네이티브 SDK에서 받은 액세스 토큰 → Firebase Custom Token (authLineExchange)
  static Future<String> exchangeLineAccessToken({
    required String accessToken,
  }) async {
    final uri = _baseUri('/authLineExchange');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': accessToken}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('LINE token exchange failed (${response.statusCode})');
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final token = map['firebaseCustomToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('firebaseCustomToken is missing in API response');
    }
    return token;
  }
}
