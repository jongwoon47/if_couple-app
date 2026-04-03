import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_api_service.dart';
import 'auth_mobile_oauth.dart' if (dart.library.html) 'auth_mobile_oauth_stub.dart'
    as mobile_oauth;
import 'app_config.dart';
import 'user_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConfig.googleServerClientId.trim().isEmpty
        ? null
        : AppConfig.googleServerClientId.trim(),
  );

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

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

  /// 카카오 로그인은 Android/iOS 앱 전용입니다.
  static Future<void> startKakaoSignIn() async {
    if (kIsWeb) {
      throw UnsupportedError('Kakao login is only supported on mobile apps.');
    }
    if (!AuthApiService.isConfigured) {
      throw Exception(
        'AUTH_API_BASE_URL is not configured. '
        'Run with --dart-define=AUTH_API_BASE_URL=https://...',
      );
    }
    if (AppConfig.kakaoNativeAppKey.trim().isEmpty) {
      throw Exception(
        'KAKAO_NATIVE_APP_KEY is not set. '
        'Run with --dart-define=KAKAO_NATIVE_APP_KEY=...',
      );
    }
    await mobile_oauth.signInWithKakao();
  }

  /// LINE 로그인은 Android/iOS 앱 전용입니다.
  static Future<void> startLineSignIn() async {
    if (kIsWeb) {
      throw UnsupportedError('LINE login is only supported on mobile apps.');
    }
    if (!AuthApiService.isConfigured) {
      throw Exception(
        'AUTH_API_BASE_URL is not configured. '
        'Run with --dart-define=AUTH_API_BASE_URL=https://...',
      );
    }
    if (AppConfig.lineChannelId.trim().isEmpty) {
      throw Exception(
        'LINE_CHANNEL_ID is not set. '
        'Run with --dart-define=LINE_CHANNEL_ID=...',
      );
    }
    await mobile_oauth.signInWithLine();
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
    if (!kIsWeb) {
      await mobile_oauth.signOutSocialProviders();
    }
  }
}
