import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool small;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(small ? 10 : 14);
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
                color: AppColors.blue.withOpacity(.4),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: small ? 12 : 14,
              color: Colors.white),
        ),
      ),
    );
  }
}
