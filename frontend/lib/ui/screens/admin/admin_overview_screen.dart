import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/core/business_config.dart';
import 'package:frontend/models/agenda_appointment.dart';
import 'package:frontend/services/agenda_service.dart';
import 'package:frontend/ui/screens/cliente/home_page.dart';
import 'package:frontend/ui/screens/admin/panels/day_agenda_panel.dart';
import 'package:frontend/ui/screens/admin/panels/photos_panel.dart';
import 'package:frontend/ui/screens/admin/panels/prices_panel.dart';
import 'package:frontend/ui/screens/admin/panels/schedule_panel.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/admin/admin_ui.dart';
import 'package:frontend/ui/widgets/gradient_button.dart';
import 'package:provider/provider.dart';

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

          final agenda = twoColumns
              ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: DayAgendaPanel()),
                    SizedBox(width: 24),
                    Expanded(flex: 5, child: SchedulePanel()),
                  ],
                )
              : const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DayAgendaPanel(),
                    SizedBox(height: 24),
                    SchedulePanel(),
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyedSubtree(
                key: heroKey,
                child: _HeroCard(wide: constraints.maxWidth >= 860),
              ),
              const SizedBox(height: 24),
              KeyedSubtree(key: scheduleKey, child: agenda),
              const SizedBox(height: 24),
              KeyedSubtree(key: photosKey, child: const PhotosPanel()),
              const SizedBox(height: 24),
              KeyedSubtree(key: pricesKey, child: const PricesPanel()),
            ],
          );
        },
      ),
    );
  }
}

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
              'Turno ativo • ${BusinessConfig.timeSlots.first} - '
              '${BusinessConfig.timeSlots.last}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Admin Tal da Estética —',
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

    const stats = _HeroStats();

    final button = GradientButton(
      label: 'VER PORTAL DO CLIENTE',
      small: true,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const _ClientPortalPreview()),
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

class _HeroStats extends StatefulWidget {
  const _HeroStats();

  @override
  State<_HeroStats> createState() => _HeroStatsState();
}

class _HeroStatsState extends State<_HeroStats> {
  List<AgendaAppointment>? _items; // null = ainda sem dados
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _carregar();
    // Atualiza a cada minuto: o "em andamento" muda com o relógio.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _carregar());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final itens =
          await context.read<AgendaService>().loadDay(DateTime.now());
      if (!mounted) return;
      setState(() => _items = itens);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itens = _items;
    final agora = DateTime.now();
    final hoje = itens == null ? '—' : '${itens.length}';
    final emAndamento = itens == null
        ? '—'
        : '${itens.where((a) => a.statusAt(agora) == AgendaStatus.emAndamento).length}';

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatBox(
          icon: Icons.event_available_outlined,
          value: hoje,
          label: 'AGENDAMENTOS HOJE',
        ),
        _StatBox(
          icon: Icons.local_car_wash_outlined,
          value: emAndamento,
          label: 'EM ANDAMENTO AGORA',
        ),
      ],
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
          Icon(icon, color: AppColors.redGlow),
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

class _ClientPortalPreview extends StatelessWidget {
  const _ClientPortalPreview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const HomePage(),
          Positioned(
            left: 16,
            bottom: 16,
            child: SafeArea(
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).pop(),
                backgroundColor: AppColors.redDark,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar ao painel'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
