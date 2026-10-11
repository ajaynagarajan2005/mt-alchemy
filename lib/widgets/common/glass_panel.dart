import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';

/// Frosted-glass surface (web approximation of glassmorphism, not Apple Liquid Glass).
///
/// CONTAINER (decoration): the inner Container paints the translucent fill,
/// the 1px light border and the grey-tinted shadow that make the glass read
/// as a physical material.
///
/// Performance rules: keep a few per viewport, never nest one GlassPanel in
/// another. High-contrast mode swaps the glass for a solid fill.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.borderRadius = Radii.cardAll,
    this.blur = 20,
    this.strong = false,
    this.shadow = true,
    this.backdrop = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blur;

  /// Use a more opaque fill when the panel sits over busy media (video, photos).
  final bool strong;
  final bool shadow;

  /// Set false to skip the BackdropFilter blur (frosted fill only). Use on
  /// plain light surfaces where there is nothing to blur; it also avoids a
  /// faint rectangular edge some GPUs draw around small blurred tiles.
  final bool backdrop;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);

    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highContrast
            ? AppColors.surface
            : (strong ? AppColors.glassFillStrong : AppColors.glassFill),
        borderRadius: borderRadius,
        border: Border.all(
          color: highContrast ? AppColors.grey400 : AppColors.glassBorder,
        ),
        // Top highlight line gives the edge a sense of refraction.
        gradient: highContrast
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.04, 1],
                colors: [
                  Colors.white.withValues(alpha: strong ? 0.95 : 0.85),
                  strong ? AppColors.glassFillStrong : AppColors.glassFill,
                  strong ? AppColors.glassFillStrong : AppColors.glassFill,
                ],
              ),
      ),
      child: child,
    );

    final shadowed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: AppColors.shadowTint,
                  blurRadius: 40,
                  offset: Offset(0, 16),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: (highContrast || !backdrop)
            ? panel
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: panel,
              ),
      ),
    );

    return RepaintBoundary(child: shadowed);
  }
}
