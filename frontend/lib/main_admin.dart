import 'package:flutter/material.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/providers/booking_provider.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/providers/works_provider.dart';
import 'package:frontend/services/api_booking_repository.dart';
import 'package:frontend/services/api_catalog_repository.dart';
import 'package:frontend/services/api_works_repository.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/ui/screens/admin/admin_shell.dart';
import 'package:frontend/ui/screens/auth/login_screen.dart';
import 'package:frontend/ui/theme/app_theme.dart';

/// Ponto de entrada só do painel admin (não mexe no main.dart do cliente).
/// Rode, de dentro da pasta frontend:
///   flutter run -d chrome -t lib/main_admin.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Um único cliente HTTP: o login guarda o token nele e os repositórios o usam.
  final api = ApiClient(baseUrl: apiBaseUrl);

  // Mesmos providers do main.dart do cliente, para o botão
  // "Ver portal do cliente" conseguir abrir a HomePage.
  final catalog = CatalogProvider(repository: ApiCatalogRepository(api))..load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CatalogProvider>.value(value: catalog),
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => BookingProvider(
              catalog: catalog, repository: ApiBookingRepository(api)),
        ),
        ChangeNotifierProvider<WorksProvider>(
          create: (_) => WorksProvider(repository: ApiWorksRepository(api))..load(),
        ),
      ],
      child: AdminApp(authService: ApiAuthService(api)),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tal da Estética – Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _AuthGate(authService: authService),
    );
  }
}

/// Mostra o login enquanto não houver usuário e o painel depois do login.
class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.authService});

  final AuthService authService;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthUser? _user;

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return LoginScreen(
        authService: widget.authService,
        onLoggedIn: (user) => setState(() => _user = user),
      );
    }
    return const AdminShell();
  }
}
