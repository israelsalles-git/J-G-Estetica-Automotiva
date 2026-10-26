import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/business_config.dart';
import '../../core/load_status.dart';
import '../../providers/booking_provider.dart';
import '../theme/app_theme.dart';
import 'app_container.dart';
import 'section_title.dart';

class BookingSection extends StatelessWidget {
  const BookingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);

    return Container(
      color: AppColors.bgAlt,
      padding: EdgeInsets.symmetric(vertical: mobile ? 40 : 70),
      child: AppContainer(
        child: Column(children: [
          const SectionTitle(
            tag: 'AGENDAMENTO RÁPIDO',
            title: 'Agendamento',
            subtitle:
                'Escolha o dia (Sábado ou Domingo) e o horário de sua preferência.',
          ),
          const SizedBox(height: 32),
          mobile
              ? const Column(children: [
                  _BookingForm(),
                  SizedBox(height: 20),
                  _BookingSummary(),
                ])
              : const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _BookingForm()),
                    SizedBox(width: 24),
                    Expanded(child: _BookingSummary()),
                  ],
                ),
        ]),
      ),
    );
  }
}

// ---------------- Formulário (dia + horário) ----------------

class _BookingForm extends StatelessWidget {
  const _BookingForm();

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BookingProvider>();
    final timeError = b.errorFor('time');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _StepTitle('1. SELECIONE O DIA DO ATENDIMENTO:'),
        Row(children: [
          for (var i = 0; i < BusinessConfig.days.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _DayButton(
                day: BusinessConfig.days[i],
                selected: b.day == BusinessConfig.days[i],
                onTap: () => b.selectDay(BusinessConfig.days[i]),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 22),
        const _StepTitle('2. SELECIONE O HORÁRIO DESEJADO:'),
        // Barra fina reservada: aparece só durante a consulta, sem mexer no layout.
        SizedBox(
          height: 2,
          child: b.slotsStatus == LoadStatus.loading
              ? const LinearProgressIndicator(
                  color: AppColors.red, backgroundColor: AppColors.border)
              : null,
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final t in BusinessConfig.timeSlots)
            _TimeChip(
              time: t,
              selected: b.time == t,
              busy: b.busySlots.contains(t),
              onTap: () => b.selectTime(t),
            ),
        ]),
        if (b.slotsStatus == LoadStatus.error) ...[
          const SizedBox(height: 12),
          _InlineMessage(
            text: b.slotsError ?? 'Não foi possível verificar a disponibilidade.',
            actionLabel: 'Tentar novamente',
            onAction: b.reloadAvailability,
          ),
        ],
        if (timeError != null) ...[
          const SizedBox(height: 12),
          _InlineMessage(text: timeError),
        ],
      ]),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String text;
  const _StepTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

/// Mensagem de erro/aviso curta, com ação opcional.
class _InlineMessage extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineMessage({required this.text, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
        Text(text,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            child: Text(actionLabel!,
                style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  final String day;
  final bool selected;
  final VoidCallback onTap;

  const _DayButton(
      {required this.day, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Dia $day',
      child: InkWell(
        key: ValueKey('booking_day_$day'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.redDark.withValues(alpha: .15) : AppColors.card2,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: selected ? AppColors.red : AppColors.border),
          ),
          child: Text(day,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.red : Colors.white)),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  const _TimeChip({
    required this.time,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !busy,
      selected: selected,
      label: busy ? 'Horário $time indisponível' : 'Horário $time',
      child: InkWell(
        key: ValueKey('booking_time_$time'),
        borderRadius: BorderRadius.circular(10),
        onTap: busy ? null : onTap,
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.redDark : AppColors.card2,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: selected ? AppColors.red : AppColors.border),
          ),
          child: Text(time,
              style: TextStyle(
                fontSize: 13,
                color: busy ? AppColors.muted.withValues(alpha: .4) : Colors.white,
                decoration: busy ? TextDecoration.lineThrough : null,
              )),
        ),
      ),
    );
  }
}

// ---------------- Resumo ----------------

class _BookingSummary extends StatelessWidget {
  const _BookingSummary();

  Future<void> _confirm(BuildContext context) async {
    final b = context.read<BookingProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await b.submit();

    if (ok) {
      messenger.showSnackBar(SnackBar(
          content: Text(b.resultMessage ?? 'Agendamento enviado.')));
    } else if (b.submitStatus == LoadStatus.error) {
      messenger.showSnackBar(SnackBar(
          content: Text(b.submitError ?? 'Não foi possível enviar.')));
    } else if (b.firstError != null) {
      messenger.showSnackBar(SnackBar(content: Text(b.firstError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BookingProvider>();
    final s = b.service;
    final serviceError = b.errorFor('service');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.redDark.withValues(alpha: .6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('RESUMO DO AGENDAMENTO',
            style: TextStyle(
                color: AppColors.red, fontSize: 11, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        _SummaryRow('Serviço', s?.name ?? '—'),
        _SummaryRow('Dia', b.day),
        _SummaryRow('Horário', b.time ?? '—'),
        _SummaryRow('Duração', s?.duration ?? '—'),
        if (serviceError != null) ...[
          const SizedBox(height: 8),
          _InlineMessage(text: serviceError),
        ],
        const Divider(color: AppColors.border, height: 28),
        const Text('Valor total',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
        Text(s?.priceLabel ?? '—',
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.red)),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const ValueKey('booking_confirm_button'),
            onPressed: b.isSubmitting ? null : () => _confirm(context),
            icon: b.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.chat),
            label: Text(
                b.isSubmitting ? 'Enviando...' : 'Confirmar pelo WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ]),
      );
}
