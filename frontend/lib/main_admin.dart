import 'package:flutter/material.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/providers/booking_provider.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/providers/works_provider.dart';
import 'package:frontend/services/agenda_service.dart';
import 'package:frontend/services/api_agenda_service.dart';
import 'package:frontend/services/api_booking_repository.dart';
import 'package:frontend/services/api_catalog_repository.dart';
import 'package:frontend/services/api_works_repository.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/ui/screens/admin/admin_shell.dart';
import 'package:frontend/ui/screens/auth/login_screen.dart';
import 'package:frontend/ui/theme/app_theme.dart';

/// Ponto de entrada só do painel admin (não mexe no main.dart do cliente).
/// Rode, de dentro da pasta frontend (porta fixa: precisa estar cadastrada no Google Cloud):
///   flutter run -d chrome -t lib/main_admin.dart --web-port=5000
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
        // Agenda do painel (usada pela Agenda do dia e pela Liberação de Horários).
        Provider<AgendaService>.value(value: ApiAgendaService(api)),
        ChangeNotifierProvider<CatalogProvider>.value(value: catalog),
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => BookingProvider(
              catalog: catalog, repository: ApiBookingRepository(api)),
        ),
        ChangeNotifierProvider<WorksProvider>(
          create: (_) => WorksProvider(repository: ApiWorksRepository(api))..load(),
        ),
      ],
      child: AdminApp(api: api, authService: ApiAuthService(api)),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.authService, required this.api});

  final AuthService authService;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tal da Estética – Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _AuthGate(authService: authService, api: api),
    );
  }
}

/// Decide a tela: loading enquanto tenta restaurar a sessão salva, login se
/// não houver sessão, painel se houver. Também cuida de "Sair" e de sessão vencida.
class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.authService, required this.api});

  final AuthService authService;
  final ApiClient api;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthUser? _user;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    // O ApiClient avisa aqui quando a API responde 401 a uma chamada com token.
    widget.api.onSessaoExpirada = _sessaoExpirou;
    _restaurar();
  }

  @override
  void dispose() {
    widget.api.onSessaoExpirada = null;
    super.dispose();
  }

  Future<void> _restaurar() async {
    AuthUser? user;
    try {
      user = await widget.authService.restoreSession();
    } catch (_) {
      user = null;
    }
    if (!mounted) return;
    setState(() {
      _user = user;
      _carregando = false;
    });
  }

  /// Pode ser chamado várias vezes seguidas (vários 401 juntos): só a primeira vale.
  void _sessaoExpirou() {
    if (!mounted || _carregando || _user == null) return;
    widget.authService.signOut(); // apaga também o token salvo
    _voltarAoLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão expirada. Entre novamente.')),
      );
    });
  }

  Future<void> _sair() async {
    await widget.authService.signOut();
    if (!mounted) return;
    _voltarAoLogin();
  }

  void _voltarAoLogin() {
    // Fecha telas empilhadas (ex.: "Ver portal do cliente") antes de trocar a tela.
    Navigator.of(context).popUntil((rota) => rota.isFirst);
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.redGlow)),
      );
    }
    final user = _user;
    if (user == null) {
      return LoginScreen(
        authService: widget.authService,
        onLoggedIn: (u) => setState(() => _user = u),
      );
    }
    return AdminShell(
      user: user,
      onLogout: _sair,
      checkOnline: widget.api.verificarSaude,
    );
  }
}
