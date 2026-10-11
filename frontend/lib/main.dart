import 'package:flutter/material.dart';
import 'package:frontend/providers/booking_provider.dart';
import 'package:frontend/ui/screens/cliente/home_page.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';
 
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BookingProvider(),
      child: const MainApp(),
    ),
  );
}
 
class MainApp extends StatelessWidget {
  const MainApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J&G Estética Automotiva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomePage(),
    );
  }
}
 