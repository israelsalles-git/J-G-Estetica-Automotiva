import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0175C2)),
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}