import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';
import '../../theme/radii.dart';

/// Drop-in replacement for GestureDetector on custom cards, rows and links.
///
/// Adds what a bare GestureDetector lacks: it is reachable with Tab, fires on
/// Enter and Space, and paints a 2 px red focus ring that follows [radius].
/// Callers keep their own Semantics and MouseRegion.
class Tappable extends StatefulWidget {
  const Tappable({
    super.key,
    required this.onTap,
    required this.child,
    this.radius = Radii.inputAll,
    this.behavior,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// Corner radius of the focus ring.
  final BorderRadius radius;
  final HitTestBehavior? behavior;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.onTap != null,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: widget.behavior,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.radius,
            border: _focused
                ? Border.all(color: AppColors.red, width: 2)
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
