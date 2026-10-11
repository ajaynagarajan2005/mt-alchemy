import 'package:flutter/widgets.dart';

/// Shape rule (applied everywhere, no exceptions):
/// buttons and chips are full pill, cards and media are 24, inputs are 14.
abstract final class Radii {
  static const double pill = 999;
  static const double card = 24;
  static const double input = 14;
  static const double small = 10;

  static const pillAll = BorderRadius.all(Radius.circular(pill));
  static const cardAll = BorderRadius.all(Radius.circular(card));
  static const inputAll = BorderRadius.all(Radius.circular(input));
  static const smallAll = BorderRadius.all(Radius.circular(small));
}
