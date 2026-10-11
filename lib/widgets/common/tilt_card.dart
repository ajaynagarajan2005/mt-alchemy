import 'package:flutter/gestures.dart' show PointerHoverEvent;
import 'package:material_ui/material_ui.dart';

import '../../theme/motion.dart';
import 'tappable.dart';
import '../../theme/radii.dart';

/// Tilts its child in 3D towards the pointer (Matrix4 perspective).
/// Hover feedback only: inactive on touch and under reduced motion.
class TiltCard extends StatefulWidget {
  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 0.07,
    this.onTap,
  });

  final Widget child;

  /// Maximum rotation in radians on each axis.
  final double maxTilt;
  final VoidCallback? onTap;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  /// Pointer position relative to the card centre, -1 to 1 on each axis.
  Offset _target = Offset.zero;

  void _onHover(PointerHoverEvent e) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final s = box.size;
    setState(
      () => _target = Offset(
        (e.localPosition.dx / s.width) * 2 - 1,
        (e.localPosition.dy / s.height) * 2 - 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final tappable = widget.onTap != null;

    Widget card = TweenAnimationBuilder<Offset>(
      tween: Tween(end: reduced ? Offset.zero : _target),
      duration: Motion.medium,
      curve: Motion.ease,
      child: widget.child,
      builder: (context, o, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011) // perspective
          ..rotateX(-o.dy * widget.maxTilt)
          ..rotateY(o.dx * widget.maxTilt),
        child: child,
      ),
    );

    if (tappable) {
      card = Tappable(radius: Radii.cardAll, onTap: widget.onTap, child: card);
    }

    return MouseRegion(
      cursor: tappable ? SystemMouseCursors.click : MouseCursor.defer,
      onHover: reduced ? null : _onHover,
      onExit: (_) => setState(() => _target = Offset.zero),
      child: card,
    );
  }
}
