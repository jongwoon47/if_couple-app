import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'kakao_line_init.dart' if (dart.library.html) 'kakao_line_init_stub.dart'
    as kakao_line;
import 'l10n/app_locale_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  await initializeDateFormatting('ja', null);
  await AppLocaleController.loadSavedLocale();
  if (!kIsWeb) {
    await kakao_line.initKakaoAndLine();
  }
  runApp(const IfApp());
}
