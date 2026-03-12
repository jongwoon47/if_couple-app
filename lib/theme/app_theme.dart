import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const seed = Color(0xFF2B7A78);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F8FB),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
