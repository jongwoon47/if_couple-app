import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'user_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static String? _registeredUserId;
  static bool _tokenRefreshListenerAttached = false;

  static Future<void> ensureInitializedForUser(String userId) async {
    if (kIsWeb) return;
    if (_registeredUserId == userId) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null && token.trim().isNotEmpty) {
      await UserService.addFcmToken(userId: userId, token: token);
    }

    if (!_tokenRefreshListenerAttached) {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final uid = _registeredUserId;
        if (uid == null || uid.isEmpty) return;
        await UserService.addFcmToken(userId: uid, token: newToken);
      });
      _tokenRefreshListenerAttached = true;
    }

    _registeredUserId = userId;
  }
}
