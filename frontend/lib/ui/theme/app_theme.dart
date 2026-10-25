import 'package:flutter/material.dart';
 
/// Cores usadas pelo site (tema escuro).
class AppColors {
  AppColors._();
 
static const bg = Color(0xFF0B0506);
  static const bgAlt = Color(0xFF140809);
  static const nav = Color(0xFF100607);
  static const footer = Color(0xFF080303);
  static const card = Color(0xFF1A0B0D);
  static const card2 = Color(0xFF260D13);
  static const cyan = Color(0xFFFF3038);
  static const blue = Color(0xFFB90918);
  static const muted = Color(0xFFB0A0A2);
  static const border = Color(0xFF48151B);
  static const whatsapp = Color(0xFFB90918);
 
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
 