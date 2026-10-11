import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/booking_provider.dart';
import '../../services/catalog_service.dart';
import '../theme/app_theme.dart';
import 'app_container.dart';
import 'section_title.dart';
import 'service_card.dart';

class ServicesSection extends StatelessWidget {
  /// Chamado depois de escolher um serviço (rola até o agendamento).
  final VoidCallback onSelected;

  const ServicesSection({super.key, required this.onSelected});

  void _select(BuildContext context, int index) {
    context.read<BookingProvider>().selectService(index);
    onSelected();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: mobile ? 40 : 70),
      child: Column(children: [
        const AppContainer(
          child: SectionTitle(
            tag: 'CATÁLOGO PERSONALIZADO',
            title: 'Serviços para Carros & Motocicletas',
            subtitle:
                'Preços transparentes, produtos específicos para cada tipo de superfície e tempo estimado.',
          ),
        ),
        const SizedBox(height: 32),
        mobile
            ? _buildMobile(context)
            : _DesktopCarousel(onSelect: (i) => _select(context, i)),
      ]),
    );
  }

  /// Mobile: carrosséis horizontais por categoria (Carro / Moto).
  Widget _buildMobile(BuildContext context) {
    final all = CatalogService.services;
    return Column(
      children: [
        for (final category in CatalogService.categories) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(category,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          SizedBox(
            height: 340,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final s in CatalogService.byCategory(category))
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 240,
                      child: ServiceCard(
                        service: s,
                        number: all.indexOf(s) + 1,
                        compact: true,
                        onSchedule: () => _select(context, all.indexOf(s)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Desktop/Tablet: todos os cards lado a lado, com rolagem horizontal
/// (mouse arrastando, scroll lateral, scrollbar e setas).
class _DesktopCarousel extends StatefulWidget {
  final ValueChanged<int> onSelect;
  const _DesktopCarousel({required this.onSelect});

  @override
  State<_DesktopCarousel> createState() => _DesktopCarouselState();
}

class _DesktopCarouselState extends State<_DesktopCarousel> {
  static const _cardWidth = 300.0;
  static const _gap = 20.0;

  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(target,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final all = CatalogService.services;
    final w = Responsive.width(context);
    // Alinha o início da fileira com o resto do conteúdo.
    final sidePad = math.max(32.0, (w - Responsive.maxContent) / 2 + 32);

    return Column(
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
            scrollbars: false,
          ),
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: sidePad, vertical: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < all.length; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: _cardWidth,
                      child: ServiceCard(
                        service: all[i],
                        number: i + 1,
                        onSchedule: () => widget.onSelect(i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ArrowButton(
              icon: Icons.chevron_left,
              onTap: () => _scrollBy(-(_cardWidth + _gap) * 2),
            ),
            const SizedBox(width: 12),
            _ArrowButton(
              icon: Icons.chevron_right,
              onTap: () => _scrollBy((_cardWidth + _gap) * 2),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.cyan),
      ),
    );
  }
}
