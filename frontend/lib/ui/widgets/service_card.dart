import 'package:flutter/material.dart';

import '../../models/service.dart';
import '../theme/app_theme.dart';
import 'gradient_button.dart';

/// Card de serviço com tamanho FIXO ([sizeOf]).
///
/// Por que tamanho fixo: assim todos os cards têm a mesma altura, e o preço e
/// o botão ficam sempre alinhados na base — independente de o nome ter 1 ou
/// 2 linhas ou de a descrição ser curta ou longa. A descrição ocupa o espaço
/// que sobrar, e o texto longo é cortado com "…" em vez de estourar o card.
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

  /// Largura e altura do card (compacto = celular).
  static Size sizeOf({required bool compact}) =>
      compact ? const Size(260, 340) : const Size(300, 400);

  /// Espaço extra reservado em volta do card para o brilho do card VIP não
  /// ser cortado nem encostar no vizinho.
  static const double glowRoom = 24;

  Widget _imageFallback(Service s) => Container(
        color: AppColors.card2,
        alignment: Alignment.center,
        child: Icon(
          s.category == 'Moto' ? Icons.two_wheeler : Icons.directions_car,
          size: 48,
          color: AppColors.red,
        ),
      );

  Widget _image(Service s) {
    if (s.imageUrl.isEmpty) return _imageFallback(s);
    if (!s.imageUrl.startsWith('http')) {
      // Caminho de arquivo do projeto (assets).
      return Image.asset(
        s.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(s),
      );
    }
    return Image.network(
      s.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : _imageFallback(s),
      errorBuilder: (_, __, ___) => _imageFallback(s),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = service;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: s.vip ? AppColors.red : AppColors.redDark.withValues(alpha: .7)),
        boxShadow: s.vip
            ? [BoxShadow(color: AppColors.red.withValues(alpha: .30), blurRadius: 16)]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: compact ? 130 : 170,
            child: Stack(fit: StackFit.expand, children: [
              _image(s),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.red)),
                  child: Text(s.vip ? 'PREMIUM / VIP' : s.category,
                      style:
                          const TextStyle(fontSize: 10, color: AppColors.red)),
                ),
              ),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reserva sempre 2 linhas para o nome → tudo abaixo alinha.
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 38),
                    child: Text('$number. ${s.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.25)),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(s.description,
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12, height: 1.4)),
                  ),
                  Row(children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Tempo estimado: ${s.duration}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(s.priceLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GradientButton(label: 'Agendar', onTap: onSchedule, small: true),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
