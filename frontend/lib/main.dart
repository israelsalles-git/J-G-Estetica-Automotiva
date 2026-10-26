import 'package:flutter/material.dart';
import 'package:frontend/demo/demo_repositories.dart';
import 'package:frontend/providers/booking_provider.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/providers/works_provider.dart';
import 'package:frontend/services/booking_repository.dart';
import 'package:frontend/services/catalog_repository.dart';
import 'package:frontend/services/works_repository.dart';
import 'package:frontend/ui/screens/cliente/home_page.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

 
  const CatalogRepository catalogRepository = DemoCatalogRepository();
  const BookingRepository bookingRepository = DemoBookingRepository();
  const WorksRepository worksRepository = DemoWorksRepository();

  // O catálogo é compartilhado: o agendamento precisa dele para saber
  // qual é o serviço escolhido.
  final catalog = CatalogProvider(repository: catalogRepository)..load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CatalogProvider>.value(value: catalog),
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => BookingProvider(
              catalog: catalog, repository: bookingRepository),
        ),
        ChangeNotifierProvider<WorksProvider>(
          create: (_) => WorksProvider(repository: worksRepository)..load(),
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
