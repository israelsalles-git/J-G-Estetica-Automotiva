import 'package:flutter/material.dart';

import '../../core/business_config.dart';
import '../theme/app_theme.dart';

/// Logo da marca. Se o arquivo não for encontrado (asset não declarado no
/// pubspec.yaml, por exemplo), mostra o nome em texto em vez de quebrar a tela.
class BrandLogo extends StatelessWidget {
  final double? width;
  final double? height;

  const BrandLogo({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BusinessConfig.logoAsset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: BusinessConfig.name,
      errorBuilder: (_, __, ___) => Text(
        BusinessConfig.name.toUpperCase(),
        style: const TextStyle(
            color: AppColors.red, fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}
