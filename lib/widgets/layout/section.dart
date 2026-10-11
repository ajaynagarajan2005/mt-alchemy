import 'package:material_ui/material_ui.dart';

import '../../theme/breakpoints.dart';
import '../../theme/spacing.dart';
import 'content_frame.dart';

/// A vertical band of the page.
///
/// CONTAINER (grouping): the Container groups one section's content, gives it
/// consistent vertical rhythm and an optional background colour.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.child,
    this.color,
    this.framed = true,
    this.top = true,
    this.bottom = true,
  });

  final Widget child;
  final Color? color;

  /// Wrap the child in a [ContentFrame]. Turn off for full-bleed content.
  final bool framed;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final v = context.isCompact ? Space.sectionCompact : Space.section;
    return Container(
      width: double.infinity,
      color: color,
      padding: EdgeInsets.only(top: top ? v : 0, bottom: bottom ? v : 0),
      child: framed ? ContentFrame(child: child) : child,
    );
  }
}
