import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../l10n/app_localizations.dart';

/// Storage / Firestore 업로드 실패 시 사용자 안내
String messageForUploadFailure(Object error, AppLocalizations l10n) {
  if (error is TimeoutException) {
    return error.message ?? l10n.uploadTimeout;
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return l10n.uploadPermissionDenied(
          kIsWeb ? l10n.webCorsBullet : '',
        );
      case 'unauthenticated':
      case 'unauthorized':
        return l10n.uploadLoginRequired;
      case 'canceled':
        return l10n.uploadCanceled;
      default:
        final m = error.message?.trim();
        if (m != null && m.isNotEmpty && m.length < 200) {
          return l10n.uploadFailedWithMessage(error.code, m);
        }
        return l10n.uploadFailedCodeOnly(error.code);
    }
  }

  final s = error.toString();
  final lower = s.toLowerCase();
  if (kIsWeb &&
      (lower.contains('cors') ||
          lower.contains('xmlhttprequest') ||
          lower.contains('network'))) {
    return l10n.uploadBrowserBlocked;
  }

  if (s.length > 280) {
    return '${s.substring(0, 280)}…';
  }
  return s;
}
