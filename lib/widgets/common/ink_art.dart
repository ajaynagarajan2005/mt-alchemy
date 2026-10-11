import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';

/// Seeded abstract "crimson ink in water" artwork.
///
/// PLACEHOLDER: stands in for photography and the hero video until the fal
/// assets are approved. The same seed always paints the same composition,
/// so each course or product keeps a stable visual identity.
class InkArt extends StatelessWidget {
  const InkArt({super.key, required this.seed, this.intensity = 1});

  final String seed;

  /// 0 to 1: how strongly the red ink shows.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    // Decorative artwork: hidden from assistive tech.
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _InkPainter(_hash(seed), intensity),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  static int _hash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7fffffff;
    }
    return h;
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.seed, this.intensity);

  final int seed;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rnd = math.Random(seed);
    final d = math.max(size.width, size.height);

    canvas.clipRect(rect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.white, AppColors.grey100],
        ).createShader(rect),
    );

    Offset pt() => Offset(
      size.width * (0.1 + rnd.nextDouble() * 0.8),
      size.height * (0.1 + rnd.nextDouble() * 0.8),
    );

    // Soft clouds of ink and grey.
    for (var i = 0; i < 6; i++) {
      final center = pt();
      final radius = d * (0.18 + rnd.nextDouble() * 0.32);
      final isRed = i.isEven;
      final color = isRed
          ? AppColors.red
          : (i % 3 == 0 ? AppColors.grey700 : AppColors.grey400);
      final alpha =
          (isRed
              ? 0.18 + rnd.nextDouble() * 0.22
              : 0.10 + rnd.nextDouble() * 0.12) *
          (isRed ? intensity : 1);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // Flowing ink trails.
    for (var i = 0; i < 5; i++) {
      final a = pt(), b = pt(), c = pt(), e = pt();
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(b.dx, b.dy, c.dx, c.dy, e.dx, e.dy);
      final width = d * (0.015 + rnd.nextDouble() * 0.05);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width
          ..color = (i.isEven ? AppColors.red : AppColors.redDeep).withValues(
            alpha: (0.12 + rnd.nextDouble() * 0.18) * intensity,
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_InkPainter old) =>
      old.seed != seed || old.intensity != intensity;
}
