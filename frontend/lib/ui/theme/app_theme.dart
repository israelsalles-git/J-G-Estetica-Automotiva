import 'package:flutter/material.dart';
 
/// Cores usadas pelo site (tema escuro).
class AppColors {
  AppColors._();
 
  static const bg = Color(0xFF0B0F1A);
  static const bgAlt = Color(0xFF0D1322);
  static const nav = Color(0xFF0E1424);
  static const footer = Color(0xFF080B14);
  static const card = Color(0xFF131A2B);
  static const card2 = Color(0xFF1A2236);
  static const cyan = Color(0xFF22D3EE);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF94A3B8);
  static const border = Color(0xFF243049);
  static const whatsapp = Color(0xFF25D366);
 
  static const gradient = LinearGradient(colors: [blue, cyan]);
}
 
class AppTheme {
  AppTheme._();
 
  /// Tema original (tela de admin).
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0175C2)),
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
 
  /// Tema do site (J&G Estética Automotiva).
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cyan,
      secondary: AppColors.blue,
    ),
    fontFamily: 'Roboto',
  );
}
 