import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

const String kPrefsLocaleKey = 'app_locale';

/// 앱 전역 로케일(서비스 레이어에서 [lookupAppLocalizations]용).
class AppLocaleController {
  AppLocaleController._();

  static Locale locale = const Locale('ja');

  static AppLocalizations get l10n => lookupAppLocalizations(locale);

  static void applyLocale(Locale l) {
    locale = l;
    Intl.defaultLocale = l.languageCode == 'ja' ? 'ja_JP' : 'ko_KR';
  }

  /// 저장된 설정이 없으면 기기 시스템 언어를 사용합니다.
  /// 일본어 기기 → 일본어, 한국어 기기 → 한국어, 그 외 → 일본어(기본)
  static Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(kPrefsLocaleKey);
    if (code != null) {
      applyLocale(Locale(code));
      return;
    }
    final systemLang = ui.PlatformDispatcher.instance.locale.languageCode;
    applyLocale(Locale(systemLang == 'ko' ? 'ko' : 'ja'));
  }

  static Future<void> persistAndApply(Locale l) async {
    applyLocale(l);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefsLocaleKey, l.languageCode);
  }
}

/// 설정 등에서 [setLocale] 호출 시 MaterialApp이 리빌드되도록 상위에서 감쌉니다.
class AppLocaleScope extends InheritedWidget {
  const AppLocaleScope({
    required this.locale,
    required this.setLocale,
    required super.child,
    super.key,
  });

  final Locale locale;
  final ValueChanged<Locale> setLocale;

  static AppLocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppLocaleScope oldWidget) =>
      oldWidget.locale != locale;
}
