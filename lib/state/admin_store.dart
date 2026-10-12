import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/backend.dart';
import '../data/models/course.dart';
import '../data/models/people.dart';
import 'learning_store.dart';
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

  /// Enrolment, payment and revenue totals per course (live).
  /// [priceOf] supplies a course's list price for purchases recorded before
  /// the amount was stored.
  Stream<Map<String, CourseStats>> courseStats(
    double Function(String courseId) priceOf,
  ) => _backend.col('enrolments').snapshots().map((snap) {
    final stats = <String, CourseStats>{};
    for (final d in snap.docs) {
      final e = Enrolment.fromMap(d.id, d.data());
      stats.update(
        e.courseId,
        (s) => s.add(e, priceOf),
        ifAbsent: () => const CourseStats().add(e, priceOf),
      );
    }
    return stats;
  });

  /// Everyone enrolled on [courseId], newest first (live).
  Stream<List<Enrolment>> enrolmentsFor(String courseId) => _backend
      .col('enrolments')
      .where('courseId', isEqualTo: courseId)
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) Enrolment.fromMap(d.id, d.data())]
              ..sort((a, b) => b.enrolledAt.compareTo(a.enrolledAt)),
      );

  /// Gives [learner] free access to [course]: no payment, no seat. Returns an
  /// error message or null.
  Future<String?> grantAccess(AppUser learner, Course course) async {
    final staff = _auth.currentUser;
    if (staff == null || !staff.role.isStaff) {
      return 'Only trainers and admins can add people to a course.';
    }
    return _guard(() async {
      await _backend.col('enrolments').doc('${learner.id}_${course.id}').set({
        'userId': learner.id,
        'userName': learner.name,
        'userEmail': learner.email.toLowerCase(),
        'courseId': course.id,
        'source': 'granted',
        'grantedBy': staff.id,
        'completedModuleIds': <String>[],
        'quizScores': <String, double>{},
        'progress': 0.0,
        'status': 'active',
        'enrolledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _backend.col('notifications').add({
        'userId': learner.id,
        'title': 'You now have access to ${course.title}',
        'body': 'Added by ${staff.name}. Open it from My learning.',
        'link': '/learn/${course.id}',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Removes someone from a course. Their progress is deleted; a paid
  /// order is not refunded automatically.
  Future<String?> removeAccess(Enrolment e) =>
      _guard(() => _backend.col('enrolments').doc(e.id).delete());

  /// Learner accounts, for the "add a person" picker.
  Future<List<AppUser>> findLearners(String query) async {
    final snap = await _backend.col('users').get();
    final q = query.trim().toLowerCase();
    return [for (final d in snap.docs) AppUser.fromMap(d.id, d.data())]
        .where((u) => u.role == UserRole.individual && !u.disabled)
        .where(
          (u) =>
              q.isEmpty ||
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q),
        )
        .take(8)
        .toList();
  }

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

/// Totals for one course in the admin list.
class CourseStats {
  const CourseStats({
    this.enrolled = 0,
    this.paid = 0,
    this.assigned = 0,
    this.granted = 0,
    this.revenue = 0,
  });

  final int enrolled;

  /// People who bought the course themselves.
  final int paid;

  /// Enrolled through an employer's seats.
  final int assigned;

  /// Given free access by staff.
  final int granted;

  /// Money received from individual purchases.
  final double revenue;

  CourseStats add(Enrolment e, double Function(String) priceOf) {
    final type = e.accessType;
    return CourseStats(
      enrolled: enrolled + 1,
      paid: paid + (type == 'purchase' ? 1 : 0),
      assigned: assigned + (type == 'assignment' ? 1 : 0),
      granted: granted + (type == 'granted' ? 1 : 0),
      revenue:
          revenue +
          (type == 'purchase' ? (e.amountPaid ?? priceOf(e.courseId)) : 0),
    );
  }
}
