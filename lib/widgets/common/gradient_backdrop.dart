import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';

/// A soft blob of colour that glass panels can blur.
class Blob {
  const Blob({
    required this.alignment,
    required this.size,
    this.color,
    this.opacity = 0.16,
  });

  final Alignment alignment;

  /// Diameter in logical pixels (not clamped to the section size).
  final double size;

  /// Null means the brand red of the active palette.
  final Color? color;
  final double opacity;
}

/// Paints soft radial blobs behind a section so the glass has something to refract.
/// Radial gradients are far cheaper than blurring real shapes on Flutter web.
class GradientBackdrop extends StatelessWidget {
  const GradientBackdrop({super.key, required this.child, this.blobs});

  final Widget child;

  /// Null uses [defaultBlobs].
  final List<Blob>? blobs;

  static List<Blob> get defaultBlobs => [
    Blob(
      alignment: const Alignment(-1.0, -0.7),
      size: 560,
      opacity: AppColors.isDark ? 0.2 : 0.16,
    ),
    Blob(
      alignment: const Alignment(1.0, 0.3),
      size: 640,
      color: AppColors.grey400,
      opacity: AppColors.isDark ? 0.5 : 0.35,
    ),
    Blob(
      alignment: const Alignment(0.4, 1.1),
      size: 420,
      opacity: AppColors.isDark ? 0.16 : 0.12,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BlobPainter(blobs ?? defaultBlobs),
      child: child,
    );
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
            (blob.color ?? AppColors.red).withValues(alpha: blob.opacity),
            (blob.color ?? AppColors.red).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.blobs != blobs;
}
