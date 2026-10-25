import 'package:flutter/material.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/admin/admin_ui.dart';

// ---- Regras de funcionamento (iguais às do site do cliente) ----
// Se o grupo mudar o expediente, basta ajustar estas constantes.
const int kAdminOpenHour = 7;
const int kAdminCloseHour = 18; // o último horário começa às 17:00
const int kAdminLunchHour = 12;
const Set<int> kAdminOpenWeekdays = {DateTime.saturday, DateTime.sunday};

enum AdminSlotState { livre, marcado, travado, fechado }

class AdminBooking {
  const AdminBooking({
    required this.vehicle,
    required this.customer,
    required this.service,
    required this.box,
  });

  final String vehicle;
  final String customer;
  final String service;
  final int box;
}

class AdminTimeSlot {
  const AdminTimeSlot(this.hour, this.state, {this.detail, this.booking});

  final int hour;
  final AdminSlotState state;
  final String? detail;
  final AdminBooking? booking;

  String get hourLabel => '${hour.toString().padLeft(2, '0')}:00';

  AdminTimeSlot withState(AdminSlotState newState, {String? detail}) {
    return AdminTimeSlot(hour, newState, detail: detail, booking: booking);
  }
}

// ---- Dados de exemplo (trocar pela API depois) ----
// A chave externa é o índice do dia (0 = primeiro dia da lista de abas).
const Map<int, Map<int, AdminBooking>> _demoBookings = {
  0: {
    8: AdminBooking(
      vehicle: 'BMW 320i',
      customer: 'Ana P.',
      service: 'Lavagem de Carro + Cera',
      box: 3,
    ),
    9: AdminBooking(
      vehicle: 'Civic',
      customer: 'Marcos T.',
      service: 'Lavagem de Carro',
      box: 4,
    ),
    14: AdminBooking(
      vehicle: 'Ducati Panigale V4',
      customer: 'Roberto M.',
      service: 'Lavagem Detalhada de Moto',
      box: 2,
    ),
    15: AdminBooking(
      vehicle: 'Porsche 911 Carrera GTS',
      customer: 'Lucas S.',
      service: 'Lavagem de Carro + Cera',
      box: 1,
    ),
  },
  1: {
    9: AdminBooking(
      vehicle: 'Hilux',
      customer: 'Paulo R.',
      service: 'Lavagem de Carro',
      box: 1,
    ),
    10: AdminBooking(
      vehicle: 'CB 500',
      customer: 'Joana L.',
      service: 'Lavagem de Moto',
      box: 2,
    ),
  },
};

List<DateTime> _nextOpenDays(int count) {
  final today = DateTime.now();
  final result = <DateTime>[];
  var offset = 0;
  while (result.length < count && offset < 60) {
    final date = DateTime(today.year, today.month, today.day + offset);
    if (kAdminOpenWeekdays.contains(date.weekday)) result.add(date);
    offset++;
  }
  return result;
}

List<AdminTimeSlot> _buildDay(int dayIndex) {
  final bookings = _demoBookings[dayIndex] ?? const <int, AdminBooking>{};
  return [
    for (var h = kAdminOpenHour; h < kAdminCloseHour; h++)
      if (h == kAdminLunchHour)
        AdminTimeSlot(h, AdminSlotState.fechado, detail: 'Almoço')
      else if (bookings.containsKey(h))
        AdminTimeSlot(h, AdminSlotState.marcado, booking: bookings[h])
      else if (dayIndex == 0 && h == 16)
        AdminTimeSlot(h, AdminSlotState.travado, detail: 'pelo gerente')
      else
        AdminTimeSlot(h, AdminSlotState.livre),
  ];
}

/// Painel "Liberação de Horários": abas de dias, grade de horários e
/// lista dos próximos veículos confirmados.
class SchedulePanel extends StatefulWidget {
  const SchedulePanel({super.key});

  @override
  State<SchedulePanel> createState() => _SchedulePanelState();
}

class _SchedulePanelState extends State<SchedulePanel> {
  static const _weekdays = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

