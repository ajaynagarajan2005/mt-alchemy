import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/state/theme_controller.dart';
import 'package:mt_alchemy/widgets/common/search_field.dart';

void main() {
  group('matchesQuery', () {
    test('empty query matches everything', () {
      expect(matchesQuery('', ['anything']), isTrue);
      expect(matchesQuery('   ', ['anything']), isTrue);
    });

    test('every word must appear, in any order, ignoring case', () {
      const text = ['Leading Through Change', 'Help your team commit'];
      expect(matchesQuery('change team', text), isTrue);
      expect(matchesQuery('TEAM leading', text), isTrue);
      expect(matchesQuery('change budget', text), isFalse);
    });
  });

  group('ThemeController', () {
    test('text size changes and notifies', () {
      final c = ThemeController(persist: false);
      var n = 0;
      c.addListener(() => n++);
      expect(c.textScale, 1.0);
      c.setTextScale(1.3);
      c.setTextScale(1.3);
      expect(c.textScale, 1.3);
      expect(n, 1);
    });
  });
}
