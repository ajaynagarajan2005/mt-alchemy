import 'package:material_ui/material_ui.dart';

import 'app_icon.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';

enum ButtonVariant {
  /// Red fill, white label. One primary per view.
  primary,

  /// Grey outline on light or glass backgrounds.
  secondary,

  /// Light outline for dark backgrounds (footer, CTA band).
  inverse,
}

/// Pill button used everywhere. Presses scale to 0.98 for tactile feedback.
class AlchemyButton extends StatefulWidget {
  const AlchemyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final AppIconData? icon;

  /// Fill the available width (forms, mobile).
  final bool expand;

  /// Shows a spinner and ignores taps while an async action runs.
  final bool loading;

  @override
  State<AlchemyButton> createState() => _AlchemyButtonState();
}

class _AlchemyButtonState extends State<AlchemyButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  ButtonStyle get _style {
    const padding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    const shape = RoundedRectangleBorder(borderRadius: Radii.pillAll);
    final text = WidgetStatePropertyAll(AppText.button);

    return switch (widget.variant) {
      ButtonVariant.primary => ButtonStyle(
        padding: const WidgetStatePropertyAll(padding),
        shape: const WidgetStatePropertyAll(shape),
        textStyle: text,
        elevation: const WidgetStatePropertyAll(0),
        foregroundColor: WidgetStatePropertyAll(AppColors.onAccent),
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return AppColors.grey300;
          if (s.contains(WidgetState.hovered) ||
              s.contains(WidgetState.pressed)) {
            return AppColors.accentHover;
          }
          return AppColors.accentFill;
        }),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      ButtonVariant.secondary => ButtonStyle(
        padding: const WidgetStatePropertyAll(padding),
        shape: const WidgetStatePropertyAll(shape),
        textStyle: text,
        foregroundColor: WidgetStatePropertyAll(AppColors.ink),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered)
              ? AppColors.grey100
              : AppColors.surface.withValues(alpha: 0.6),
        ),
        side: WidgetStateProperty.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.hovered)
                ? AppColors.grey900
                : AppColors.grey400,
          ),
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      ButtonVariant.inverse => ButtonStyle(
        padding: const WidgetStatePropertyAll(padding),
        shape: const WidgetStatePropertyAll(shape),
        textStyle: text,
        foregroundColor: WidgetStatePropertyAll(AppColors.onInverse),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered)
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: AppColors.inverseOutline),
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.loading) ...[
          const SizedBox(width: 10),
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ] else if (widget.icon != null) ...[
          const SizedBox(width: 10),
          AppIcon(widget.icon!, size: 18),
        ],
      ],
    );
    final onPressed = widget.loading ? null : widget.onPressed;

    final button = widget.variant == ButtonVariant.primary
        ? FilledButton(onPressed: onPressed, style: _style, child: child)
        : OutlinedButton(
            onPressed: onPressed,
            style: _style,
            child: child,
          );

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed && !Motion.reduced(context) ? 0.98 : 1,
        duration: Motion.fast,
        curve: Motion.ease,
        child: widget.expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}
