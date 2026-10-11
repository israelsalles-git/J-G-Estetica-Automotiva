import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_container.dart';
import 'gradient_button.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback onBooking;
  final VoidCallback onServices;

  const HeroSection({
    super.key,
    required this.onBooking,
    required this.onServices,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final align = mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = mobile ? TextAlign.center : TextAlign.start;
    final titleSize = mobile ? 32.0 : 52.0;

    final text = Column(
      crossAxisAlignment: align,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cyan.withOpacity(.3)),
          ),
          child: const Text('EXCLUSIVO FINAIS DE SEMANA',
              style: TextStyle(
                  color: AppColors.cyan, fontSize: 10, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 18),
        Text('ESTÉTICA AUTOMOTIVA\nDE',
            textAlign: textAlign,
            style: TextStyle(
                fontSize: titleSize, fontWeight: FontWeight.w900, height: 1.05)),
        ShaderMask(
          shaderCallback: (r) => AppColors.gradient.createShader(r),
          child: Text('ALTA PRECISÃO',
              style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Atendimento exclusivo aos finais de semana (Sábados e Domingos, das 07:00 às 18:00). '
            'Tratamento artesanal detalhado para recuperar o brilho de concessionária do seu carro ou motocicleta.',
            textAlign: textAlign,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
        const Wrap(spacing: 16, runSpacing: 8, children: [
          _Check('Produtos Premium pH Neutro'),
          _Check('Pontualidade Rigorosa'),
          _Check('Cuidado em Cada Peça'),
        ]),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            GradientButton(
                label: 'Garantir Minha Vaga no Final de Semana', onTap: onBooking),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onServices,
              child: const Text('Conheça Catálogo',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );

    final logoSize = mobile ? 180.0 : 280.0;
    final logo = Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card,
        border: Border.all(color: AppColors.cyan.withOpacity(.5), width: 3),
        boxShadow: [
          BoxShadow(color: AppColors.blue.withOpacity(.5), blurRadius: 60)
        ],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('J&G',
            style: TextStyle(
                fontSize: mobile ? 52 : 80,
                fontWeight: FontWeight.w900,
                color: AppColors.cyan)),
        const Text('ESTÉTICA AUTOMOTIVA',
            style: TextStyle(
                fontSize: 10, letterSpacing: 2, color: AppColors.muted)),
      ]),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [Color(0xFF12234A), AppColors.bg],
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: mobile ? 40 : 80),
      child: AppContainer(
        child: mobile
            ? Column(children: [text, const SizedBox(height: 40), logo])
            : Row(children: [
                Expanded(flex: 3, child: text),
                const SizedBox(width: 32),
                Expanded(flex: 2, child: Center(child: logo)),
              ]),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final String text;
  const _Check(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check_circle_outline, color: AppColors.cyan, size: 16),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ]);
  }
}
