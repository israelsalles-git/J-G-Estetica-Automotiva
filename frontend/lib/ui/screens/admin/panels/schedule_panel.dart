import 'package:flutter/material.dart';
import 'package:frontend/core/app_exception.dart';
import 'package:frontend/core/business_config.dart';
import 'package:frontend/core/formatar_duracao.dart';
import 'package:frontend/models/agenda_appointment.dart';
import 'package:frontend/services/agenda_service.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/admin/admin_ui.dart';
import 'package:provider/provider.dart';

// Dias e horários vêm do BusinessConfig (a mesma fonte do site do cliente).

enum AdminSlotState { livre, marcado }

String _two(int n) => n.toString().padLeft(2, '0');

String _hhmm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// Próximos dias em que a empresa atende (hoje inclusive, se for dia de atendimento).
List<DateTime> _proximosDiasDeAtendimento(int quantidade) {
  final hoje = DateTime.now();
  final dias = BusinessConfig.weekdays.values.toSet();
  return [
    for (var i = 0; i < 60; i++) DateTime(hoje.year, hoje.month, hoje.day + i),
  ].where((d) => dias.contains(d.weekday)).take(quantidade).toList();
}

/// Atendimento que ocupa o início do horário "HH:mm" no [dia], ou null se estiver livre.
/// Um serviço de 90 min que começa às 09:00 ocupa o bloco das 09:00 e o das 10:00.
AgendaAppointment? _ocupante(
  DateTime dia,
  String horario,
  List<AgendaAppointment> itens,
) {
  final p = horario.split(':');
  final inicio = DateTime(dia.year, dia.month, dia.day, int.parse(p[0]), int.parse(p[1]));
  for (final a in itens) {
    if (!inicio.isBefore(a.start) && inicio.isBefore(a.end)) return a;
  }
  return null;
}

/// Painel "Liberação de Horários": abas de dias, grade de horários e
/// lista dos atendimentos confirmados. Tudo vem da API (AgendaService).
class SchedulePanel extends StatefulWidget {
  const SchedulePanel({super.key});

  @override
  State<SchedulePanel> createState() => _SchedulePanelState();
}

class _SchedulePanelState extends State<SchedulePanel> {
  static const _weekdays = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

  late final List<DateTime> _dates;
  int _selectedDay = 0;
  List<AgendaAppointment> _itens = const [];
  bool _carregando = true;
  String? _erro;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _dates = _proximosDiasDeAtendimento(4);
    _carregar();
  }

  /// Troca de dia (ou tenta de novo) e busca na API.
  void _abrirDia(int index) {
    setState(() {
      _selectedDay = index;
      _carregando = true;
      _erro = null;
    });
    _carregar();
  }

  Future<void> _carregar() async {
    final pedido = ++_requestId;
    try {
      final itens =
          await context.read<AgendaService>().loadDay(_dates[_selectedDay]);
      // Ignora respostas antigas se a pessoa já trocou de dia.
      if (!mounted || pedido != _requestId) return;
      setState(() {
        _itens = [...itens]..sort((a, b) => a.start.compareTo(b.start));
        _carregando = false;
      });
    } catch (e) {
      if (!mounted || pedido != _requestId) return;
      setState(() {
        _itens = const [];
        _carregando = false;
        _erro = errorMessage(
          e,
          fallback: 'Não foi possível carregar os horários deste dia.',
        );
      });
    }
  }

  String _dayLabel(int i) {
    final date = _dates[i];
    final weekday = _weekdays[date.weekday - 1];
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    if (isToday) return 'HOJE ($weekday)';
    return '$weekday (${_two(date.day)})';
  }

  void _onSlotTap(AgendaAppointment? ocupante) {
    // Horário livre: não faz nada (a API ainda não tem bloqueio de horário).
    if (ocupante == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Horário já agendado: ${ocupante.customer}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPanelHeader(
            icon: Icons.event_available_outlined,
            title: 'Liberação de Horários',
            subtitle: 'Horários livres e agendados de cada dia.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _dates.length; i++)
                _DayChip(
                  label: _dayLabel(i),
                  selected: i == _selectedDay,
                  onTap: () => _abrirDia(i),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const AdminLabel('GRADE DIÁRIA (UM ATENDIMENTO POR VEZ)'),
          const SizedBox(height: 10),
          const _Legend(),
          const SizedBox(height: 14),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.redGlow),
        ),
      );
    }
    if (_erro != null) {
      return _MessageBox(
        message: _erro!,
        action: AdminOutlineButton(
          label: 'Tentar novamente',
          onPressed: () => _abrirDia(_selectedDay),
        ),
      );
    }

    final dia = _dates[_selectedDay];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 130,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          children: [
            for (final horario in BusinessConfig.timeSlots)
              _SlotTile(
                horario: horario,
                ocupante: _ocupante(dia, horario, _itens),
                onTap: _onSlotTap,
              ),
          ],
        ),
        const SizedBox(height: 28),
        const AdminLabel('PRÓXIMOS ATENDIMENTOS CONFIRMADOS'),
        const SizedBox(height: 10),
        if (_itens.isEmpty)
          const Text(
            'Nenhum atendimento confirmado para este dia.',
            style: TextStyle(color: AppColors.muted),
          )
        else
          for (final item in _itens) _BookingRow(item: item),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminTapSurface(
      onTap: onTap,
      color: selected ? AppColors.redDark : Colors.transparent,
      borderColor: selected ? AppColors.redDark : AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.muted,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  Widget _item(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _item('Livre', AppColors.redGlow),
        _item('Marcado', AppColors.redDark),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.horario,
    required this.ocupante,
    required this.onTap,
  });

  final String horario;
  final AgendaAppointment? ocupante;
  final ValueChanged<AgendaAppointment?> onTap;

  @override
  Widget build(BuildContext context) {
    final state =
        ocupante == null ? AdminSlotState.livre : AdminSlotState.marcado;

    final Color tint = switch (state) {
      AdminSlotState.livre => AppColors.redGlow,
      AdminSlotState.marcado => AppColors.redDark,
    };
    final Color background = switch (state) {
      AdminSlotState.livre => AppColors.redGlow.withValues(alpha: 0.08),
      AdminSlotState.marcado => AppColors.redDark.withValues(alpha: 0.25),
    };
    final Color borderColor = switch (state) {
      AdminSlotState.livre => AppColors.redGlow.withValues(alpha: 0.35),
      AdminSlotState.marcado => AppColors.redDark.withValues(alpha: 0.8),
    };
    final String label = switch (state) {
      AdminSlotState.livre => 'LIVRE',
      AdminSlotState.marcado => 'MARCADO',
    };
    final String? sub = ocupante?.customer.split(' ').first;

    return AdminTapSurface(
      onTap: () => onTap(ocupante),
      color: background,
      borderColor: borderColor,
      radius: 14,
      padding: const EdgeInsets.all(8),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                horario,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: tint,
                ),
              ),
              if (sub != null)
                Text(
                  sub,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.item});

  final AgendaAppointment item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _hhmm(item.start),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  item.service,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AdminPill(label: formatarDuracao(item.duration)),
        ],
      ),
    );
  }
}
