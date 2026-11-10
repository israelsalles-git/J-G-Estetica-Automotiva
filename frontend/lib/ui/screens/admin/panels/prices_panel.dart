import 'package:flutter/material.dart';
import 'package:frontend/core/load_status.dart';
import 'package:frontend/models/service.dart';
import 'package:frontend/providers/admin_catalog_provider.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/admin/admin_ui.dart';
import 'package:frontend/ui/widgets/gradient_button.dart';
import 'package:provider/provider.dart';

const _flexName = 5;
const _flexCategory = 2;
const _flexTime = 2;
const _flexPrice = 2;
const _flexStatus = 2;
const _flexAction = 4;

const _categorias = ['Carro', 'Moto'];

String _preco(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

class PricesPanel extends StatefulWidget {
  const PricesPanel({super.key});

  @override
  State<PricesPanel> createState() => _PricesPanelState();
}

class _PricesPanelState extends State<PricesPanel> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminCatalogProvider>().load();
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _depoisDaAcao(bool ok, String sucesso, AdminCatalogProvider admin,
      CatalogProvider site) {
    if (!mounted) return;
    if (ok) {
      site.load();
      _snack(sucesso);
    } else {
      _snack(admin.actionError ?? 'Não foi possível concluir a ação.');
    }
  }

  Future<void> _add() async {
    final admin = context.read<AdminCatalogProvider>();
    final site = context.read<CatalogProvider>();
    final dados = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _ServiceDialog(),
    );
    if (dados == null) return;
    final ok = await admin.add(dados);
    _depoisDaAcao(ok, 'Serviço adicionado.', admin, site);
  }

  Future<void> _edit(Service item) async {
    final admin = context.read<AdminCatalogProvider>();
    final site = context.read<CatalogProvider>();
    final dados = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ServiceDialog(initial: item),
    );
    if (dados == null) return;
    final ok = await admin.update(item.id, dados);
    _depoisDaAcao(ok, 'Serviço atualizado.', admin, site);
  }

  Future<void> _toggle(Service item) async {
    final admin = context.read<AdminCatalogProvider>();
    final site = context.read<CatalogProvider>();
    final ok =
        item.active ? await admin.pause(item.id) : await admin.reactivate(item.id);
    _depoisDaAcao(
      ok,
      item.active ? 'Serviço pausado.' : 'Serviço reativado.',
      admin,
      site,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminCatalogProvider>();
    final query = _query.trim().toLowerCase();
    final filtered = admin.services
        .where((s) => s.name.toLowerCase().contains(query))
        .toList();

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPanelHeader(
            icon: Icons.tune,
            title: 'Tabela de Preços e Catálogo',
            subtitle: 'Ajuste valores de tabela em tempo real, sem complicação.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: adminInputDecoration(
                    hint: 'Filtrar serviço...',
                    icon: Icons.search,
                  ),
                ),
              ),
              GradientButton(
                label: '+ Adicionar serviço',
                onTap: admin.isSaving ? () {} : _add,
                small: true,
              ),
              if (admin.isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.redGlow,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBody(admin, filtered),
        ],
      ),
    );
  }

  Widget _buildBody(AdminCatalogProvider admin, List<Service> filtered) {
    if (admin.status == LoadStatus.idle || admin.status == LoadStatus.loading) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.redGlow),
        ),
      );
    }
    if (admin.status == LoadStatus.error) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            admin.error ?? 'Não foi possível carregar os serviços.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          AdminOutlineButton(label: 'Tentar novamente', onPressed: admin.load),
        ],
      );
    }
    if (admin.services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Nenhum serviço cadastrado ainda.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth < 820 ? 820.0 : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                const _HeaderRow(),
                const Divider(height: 1, color: AppColors.border),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Nenhum serviço encontrado',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  for (final item in filtered)
                    _ServiceRow(
                      item: item,
                      busy: admin.isSaving,
                      onEdit: () => _edit(item),
                      onToggle: () => _toggle(item),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: _flexName, child: AdminLabel('SERVIÇO PRINCIPAL')),
          Expanded(flex: _flexCategory, child: AdminLabel('CATEGORIA')),
          Expanded(flex: _flexTime, child: AdminLabel('TEMPO MÉDIO')),
          Expanded(flex: _flexPrice, child: AdminLabel('PREÇO')),
          Expanded(flex: _flexStatus, child: AdminLabel('STATUS')),
          Expanded(flex: _flexAction, child: AdminLabel('AÇÃO DIRETA')),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.item,
    required this.busy,
    required this.onEdit,
    required this.onToggle,
  });

  final Service item;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.active ? AppColors.redGlow : AppColors.muted;

    return Opacity(
      opacity: item.active ? 1 : 0.65,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: _flexName,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: _flexCategory,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AdminPill(label: item.category.toUpperCase()),
              ),
            ),
            Expanded(flex: _flexTime, child: Text(item.duration)),
            Expanded(
              flex: _flexPrice,
              child: Text(
                _preco(item.price),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            Expanded(
              flex: _flexStatus,
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    item.active ? 'ATIVO' : 'PAUSADO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: _flexAction,
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AdminOutlineButton(
                    label: 'Ajustar',
                    onPressed: busy ? () {} : onEdit,
                  ),
                  IconButton(
                    tooltip: item.active ? 'Pausar serviço' : 'Reativar serviço',
                    onPressed: busy ? null : onToggle,
                    icon: Icon(
                      item.active
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({this.initial});

  final Service? initial;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  late final TextEditingController _name;
  late final TextEditingController _minutes;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late String _category;
  late bool _vip;
  String? _error;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s?.name ?? '');
    _minutes = TextEditingController(text: s == null ? '' : '${s.durationMinutes}');
    _price = TextEditingController(
      text: s == null ? '' : s.price.toStringAsFixed(2).replaceAll('.', ','),
    );
    _description = TextEditingController(text: s?.description ?? '');
    _category = (s != null && _categorias.contains(s.category))
        ? s.category
        : _categorias.first;
    _vip = s?.vip ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _minutes.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 120) {
      setState(() => _error = 'O nome deve ter de 1 a 120 caracteres.');
      return;
    }
    final minutes = int.tryParse(_minutes.text.trim());
    if (minutes == null || minutes < 1 || minutes > 1440) {
      setState(() => _error = 'A duração deve ser de 1 a 1440 minutos.');
      return;
    }
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    if (price == null || price <= 0) {
      setState(() => _error = 'Informe um preço válido.');
      return;
    }
    final description = _description.text.trim();
    if (description.length > 500) {
      setState(() => _error = 'A descrição pode ter até 500 caracteres.');
      return;
    }

    Navigator.of(context).pop(<String, dynamic>{
      'nome': name,
      'categoria': _category,
      'duracao_min': minutes,
      'preco': price.toStringAsFixed(2),
      'descricao': description.isEmpty ? null : description,
      'destaque': _vip,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(_isEdit ? 'Ajustar serviço' : 'Adicionar serviço'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: adminInputDecoration(hint: 'Nome do serviço'),
              ),
              const SizedBox(height: 12),
              AdminDropdown(
                value: _category,
                items: _categorias,
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                decoration: adminInputDecoration(
                  hint: 'Duração em minutos (ex.: 40)',
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: adminInputDecoration(
                  hint: 'Preço (ex.: 80,00)',
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 3,
                maxLength: 500,
                decoration: adminInputDecoration(hint: 'Descrição (opcional)'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Destaque no site'),
                value: _vip,
                onChanged: (v) => setState(() => _vip = v),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        GradientButton(label: 'Salvar', onTap: _submit, small: true),
      ],
    );
  }
}
