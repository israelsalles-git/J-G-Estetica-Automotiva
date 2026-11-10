import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:frontend/core/load_status.dart';
import 'package:frontend/models/work.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/providers/works_provider.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/admin/admin_ui.dart';
import 'package:provider/provider.dart';

/// Limite de tamanho da foto (o back-end também recusa acima de 5 MB).
const _maxBytes = 5 * 1024 * 1024;
const _extensoes = ['jpg', 'jpeg', 'png', 'webp'];
const _modalidades = ['Carro', 'Moto'];

String _two(int n) => n.toString().padLeft(2, '0');

String _dataCurta(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// Painel "Fotos de Serviços": formulário de envio e galeria publicada.
/// Tudo vem do [WorksProvider] (API): enviar, editar e excluir são reais, e o
/// site do cliente, que usa o mesmo provider, mostra a foto nova na hora.
class PhotosPanel extends StatefulWidget {
  const PhotosPanel({super.key});

  @override
  State<PhotosPanel> createState() => _PhotosPanelState();
}

class _PhotosPanelState extends State<PhotosPanel> {
  String? _service; // título da foto: nome de um serviço do catálogo
  String _modality = 'Carro'; // vira a "categoria" no back-end
  DateTime? _date; // null = hoje
  final _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _selecionarFoto(String titulo) async {
    final works = context.read<WorksProvider>();
    if (works.isSaving) return;

    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _extensoes,
      withData: true, // na web não há caminho de arquivo, só os bytes
    );
    final f = r?.files.single;
    if (f == null || f.bytes == null) return;

    final extensao = f.name.contains('.') ? f.name.split('.').last.toLowerCase() : '';
    if (!_extensoes.contains(extensao)) {
      _snack('Use uma foto JPG, PNG ou WEBP.');
      return;
    }
    if (f.size > _maxBytes) {
      _snack('A foto deve ter no máximo 5 MB.');
      return;
    }

    final descricao = _description.text.trim();
    final ok = await works.add(WorkDraft(
      imageBytes: f.bytes!,
      imageFileName: f.name,
      title: titulo,
      description: descricao.isEmpty ? null : descricao,
      category: _modality, // 'Carro' | 'Moto'
      date: _date ?? DateTime.now(),
    ));
    if (!mounted) return;
    if (ok) _description.clear();
    _snack(ok ? 'Foto publicada!' : (works.actionError ?? 'Não foi possível enviar a foto.'));
  }

  Future<void> _editar(Work work) async {
    final works = context.read<WorksProvider>();
    final editado = await showDialog<Work>(
      context: context,
      builder: (_) => _EditWorkDialog(work: work),
    );
    if (editado == null) return;
    final ok = await works.update(editado);
    if (!mounted) return;
    _snack(ok ? 'Foto atualizada.' : (works.actionError ?? 'Não foi possível salvar.'));
  }

  Future<void> _excluir(Work work) async {
    final works = context.read<WorksProvider>();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir foto?'),
        content: Text(
          'A foto "${work.title ?? 'sem título'}" será removida do portal '
          'e o arquivo será apagado do servidor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.redGlow),
            ),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    final ok = await works.remove(work.id);
    if (!mounted) return;
    _snack(ok ? 'Foto excluída.' : (works.actionError ?? 'Não foi possível excluir.'));
  }

  @override
  Widget build(BuildContext context) {
    final works = context.watch<WorksProvider>();
    final servicos = [
      for (final s in context.watch<CatalogProvider>().services) s.name,
    ];
    // Mantém a escolha atual se ela ainda existe no catálogo; senão, o primeiro.
    final servico = servicos.isEmpty
        ? null
        : (servicos.contains(_service) ? _service! : servicos.first);

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPanelHeader(
            icon: Icons.photo_library_outlined,
            title: 'Fotos de Serviços',
            subtitle:
                'Suba registros reais do pátio para alimentar o mostruário do cliente.',
            trailing: AdminPill(label: '${works.works.length} FOTOS PUBLICADAS'),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Field(
                label: 'SERVIÇO REFERENTE',
                width: 250,
                child: servico == null
                    ? const _FieldPlaceholder('Carregando serviços...')
                    : AdminDropdown(
                        value: servico,
                        items: servicos,
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
                label: 'DATA (OPCIONAL)',
                width: 170,
                child: AdminTapSurface(
                  onTap: _pickDate,
                  color: AppColors.card2,
                  radius: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        const Icon(Icons.event, size: 18, color: AppColors.muted),
                        const SizedBox(width: 8),
                        Text(_date == null ? 'Hoje' : _dataCurta(_date!)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AdminLabel('DESCRIÇÃO (OPCIONAL)'),
          const SizedBox(height: 6),
          TextField(
            controller: _description,
            maxLines: 2,
            maxLength: 300,
            decoration: adminInputDecoration(hint: 'Ex.: Vitrificação completa'),
          ),
          const SizedBox(height: 12),
          _DropZone(
            saving: works.isSaving,
            enabled: servico != null,
            onTap: () => _selecionarFoto(servico!),
          ),
          const SizedBox(height: 28),
          const AdminLabel('GALERIA PUBLICADA NO PORTAL (RECENTES)'),
          const SizedBox(height: 12),
          _buildGallery(works),
        ],
      ),
    );
  }

  Widget _buildGallery(WorksProvider works) {
    if (works.status == LoadStatus.loading || works.status == LoadStatus.idle) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.redGlow),
        ),
      );
    }
    if (works.status == LoadStatus.error) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            works.error ?? 'Não foi possível carregar as fotos.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          AdminOutlineButton(label: 'Tentar novamente', onPressed: works.load),
        ],
      );
    }
    if (works.works.isEmpty) {
      return const Text(
        'Nenhuma foto publicada ainda.',
        style: TextStyle(color: AppColors.muted),
      );
    }
    return SizedBox(
      height: 270,
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
          itemCount: works.works.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final work = works.works[index];
            return _PhotoCard(
              work: work,
              busy: works.isSaving,
              onEdit: () => _editar(work),
              onDelete: () => _excluir(work),
            );
          },
        ),
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