  late final List<DateTime> _dates;
  late final List<List<AdminTimeSlot>> _days;
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _dates = _nextOpenDays(4);
    _days = List.generate(_dates.length, _buildDay);
  }

  String _dayLabel(int i) {
    final date = _dates[i];
    final weekday = _weekdays[date.weekday - 1];
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    if (isToday) return 'HOJE ($weekday)';
    final day = date.day.toString().padLeft(2, '0');
    return '$weekday ($day)';
  }

  void _onSlotTap(int index) {
    final slot = _days[_selectedDay][index];
    switch (slot.state) {
      case AdminSlotState.livre:
        setState(() {
          _days[_selectedDay][index] =
              slot.withState(AdminSlotState.travado, detail: 'por você');
        });
      case AdminSlotState.travado:
        setState(() {
          _days[_selectedDay][index] = slot.withState(AdminSlotState.livre);
        });
      case AdminSlotState.marcado:
        final vehicle = slot.booking?.vehicle ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Horário já agendado: $vehicle')),
        );
      case AdminSlotState.fechado:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = _days[_selectedDay];
    final booked =
        slots.where((s) => s.state == AdminSlotState.marcado).toList();

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPanelHeader(
            icon: Icons.event_available_outlined,
            title: 'Liberação de Horários',
            subtitle: 'Toque nos blocos para trancar ou liberar vagas.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _days.length; i++)
                _DayChip(
                  label: _dayLabel(i),
                  selected: i == _selectedDay,
                  onTap: () => setState(() => _selectedDay = i),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const AdminLabel('GRADE DIÁRIA DE ATENDIMENTO (BOXES 1 A 4)'),
          const SizedBox(height: 10),
          const _Legend(),
          const SizedBox(height: 14),
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
              for (var i = 0; i < slots.length; i++)
                _SlotTile(slot: slots[i], onTap: () => _onSlotTap(i)),
            ],
          ),
          const SizedBox(height: 28),
          const AdminLabel('PRÓXIMOS VEÍCULOS CONFIRMADOS'),
          const SizedBox(height: 10),
          if (booked.isEmpty)
            const Text(
              'Nenhum veículo confirmado para este dia.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            for (final slot in booked) _BookingRow(slot: slot),
        ],
      ),
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
      color: selected ? AppColors.blue : Colors.transparent,
      borderColor: selected ? AppColors.blue : AppColors.border,
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
        _item('Livre', AppColors.cyan),
        _item('Marcado', AppColors.blue),
        _item('Travado', AppColors.muted),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.onTap});

  final AdminTimeSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final closed = slot.state == AdminSlotState.fechado;

    final Color tint = switch (slot.state) {
      AdminSlotState.livre => AppColors.cyan,
      AdminSlotState.marcado => AppColors.blue,
      AdminSlotState.travado => AppColors.muted,
      AdminSlotState.fechado => AppColors.muted,
    };

    final Color background = switch (slot.state) {
      AdminSlotState.livre => AppColors.cyan.withValues(alpha: 0.08),
      AdminSlotState.marcado => AppColors.blue.withValues(alpha: 0.25),
      AdminSlotState.travado => AppColors.card2,
      AdminSlotState.fechado => AppColors.bgAlt,
    };

    final Color borderColor = switch (slot.state) {
      AdminSlotState.livre => AppColors.cyan.withValues(alpha: 0.35),
      AdminSlotState.marcado => AppColors.blue.withValues(alpha: 0.8),
      AdminSlotState.travado => AppColors.border,
      AdminSlotState.fechado => AppColors.border,
    };

    final String label = switch (slot.state) {
      AdminSlotState.livre => 'LIVRE',
      AdminSlotState.marcado => 'MARCADO',
      AdminSlotState.travado => 'TRAVADO',
      AdminSlotState.fechado => (slot.detail ?? 'FECHADO').toUpperCase(),
    };

    final String? sub = switch (slot.state) {
      AdminSlotState.livre => 'toque p/ trancar',
      AdminSlotState.marcado => slot.booking?.vehicle.split(' ').first,
      AdminSlotState.travado => slot.detail,
      AdminSlotState.fechado => null,
    };

    return AdminTapSurface(
      onTap: closed ? null : onTap,
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
                slot.hourLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: closed ? AppColors.muted : Colors.white,
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
  const _BookingRow({required this.slot});

  final AdminTimeSlot slot;

  @override
  Widget build(BuildContext context) {
    final booking = slot.booking!;
    final box = booking.box.toString().padLeft(2, '0');

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
              slot.hourLabel,
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
                  booking.vehicle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${booking.customer} • ${booking.service}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AdminPill(label: 'BOX $box'),
        ],
      ),
    );
  }
}
