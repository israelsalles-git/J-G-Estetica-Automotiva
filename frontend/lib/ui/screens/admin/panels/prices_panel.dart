import 'package:flutter/material.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/admin/admin_ui.dart';
import 'package:frontend/ui/widgets/gradient_button.dart';

class AdminService {
  const AdminService({
    required this.name,
    required this.description,
    required this.category,
    required this.duration,
    required this.price,
    this.active = true,
  });

  final String name;
  final String description;
  final String category;
  final String duration;
  final double price;
  final bool active;

  String get priceLabel =>
      'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';

  AdminService copyWith({double? price, bool? active}) {
    return AdminService(
      name: name,
      description: description,
      category: category,
      duration: duration,
      price: price ?? this.price,
      active: active ?? this.active,
    );
  }
}

// Proporção de cada coluna (cabeçalho e linhas usam os mesmos valores).
const _flexName = 5;
const _flexCategory = 2;
const _flexTime = 2;
const _flexPrice = 2;
const _flexStatus = 2;
const _flexAction = 4;

/// Painel "Tabela de Preços e Catálogo": busca, adicionar, ajustar preço
/// e pausar/reativar serviços. Dados de exemplo (trocar pela API depois).
class PricesPanel extends StatefulWidget {
  const PricesPanel({super.key});

  @override
  State<PricesPanel> createState() => _PricesPanelState();
}

class _PricesPanelState extends State<PricesPanel> {
  final List<AdminService> _services = [
    const AdminService(
      name: 'Lavagem de Carro',
      description: 'Snow foam, limpeza de caixas de roda e aspiração interna',
      category: 'CARROS',
      duration: '40 min',
      price: 70,
    ),
    const AdminService(
      name: 'Lavagem de Carro + Cera',
      description: 'Cera nobre de carnaúba com acabamento aveludado',
      category: 'CARROS',
      duration: '1h',
      price: 80,
    ),
    const AdminService(
      name: 'Lavagem de Moto',
      description: 'Lavagem técnica sem agredir partes elétricas',
      category: 'MOTOS',
      duration: '40 min',
      price: 50,
    ),
    const AdminService(
      name: 'Lavagem de Moto + Cera',
      description: 'Cera protetora nas carenagens, tanque e plásticos',
      category: 'MOTOS',
      duration: '1h',
      price: 60,
    ),
    const AdminService(
      name: 'Lavagem Detalhada de Moto',
      description: 'Desmontagem superficial, lubrificação e proteção térmica',
      category: 'MOTOS',
      duration: '1h30',
      price: 150,
    ),
  ];

  String _query = '';

  Future<void> _add() async {
    final result = await showDialog<AdminService>(
      context: context,
      builder: (_) => const _ServiceDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _services.insert(0, result));
  }

  Future<void> _editPrice(AdminService item) async {
    final result = await showDialog<AdminService>(
      context: context,
      builder: (_) => _ServiceDialog(initial: item),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _services.indexOf(item);
      if (index != -1) _services[index] = result;
    });
  }

  void _toggleActive(AdminService item) {
    setState(() {
      final index = _services.indexOf(item);
      if (index != -1) _services[index] = item.copyWith(active: !item.active);
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered =
        _services.where((s) => s.name.toLowerCase().contains(query)).toList();

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
                onTap: _add,
                small: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
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
                            onEdit: () => _editPrice(item),
                            onToggle: () => _toggleActive(item),
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
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
    required this.onEdit,
    required this.onToggle,
  });

  final AdminService item;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.active ? AppColors.cyan : AppColors.muted;

    return Container(
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
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Expanded(
            flex: _flexCategory,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AdminPill(label: item.category),
            ),
          ),
          Expanded(flex: _flexTime, child: Text(item.duration)),
          Expanded(
            flex: _flexPrice,
            child: Text(
              item.priceLabel,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
                AdminOutlineButton(label: 'Ajustar preço', onPressed: onEdit),
                IconButton(
                  tooltip: item.active ? 'Pausar serviço' : 'Reativar serviço',
                  onPressed: onToggle,
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
    );
  }
}

/// Diálogo de "Adicionar serviço" (sem [initial]) ou "Ajustar preço" (com [initial]).
class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({this.initial});

  final AdminService? initial;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  late final TextEditingController _name;
  late final TextEditingController _duration;
  late final TextEditingController _price;
  String _category = 'CARROS';
  String? _error;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _duration = TextEditingController(text: initial?.duration ?? '');
    _price = TextEditingController(
      text: initial == null
          ? ''
          : initial.price.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _duration.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    if (price == null || price <= 0) {
      setState(() => _error = 'Informe um preço válido.');
      return;
    }
    if (!_isEdit && _name.text.trim().isEmpty) {
      setState(() => _error = 'Informe o nome do serviço.');
      return;
    }

    final base = widget.initial;
    final duration = _duration.text.trim();
    Navigator.of(context).pop(
      AdminService(
        name: base?.name ?? _name.text.trim(),
        description: base?.description ?? 'Serviço adicionado pelo painel',
        category: base?.category ?? _category,
        duration: base?.duration ?? (duration.isEmpty ? '—' : duration),
        price: price,
        active: base?.active ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(_isEdit ? 'Ajustar preço' : 'Adicionar serviço'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isEdit)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  widget.initial!.name,
                  style: const TextStyle(color: AppColors.muted),
                ),
              )
            else ...[
              TextField(
                controller: _name,
                decoration: adminInputDecoration(hint: 'Nome do serviço'),
              ),
              const SizedBox(height: 12),
              AdminDropdown(
                value: _category,
                items: const ['CARROS', 'MOTOS'],
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _duration,
                decoration:
                    adminInputDecoration(hint: 'Tempo médio (ex.: 40 min)'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: adminInputDecoration(
                hint: 'Preço (ex.: 80,00)',
                icon: Icons.attach_money,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
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