class _FieldPlaceholder extends StatelessWidget {
  const _FieldPlaceholder(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.muted)),
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
          for (final option in _modalidades)
            Expanded(
              child: AdminTapSurface(
                onTap: () => onChanged(option),
                color: option == value ? AppColors.redDark : Colors.transparent,
                borderColor: Colors.transparent,
                radius: 9,
                child: Center(
                  child: Text(
                    option.toUpperCase(),
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
  const _DropZone({
    required this.saving,
    required this.enabled,
    required this.onTap,
  });

  final bool saving;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AdminTapSurface(
        onTap: (saving || !enabled) ? null : onTap,
        color: AppColors.bgAlt,
        borderColor: AppColors.redGlow.withValues(alpha: 0.35),
        radius: 16,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (saving)
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.redGlow,
                ),
              )
            else
              const Icon(
                Icons.cloud_upload_outlined,
                size: 36,
                color: AppColors.redGlow,
              ),
            const SizedBox(height: 10),
            Text(
              saving ? 'Enviando foto...' : 'Clique para selecionar a foto',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Formatos JPG, PNG ou WEBP até 5 MB',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: AppColors.redGlow,
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.work,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final Work work;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final category = work.category;
    final detalhes = [
      if (category != null && category.isNotEmpty) category.toUpperCase(),
      if (work.dateLabel != null) work.dateLabel!,
    ].join('  •  ');

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
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  work.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const ColoredBox(
                    color: AppColors.card2,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: AppColors.muted, size: 36),
                    ),
                  ),
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const ColoredBox(
                          color: AppColors.card2,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.redGlow,
                              ),
                            ),
                          ),
                        ),
                ),
                if (category != null && category.isNotEmpty)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _Badge(category.toUpperCase()),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  work.title ?? 'Sem título',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  detalhes.isEmpty ? ' ' : detalhes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: AppColors.muted,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      visualDensity: VisualDensity.compact,
                      onPressed: busy ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: AppColors.muted),
                    ),
                    IconButton(
                      tooltip: 'Excluir',
                      visualDensity: VisualDensity.compact,
                      onPressed: busy ? null : onDelete,
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.redGlow),
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

class _EditWorkDialog extends StatefulWidget {
  const _EditWorkDialog({required this.work});

  final Work work;

  @override
  State<_EditWorkDialog> createState() => _EditWorkDialogState();
}

class _EditWorkDialogState extends State<_EditWorkDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.work.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.work.description ?? '');

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    final description = _description.text.trim();
    Navigator.of(context).pop(
      Work(
        id: widget.work.id,
        imageUrl: widget.work.imageUrl,
        title: title.isEmpty ? null : title,
        description: description.isEmpty ? null : description,
        category: widget.work.category,
        date: widget.work.date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('Editar foto'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminLabel('TÍTULO'),
            const SizedBox(height: 6),
            TextField(
              controller: _title,
              decoration: adminInputDecoration(hint: 'Título da foto'),
            ),
            const SizedBox(height: 14),
            const AdminLabel('DESCRIÇÃO'),
            const SizedBox(height: 6),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: adminInputDecoration(hint: 'Descrição (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text(
            'Salvar',
            style: TextStyle(color: AppColors.redGlow),
          ),
        ),
      ],
    );
  }
}
