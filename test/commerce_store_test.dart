import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/data/mock/products.dart';
import 'package:mt_alchemy/state/cart_store.dart';
import 'package:mt_alchemy/state/commerce_store.dart';

import 'helpers/fake_backend.dart';

void main() {
  const card = CardPayment(name: 'Test', number: '4242 4242 4242 4242');

  group('CommerceStore checkout (fake Firestore)', () {
    test('writes order, payment, shipping, download and enrolment', () async {
      final s = await FakeSession.signedIn();
      for (final p in products) {
        await s.db.collection('products').doc(p.id).set(p.toMap());
      }
      final commerce = CommerceStore(s.backend, s.auth);
      final physical = productById('feedback-conversation-cards')!;
      final digital = productById('ei-self-coaching-toolkit')!;
      final course = courses.first;
      final cart = CartStore()
        ..add(physical)
        ..add(digital)
        ..addCourse(course);

      final (order, error) = await commerce.checkout(
        cart: cart,
        email: s.user.email,
        card: card,
        address: {
          'name': 'Test',
          'line1': '1 Road',
          'city': 'KL',
          'postcode': '50450',
        },
        random: Random(1),
      );
      expect(error, isNull);
      expect(cart.isEmpty, isTrue);
      final id = order!.number;
      expect(id, matches(RegExp(r'^MTA-\d{5}$')));

      final db = s.db;
      expect(
        (await db.collection('orders').doc(id).get()).data()!['status'],
        'paid',
      );
      final pay = await db.collection('payments').doc('pay-$id').get();
      expect(pay.data()!['last4'], '4242');
      final ship = await db.collection('shipping').doc(id).get();
      expect(ship.data()!['status'], 'processing');
      final dl = await db
          .collection('downloads')
          .doc('${s.user.id}_${digital.id}')
          .get();
      expect(dl.data()!['url'], digital.fileUrl);
      final enrol = await db
          .collection('enrolments')
          .doc('${s.user.id}_${course.id}')
          .get();
      expect(enrol.data()!['orderId'], id);
      final stock = await db.collection('products').doc(physical.id).get();
      expect(stock.data()!['stock'], physical.stock - 1);
    });

    test('a declined card places no order', () async {
      final s = await FakeSession.signedIn();
      final commerce = CommerceStore(s.backend, s.auth);
      final cart = CartStore()..add(products.first);
      final (order, error) = await commerce.checkout(
        cart: cart,
        email: s.user.email,
        card: const CardPayment(name: 'x', number: '4000 0000 0000 0002'),
      );
      expect(order, isNull);
      expect(error, contains('declined'));
      expect(cart.isEmpty, isFalse);
      expect((await s.db.collection('orders').get()).docs, isEmpty);
    });

    test('a completed PayPal payment places and records the order', () async {
      final s = await FakeSession.signedIn();
      final commerce = CommerceStore(s.backend, s.auth);
      final course = courses.first;
      final cart = CartStore()..addCourse(course);
      final (order, error) = await commerce.checkout(
        cart: cart,
        email: s.user.email,
        paypal: const PayPalPayment(
          orderId: '5O190127TN364715T',
          captureId: '3C679366HH908993F',
          status: 'COMPLETED',
          payerEmail: 'buyer@example.com',
        ),
      );
      expect(error, isNull);
      final id = order!.number;
      final pay = (await s.db.collection('payments').doc('pay-$id').get())
          .data()!;
      expect(pay['method'], 'paypal');
      expect(pay['gateway'], 'paypal-sandbox');
      expect(pay['paypalOrderId'], '5O190127TN364715T');
      expect(pay['paypalCaptureId'], '3C679366HH908993F');
      expect(pay['payerEmail'], 'buyer@example.com');
      expect(pay.containsKey('last4'), isFalse);
      final enrol = await s.db
          .collection('enrolments')
          .doc('${s.user.id}_${course.id}')
          .get();
      expect(enrol.data()!['orderId'], id);
    });

    test('buying a download you already own keeps the existing one', () async {
      final s = await FakeSession.signedIn();
      final digital = productById('ei-self-coaching-toolkit')!;
      final doc = s.db
          .collection('downloads')
          .doc('${s.user.id}_${digital.id}');
      await doc.set({
        'userId': s.user.id,
        'productId': digital.id,
        'orderId': 'MTA-OLD',
        'downloadCount': 3,
      });
      // Checkout straight away, before the store's live list has loaded.
      final commerce = CommerceStore(s.backend, s.auth);
      final cart = CartStore()..add(digital);
      final (order, error) = await commerce.checkout(
        cart: cart,
        email: s.user.email,
        card: card,
      );
      expect(error, isNull);
      expect(order, isNotNull);
      final kept = (await doc.get()).data()!;
      expect(kept['orderId'], 'MTA-OLD');
      expect(kept['downloadCount'], 3);
    });

    test('a PayPal payment that is not completed places no order', () async {
      final s = await FakeSession.signedIn();
      final commerce = CommerceStore(s.backend, s.auth);
      final cart = CartStore()..add(products.first);
      final (order, error) = await commerce.checkout(
        cart: cart,
        email: s.user.email,
        paypal: const PayPalPayment(
          orderId: 'X',
          captureId: 'Y',
          status: 'DECLINED',
        ),
      );
      expect(order, isNull);
      expect(error, contains('not been charged'));
      expect(cart.isEmpty, isFalse);
      expect((await s.db.collection('orders').get()).docs, isEmpty);
    });

    test('shipment advances processing to shipped to delivered', () async {
      final s = await FakeSession.signedIn();
      final commerce = CommerceStore(s.backend, s.auth);
      await s.db.collection('shipping').doc('MTA-1').set({
        'userId': s.user.id,
        'status': 'processing',
        'address': <String, dynamic>{},
        'history': <dynamic>[],
      });
      await settle();
      var ship = commerce.shipmentFor('MTA-1')!;
      await commerce.advanceShipment(ship);
      await settle();
      ship = commerce.shipmentFor('MTA-1')!;
      expect(ship.status, ShippingStatus.shipped);
      await commerce.advanceShipment(ship);
      await settle();
      expect(commerce.shipmentFor('MTA-1')!.status, ShippingStatus.delivered);
      final notes = await s.db.collection('notifications').get();
      expect(notes.docs, hasLength(2));
    });
  });
}
