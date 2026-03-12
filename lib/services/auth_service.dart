import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/login_provider.dart';
import 'auth_api_service.dart';
import 'user_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static bool _webCallbackHandled = false;

  static Future<UserCredential> signInWithGoogle() async {
    late final UserCredential userCredential;

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      userCredential = await _auth.signInWithPopup(provider);
    } else {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCredential = await _auth.signInWithCredential(credential);
    }

    await _createUserDocumentIfNeeded(userCredential.user);
    return userCredential;
  }

  static Future<void> startKakaoSignIn() {
    return _startOAuthSignIn(LoginProvider.kakao);
  }

  static Future<void> startLineSignIn() {
    return _startOAuthSignIn(LoginProvider.line);
  }

  static Future<void> _startOAuthSignIn(LoginProvider provider) async {
    if (!kIsWeb) {
      throw Exception(
        '${provider.name.toUpperCase()} mobile login will be added after web API integration is completed.',
      );
    }

    final redirectUri = _buildCleanRedirectUri();
    final startUri = AuthApiService.buildWebOAuthStartUri(
      provider: provider,
      redirectUri: redirectUri,
    );

    final launched = await launchUrl(startUri, webOnlyWindowName: '_self');
    if (!launched) {
      throw Exception('Could not open OAuth page for ${provider.name}.');
    }
  }

  static Future<void> handleWebOAuthCallbackIfNeeded() async {
    if (!kIsWeb || _webCallbackHandled) {
      return;
    }

    final uri = Uri.base;
    final providerName = uri.queryParameters['auth_provider'];
    final authCode = uri.queryParameters['auth_code'];
    final state = uri.queryParameters['auth_state'];
    final customToken = uri.queryParameters['firebase_custom_token'];
    final authError = uri.queryParameters['auth_error'];

    final hasOAuthParams = providerName != null ||
        authCode != null ||
        customToken != null ||
        authError != null;

    if (!hasOAuthParams) {
      return;
    }

    _webCallbackHandled = true;

    if (authError != null && authError.isNotEmpty) {
      throw Exception('OAuth failed: $authError');
    }

    String token = customToken ?? '';
    if (token.isEmpty) {
      final provider = _parseProvider(providerName);
      if (provider == null) {
        throw Exception('Unsupported auth_provider in callback');
      }
      if (authCode == null || authCode.isEmpty) {
        throw Exception('auth_code is missing in callback');
      }

      token = await AuthApiService.exchangeAuthCodeForFirebaseCustomToken(
        provider: provider,
        authCode: authCode,
        redirectUri: _buildCleanRedirectUri(),
        state: state,
      );
    }

    final credential = await _auth.signInWithCustomToken(token);
    await _createUserDocumentIfNeeded(credential.user);
  }

  static LoginProvider? _parseProvider(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final provider in LoginProvider.values) {
      if (provider.name == raw.toLowerCase()) {
        return provider;
      }
    }
    return null;
  }

  static Uri _buildCleanRedirectUri() {
    final uri = Uri.base;
    final cleanParams = Map<String, String>.from(uri.queryParameters)
      ..remove('auth_provider')
      ..remove('auth_code')
      ..remove('auth_state')
      ..remove('firebase_custom_token')
      ..remove('auth_error');

    return uri.replace(queryParameters: cleanParams.isEmpty ? null : cleanParams);
  }

  static Future<void> _createUserDocumentIfNeeded(User? user) async {
    if (user == null) return;
    await UserService.createUserIfNotExists(user);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore errors from providers that were not used.
    }
  }
}
