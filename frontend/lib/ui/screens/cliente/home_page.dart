import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/booking_section.dart';
import 'package:frontend/ui/widgets/footer_section.dart';
import 'package:frontend/ui/widgets/hero_section.dart';
import 'package:frontend/ui/widgets/navbar.dart';
import 'package:frontend/ui/widgets/services_section.dart';
import 'package:frontend/ui/widgets/works_section.dart';

const _whatsappPhone = '5511999999999';
const _whatsappMessage = 'Olá! Gostaria de agendar um horário.';

class HomePage extends StatefulWidget {
  /// Toque no botão flutuante de contato. Se não for informado, abre o WhatsApp.
  final VoidCallback? onContactPressed;

  const HomePage({super.key, this.onContactPressed});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _servicesKey = GlobalKey();
  final _bookingKey = GlobalKey();
  final _worksKey = GlobalKey();

  void _goTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openWhatsapp() async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.https('wa.me', '/$_whatsappPhone', {'text': _whatsappMessage});
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    void toServices() => _goTo(_servicesKey);
    void toBooking() => _goTo(_bookingKey);
    void toWorks() => _goTo(_worksKey);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.whatsapp,
        onPressed: widget.onContactPressed ?? _openWhatsapp,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Navbar(
                onServices: toServices, onBooking: toBooking, onWorks: toWorks),
            HeroSection(onBooking: toBooking, onServices: toServices),
            KeyedSubtree(
              key: _servicesKey,
              child: ServicesSection(onSelected: toBooking),
            ),
            KeyedSubtree(key: _bookingKey, child: const BookingSection()),
            KeyedSubtree(key: _worksKey, child: const WorksSection()),
            FooterSection(
                onServices: toServices, onBooking: toBooking, onWorks: toWorks),
          ],
        ),
      ),
    );
  }
}