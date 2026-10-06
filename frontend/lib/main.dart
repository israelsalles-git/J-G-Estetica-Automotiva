import 'package:flutter/material.dart';
import 'package:frontend/ui/screens/admin/admin_home_screen.dart';
import 'package:frontend/ui/theme/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J&G Estética Automotiva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AdminHomeScreen(),
    );
  }
}
