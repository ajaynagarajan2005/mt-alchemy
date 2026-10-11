import 'package:flutter/widgets.dart';

abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 600);
  static const stagger = Duration(milliseconds: 70);

  /// Calm ease-out used for reveals and hovers.
  static const ease = Cubic(0.16, 1, 0.3, 1);

  /// True when the user asked the OS / browser for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}
