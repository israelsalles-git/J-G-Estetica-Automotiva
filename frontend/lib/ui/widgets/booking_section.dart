import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/booking_provider.dart';
import '../../services/catalog_service.dart';
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
          for (var i = 0; i < CatalogService.days.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _DayButton(CatalogService.days[i])),
          ],
        ]),
        const SizedBox(height: 22),
        const _StepTitle('2. SELECIONE O HORÁRIO DESEJADO:'),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final t in CatalogService.timeSlots) _TimeChip(t),
        ]),
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

class _DayButton extends StatelessWidget {
  final String day;
  const _DayButton(this.day);

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BookingProvider>();
    final selected = b.day == day;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => b.selectDay(day),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.blue.withOpacity(.15) : AppColors.card2,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: selected ? AppColors.cyan : AppColors.border),
        ),
        child: Text(day,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.cyan : Colors.white)),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  const _TimeChip(this.time);

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BookingProvider>();
    final busy = CatalogService.busySlots.contains(time);
    final selected = b.time == time;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: busy ? null : () => b.selectTime(time),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : AppColors.card2,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: selected ? AppColors.cyan : AppColors.border),
        ),
        child: Text(time,
            style: TextStyle(
              fontSize: 13,
              color: busy ? AppColors.muted.withOpacity(.4) : Colors.white,
              decoration: busy ? TextDecoration.lineThrough : null,
            )),
      ),
    );
  }
}

// ---------------- Resumo ----------------

class _BookingSummary extends StatelessWidget {
  const _BookingSummary();

  void _confirm(BuildContext context) {
    final b = context.read<BookingProvider>();
    if (!b.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escolha o horário desejado.')));
      return;
    }
    b.confirmByWhatsapp();
  }

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BookingProvider>();
    final s = b.service;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.blue.withOpacity(.6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('RESUMO DO AGENDAMENTO',
            style: TextStyle(
                color: AppColors.cyan, fontSize: 11, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        _SummaryRow('Serviço', s.name),
        _SummaryRow('Dia', b.day),
        _SummaryRow('Horário', b.time ?? '—'),
        _SummaryRow('Duração', s.duration),
        const Divider(color: AppColors.border, height: 28),
        const Text('Valor total',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
        Text(s.priceLabel,
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.cyan)),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirm(context),
            icon: const Icon(Icons.chat),
            label: const Text('Confirmar pelo WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
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
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ]),
      );
}
