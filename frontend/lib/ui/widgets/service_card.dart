import 'package:flutter/material.dart';

import '../../models/service.dart';
import '../theme/app_theme.dart';
import 'gradient_button.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final int number;
  final bool compact;
  final VoidCallback onSchedule;

  const ServiceCard({
    super.key,
    required this.service,
    required this.number,
    required this.onSchedule,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = service;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.vip ? AppColors.cyan : AppColors.border),
        boxShadow: s.vip
            ? [BoxShadow(color: AppColors.cyan.withOpacity(.25), blurRadius: 24)]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            SizedBox(
              height: compact ? 130 : 170,
              width: double.infinity,
              child: Image.network(
                s.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.card2,
                  child: Icon(
                    s.category == 'Moto' ? Icons.two_wheeler : Icons.directions_car,
                    size: 48,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Text(s.vip ? 'PREMIUM / VIP' : s.category,
                    style: const TextStyle(fontSize: 10, color: AppColors.cyan)),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$number. ${s.name}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 6),
              Text(s.description,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12, height: 1.4)),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.schedule, size: 14, color: AppColors.cyan),
                const SizedBox(width: 6),
                Text('Tempo estimado: ${s.duration}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ]),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(s.priceLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18)),
                GradientButton(label: 'Agendar', onTap: onSchedule, small: true),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}
