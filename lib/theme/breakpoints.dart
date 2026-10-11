import 'package:flutter/widgets.dart';

import 'spacing.dart';

enum ScreenSize { compact, medium, expanded }

/// compact < 600, medium 600-1023, expanded >= 1024.
abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 1024;

  static ScreenSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static ScreenSize fromWidth(double width) {
    if (width >= expanded) return ScreenSize.expanded;
    if (width >= medium) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  static double gutter(BuildContext context) => switch (of(context)) {
    ScreenSize.compact => Space.gutterCompact,
    ScreenSize.medium => Space.gutterMedium,
    ScreenSize.expanded => Space.gutterExpanded,
  };
}

extension ScreenSizeX on BuildContext {
  ScreenSize get screenSize => Breakpoints.of(this);
  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isExpanded => screenSize == ScreenSize.expanded;
}
