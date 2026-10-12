import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/backend.dart';
import '../data/models/cart_item.dart';
import '../data/models/people.dart' show dateFrom;
import 'auth_store.dart';
import 'cart_store.dart';

enum ShippingStatus { processing, shipped, delivered }

extension ShippingStatusLabel on ShippingStatus {
  String get label => switch (this) {
    ShippingStatus.processing => 'Processing',
    ShippingStatus.shipped => 'Shipped',
    ShippingStatus.delivered => 'Delivered',
  };

  ShippingStatus? get next => switch (this) {
    ShippingStatus.processing => ShippingStatus.shipped,
    ShippingStatus.shipped => ShippingStatus.delivered,
    ShippingStatus.delivered => null,
  };
}

class OrderLine {
  const OrderLine({
    required this.id,
    required this.name,
    required this.kind,
    required this.price,
    required this.quantity,
  });

  final String id;
  final String name;

  /// course | seats | physical | digital
  final String kind;
  final double price;
  final int quantity;

  double get lineTotal => price * quantity;

  factory OrderLine.fromMap(Map<String, dynamic> m) => OrderLine(
    id: m['id'] as String? ?? '',
    name: m['name'] as String? ?? '',
    kind: m['kind'] as String? ?? 'physical',
    price: (m['price'] as num?)?.toDouble() ?? 0,
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
  );
}

class Order {
  const Order({
    required this.number,
    required this.userId,
    required this.email,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.status,
    this.createdAt,
    this.orgId,
  });

  final String number;
  final String userId;
  final String email;
  final List<OrderLine> items;
  final double subtotal;
  final double shipping;
  final double total;
  final String status;
  final DateTime? createdAt;
  final String? orgId;

  bool get hasPhysical => items.any((i) => i.kind == 'physical');

  factory Order.fromMap(String id, Map<String, dynamic> m) => Order(
    number: id,
    userId: m['userId'] as String? ?? '',
    email: m['email'] as String? ?? '',
    items: [
      for (final i in (m['items'] as List? ?? const []))
        OrderLine.fromMap(Map<String, dynamic>.from(i as Map)),
    ],
    subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
    shipping: (m['shipping'] as num?)?.toDouble() ?? 0,
    total: (m['total'] as num?)?.toDouble() ?? 0,
    status: m['status'] as String? ?? 'paid',
    createdAt: dateFrom(m['createdAt']),
    orgId: m['orgId'] as String?,
  );
}

class Shipment {
  const Shipment({
    required this.orderId,
    required this.userId,
    required this.status,
    required this.address,
    this.tracking,
    this.history = const [],
  });

  final String orderId;
  final String userId;
  final ShippingStatus status;
  final Map<String, dynamic> address;
  final String? tracking;
  final List<(ShippingStatus, DateTime)> history;

  factory Shipment.fromMap(String id, Map<String, dynamic> m) => Shipment(
    orderId: id,
    userId: m['userId'] as String? ?? '',
    status: ShippingStatus.values.firstWhere(
      (s) => s.name == m['status'],
      orElse: () => ShippingStatus.processing,
    ),
    address: Map<String, dynamic>.from(m['address'] as Map? ?? const {}),
    tracking: m['tracking'] as String?,
    history: [
      for (final h in (m['history'] as List? ?? const []))
        (
          ShippingStatus.values.firstWhere(
            (s) => s.name == (h as Map)['status'],
            orElse: () => ShippingStatus.processing,
          ),
          dateFrom((h as Map)['at']) ?? DateTime.now(),
        ),
    ],
  );
}

class DigitalDownload {
  const DigitalDownload({
    required this.id,
    required this.productId,
    required this.name,
    required this.url,
    required this.downloadCount,
    this.createdAt,
  });

  final String id;
  final String productId;
  final String name;
  final String url;
  final int downloadCount;
  final DateTime? createdAt;

