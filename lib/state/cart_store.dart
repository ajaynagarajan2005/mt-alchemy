import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models/cart_item.dart';
import '../data/models/product.dart';

class CartStore extends ChangeNotifier {
  static const double shippingFlat = 4.95;
  static const double freeShippingFrom = 50;

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get count => _items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0, (sum, i) => sum + i.lineTotal);
  double get shipping =>
      isEmpty || subtotal >= freeShippingFrom ? 0 : shippingFlat;
  double get total => subtotal + shipping;

  void add(Product product, {int quantity = 1}) {
    final existing = _items.where((i) => i.product.id == product.id);
    if (existing.isNotEmpty) {
      existing.first.quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) return remove(productId);
    _items.firstWhere((i) => i.product.id == productId).quantity = quantity;
    notifyListeners();
  }

  void remove(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Order? _lastOrder;
  Order? get lastOrder => _lastOrder;

  /// Turns the cart into an order (MTA-12345), empties the cart and returns it.
  Order placeOrder({required String email, Random? random}) {
    final number = 10000 + (random ?? Random()).nextInt(90000);
    final order = Order(
      number: 'MTA-$number',
      items: [
        for (final i in _items)
          CartItem(product: i.product, quantity: i.quantity),
      ],
      subtotal: subtotal,
      shipping: shipping,
      total: total,
      email: email,
    );
    _lastOrder = order;
    _items.clear();
    notifyListeners();
    return order;
  }
}

/// A completed (mock) order, kept in memory for the confirmation screen.
class Order {
  const Order({
    required this.number,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.email,
  });

  final String number;
  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final double total;
  final String email;
}
