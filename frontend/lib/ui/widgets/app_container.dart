import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static const maxContent = 1200.0;

  static double width(BuildContext c) => MediaQuery.sizeOf(c).width;
  static bool isMobile(BuildContext c) => width(c) < 700;
  static bool isDesktop(BuildContext c) => width(c) >= 1000;

  /// Largura útil do conteúdo (já descontando o padding lateral).
  static double contentWidth(BuildContext c) {
    final w = width(c);
    return (w > maxContent ? maxContent : w) - (isMobile(c) ? 40 : 64);
  }
}

/// Centraliza o conteúdo com largura máxima e padding lateral responsivo.
class AppContainer extends StatelessWidget {
  final Widget child;
  const AppContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxContent),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: Responsive.isMobile(context) ? 20 : 32),
          child: child,
        ),
      ),
    );
  }
}
