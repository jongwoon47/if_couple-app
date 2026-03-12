import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/login_provider.dart';
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

  /// 카카오: Firebase Functions URL (authKakaoStart). 그 외: /auth/{provider}/start
  static Uri buildWebOAuthStartUri({
    required LoginProvider provider,
    required Uri redirectUri,
  }) {
    final path = provider == LoginProvider.kakao
        ? '/authKakaoStart'
        : '/auth/${provider.name}/start';
    return _baseUri(path).replace(
      queryParameters: {
        'redirect_uri': redirectUri.toString(),
      },
    );
  }

  /// 카카오: Firebase Functions URL (authKakaoExchange). 그 외: /auth/{provider}/exchange
  static Future<String> exchangeAuthCodeForFirebaseCustomToken({
    required LoginProvider provider,
    required String authCode,
    required Uri redirectUri,
    String? state,
  }) async {
    final path = provider == LoginProvider.kakao
        ? '/authKakaoExchange'
        : '/auth/${provider.name}/exchange';
    final uri = _baseUri(path);
    final body = <String, dynamic>{
      'code': authCode,
      'redirectUri': redirectUri.toString(),
    };
    if (state != null && state.isNotEmpty) {
      body['state'] = state;
    }

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('OAuth exchange failed (${response.statusCode})');
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final token = map['firebaseCustomToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('firebaseCustomToken is missing in API response');
    }
    return token;
  }
}
