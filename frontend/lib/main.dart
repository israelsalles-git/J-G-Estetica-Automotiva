import 'package:flutter/material.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/providers/booking_provider.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/providers/works_provider.dart';
import 'package:frontend/services/api_booking_repository.dart';
import 'package:frontend/services/api_catalog_repository.dart';
import 'package:frontend/services/api_works_repository.dart';
import 'package:frontend/ui/screens/cliente/home_page.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Um único cliente HTTP para o site; a API é definida por --dart-define=API_URL.
  final api = ApiClient(baseUrl: apiBaseUrl);

  // O catálogo é compartilhado: o agendamento precisa dele para saber
  // qual é o serviço escolhido.
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
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tal da Estética Automotiva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Botão flutuante de contato: o que ele faz é decisão do backend/app.
      // Ex.: HomePage(onContactPressed: () { ...abrir o contato... })
      home: const HomePage(),
    );
  }
}
