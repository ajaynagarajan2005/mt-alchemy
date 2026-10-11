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
}
