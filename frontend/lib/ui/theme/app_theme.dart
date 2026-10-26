import 'package:flutter/material.dart';

/// Cores usadas pelo site (tema escuro com vermelho neon).
class AppColors {
  AppColors._();

  // Fundos
  static const bg = Color(0xFF0B0506);
  static const bgAlt = Color(0xFF140809);
  static const nav = Color(0xFF100607);
  static const footer = Color(0xFF080303);

  // Cards
  static const card = Color(0xFF1A0B0D);
  static const card2 = Color(0xFF260D11);

  // Cores principais
  static const red = Color(0xFFFF171F);
  static const redDark = Color(0xFFB90918);
  static const redGlow = Color(0xFFFF3038);

  // Textos e detalhes
  static const muted = Color(0xFFB0A0A2);
  static const border = Color(0xFF48151B);

  // WhatsApp permanece verde para manter sua identidade visual.
  static const whatsapp = Color(0xFF25D366);

  // Gradiente principal vermelho
  static const gradient = LinearGradient(
    colors: [redDark, red, redGlow],
  );
}

class AppTheme {
  AppTheme._();

 
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF3038)),
    appBarTheme: const AppBarTheme(centerTitle: true),
  );

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.red,
      secondary: AppColors.redGlow,
      surface: AppColors.card,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.nav,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: AppColors.border,
    fontFamily: 'Roboto',
  );
}
