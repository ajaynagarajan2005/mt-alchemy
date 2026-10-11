import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/motion.dart';

/// Fades and lifts its child the first time it scrolls into view.
/// Plays once, then stops listening. Static under reduced motion.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  ScrollPosition? _position;
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_scheduleCheck);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_scheduleCheck);
    _scheduleCheck();
  }

  bool _pending = false;

  /// Scroll listeners fire before the new layout, so measure after the frame.
  void _scheduleCheck() {
    if (_pending || _shown) return;
    _pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      _check();
    });
  }

  void _check() {
    if (_shown || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height * 0.92) {
      _position?.removeListener(_scheduleCheck);
      setState(() => _shown = true);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleCheck);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return widget.child
        .animate(target: _shown ? 1 : 0)
        .fadeIn(delay: widget.delay, duration: Motion.slow, curve: Motion.ease)
        .slideY(
          begin: 0.06,
          end: 0,
          delay: widget.delay,
          duration: Motion.slow,
          curve: Motion.ease,
        );
  }
}

/// Entrance stagger for hero text: each child fades up in sequence on mount.
List<Widget> staggerIn(BuildContext context, List<Widget> children) {
  if (Motion.reduced(context)) return children;
  return [
    for (var i = 0; i < children.length; i++)
      children[i]
          .animate(delay: Motion.stagger * (i + 2))
          .fadeIn(duration: Motion.slow, curve: Motion.ease)
          .slideY(
            begin: 0.25,
            end: 0,
            duration: Motion.slow,
            curve: Motion.ease,
          ),
  ];
}
