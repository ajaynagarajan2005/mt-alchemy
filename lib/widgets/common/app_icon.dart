import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

/// Icon data from the hugeicons stroke-rounded set (the only icon family in the app).
typedef AppIconData = List<List<dynamic>>;

/// Hugeicons wrapper that inherits colour and size from [IconTheme], so it
/// behaves like a normal Icon inside IconButtons and buttons.
/// One stroke width app-wide keeps the family consistent.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final AppIconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  static const strokeWidth = 1.6;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final glyph = HugeIcon(
      icon: icon,
      size: size ?? theme.size ?? 24,
      color: color ?? theme.color,
      strokeWidth: strokeWidth,
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: glyph)
        : Semantics(
            label: semanticLabel,
            child: ExcludeSemantics(child: glyph),
          );
  }
}
