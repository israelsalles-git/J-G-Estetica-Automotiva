import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/ui/screens/admin/admin_shell.dart';
import 'package:frontend/ui/screens/auth/login_screen.dart';
import 'package:frontend/ui/theme/app_theme.dart';

/// Ponto de entrada só do painel admin (não mexe no main.dart do cliente).
/// Rode, de dentro da pasta frontend:
///   flutter run -d chrome -t lib/main_admin.dart
void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J&G Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AuthGate(),
    );
  }
}

/// Mostra o login enquanto não houver usuário e o painel depois do login.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthUser? _user;

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return LoginScreen(
        onLoggedIn: (user) => setState(() => _user = user),
      );
    }
    return const AdminShell();
  }
}
