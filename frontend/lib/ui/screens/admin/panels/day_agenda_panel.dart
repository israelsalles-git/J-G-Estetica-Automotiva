import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/core/app_exception.dart';
import 'package:frontend/core/formatar_duracao.dart';
import 'package:frontend/models/agenda_appointment.dart';
import 'package:frontend/services/agenda_service.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/admin/admin_ui.dart';
import 'package:provider/provider.dart';

const _weekdaysLong = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];
const _weekdaysShort = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
const _months = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _two(int n) => n.toString().padLeft(2, '0');

String _hhmm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

class DayAgendaPanel extends StatefulWidget {
  const DayAgendaPanel({super.key});

  @override
  State<DayAgendaPanel> createState() => _DayAgendaPanelState();
}

class _DayAgendaPanelState extends State<DayAgendaPanel> {
  late DateTime _day;
  DateTime _now = DateTime.now();
  List<AgendaAppointment> _items = const [];
  bool _loading = true;
  String? _error;
  int _requestId = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _day = _dateOnly(_now);
    _fetch();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _goTo(DateTime day) {
    setState(() {
      _day = _dateOnly(day);
      _loading = true;
      _error = null;
    });
    _fetch();
  }

  Future<void> _fetch() async {
    final request = ++_requestId;
    try {
      final result = await context.read<AgendaService>().loadDay(_day);
      if (!mounted || request != _requestId) return;
      final sorted = [...result]..sort((a, b) => a.start.compareTo(b.start));
      setState(() {
        _items = sorted;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _requestId) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error = errorMessage(
          e,
          fallback: 'Não foi possível carregar a agenda deste dia.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(_now);
    final isToday = _sameDay(_day, today);

    final statuses = [for (final a in _items) a.statusAt(_now)];
    final total = _items.length;
    final live = statuses.where((s) => s == AgendaStatus.emAndamento).length;
    final upcoming = statuses.where((s) => s == AgendaStatus.agendado).length;
    final done = statuses.where((s) => s == AgendaStatus.concluido).length;

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPanelHeader(
            icon: Icons.today_outlined,
            title: 'Agenda do dia',
            subtitle: 'Atendimentos do dia ordenados por horário.',
          ),
          const SizedBox(height: 20),
          _DayNavigator(
            day: _day,
            isToday: isToday,
            onPrevious: () =>
                _goTo(DateTime(_day.year, _day.month, _day.day - 1)),
            onNext: () => _goTo(DateTime(_day.year, _day.month, _day.day + 1)),
            onToday: () => _goTo(today),
          ),
          const SizedBox(height: 14),
          _WeekStrip(day: _day, today: today, onSelect: _goTo),
          const SizedBox(height: 20),
          if (!_loading && _error == null && total > 0) ...[
            _Summary(
              total: total,
              live: live,
              upcoming: upcoming,
              done: done,
            ),
            const SizedBox(height: 16),
          ],
          _buildBody(statuses),
        ],
      ),
    );
  }

  Widget _buildBody(List<AgendaStatus> statuses) {
    if (_loading) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.redGlow),
        ),
      );
    }
    if (_error != null) {
      return _MessageBox(
        icon: Icons.error_outline,
        message: _error!,
        action: AdminOutlineButton(
          label: 'Tentar novamente',
          onPressed: () => _goTo(_day),
        ),
      );
    }
    if (_items.isEmpty) {
      return const _MessageBox(
        icon: Icons.event_busy_outlined,
        message: 'Nenhum atendimento neste dia.',
      );
    }
    return Column(
      children: [
        for (var i = 0; i < _items.length; i++)
          _AppointmentTile(item: _items[i], status: statuses[i]),
      ],
    );
  }
}

