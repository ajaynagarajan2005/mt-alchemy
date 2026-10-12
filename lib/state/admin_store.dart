import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/backend.dart';
import '../data/models/people.dart';
import 'auth_store.dart';

enum EnquiryStatus { newEnquiry, inDiscussion, proposal, won, closed }

extension EnquiryStatusX on EnquiryStatus {
  String get value => switch (this) {
    EnquiryStatus.newEnquiry => 'new',
    EnquiryStatus.inDiscussion => 'in-discussion',
    EnquiryStatus.proposal => 'proposal',
    EnquiryStatus.won => 'won',
    EnquiryStatus.closed => 'closed',
  };

  String get label => switch (this) {
    EnquiryStatus.newEnquiry => 'New',
    EnquiryStatus.inDiscussion => 'In discussion',
    EnquiryStatus.proposal => 'Proposal sent',
    EnquiryStatus.won => 'Programme agreed',
    EnquiryStatus.closed => 'Closed',
  };

  static EnquiryStatus from(Object? v) => EnquiryStatus.values.firstWhere(
    (s) => s.value == v,
    orElse: () => EnquiryStatus.newEnquiry,
  );
}

/// Journey E: a corporate enquiry that becomes a customised programme.
class Enquiry {
  const Enquiry({
    required this.id,
    required this.organisation,
    required this.name,
    required this.email,
    required this.size,
    required this.interest,
    required this.message,
    required this.status,
    this.proposal = '',
    this.createdAt,
  });

  final String id;
  final String organisation;
  final String name;
  final String email;
  final String size;
  final String interest;
  final String message;
  final EnquiryStatus status;
  final String proposal;
  final DateTime? createdAt;

  factory Enquiry.fromMap(String id, Map<String, dynamic> m) => Enquiry(
    id: id,
    organisation: m['organisation'] as String? ?? '',
    name: m['name'] as String? ?? '',
    email: m['email'] as String? ?? '',
    size: m['size'] as String? ?? '',
    interest: m['interest'] as String? ?? '',
    message: m['message'] as String? ?? '',
    status: EnquiryStatusX.from(m['status']),
    proposal: m['proposal'] as String? ?? '',
    createdAt: dateFrom(m['createdAt']),
  );
}

/// Super admin tools (user management, enquiries) plus the two public
/// write paths guests can use: corporate enquiries and contact messages.
class AdminStore extends ChangeNotifier {
  AdminStore(this._backend, this._auth);

  final Backend _backend;
  final AuthStore _auth;

  bool get isSuper => _auth.currentUser?.role == UserRole.superAdmin;

  // ---------- Public ----------

  Future<String?> submitEnquiry({
    required String organisation,
    required String name,
    required String email,
    required String size,
    required String interest,
    required String message,
  }) => _guard(
    () => _backend.col('enquiries').add({
      'organisation': organisation.trim(),
      'name': name.trim(),
      'email': email.trim(),
      'size': size,
      'interest': interest,
      'message': message.trim(),
      'status': EnquiryStatus.newEnquiry.value,
      'proposal': '',
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  Future<String?> submitContact({
    required String name,
    required String email,
    required String topic,
    required String message,
  }) => _guard(
    () => _backend.col('contactMessages').add({
      'name': name.trim(),
      'email': email.trim(),
      'topic': topic,
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  // ---------- Users ----------

  Stream<List<AppUser>> users() => _backend
      .col('users')
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) AppUser.fromMap(d.id, d.data())]
              ..sort((a, b) => a.name.compareTo(b.name)),
      );

  Future<String?> setRole(String uid, UserRole role) =>
      _guard(() => _backend.col('users').doc(uid).update({'role': role.name}));

  Future<String?> setDisabled(String uid, bool disabled) => _guard(
    () => _backend.col('users').doc(uid).update({'disabled': disabled}),
  );

  /// Removes the profile; the person can no longer use any portal.
  Future<String?> deleteUser(String uid) =>
      _guard(() => _backend.col('users').doc(uid).delete());

  /// Creates a login for someone else without signing the admin out, using a
  /// second Firebase app instance for the new account.
  Future<String?> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    FirebaseApp? secondary;
    try {
      secondary = await Firebase.initializeApp(
        name: 'admin-create-${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final cred = await FirebaseAuth.instanceFor(
        app: secondary,
      ).createUserWithEmailAndPassword(email: email.trim(), password: password);
      final uid = cred.user!.uid;
      await _backend.col('users').doc(uid).set({
        ...AppUser(
          id: uid,
          name: name.trim(),
          email: email.trim(),
          role: role,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return friendlyError(e);
    } finally {
      await secondary?.delete();
    }
  }

  // ---------- Enquiries ----------

  Stream<List<Enquiry>> enquiries() => _backend
      .col('enquiries')
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) Enquiry.fromMap(d.id, d.data())]
          ..sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          ),
      );

  Future<String?> updateEnquiry(
    String id, {
    EnquiryStatus? status,
    String? proposal,
  }) => _guard(
    () => _backend.col('enquiries').doc(id).update({
      'status': ?status?.value,
      'proposal': ?proposal,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  Stream<List<Map<String, dynamic>>> contactMessages() => _backend
      .col('contactMessages')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs) {'id': d.id, ...d.data()},
        ],
      );

  /// Learners per course (individual and employer-assigned), for trainers.
  Stream<Map<String, int>> learnersPerCourse() =>
      _backend.col('enrolments').snapshots().map((s) {
        final counts = <String, int>{};
        for (final d in s.docs) {
          final id = d.data()['courseId'] as String? ?? '';
          counts[id] = (counts[id] ?? 0) + 1;
        }
        return counts;
      });

  /// Live headline counts: updates the moment any of these collections
  /// changes (real-time Firestore listeners, no refresh needed).
  Stream<Map<String, int>> liveCounts() {
    const names = [
      'users',
      'orders',
      'enrolments',
      'certificates',
      'enquiries',
    ];
    final counts = <String, int>{};
    late final StreamController<Map<String, int>> controller;
    final subs = <StreamSubscription<Object?>>[];
    controller = StreamController<Map<String, int>>(
      onListen: () {
        for (final n in names) {
          subs.add(
            _backend.col(n).snapshots().listen((snap) {
              counts[n] = snap.size;
              controller.add(Map.of(counts));
            }, onError: (_) {}),
          );
        }
      },
      onCancel: () {
        for (final s in subs) {
          s.cancel();
        }
      },
    );
    return controller.stream;
  }

  /// Headline counts for the admin dashboard.
  Future<Map<String, int>> counts() async {
    Future<int> count(String col) async {
      try {
        final agg = await _backend.col(col).count().get();
        return agg.count ?? 0;
      } catch (_) {
        return 0;
      }
    }

    final names = [
      'users',
      'orders',
      'enrolments',
      'enquiries',
      'certificates',
    ];
    final values = await Future.wait(names.map(count));
    return {for (var i = 0; i < names.length; i++) names[i]: values[i]};
  }

  Future<String?> _guard(Future<void> Function() op) async {
    try {
      await op();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }
}