  factory DigitalDownload.fromMap(String id, Map<String, dynamic> m) =>
      DigitalDownload(
        id: id,
        productId: m['productId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        url: m['url'] as String? ?? '',
        downloadCount: (m['downloadCount'] as num?)?.toInt() ?? 0,
        createdAt: dateFrom(m['createdAt']),
      );
}

/// Card details for the simulated payment gateway (test mode, no real charge).
class CardPayment {
  const CardPayment({required this.name, required this.number});

  final String name;
  final String number;

  String get last4 {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
  }
}

/// Orders, payments, shipping and digital downloads for the signed-in user,
/// plus the admin view of every order.
class CommerceStore extends ChangeNotifier {
  CommerceStore(this._backend, this._auth) {
    _auth.addListener(_onAuth);
    _onAuth();
  }

  final Backend _backend;
  final AuthStore _auth;
  final _subs = <StreamSubscription<Object?>>[];
  String? _uid;

  List<Order> _orders = [];
  List<DigitalDownload> _downloads = [];
  Map<String, Shipment> _shipments = {};
  Order? _lastOrder;

  List<Order> get orders => _orders;
  List<DigitalDownload> get downloads => _downloads;
  Shipment? shipmentFor(String orderId) => _shipments[orderId];
  Order? get lastOrder => _lastOrder;

  void _onAuth() {
    final user = _auth.currentUser;
    if (user?.id == _uid) return;
    _uid = user?.id;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _orders = [];
    _downloads = [];
    _shipments = {};
    notifyListeners();
    if (user == null) return;
    _subs
      ..add(
        _backend
            .col('orders')
            .where('userId', isEqualTo: user.id)
            .snapshots()
            .listen((s) {
              _orders = [for (final d in s.docs) Order.fromMap(d.id, d.data())]
                ..sort(
                  (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                    a.createdAt ?? DateTime.now(),
                  ),
                );
              notifyListeners();
            }, onError: (_) {}),
      )
      ..add(
        _backend
            .col('downloads')
            .where('userId', isEqualTo: user.id)
            .snapshots()
            .listen((s) {
              _downloads = [
                for (final d in s.docs) DigitalDownload.fromMap(d.id, d.data()),
              ];
              notifyListeners();
            }, onError: (_) {}),
      )
      ..add(
        _backend
            .col('shipping')
            .where('userId', isEqualTo: user.id)
            .snapshots()
            .listen((s) {
              _shipments = {
                for (final d in s.docs) d.id: Shipment.fromMap(d.id, d.data()),
              };
              notifyListeners();
            }, onError: (_) {}),
      );
  }

  /// Simulated gateway: declines the standard test "decline" card, approves
  /// everything else that passed form validation.
  static bool _approve(CardPayment card) =>
      !card.number.replaceAll(' ', '').startsWith('4000000000000002');

