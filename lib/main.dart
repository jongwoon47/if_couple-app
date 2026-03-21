import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'l10n/app_locale_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  await initializeDateFormatting('ja', null);
  await AppLocaleController.loadSavedLocale();
  runApp(const IfApp());
}
