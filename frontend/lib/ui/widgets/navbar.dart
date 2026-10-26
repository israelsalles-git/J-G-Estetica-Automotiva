import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_container.dart';
import 'brand_logo.dart';
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: AppColors.nav,
          padding: EdgeInsets.symmetric(vertical: mobile ? 10 : 12),
          child: AppContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BrandLogo(height: mobile ? 38 : 52),
                if (mobile)
                  PopupMenuButton<VoidCallback>(
                    icon: const Icon(Icons.menu),
                    color: AppColors.card,
                    onSelected: (cb) => cb(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: onServices,
                          child: const Text('Serviços & Catálogo')),
                      PopupMenuItem(
                          value: onBooking, child: const Text('Agendamento')),
                      PopupMenuItem(
                          value: onWorks,
                          child: const Text('Últimos Trabalhos')),
                    ],
                  )
                else
                  Row(children: [
                    _NavLink('Serviços & Catálogo', onServices),
                    _NavLink('Agendamento', onBooking),
                    _NavLink('Últimos Trabalhos', onWorks),
                    const SizedBox(width: 12),
                    GradientButton(
                        label: 'Agendar Agora', onTap: onBooking, small: true),
                  ]),
              ],
            ),
          ),
        ),
        // Linha de luz vermelha sob o menu.
        Container(
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              AppColors.redDark,
              AppColors.red,
              AppColors.redDark,
              Colors.transparent,
            ]),
          ),
        ),
      ],
    );
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
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}
