import 'package:flutter/material.dart';

import 'package:frontend/services/whatsapp_service.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/booking_section.dart';
import 'package:frontend/ui/widgets/footer_section.dart';
import 'package:frontend/ui/widgets/hero_section.dart';
import 'package:frontend/ui/widgets/navbar.dart';
import 'package:frontend/ui/widgets/services_section.dart';
import 'package:frontend/ui/widgets/works_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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

  @override
  Widget build(BuildContext context) {
    void toServices() => _goTo(_servicesKey);
    void toBooking() => _goTo(_bookingKey);
    void toWorks() => _goTo(_worksKey);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.whatsapp,
        onPressed: () => WhatsappService.open(),
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