  /// Turns the cart into a paid order and fulfils it: payment record,
  /// shipping for physical goods, downloads for digital goods, enrolments
  /// for courses and seats for employers. Returns (order, null) or
  /// (null, error).
  Future<(Order?, String?)> checkout({
    required CartStore cart,
    required String email,
    required CardPayment card,
    Map<String, String>? address,
    Random? random,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return (null, 'Please sign in to complete your order.');
    if (cart.isEmpty) return (null, 'Your cart is empty.');
    if (!_approve(card)) {
      return (null, 'Your card was declined. Please try another card.');
    }

    final number = 'MTA-${10000 + (random ?? Random()).nextInt(90000)}';
    final lines = [for (final i in cart.items) i];
    final orgId = _auth.currentOrganisation?.id;
    final orderData = {
      'userId': user.id,
      'email': email,
      'orgId': ?orgId,
      'status': 'paid',
      'items': [
        for (final i in lines)
          {
            'id': i.itemId,
            'name': i.name,
            'kind': i.kind == CartKind.product
                ? i.product!.type.name
                : i.kind.name,
            'price': i.price,
            'quantity': i.quantity,
          },
      ],
      'subtotal': cart.subtotal,
      'shipping': cart.shipping,
      'total': cart.total,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      final db = _backend.db;
      final batch = db.batch();
      batch.set(_backend.col('orders').doc(number), orderData);
      batch.set(_backend.col('payments').doc('pay-$number'), {
        'userId': user.id,
        'orderId': number,
        'amount': cart.total,
        'method': 'card',
        'last4': card.last4,
        'status': 'paid',
        'gateway': 'test-mode',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (cart.hasPhysical) {
        batch.set(_backend.col('shipping').doc(number), {
          'userId': user.id,
          'orderId': number,
          'status': ShippingStatus.processing.name,
          'address': address ?? const {},
          'tracking': 'MY${number.substring(4)}${(random ?? Random()).nextInt(9000) + 1000}',
          'history': [
            {'status': 'processing', 'at': Timestamp.now()},
          ],
        });
      }
      for (final i in lines) {
        final p = i.product;
        // Already owned digital products keep their existing download.
        if (p != null &&
            p.isDigital &&
            !_downloads.any((d) => d.productId == p.id)) {
          batch.set(_backend.col('downloads').doc('${user.id}_${p.id}'), {
            'userId': user.id,
            'productId': p.id,
            'name': p.name,
            'orderId': number,
            'url': p.fileUrl,
            'downloadCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();

      // Enrolments read the order back in their security rule, so they are
      // written after the order exists.
      for (final i in lines) {
        final p = i.product;
        if (p != null && !p.isDigital) {
          await _decrementStock(p.id, i.quantity);
        }
        if (i.kind == CartKind.course) {
          await _backend.col('enrolments').doc('${user.id}_${i.itemId}').set({
            'userId': user.id,
            'userEmail': user.email.toLowerCase(),
            'courseId': i.itemId,
            'orderId': number,
            'completedModuleIds': <String>[],
            'quizScores': <String, double>{},
            'progress': 0.0,
            'status': 'active',
            'enrolledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        if (i.kind == CartKind.seats && orgId != null) {
          await _backend.col('organizations').doc(orgId).update({
            FieldPath(['seats', i.itemId]): FieldValue.increment(i.quantity),
          });
        }
      }

      final order = Order.fromMap(number, {
        ...orderData,
        'createdAt': DateTime.now(),
      });
      _lastOrder = order;
      cart.clear();
      notifyListeners();
      return (order, null);
    } catch (e) {
      return (null, friendlyError(e));
    }
  }

  Future<void> _decrementStock(String productId, int quantity) async {
    final ref = _backend.col('products').doc(productId);
    await _backend.db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final stock = (snap.data()?['stock'] as num?)?.toInt() ?? 0;
      if (stock <= 0) return;
      tx.update(ref, {'stock': max(0, stock - quantity)});
    });
  }

  /// Counts a download and returns the file location.
  Future<String> recordDownload(DigitalDownload d) async {
    try {
      await _backend.col('downloads').doc(d.id).update({
        'downloadCount': FieldValue.increment(1),
        'lastDownloadedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // The file still opens if the counter cannot be updated.
    }
    return d.url;
  }

  // ---------- Admin ----------

  Stream<List<Order>> allOrders() => _backend
      .col('orders')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => [for (final d in s.docs) Order.fromMap(d.id, d.data())]);

  Stream<List<Shipment>> allShipments() => _backend
      .col('shipping')
      .snapshots()
      .map((s) => [for (final d in s.docs) Shipment.fromMap(d.id, d.data())]);

  /// Moves a shipment to its next status and tells the buyer.
  Future<String?> advanceShipment(Shipment s) async {
    final next = s.status.next;
    if (next == null) return null;
    try {
      await _backend.col('shipping').doc(s.orderId).update({
        'status': next.name,
        'history': FieldValue.arrayUnion([
          {'status': next.name, 'at': Timestamp.now()},
        ]),
      });
      await _backend.col('notifications').add({
        'userId': s.userId,
        'title': 'Order ${s.orderId} ${next.label.toLowerCase()}',
        'body': next == ShippingStatus.shipped
            ? 'Tracking ${s.tracking ?? ''}'
            : 'Your order has arrived. Enjoy!',
        'link': '/portal/me/orders',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
