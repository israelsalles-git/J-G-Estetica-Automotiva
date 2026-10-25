import 'package:flutter/material.dart';
import 'package:frontend/ui/screens/admin/panels/photos_panel.dart';
import 'package:frontend/ui/screens/admin/panels/prices_panel.dart';
import 'package:frontend/ui/screens/admin/panels/schedule_panel.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/admin/admin_ui.dart';
import 'package:frontend/ui/widgets/gradient_button.dart';

/// Página única do painel: resumo do dia + fotos, horários e tabela de preços.
/// O menu lateral (AdminShell) rola até cada bloco usando as chaves abaixo,
/// do mesmo jeito que a navbar do site do cliente.
class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({
    super.key,
    required this.heroKey,
    required this.photosKey,
    required this.pricesKey,
    required this.scheduleKey,
  });

  final GlobalKey heroKey;
  final GlobalKey photosKey;
  final GlobalKey pricesKey;
  final GlobalKey scheduleKey;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 1000;
          final photos =
              KeyedSubtree(key: photosKey, child: const PhotosPanel());
          final schedule =
              KeyedSubtree(key: scheduleKey, child: const SchedulePanel());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyedSubtree(
                key: heroKey,
                child: _HeroCard(wide: constraints.maxWidth >= 860),
              ),
              const SizedBox(height: 24),
              if (twoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: photos),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: schedule),
                  ],
                )
              else ...[
                photos,
                const SizedBox(height: 24),
                schedule,
              ],
              const SizedBox(height: 24),
              KeyedSubtree(key: pricesKey, child: const PricesPanel()),
            ],
          );
        },
      ),
    );
  }
}

String _hh(int hour) => '${hour.toString().padLeft(2, '0')}:00';

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final titleSize = wide ? 36.0 : 28.0;

    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const AdminPill(label: 'CENTRO DE COMANDO'),
            Text(
              'Turno ativo • ${_hh(kAdminOpenHour)} - ${_hh(kAdminCloseHour)}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Admin J&G —',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        ShaderMask(
          shaderCallback: (rect) => AppColors.gradient.createShader(rect),
          child: Text(
            'Gestão Operacional',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              height: 1.05,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Controle de vitrine, precificação ágil de pacotes e '
          'travamento imediato de boxes.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
      ],
    );

    // Números de exemplo; serão trocados pelos dados reais da API.
    const stats = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatBox(
          icon: Icons.event_available_outlined,
          value: '8',
          label: 'AGENDAMENTOS HOJE',
        ),
        _StatBox(
          icon: Icons.local_car_wash_outlined,
          value: '3 / 4',
          label: 'BOXES OCUPADOS',
        ),
      ],
    );

    final button = GradientButton(
      label: 'VER PORTAL DO CLIENTE',
      small: true,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atalho para o portal do cliente (a ligar depois).'),
          ),
        );
      },
    );

    return AdminCard(
      padding: const EdgeInsets.all(28),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: intro),
                const SizedBox(width: 24),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [stats, const SizedBox(height: 16), button],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                intro,
                const SizedBox(height: 20),
                stats,
                const SizedBox(height: 16),
                button,
              ],
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.cyan),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              AdminLabel(label),
            ],
          ),
        ],
      ),
    );
  }
}
