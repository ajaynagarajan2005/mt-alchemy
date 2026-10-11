import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';

/// A soft blob of colour that glass panels can blur.
class Blob {
  const Blob({
    required this.alignment,
    required this.size,
    this.color = AppColors.red,
    this.opacity = 0.16,
  });

  final Alignment alignment;

  /// Diameter in logical pixels (not clamped to the section size).
  final double size;
  final Color color;
  final double opacity;
}

/// Paints soft radial blobs behind a section so the glass has something to refract.
/// Radial gradients are far cheaper than blurring real shapes on Flutter web.
class GradientBackdrop extends StatelessWidget {
  const GradientBackdrop({
    super.key,
    required this.child,
    this.blobs = defaultBlobs,
  });

  final Widget child;
  final List<Blob> blobs;

  static const defaultBlobs = [
    Blob(alignment: Alignment(-1.0, -0.7), size: 560),
    Blob(
      alignment: Alignment(1.0, 0.3),
      size: 640,
      color: AppColors.grey400,
      opacity: 0.35,
    ),
    Blob(alignment: Alignment(0.4, 1.1), size: 420, opacity: 0.12),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BlobPainter(blobs), child: child);
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.blobs);

  final List<Blob> blobs;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final blob in blobs) {
      final center = blob.alignment.alongSize(size);
      final radius = blob.size / 2;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.color.withValues(alpha: blob.opacity),
            blob.color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.blobs != blobs;
}
