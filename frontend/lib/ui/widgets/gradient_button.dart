import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botão principal: gradiente vermelho com brilho neon.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool small;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.small = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(small ? 10 : 14);
    final fontSize = small ? 12.0 : 14.0;
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 14 : 24, vertical: small ? 10 : 16),
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
                color: AppColors.redGlow.withValues(alpha: .45),
                blurRadius: small ? 14 : 22,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 4, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: fontSize,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
