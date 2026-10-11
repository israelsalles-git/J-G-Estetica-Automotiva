import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_container.dart';

class SectionTitle extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;

  const SectionTitle({
    super.key,
    required this.tag,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    return Column(
      children: [
        Text(tag,
            style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: mobile ? 24 : 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 14)),
      ],
    );
  }
}
