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

  /// Second row of links under the app bar below 1024px.
  static const double navStrip = 52;

  /// Horizontal inner padding of text fields. Helper and error text are
  /// shifted back by this amount so they align with the label.
  static const double fieldInset = 16;

  /// Height of the decorative 3D crystal in page headers.
  static const double crystalHeight = 380;
}