class _DayNavigator extends StatelessWidget {
  const _DayNavigator({
    required this.day,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime day;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdaysLong[day.weekday - 1];
    final date = '${_two(day.day)} de ${_months[day.month - 1]} de ${day.year}';

    return Row(
      children: [
        _NavButton(
          icon: Icons.chevron_left,
          tooltip: 'Dia anterior',
          onTap: onPrevious,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weekday,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    date,
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  if (isToday) const AdminPill(label: 'HOJE'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (!isToday) ...[
          AdminOutlineButton(label: 'Hoje', onPressed: onToday),
          const SizedBox(width: 8),
        ],
        _NavButton(
          icon: Icons.chevron_right,
          tooltip: 'Próximo dia',
          onTap: onNext,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AdminTapSurface(
        onTap: onTap,
        radius: 12,
        padding: const EdgeInsets.all(10),
        child: Icon(icon),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.day,
    required this.today,
    required this.onSelect,
  });

  final DateTime day;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var offset = -3; offset <= 3; offset++) ...[
          if (offset > -3) const SizedBox(width: 6),
          Expanded(
            child: _WeekDayChip(
              date: DateTime(day.year, day.month, day.day + offset),
              selected: offset == 0,
              isToday: _sameDay(
                DateTime(day.year, day.month, day.day + offset),
                today,
              ),
              onTap: () =>
                  onSelect(DateTime(day.year, day.month, day.day + offset)),
            ),
          ),
        ],
      ],
    );
  }
}

class _WeekDayChip extends StatelessWidget {
  const _WeekDayChip({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminTapSurface(
      onTap: onTap,
      color: selected ? AppColors.redDark : Colors.transparent,
      borderColor: selected ? AppColors.redDark : AppColors.border,
      radius: 12,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _weekdaysShort[date.weekday - 1],
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _two(date.day),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? AppColors.redGlow : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.total,
    required this.live,
    required this.upcoming,
    required this.done,
  });

  final int total;
  final int live;
  final int upcoming;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _CountChip(value: total, label: 'ATENDIMENTOS', color: Colors.white),
        _CountChip(value: live, label: 'EM ANDAMENTO', color: AppColors.redGlow),
        _CountChip(value: upcoming, label: 'PRÓXIMOS', color: Colors.white),
        _CountChip(value: done, label: 'CONCLUÍDOS', color: AppColors.muted),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          AdminLabel(label),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.muted),
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

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.item, required this.status});

  final AgendaAppointment item;
  final AgendaStatus status;

  @override
  Widget build(BuildContext context) {
    final active = status == AgendaStatus.emAndamento;
    final done = status == AgendaStatus.concluido;

    return Opacity(
      opacity: done ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active
              ? AppColors.redDark.withValues(alpha: 0.18)
              : AppColors.bgAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppColors.redGlow : AppColors.border,
            width: active ? 1.5 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.redGlow.withValues(alpha: 0.25),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _TimeBlock(item: item, active: active),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.customer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.service,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AdminPill(label: formatarDuracao(item.duration)),
                const SizedBox(height: 8),
                _StatusBadge(status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({required this.item, required this.active});

  final AgendaAppointment item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: active ? AppColors.gradient : null,
        color: active ? null : AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: active ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _hhmm(item.start),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'até ${_hhmm(item.end)}',
            style: TextStyle(
              fontSize: 10,
              color: active ? Colors.white70 : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final AgendaStatus status;

  @override
  Widget build(BuildContext context) {
    final String label = switch (status) {
      AgendaStatus.emAndamento => 'EM ANDAMENTO',
      AgendaStatus.agendado => 'AGENDADO',
      AgendaStatus.concluido => 'CONCLUÍDO',
    };
    final Color color = switch (status) {
      AgendaStatus.emAndamento => AppColors.redGlow,
      AgendaStatus.agendado => Colors.white70,
      AgendaStatus.concluido => AppColors.muted,
    };
    final IconData icon = switch (status) {
      AgendaStatus.emAndamento => Icons.circle,
      AgendaStatus.agendado => Icons.schedule,
      AgendaStatus.concluido => Icons.check_circle_outline,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
