import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/load_status.dart';
import '../../models/service.dart';
import '../../providers/booking_provider.dart';
import '../../providers/catalog_provider.dart';
import 'app_container.dart';
import 'horizontal_scroller.dart';
import 'section_title.dart';
import 'service_card.dart';
import 'state_views.dart';

class ServicesSection extends StatelessWidget {
  /// Chamado depois de escolher um serviço (rola até o agendamento).
  final VoidCallback onSelected;

  const ServicesSection({super.key, required this.onSelected});

  void _select(BuildContext context, Service service) {
    context.read<BookingProvider>().selectService(service);
    onSelected();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final catalog = context.watch<CatalogProvider>();

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
        _content(context, catalog, mobile),
      ]),
    );
  }

  Widget _content(BuildContext context, CatalogProvider catalog, bool mobile) {
    switch (catalog.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView(height: 320);
      case LoadStatus.error:
        return AppContainer(
          child: ErrorView(
            message: catalog.error ?? 'Não foi possível carregar os serviços.',
            onRetry: catalog.load,
          ),
        );
      case LoadStatus.success:
        if (catalog.services.isEmpty) {
          return const AppContainer(
            child: EmptyView(
              icon: Icons.build_circle_outlined,
              title: 'Nenhum serviço disponível',
              message:
                  'Os serviços aparecerão aqui assim que forem cadastrados.',
            ),
          );
        }
        return mobile ? _mobile(context, catalog) : _desktop(context, catalog);
    }
  }

  /// Desktop/tablet: todos os cards numa única fileira com rolagem lateral.
  Widget _desktop(BuildContext context, CatalogProvider catalog) {
    final size = ServiceCard.sizeOf(compact: false);
    final all = catalog.services;
    return HorizontalScroller(
      height: size.height + 2 * ServiceCard.glowRoom,
      verticalPadding: ServiceCard.glowRoom,
      itemWidth: size.width,
      children: [
        for (var i = 0; i < all.length; i++)
          ServiceCard(
            service: all[i],
            number: i + 1,
            onSchedule: () => _select(context, all[i]),
          ),
      ],
    );
  }

  /// Celular: uma fileira rolável por categoria (Carro / Moto).
  Widget _mobile(BuildContext context, CatalogProvider catalog) {
    final size = ServiceCard.sizeOf(compact: true);
    final all = catalog.services;
    return Column(
      children: [
        for (final category in catalog.categories) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(category,
                  style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          HorizontalScroller(
            height: size.height + 2 * ServiceCard.glowRoom,
            verticalPadding: ServiceCard.glowRoom,
            itemWidth: size.width,
            children: [
              for (final s in catalog.byCategory(category))
                ServiceCard(
                  service: s,
                  number: all.indexOf(s) + 1,
                  compact: true,
                  onSchedule: () => _select(context, s),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
