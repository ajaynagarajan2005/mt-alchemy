import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';

/// Subtle film grain over the whole app. Fixed (never inside a scroll view)
/// and ignores pointer events so it costs a single static layer.
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({super.key, this.opacity = 0.035});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/textures/grain.png'),
              repeat: ImageRepeat.repeat,
              opacity: AppColors.isDark ? opacity * 1.6 : opacity,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
  }
}
