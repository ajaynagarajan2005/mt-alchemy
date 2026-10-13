import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/state/theme_controller.dart';

void main() {
  test('toggle flips light and dark repeatedly', () {
    final c = ThemeController();
    const platform = Brightness.light;
    expect(c.effective(platform), Brightness.light);
    for (final expected in [
      Brightness.dark,
      Brightness.light,
      Brightness.dark,
      Brightness.light,
    ]) {
      c.toggle(c.effective(platform));
      expect(c.effective(platform), expected);
    }
  });

  test('follows the browser until the user chooses', () {
    final c = ThemeController();
    expect(c.effective(Brightness.dark), Brightness.dark);
    c.toggle(c.effective(Brightness.dark));
    expect(c.effective(Brightness.dark), Brightness.light);
  });
}
