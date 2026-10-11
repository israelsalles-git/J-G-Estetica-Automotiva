import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_container.dart';
import 'gradient_button.dart';

class Navbar extends StatelessWidget {
  final VoidCallback onServices;
  final VoidCallback onBooking;
  final VoidCallback onWorks;

  const Navbar({
    super.key,
    required this.onServices,
    required this.onBooking,
    required this.onWorks,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.nav,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: AppContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Logo(),
            if (mobile)
              PopupMenuButton<VoidCallback>(
                icon: const Icon(Icons.menu),
                color: AppColors.card,
                onSelected: (cb) => cb(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: onServices, child: const Text('Serviços & Catálogo')),
                  PopupMenuItem(
                      value: onBooking, child: const Text('Agendamento')),
                  PopupMenuItem(
                      value: onWorks, child: const Text('Últimos Trabalhos')),
                ],
              )
            else
              Row(children: [
                _NavLink('Serviços & Catálogo', onServices),
                _NavLink('Agendamento', onBooking),
                _NavLink('Últimos Trabalhos', onWorks),
                const SizedBox(width: 12),
                GradientButton(label: 'Agendar Agora', onTap: onBooking, small: true),
              ]),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.directions_car, color: AppColors.cyan, size: 18),
      ),
      const SizedBox(width: 10),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('J&G ESTÉTICA',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.cyan)),
          Text('CARROS & MOTOS',
              style: TextStyle(
                  fontSize: 9, color: AppColors.muted, letterSpacing: 1.5)),
        ],
      ),
    ]);
  }
}

class _NavLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _NavLink(this.text, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: onTap,
        child: Text(text,
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      ),
    );
  }
}
