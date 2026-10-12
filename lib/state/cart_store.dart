import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/backend.dart';
import '../data/models/cart_item.dart';
import '../data/models/course.dart';
import '../data/models/product.dart';
import 'auth_store.dart';
import 'catalog_store.dart';

/// The shopping cart. Guests keep it in memory; signed-in users have it saved
/// in carts/{uid}, and a guest cart is merged in when they sign in.
class CartStore extends ChangeNotifier {
  CartStore([this._backend, this._auth, this._catalog]) {
    _auth?.addListener(_onAuth);
    _onAuth();
  }

  static const double shippingFlat = 4.95;
  static const double freeShippingFrom = 50;

  final Backend? _backend;
  final AuthStore? _auth;
  final CatalogStore? _catalog;
  String? _uid;
  bool _restoring = false;

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get count => _items.fold(0, (total, i) => total + i.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get hasPhysical => _items.any((i) => i.isPhysical);

  double get subtotal => _items.fold(0, (total, i) => total + i.lineTotal);
  double get physicalSubtotal => _items
      .where((i) => i.isPhysical)
      .fold(0, (total, i) => total + i.lineTotal);

  /// Flat delivery for physical items, free from £50 of physical goods.
  double get shipping =>
      !hasPhysical || physicalSubtotal >= freeShippingFrom ? 0 : shippingFlat;
  double get total => subtotal + shipping;

  void add(Product product, {int quantity = 1}) =>
      _addLine(CartItem.product(product, quantity: quantity));

  /// A course for the signed-in learner (Journey A).
  void addCourse(Course course) => _addLine(CartItem.course(course));

  /// Course seats an employer buys for their team (Journey D).
  void addSeats(Course course, int seats) =>
      _addLine(CartItem.seats(course, quantity: seats));

  void _addLine(CartItem line) {
    final existing = _items.where((i) => i.key == line.key);
    if (existing.isNotEmpty) {
      if (!line.fixedQuantity) existing.first.quantity += line.quantity;
    } else {
      _items.add(line);
    }
    _changed();
  }

  bool containsCourse(String courseId) =>
      _items.any((i) => i.key == 'course:$courseId');

  void setQuantity(String key, int quantity) {
    if (quantity <= 0) return remove(key);
    _items.firstWhere((i) => i.key == key).quantity = quantity;
    _changed();
  }

  void remove(String key) {
    _items.removeWhere((i) => i.key == key);
    _changed();
  }

  void clear() {
    _items.clear();
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  // ---------- Persistence ----------

  DocumentReference<Map<String, dynamic>>? get _doc =>
      _uid == null ? null : _backend?.col('carts').doc(_uid);

  void _save() {
    if (_restoring) return;
    _doc
        ?.set({
          'items': [for (final i in _items) i.toMap()],
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .catchError((_) {});
  }

  Future<void> _onAuth() async {
    final uid = _auth?.currentUser?.id;
    if (uid == _uid) return;
    _uid = uid;
    if (uid == null) {
      _items.clear();
      notifyListeners();
      return;
    }
    // Merge the saved cart with whatever the guest added before signing in.
    try {
      final snap = await _doc!.get();
      final saved = (snap.data()?['items'] as List?) ?? const [];
      _restoring = true;
      for (final raw in saved) {
        final line = _lineFrom(Map<String, dynamic>.from(raw as Map));
        if (line != null) _addLine(line);
      }
    } catch (_) {
      // Offline: keep the in-memory cart.
    } finally {
      _restoring = false;
    }
    _changed();
  }

  CartItem? _lineFrom(Map<String, dynamic> m) {
    final catalog = _catalog;
    if (catalog == null) return null;
    final qty = (m['quantity'] as num?)?.toInt() ?? 1;
    final id = m['id'] as String? ?? '';
    switch (m['kind']) {
      case 'course':
        final c = catalog.courseById(id);
        return c == null ? null : CartItem.course(c);
      case 'seats':
        final c = catalog.courseById(id);
        return c == null ? null : CartItem.seats(c, quantity: qty);
      default:
        final p = catalog.productById(id);
        return p == null ? null : CartItem.product(p, quantity: qty);
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuth);
    super.dispose();
  }
}
