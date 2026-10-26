import 'package:flutter/material.dart';

import '../../models/work.dart';
import '../theme/app_theme.dart';

/// Foto de um trabalho. Aceita caminho de asset (hoje) ou URL http(s) (API).
/// Mostra um espaço reservado enquanto carrega ou se a imagem falhar.
class WorkImage extends StatelessWidget {
  final Work work;
  final BoxFit fit;

  const WorkImage({super.key, required this.work, this.fit = BoxFit.cover});

  Widget _placeholder({bool loading = false}) => Container(
        color: AppColors.card2,
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.red),
              )
            : const Icon(Icons.image_outlined, color: AppColors.muted, size: 40),
      );

  @override
  Widget build(BuildContext context) {
    if (work.imageUrl.isEmpty) return _placeholder();
    if (work.isNetworkImage) {
      return Image.network(
        work.imageUrl,
        fit: fit,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _placeholder(loading: true),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.asset(
      work.imageUrl,
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }
}

/// Card da galeria: foto em proporção fixa (4:3, sem distorcer — `BoxFit.cover`)
/// e, opcionalmente, categoria, data, título e descrição logo abaixo.
class WorkCard extends StatelessWidget {
  final Work work;

  /// Reserva a área de texto (todos os cards da fileira devem usar o mesmo valor
  /// para terem a mesma altura).
  final bool showCaption;

  const WorkCard({super.key, required this.work, this.showCaption = false});

  static const double aspectRatio = 4 / 3;
  static const double captionHeight = 104;

  /// Altura total do card para uma [width] (usada para dimensionar a fileira).
  static double heightFor(double width, {required bool showCaption}) =>
      width / aspectRatio + (showCaption ? captionHeight : 0);

  void _open(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: InteractiveViewer(
                  child: WorkImage(work: work, fit: BoxFit.contain),
                ),
              ),
              if (work.hasDetails)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _CaptionText(work: work, maxDescriptionLines: 6),
                ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              tooltip: 'Fechar',
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _open(context),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: WorkImage(work: work),
              ),
              if (showCaption)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: _CaptionText(work: work),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptionText extends StatelessWidget {
  final Work work;
  final int maxDescriptionLines;

  const _CaptionText({required this.work, this.maxDescriptionLines = 2});

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (work.category != null && work.category!.trim().isNotEmpty)
        work.category!.toUpperCase(),
      if (work.dateLabel != null) work.dateLabel!,
    ].join('  •  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (meta.isNotEmpty)
          Text(meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.red, fontSize: 10, letterSpacing: 1)),
        if (work.title != null && work.title!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(work.title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ],
        if (work.description != null && work.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(work.description!,
              maxLines: maxDescriptionLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 12, height: 1.4)),
        ],
      ],
    );
  }
}
