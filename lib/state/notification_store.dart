import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/backend.dart';
import '../data/models/people.dart' show dateFrom;
import 'auth_store.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    this.link,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool read;
  final String? link;
  final DateTime? createdAt;
}

/// In-app notifications for the signed-in user (bell in the portal bar).
class NotificationStore extends ChangeNotifier {
  NotificationStore(this._backend, this._auth) {
    _auth.addListener(_onAuth);
    _onAuth();
  }

  final Backend _backend;
  final AuthStore _auth;
  StreamSubscription<Object?>? _sub;
  String? _uid;
  List<AppNotification> _items = [];

  List<AppNotification> get items => _items;
  int get unread => _items.where((n) => !n.read).length;

  void _onAuth() {
    final uid = _auth.currentUser?.id;
    if (uid == _uid) return;
    _uid = uid;
    _sub?.cancel();
    _items = [];
    notifyListeners();
    if (uid == null) return;
    _sub = _backend
        .col('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((s) {
          _items =
              [
                for (final d in s.docs)
                  AppNotification(
                    id: d.id,
                    title: d.data()['title'] as String? ?? '',
                    body: d.data()['body'] as String? ?? '',
                    read: d.data()['read'] as bool? ?? false,
                    link: d.data()['link'] as String?,
                    createdAt: dateFrom(d.data()['createdAt']),
                  ),
              ]..sort(
                (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                  a.createdAt ?? DateTime.now(),
                ),
              );
          notifyListeners();
        }, onError: (_) {});
  }

  Future<void> markRead(String id) => _backend
      .col('notifications')
      .doc(id)
      .update({'read': true})
      .catchError((_) {});

  Future<void> markAllRead() async {
    for (final n in _items.where((n) => !n.read)) {
      await markRead(n.id);
    }
  }

  /// Sends a notification to another user (staff and employers only).
  Future<void> send({
    required String userId,
    required String title,
    required String body,
    String? link,
  }) => _backend
      .col('notifications')
      .add({
        'userId': userId,
        'title': title,
        'body': body,
        'link': link,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      })
      .then((_) {})
      .catchError((_) {});

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    _sub?.cancel();
    super.dispose();
  }
}
