import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/admin/admin_ui.dart';

class AdminPhoto {
  const AdminPhoto({
    required this.title,
    required this.modality,
    required this.stage,
    this.active = true,
    this.featured = false,
  });

  final String title;
  final String modality;
  final String stage;
  final bool active;
  final bool featured;

  AdminPhoto copyWith({bool? active, bool? featured}) {
    return AdminPhoto(
      title: title,
      modality: modality,
      stage: stage,
      active: active ?? this.active,
      featured: featured ?? this.featured,
    );
  }
}

/// Painel "Fotos de Serviços": filtros, área de envio e galeria publicada.
/// O envio de arquivo ainda é simulado (cria um rascunho de exemplo);
/// o upload real será ligado ao backend depois.
class PhotosPanel extends StatefulWidget {
  const PhotosPanel({super.key});

  @override
  State<PhotosPanel> createState() => _PhotosPanelState();
}

class _PhotosPanelState extends State<PhotosPanel> {
  static const _services = [
    'Lavagem de Carro',
    'Lavagem de Carro + Cera',
    'Lavagem de Moto',
    'Lavagem de Moto + Cera',
    'Lavagem Detalhada de Moto',
  ];
  static const _stages = ['Antes', 'Durante', 'Depois'];

  String _service = _services.first;
  String _modality = 'CARRO';
  String _stage = 'Depois';

  final List<AdminPhoto> _photos = [
    const AdminPhoto(
      title: 'Vitrificação 9H',
      modality: 'CARRO',
      stage: 'Depois',
      featured: true,
    ),
    const AdminPhoto(
      title: 'Cuidado Completo',
      modality: 'MOTO',
      stage: 'Depois',
    ),
    const AdminPhoto(
      title: 'Higienização Interna',
      modality: 'CARRO',
      stage: 'Depois',
    ),
    const AdminPhoto(
      title: 'Lavagem Técnica',
      modality: 'CARRO',
      stage: 'Antes',
      active: false,
    ),
  ];

  void _addDraft() {
    setState(() {
      _photos.insert(
        0,
        AdminPhoto(
          title: _service,
          modality: _modality,
          stage: _stage,
          active: false,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Foto de exemplo adicionada como rascunho. '
          'O envio real será ligado ao backend.',
        ),
      ),
    );
  }

  void _toggleActive(int index) {
    setState(() {
      _photos[index] = _photos[index].copyWith(active: !_photos[index].active);
    });
  }

  void _toggleFeatured(int index) {
    setState(() {
      _photos[index] =
          _photos[index].copyWith(featured: !_photos[index].featured);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _photos.where((p) => p.active).length;

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPanelHeader(
            icon: Icons.photo_library_outlined,
            title: 'Fotos de Serviços & Antes/Depois',
            subtitle:
                'Suba registros reais do pátio para alimentar o mostruário do cliente.',
            trailing: AdminPill(label: '$activeCount IMAGENS ATIVAS'),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Field(
                label: 'SERVIÇO REFERENTE',
                width: 250,
                child: AdminDropdown(
                  value: _service,
                  items: _services,
                  onChanged: (v) => setState(() => _service = v),
                ),
              ),
              _Field(
                label: 'MODALIDADE',
                width: 190,
                child: _ModalityToggle(
                  value: _modality,
                  onChanged: (v) => setState(() => _modality = v),
                ),
              ),
              _Field(
                label: 'ESTÁGIO',
                width: 150,
                child: AdminDropdown(
                  value: _stage,
                  items: _stages,
                  onChanged: (v) => setState(() => _stage = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DropZone(onTap: _addDraft),
          const SizedBox(height: 28),
          const AdminLabel('GALERIA PUBLICADA NO PORTAL (RECENTES)'),
          const SizedBox(height: 12),
          SizedBox(
            height: 232,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
                scrollbars: false,
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _PhotoCard(
                  photo: _photos[index],
                  onToggleActive: () => _toggleActive(index),
                  onToggleFeatured: () => _toggleFeatured(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.width,
    required this.child,
  });

  final String label;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminLabel(label),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _ModalityToggle extends StatelessWidget {
  const _ModalityToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final option in const ['CARRO', 'MOTO'])
            Expanded(
              child: AdminTapSurface(
                onTap: () => onChanged(option),
                color: option == value ? AppColors.red : Colors.transparent,
                borderColor: Colors.transparent,
                radius: 9,
                child: Center(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: option == value ? Colors.white : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AdminTapSurface(
        onTap: onTap,
        color: AppColors.bgAlt,
        borderColor: AppColors.red.withValues(alpha: 0.35),
        radius: 16,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.red),
            SizedBox(height: 10),
            Text(
              'Clique para selecionar foto ou arraste arquivos aqui',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Formatos JPG, PNG ou WEBP até 15 MB',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.filled = false});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? AppColors.red : Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : AppColors.red,
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.photo,
    required this.onToggleActive,
    required this.onToggleFeatured,
  });

  final AdminPhoto photo;
  final VoidCallback onToggleActive;
  final VoidCallback onToggleFeatured;

  @override
  Widget build(BuildContext context) {
    final isCar = photo.modality == 'CARRO';
    final tint = isCar ? AppColors.red : AppColors.red;
    final statusColor = photo.active ? AppColors.red : AppColors.muted;

    return Container(
      width: 176,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 104,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tint.withValues(alpha: 0.55), AppColors.bgAlt],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    isCar ? Icons.directions_car : Icons.two_wheeler,
                    size: 40,
                    color: Colors.white70,
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Wrap(
                    spacing: 4,
                    children: [
                      if (photo.featured)
                        const _Badge('DESTAQUE', filled: true),
                      _Badge(photo.stage.toUpperCase()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  photo.modality,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: AppColors.muted,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: onToggleActive,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            photo.active ? 'Ativa' : 'Rascunho',
                            style: TextStyle(fontSize: 12, color: statusColor),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Destacar no portal',
                      visualDensity: VisualDensity.compact,
                      onPressed: onToggleFeatured,
                      icon: Icon(
                        photo.featured ? Icons.star : Icons.star_border,
                        size: 20,
                        color:
                            photo.featured ? AppColors.red : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
