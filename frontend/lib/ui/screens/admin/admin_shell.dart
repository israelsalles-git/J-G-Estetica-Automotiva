import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/ui/screens/admin/admin_overview_screen.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/admin/admin_ui.dart';
import 'package:frontend/ui/widgets/app_container.dart';

class _NavItem {
  const _NavItem(this.label, this.shortLabel, this.icon);

  final String label;
  final String shortLabel;
  final IconData icon;
}

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.user,
    required this.onLogout,
    this.checkOnline,
  });

  final AuthUser user;

  final VoidCallback onLogout;

  final Future<bool> Function()? checkOnline;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const _items = [
    _NavItem('Visão Geral', 'Geral', Icons.dashboard_outlined),
    _NavItem('Fotos de Serviços', 'Fotos', Icons.photo_library_outlined),
    _NavItem('Tabela & Preços', 'Preços', Icons.payments_outlined),
    _NavItem('Agenda & Horários', 'Agenda', Icons.calendar_month_outlined),
  ];

  final _heroKey = GlobalKey();
  final _photosKey = GlobalKey();
  final _pricesKey = GlobalKey();
  final _scheduleKey = GlobalKey();

  int _index = 0;

  void _select(int index) {
    setState(() => _index = index);
    final keys = [_heroKey, _photosKey, _pricesKey, _scheduleKey];
    final target = keys[index].currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final compact = !mobile && Responsive.width(context) < 1000;

    final content = Column(
      children: [
        _TopBar(
          section: _items[_index].label,
          mobile: mobile,
          user: widget.user,
          onLogout: widget.onLogout,
          checkOnline: widget.checkOnline,
        ),
        Expanded(
          child: AdminOverviewScreen(
            heroKey: _heroKey,
            photosKey: _photosKey,
            pricesKey: _pricesKey,
            scheduleKey: _scheduleKey,
          ),
        ),
      ],
    );

    return Scaffold(
      bottomNavigationBar: mobile
          ? NavigationBar(
              backgroundColor: AppColors.nav,
              indicatorColor: AppColors.redDark.withValues(alpha: 0.4),
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final item in _items)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.shortLabel,
                  ),
              ],
            )
          : null,
      body: mobile
          ? content
          : Row(
              children: [
                _Sidebar(
                  items: _items,
                  selected: _index,
                  compact: compact,
                  onSelected: _select,
                ),
                Expanded(child: content),
              ],
            ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selected,
    required this.compact,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final int selected;
  final bool compact;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 76 : 264,
      decoration: const BoxDecoration(
        color: AppColors.nav,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 0 : 20,
              20,
              compact ? 0 : 20,
              24,
            ),
            child: Row(
              mainAxisAlignment:
                  compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car, color: Colors.white),
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TAL DA ESTÉTICA',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'GESTÃO OPERACIONAL',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.redGlow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _SidebarItem(
                item: items[i],
                selected: i == selected,
                compact: compact,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.muted;

    final tile = AdminTapSurface(
      onTap: onTap,
      color: selected ? AppColors.redDark : Colors.transparent,
      borderColor: Colors.transparent,
      radius: 14,
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16, vertical: 14),
      child: Row(
        mainAxisAlignment:
            compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(item.icon, color: color, size: 22),
          if (!compact) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ],
      ),
    );

    if (compact) {
      return Tooltip(message: item.label, child: tile);
    }
    return tile;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.section,
    required this.mobile,
    required this.user,
    required this.onLogout,
    required this.checkOnline,
  });

  final String section;
  final bool mobile;
  final AuthUser user;
  final VoidCallback onLogout;
  final Future<bool> Function()? checkOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 24),
      decoration: const BoxDecoration(
        color: AppColors.nav,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (!mobile) ...const [
                    TextSpan(
                      text: 'CONSOLE DE ADMINISTRAÇÃO',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.redGlow,
                      ),
                    ),
                    TextSpan(
                      text: '   /   ',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                  TextSpan(
                    text: section,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!mobile) ...[
            _ApiStatus(check: checkOnline),
            const SizedBox(width: 20),
          ],
          _UserMenu(user: user, onLogout: onLogout),
        ],
      ),
    );
  }
}

enum _ApiState { verificando, online, offline }

class _ApiStatus extends StatefulWidget {
  const _ApiStatus({required this.check});

  final Future<bool> Function()? check;

  @override
  State<_ApiStatus> createState() => _ApiStatusState();
}

class _ApiStatusState extends State<_ApiStatus> {
  _ApiState _state = _ApiState.verificando;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.check == null) return;
    _verificar();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _verificar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verificar() async {
    bool ok;
    try {
      ok = await widget.check!();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _state = ok ? _ApiState.online : _ApiState.offline);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.check == null) return const SizedBox.shrink();

    final Color color = switch (_state) {
      _ApiState.online => const Color(0xFF34D399),
      _ApiState.offline => Colors.redAccent,
      _ApiState.verificando => AppColors.muted,
    };
    final String label = switch (_state) {
      _ApiState.online => 'STATUS: ONLINE',
      _ApiState.offline => 'STATUS: OFFLINE',
      _ApiState.verificando => 'VERIFICANDO...',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.user, required this.onLogout});

  final AuthUser user;
  final VoidCallback onLogout;

  String get _initials {
    final parts = user.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return user.email.isEmpty ? '?' : user.email[0].toUpperCase();
    }
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Conta',
      offset: const Offset(0, 48),
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (value) {
        if (value == 'sair') onLogout();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'sair',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AppColors.redGlow),
              SizedBox(width: 10),
              Text('Sair'),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.card2,
        child: Text(
          _initials,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.redGlow,
          ),
        ),
      ),
    );
  }
}
