/// 4pt spacing scale. Use these instead of raw numbers in widgets.
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
  static const double section = 96;
  static const double sectionCompact = 56;

  /// Max width of page content. Wide enough that large screens stay filled.
  static const double contentMax = 1600;

  /// Page gutters per breakpoint.
  static const double gutterCompact = 16;
  static const double gutterMedium = 32;
  static const double gutterExpandedMin = 48;
  static const double gutterExpandedMax = 120;

  /// Expanded gutter is 5% of the width, clamped between the min and max.
  static const double gutterExpandedFactor = 0.05;

  static const double navHeight = 72;
}
