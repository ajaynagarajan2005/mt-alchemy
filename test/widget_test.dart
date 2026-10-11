import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/data/mock/products.dart';
import 'package:mt_alchemy/state/cart_store.dart';

void main() {
  group('CartStore', () {
    test('adds, merges and totals items with shipping', () {
      final cart = CartStore();
      final cards = products.first; // £24
      cart.add(cards);
      cart.add(cards);
      expect(cart.count, 2);
      expect(cart.subtotal, 48);
      expect(cart.shipping, CartStore.shippingFlat);
      expect(cart.total, 48 + CartStore.shippingFlat);
    });

    test('free shipping from £50 and removal at zero quantity', () {
      final cart = CartStore();
      final kit = productById('team-charter-workshop-kit')!; // £89
      cart.add(kit);
      expect(cart.shipping, 0);
      cart.setQuantity(kit.id, 0);
      expect(cart.isEmpty, isTrue);
      expect(cart.total, 0);
    });
  });
}
