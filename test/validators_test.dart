import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/utils/validators.dart';

void main() {
  group('required', () {
    test('rejects null, empty and blank', () {
      expect(Validators.required(null, 'your name'), 'Enter your name.');
      expect(Validators.required('', 'your name'), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });
    test('accepts text', () => expect(Validators.required('Ada'), isNull));
  });

  group('email', () {
    test('rejects empty and malformed', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('no-at-sign'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a b@c.com'), isNotNull);
    });
    test('accepts valid, trimming spaces', () {
      expect(Validators.email('amara@example.com'), isNull);
      expect(Validators.email(' priya@northlight.example.com '), isNull);
    });
  });

  group('password', () {
    test('rejects empty, short, no number, no letter', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
      expect(Validators.password('abc1'), 'Use at least 8 characters.');
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
    });
    test('accepts letter plus number, 8 or more', () {
      expect(Validators.password('alchemy123'), isNull);
      expect(Validators.password('abcdefg1'), isNull);
    });
  });

  group('confirm', () {
    test('rejects empty and mismatch', () {
      expect(Validators.confirm('', 'alchemy123'), isNotNull);
      expect(Validators.confirm(null, 'alchemy123'), isNotNull);
      expect(Validators.confirm('alchemy124', 'alchemy123'), isNotNull);
    });
    test('accepts match', () {
      expect(Validators.confirm('alchemy123', 'alchemy123'), isNull);
    });
  });

  group('minLength', () {
    test('rejects empty and too short', () {
      expect(Validators.minLength('', 20, 'a message'), 'Enter a message.');
      expect(Validators.minLength('too short', 20), isNotNull);
    });
    test('accepts at the limit and above', () {
      expect(Validators.minLength('a' * 20, 20), isNull);
      expect(Validators.minLength('a' * 40, 20), isNull);
    });
    test('ignores surrounding whitespace', () {
      expect(Validators.minLength('   short   ', 20), isNotNull);
    });
  });
}
