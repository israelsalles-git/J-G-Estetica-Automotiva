import 'package:flutter/material.dart';

import '../../services/works_service.dart';
import '../theme/app_theme.dart';
import 'app_container.dart';
import 'horizontal_scroller.dart';
import 'section_title.dart';

class WorksSection extends StatefulWidget {
  const WorksSection({super.key});

  @override
  State<WorksSection> createState() => _WorksSectionState();
}

class _WorksSectionState extends State<WorksSection> {
  late final Future<List<String>> _photos = WorksService.loadPhotos();

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final itemWidth = mobile ? 260.0 : 340.0;
    final height = mobile ? 200.0 : 260.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: mobile ? 40 : 70),
      child: Column(children: [
        const AppContainer(
          child: SectionTitle(
            tag: 'GALERIA',
            title: 'Últimos Trabalhos',
            subtitle: 'Confira alguns dos serviços que já realizamos.',
          ),
        ),
        const SizedBox(height: 32),
        FutureBuilder<List<String>>(
          future: _photos,
          builder: (context, snap) {
            final photos = snap.data ?? const <String>[];
            final empty = snap.connectionState == ConnectionState.done &&
                photos.isEmpty;

            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(height: height);
            }

            return HorizontalScroller(
              height: height,
              itemWidth: itemWidth,
              children: empty
                  ? List.generate(4, (_) => const _PlaceholderTile())
                  : [for (final p in photos) _PhotoTile(path: p)],
            );
          },
        ),
      ]),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  const _PhotoTile({required this.path});

  void _open(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(children: [
          InteractiveViewer(
            child: Image.asset(path, fit: BoxFit.contain),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.card2,
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.muted, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mostrado enquanto a pasta `assets/trabalhos/` está vazia.
class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              color: AppColors.cyan, size: 40),
          SizedBox(height: 10),
          Text('Adicione fotos em',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          Text('assets/trabalhos/',
              style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
