import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/load_status.dart';
import '../../providers/works_provider.dart';
import 'app_container.dart';
import 'horizontal_scroller.dart';
import 'section_title.dart';
import 'state_views.dart';
import 'work_card.dart';

/// Galeria "Últimos Trabalhos". Os trabalhos vêm do `WorksProvider`: quando um
/// trabalho novo existir na fonte de dados (pasta de assets hoje, API amanhã),
/// ele aparece aqui sem nenhuma mudança no layout.
class WorksSection extends StatelessWidget {
  const WorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final works = context.watch<WorksProvider>();

    return Padding(
      padding: EdgeInsets.fromLTRB(0, mobile ? 40 : 70, 0, mobile ? 48 : 80),
      child: Column(children: [
        const AppContainer(
          child: SectionTitle(
            tag: 'GALERIA',
            title: 'Últimos Trabalhos',
            subtitle: 'Confira alguns dos serviços que já realizamos.',
          ),
        ),
        const SizedBox(height: 32),
        _content(context, works, mobile),
      ]),
    );
  }

  Widget _content(BuildContext context, WorksProvider works, bool mobile) {
    final itemWidth = mobile ? 260.0 : 340.0;

    switch (works.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return LoadingView(
            height: WorkCard.heightFor(itemWidth, showCaption: false));
      case LoadStatus.error:
        return AppContainer(
          child: ErrorView(
            message: works.error ?? 'Não foi possível carregar os trabalhos.',
            onRetry: works.load,
          ),
        );
      case LoadStatus.success:
        if (works.works.isEmpty) {
          return const AppContainer(
            child: EmptyView(
              icon: Icons.photo_library_outlined,
              title: 'Em breve por aqui',
              message:
                  'Estamos preparando a galeria com os nossos últimos trabalhos. Volte em breve!',
            ),
          );
        }
        final showCaption = works.works.any((w) => w.hasDetails);
        return HorizontalScroller(
          height: WorkCard.heightFor(itemWidth, showCaption: showCaption),
          itemWidth: itemWidth,
          children: [
            for (final w in works.works)
              WorkCard(
                key: ValueKey('work_${w.id}'),
                work: w,
                showCaption: showCaption,
              ),
          ],
        );
    }
  }
}
