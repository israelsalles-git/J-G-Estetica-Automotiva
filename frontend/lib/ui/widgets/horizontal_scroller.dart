import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_container.dart';

/// Fileira com rolagem horizontal: arrasta com mouse/dedo, scroll lateral
/// do trackpad e setas (setas só no desktop/tablet).
///
/// Cada item recebe EXATAMENTE [itemWidth] de largura e a altura útil da
/// fileira ([height] menos [verticalPadding] em cima e embaixo).
/// Use [verticalPadding] para dar folga a sombras/brilhos que, sem isso,
/// seriam cortados pela área de rolagem.
class HorizontalScroller extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final double itemWidth;
  final double gap;
  final double verticalPadding;

  const HorizontalScroller({
    super.key,
    required this.children,
    required this.height,
    required this.itemWidth,
    this.gap = 20,
    this.verticalPadding = 0,
  });

  @override
  State<HorizontalScroller> createState() => _HorizontalScrollerState();
}

class _HorizontalScrollerState extends State<HorizontalScroller> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(target,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final w = Responsive.width(context);
    final minSide = mobile ? 20.0 : 32.0;
    final count = widget.children.length;
    final total = count * widget.itemWidth + math.max(0, count - 1) * widget.gap;

    // Cabe tudo na tela? Então centraliza a fileira (e some com as setas).
    // Senão, começa alinhada ao conteúdo da página e o resto rola para o lado.
    final fits = total + 2 * minSide <= w;
    final sidePad = fits
        ? (w - total) / 2
        : (mobile ? 20.0 : math.max(32.0, (w - Responsive.maxContent) / 2 + 32));
    final step = (widget.itemWidth + widget.gap) * 2;

    return Column(
      children: [
        SizedBox(
          height: widget.height,
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
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                  horizontal: sidePad, vertical: widget.verticalPadding),
              itemCount: widget.children.length,
              separatorBuilder: (_, __) => SizedBox(width: widget.gap),
              itemBuilder: (_, i) =>
                  SizedBox(width: widget.itemWidth, child: widget.children[i]),
            ),
          ),
        ),
        if (!mobile && !fits) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Arrow(icon: Icons.chevron_left, onTap: () => _scrollBy(-step)),
              const SizedBox(width: 12),
              _Arrow(icon: Icons.chevron_right, onTap: () => _scrollBy(step)),
            ],
          ),
        ],
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Arrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.red),
      ),
    );
  }
}
