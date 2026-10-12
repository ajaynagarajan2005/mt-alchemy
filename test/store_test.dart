
import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/data/mock/products.dart';
import 'package:mt_alchemy/state/cart_store.dart';
import 'package:mt_alchemy/utils/validators.dart';

void main() {
  group('postcode', () {
    test('accepts UK formats', () {
      for (final p in [
        'SW1A 1AA',
        'sw1a1aa',
        'M1 1AE',
        'B33 8TH',
        'EC1A 1BB',
      ]) {
        expect(CheckoutValidators.postcode(p), isNull, reason: p);
      }
    });
    test('rejects empty and malformed', () {
      expect(CheckoutValidators.postcode(''), isNotNull);
      for (final p in ['12345', 'SW1A', 'ABCDE FG', 'SW1A 1A']) {
        expect(CheckoutValidators.postcode(p), isNotNull, reason: p);
      }
    });
  });

  group('cardNumber', () {
    test('accepts a valid Luhn number with or without spaces', () {
      expect(CheckoutValidators.cardNumber('4242 4242 4242 4242'), isNull);
      expect(CheckoutValidators.cardNumber('4242424242424242'), isNull);
    });
    test('rejects bad length, letters and failed checksum', () {
      expect(CheckoutValidators.cardNumber(''), isNotNull);
      expect(CheckoutValidators.cardNumber('4242 4242'), isNotNull);
      expect(CheckoutValidators.cardNumber('4242 4242 4242 424x'), isNotNull);
      expect(CheckoutValidators.cardNumber('4242 4242 4242 4241'), isNotNull);
    });
  });

  group('expiry', () {
    final now = DateTime(2026, 10, 11);
    test('accepts current month and future', () {
      expect(CheckoutValidators.expiry('10/26', now: now), isNull);
      expect(CheckoutValidators.expiry('01/30', now: now), isNull);
    });
    test('rejects past, bad month and bad format', () {
      expect(CheckoutValidators.expiry('09/26', now: now), isNotNull);
      expect(CheckoutValidators.expiry('12/25', now: now), isNotNull);
      expect(CheckoutValidators.expiry('13/30', now: now), isNotNull);
      expect(CheckoutValidators.expiry('1230', now: now), isNotNull);
      expect(CheckoutValidators.expiry('', now: now), isNotNull);
    });
  });

  group('cvc', () {
    test('needs exactly 3 digits', () {
      expect(CheckoutValidators.cvc('123'), isNull);
      expect(CheckoutValidators.cvc('12'), isNotNull);
      expect(CheckoutValidators.cvc('1234'), isNotNull);
      expect(CheckoutValidators.cvc('12a'), isNotNull);
      expect(CheckoutValidators.cvc(''), isNotNull);
    });
  });

  group('CartStore', () {
    final cheap = productById('leading-with-care-book')!; // 18
    final mid = productById('team-charter-workshop-kit')!; // 89

    test('adds, merges and counts quantities', () {
      final cart = CartStore()
        ..add(cheap)
        ..add(cheap, quantity: 2);
      expect(cart.items.length, 1);
      expect(cart.count, 3);
      expect(cart.subtotal, 54);
    });

    test('charges shipping under the threshold, free from 50', () {
      final cart = CartStore()..add(cheap, quantity: 2); // 36
      expect(cart.shipping, CartStore.shippingFlat);
      expect(cart.total, 36 + CartStore.shippingFlat);
      cart.setQuantity(cheap.id, 3); // 54
      expect(cart.shipping, 0);
      expect(cart.total, 54);
    });

    test('exactly 50 is free shipping; empty cart has none', () {
      expect(CartStore().shipping, 0);
      final cart = CartStore()..add(mid);
      expect(cart.shipping, 0);
    });

    test('setQuantity to zero removes the line', () {
      final cart = CartStore()..add(cheap);
      cart.setQuantity(cheap.id, 0);
      expect(cart.isEmpty, isTrue);
    });

    test('digital items and courses never pay shipping', () {
      final toolkit = productById('ei-self-coaching-toolkit')!; // digital
      final cart = CartStore()
        ..add(toolkit)
        ..addCourse(courses.first);
      expect(cart.hasPhysical, isFalse);
      expect(cart.shipping, 0);
      expect(cart.total, toolkit.price + courses.first.price);
    });

    test('a course is bought once; seats add up per course', () {
      final course = courses.first;
      final cart = CartStore()
        ..addCourse(course)
        ..addCourse(course)
        ..addSeats(course, 3)
        ..addSeats(course, 2);
      expect(cart.items.length, 2);
      expect(cart.containsCourse(course.id), isTrue);
      expect(cart.items.last.quantity, 5);
      expect(cart.subtotal, course.price * 6);
    });
  });
}
