import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'auth_api_service.dart';
import 'user_service.dart';

Future<void> signInWithKakao() async {
  OAuthToken token;
  if (await isKakaoTalkInstalled()) {
    try {
      token = await UserApi.instance.loginWithKakaoTalk();
    } catch (_) {
      token = await UserApi.instance.loginWithKakaoAccount();
    }
  } else {
    token = await UserApi.instance.loginWithKakaoAccount();
  }
  final customToken = await AuthApiService.exchangeKakaoAccessToken(
    accessToken: token.accessToken,
  );
  final cred = await FirebaseAuth.instance.signInWithCustomToken(customToken);
  final user = cred.user;
  if (user != null) {
    await UserService.createUserIfNotExists(user);
  }
}

Future<void> signInWithLine() async {
  final result = await LineSDK.instance.login();
  final accessToken = result.accessToken.value;
  final customToken = await AuthApiService.exchangeLineAccessToken(
    accessToken: accessToken,
  );
  final cred = await FirebaseAuth.instance.signInWithCustomToken(customToken);
  final user = cred.user;
  if (user != null) {
    await UserService.createUserIfNotExists(user);
  }
}

Future<void> signOutSocialProviders() async {
  try {
    await UserApi.instance.logout();
  } catch (_) {}
  try {
    await LineSDK.instance.logout();
  } catch (_) {}
}
