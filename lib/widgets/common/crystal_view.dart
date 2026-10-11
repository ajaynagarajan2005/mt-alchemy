import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/motion.dart';
import '../../theme/spacing.dart';

/// Decorative rotating GLB crystal (assets/models/crystal.glb).
///
/// Transparent background, slow auto-rotate (off under reduced motion) and
/// no touch/camera controls, so it never traps page scrolling. Hidden from
/// assistive tech apart from a short decorative label, and not focusable.
class CrystalView extends StatefulWidget {
  const CrystalView({super.key, this.height = Space.crystalHeight});

  final double height;

  @override
  State<CrystalView> createState() => _CrystalViewState();
}

class _CrystalViewState extends State<CrystalView> {
  final _controller = Flutter3DController();
  bool _started = false;

  void _spin() {
    if (_started || !mounted || Motion.reduced(context)) return;
    _started = true;
    // Degrees per second; slow and calm.
    _controller.startRotation(rotationSpeed: 18);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rotating red crystal, decorative',
      image: true,
      excludeSemantics: true,
      child: ExcludeFocus(
        // IgnorePointer: wheel and touch go to the page, not the viewer.
        child: IgnorePointer(
          child: SizedBox(
            height: widget.height,
            child: Flutter3DViewer(
              controller: _controller,
              // On web the viewer fetches over HTTP, where bundled assets live under
              // the extra `assets/` prefix of the build output.
              src: kIsWeb
                  ? 'assets/assets/models/crystal.glb'
                  : 'assets/models/crystal.glb',
              enableTouch: false,
              activeGestureInterceptor: false,
              progressBarColor: const Color(0x00000000),
              onLoad: (_) => _spin(),
            ),
          ),
        ),
      ),
    );
  }
}
