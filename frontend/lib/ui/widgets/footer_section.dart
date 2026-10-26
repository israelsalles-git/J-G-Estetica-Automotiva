import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_container.dart';
import 'brand_logo.dart';

class FooterSection extends StatelessWidget {
  final VoidCallback onServices;
  final VoidCallback onBooking;
  final VoidCallback onWorks;

  const FooterSection({
    super.key,
    required this.onServices,
    required this.onBooking,
    required this.onWorks,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);

    const about = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      BrandLogo(height: 56),
      SizedBox(height: 10),
      Text('Especialistas em carros & motos.\nQualidade e brilho em cada detalhe.',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
    ]);

    final links = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Heading('ACESSOS RÁPIDOS'),
      _FooterLink('Catálogo de Serviços', onServices),
      _FooterLink('Agendar Horário', onBooking),
      _FooterLink('Últimos Trabalhos', onWorks),
    ]);

    const hours = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Heading('ATENDIMENTO FIM DE SEMANA'),
      Text('Sábado: 07:00 às 18:00', style: TextStyle(fontSize: 12)),
      Text('Domingo: 07:00 às 18:00', style: TextStyle(fontSize: 12)),
    ]);

    return Container(
      color: AppColors.footer,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: AppContainer(
        child: Column(children: [
          mobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  about,
                  const SizedBox(height: 24),
                  links,
                  const SizedBox(height: 24),
                  hours,
                ])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Expanded(
                      child: Align(alignment: Alignment.topLeft, child: about)),
                  Expanded(
                      child: Align(alignment: Alignment.topCenter, child: links)),
                  const Expanded(
                      child: Align(alignment: Alignment.topRight, child: hours)),
                ]),
          const Divider(color: AppColors.border, height: 40),
          const Text(
            '© 2026 Tal da Estética Automotiva. Todos os direitos reservados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ]),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, letterSpacing: 1.5, color: AppColors.muted)),
      );
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _FooterLink(this.text, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: InkWell(
          onTap: onTap,
          child: Text(text,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ),
      );
}
