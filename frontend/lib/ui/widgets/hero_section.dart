import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_container.dart';
import 'brand_logo.dart';
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
            color: AppColors.red.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.red.withValues(alpha: .8)),
          ),
          child: const Text('EXCLUSIVO FINAIS DE SEMANA',
              style: TextStyle(
                  color: AppColors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
        ),
        const SizedBox(height: 18),
        Text('ESTÉTICA AUTOMOTIVA\nDE',
            textAlign: textAlign,
            style: TextStyle(
                fontFamily: 'Knewave',
                fontSize: titleSize,
                fontWeight: FontWeight.normal,
                height: 1.05)),
        ShaderMask(
          shaderCallback: (r) => AppColors.gradient.createShader(r),
          child: Text('ALTA PRECISÃO',
              textAlign: textAlign,
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
            style: const TextStyle(color: Colors.white, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
        const Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
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
              label: 'Garantir Minha Vaga no Final de Semana',
              icon: Icons.calendar_today_outlined,
              onTap: onBooking,
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.red.withValues(alpha: .8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onServices,
              child: const Text('Conheça Catálogo',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );

    final logo = BrandLogo(width: mobile ? 300 : 520);

    return Stack(
      children: [
        // Riscos de luz vermelha no fundo (atrás de todo o conteúdo).
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _RedStreaksPainter()),
          ),
        ),
        Padding(
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
        ),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  final String text;
  const _Check(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check_circle_outline, color: AppColors.red, size: 16),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
    ]);
  }
}

/// Fundo do hero: preto com feixes de luz vermelha nas laterais.
/// Desenhado em código (sem imagem) e proporcional ao tamanho da seção.
class _RedStreaksPainter extends CustomPainter {
  const _RedStreaksPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    canvas.drawRect(rect, Paint()..color = AppColors.bg);

    // Brilho difuso nas laterais.
    void glow(Offset center, double radius, double opacity) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [AppColors.redDark.withValues(alpha: opacity), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    glow(Offset(0, h * .55), w * .32, .55);
    glow(Offset(w, h * .30), w * .30, .50);

    // Feixes (quadriláteros inclinados, suavizados com blur).
    void streak(List<Offset> pts, Color color, double blur) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    Offset o(double x, double y) => Offset(w * x, h * y);

    // Esquerda: sobem do canto inferior para o centro.
    streak([o(0, .40), o(.22, .12), o(.24, .15), o(0, .58)],
        AppColors.red.withValues(alpha: .55), 14);
    streak([o(0, .62), o(.30, .36), o(.31, .39), o(0, .80)],
        AppColors.redGlow.withValues(alpha: .40), 10);
    streak([o(0, .84), o(.20, .66), o(.21, .69), o(0, .98)],
        AppColors.red.withValues(alpha: .45), 12);

    // Direita.
    streak([o(1, .06), o(.84, .26), o(.82, .23), o(1, .00)],
        AppColors.red.withValues(alpha: .45), 14);
    streak([o(1, .30), o(.80, .52), o(.79, .49), o(1, .22)],
        AppColors.redGlow.withValues(alpha: .38), 10);
    streak([o(1, .62), o(.88, .74), o(.87, .71), o(1, .55)],
        AppColors.red.withValues(alpha: .40), 12);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
