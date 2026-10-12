import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/backend.dart';
import '../data/models/course.dart';
import '../data/models/people.dart' show dateFrom;
import 'auth_store.dart';

class Enrolment {
  Enrolment({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.enrolledAt,
    Set<String>? completedModuleIds,
    Map<String, double>? quizScores,
    this.orderId,
    this.assignmentId,
    this.orgId,
    this.userEmail,
    this.updatedAt,
    this.source,
    this.amountPaid,
    this.userName,
  }) : completedModuleIds = completedModuleIds ?? {},
       quizScores = quizScores ?? {};

  final String id;
  final String userId;
  final String courseId;
  final DateTime enrolledAt;
  final Set<String> completedModuleIds;

  /// Best score per quiz module, 0 to 1.
  final Map<String, double> quizScores;
  final String? orderId;
  final String? assignmentId;
  final String? orgId;
  final String? userEmail;
  final DateTime? updatedAt;

  /// 'purchase', 'assignment' (employer seat) or 'granted' (free access
  /// given by staff). Older records have none, so it is inferred.
  final String? source;

  /// What the learner paid for this course, when it was a purchase.
  final double? amountPaid;
  final String? userName;

  String get accessType =>
      source ??
      (orderId != null
          ? 'purchase'
          : assignmentId != null
          ? 'assignment'
          : 'granted');

  double progressIn(Course course) => course.modules.isEmpty
      ? 0
      : course.modules.where((m) => completedModuleIds.contains(m.id)).length /
            course.modules.length;

  bool isCompleteIn(Course course) => progressIn(course) >= 1;

  factory Enrolment.fromMap(String id, Map<String, dynamic> m) => Enrolment(
    id: id,
    userId: m['userId'] as String? ?? '',
    courseId: m['courseId'] as String? ?? '',
    enrolledAt: dateFrom(m['enrolledAt']) ?? DateTime.now(),
    completedModuleIds: {
      ...List<String>.from(m['completedModuleIds'] as List? ?? const []),
    },
    quizScores: {
      for (final e in (m['quizScores'] as Map? ?? const {}).entries)
        e.key as String: (e.value as num).toDouble(),
    },
    orderId: m['orderId'] as String?,
    assignmentId: m['assignmentId'] as String?,
    orgId: m['orgId'] as String?,
    userEmail: m['userEmail'] as String?,
    updatedAt: dateFrom(m['updatedAt']),
    source: m['source'] as String?,
    amountPaid: (m['amountPaid'] as num?)?.toDouble(),
    userName: m['userName'] as String?,
  );
}

/// A course an employer assigned to the signed-in learner.
class AssignedCourse {
  const AssignedCourse({
    required this.id,
    required this.courseId,
    required this.orgId,
    required this.assignedAt,
  });

  final String id;
  final String courseId;
  final String orgId;
  final DateTime assignedAt;
}

class Certificate {
  const Certificate({
    required this.code,
    required this.userId,
    required this.userName,
    required this.courseId,
    required this.courseTitle,
    required this.issuedAt,
  });

  final String code;
  final String userId;
  final String userName;
  final String courseId;
  final String courseTitle;
  final DateTime issuedAt;

  factory Certificate.fromMap(String code, Map<String, dynamic> m) =>
      Certificate(
        code: code,
        userId: m['userId'] as String? ?? '',
        userName: m['userName'] as String? ?? '',
        courseId: m['courseId'] as String? ?? '',
        courseTitle: m['courseTitle'] as String? ?? '',
        issuedAt: dateFrom(m['issuedAt']) ?? DateTime.now(),
      );
}

/// The signed-in learner's enrolments, employer assignments and certificates.
class LearningStore extends ChangeNotifier {
  LearningStore(this._backend, this._auth) {
    _auth.addListener(_onAuth);
    _onAuth();
  }

  final Backend _backend;
  final AuthStore _auth;
  final _subs = <StreamSubscription<Object?>>[];
  String? _uid;

  Map<String, Enrolment> _enrolments = {};
  List<AssignedCourse> _assigned = [];
  List<Certificate> _certificates = [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<Enrolment> get enrolments =>
      _enrolments.values.toList()
        ..sort((a, b) => b.enrolledAt.compareTo(a.enrolledAt));
  List<AssignedCourse> get assigned => _assigned;
  List<Certificate> get certificates => _certificates;

  Enrolment? enrolment(String courseId) => _enrolments[courseId];
  bool isEnrolled(String courseId) => _enrolments.containsKey(courseId);
  Certificate? certificateFor(String courseId) {
    for (final c in _certificates) {
      if (c.courseId == courseId) return c;
    }
    return null;
  }

  AssignedCourse? assignmentFor(String courseId) {
    for (final a in _assigned) {
      if (a.courseId == courseId) return a;
    }
    return null;
  }

  void _onAuth() {
    final user = _auth.currentUser;
    if (user?.id == _uid) return;
    _uid = user?.id;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _enrolments = {};
    _assigned = [];
    _certificates = [];
    _loaded = false;
    notifyListeners();
    if (user == null) return;

    _subs
      ..add(
        _backend
            .col('enrolments')
            .where('userId', isEqualTo: user.id)
            .snapshots()
            .listen((s) {
              _enrolments = {
                for (final d in s.docs)
                  d.data()['courseId'] as String: Enrolment.fromMap(
                    d.id,
                    d.data(),
                  ),
              };
              _loaded = true;
              notifyListeners();
            }, onError: (_) {}),
      )
      ..add(
        _backend
            .col('certificates')
            .where('userId', isEqualTo: user.id)
            .snapshots()
            .listen((s) {
              _certificates = [
                for (final d in s.docs) Certificate.fromMap(d.id, d.data()),
              ];
              notifyListeners();
            }, onError: (_) {}),
      )
      ..add(
        _backend
            .col('assignments')
            .where('employeeEmail', isEqualTo: user.email.toLowerCase())
            .snapshots()
            .listen((s) {
              _assigned = [
                for (final d in s.docs)
                  AssignedCourse(
                    id: d.id,
                    courseId: d.data()['courseId'] as String,
                    orgId: d.data()['orgId'] as String,
                    assignedAt:
                        dateFrom(d.data()['assignedAt']) ?? DateTime.now(),
                  ),
              ];
              notifyListeners();
            }, onError: (_) {}),
      );
  }

  DocumentReference<Map<String, dynamic>> _ref(String courseId) =>
      _backend.col('enrolments').doc('${_uid}_$courseId');

  Map<String, dynamic> _base(String courseId) => {
    'userId': _uid,
    'userName': _auth.currentUser?.name,
    'userEmail': _auth.currentUser?.email.toLowerCase(),
    'courseId': courseId,
    'completedModuleIds': <String>[],
    'quizScores': <String, double>{},
    'progress': 0.0,
    'status': 'active',
    'enrolledAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// Enrols after a paid order (Journey A).
  Future<String?> enrolFromOrder(
    String courseId,
    String orderId, {
    double? amountPaid,
  }) => _guard(
    () => _ref(courseId).set({
      ..._base(courseId),
      'orderId': orderId,
      'source': 'purchase',
      'amountPaid': ?amountPaid,
    }),
  );

  /// Starts a course an employer assigned (Journey D).
  Future<String?> startAssigned(AssignedCourse a) => _guard(
    () => _ref(a.courseId).set({
      ..._base(a.courseId),
      'source': 'assignment',
      'assignmentId': a.id,
      'orgId': a.orgId,
    }),
  );

  Future<String?> setModuleComplete(
    Course course,
    String moduleId,
    bool complete,
  ) async {
    final e = _enrolments[course.id];
    if (e == null || _uid == null) {
      return 'You are not enrolled on this course.';
    }
    complete
        ? e.completedModuleIds.add(moduleId)
        : e.completedModuleIds.remove(moduleId);
    notifyListeners(); // Optimistic; Firestore confirms in the snapshot.
    final progress = e.progressIn(course);
    return _guard(() async {
      await _ref(course.id).update({
        'completedModuleIds': complete
            ? FieldValue.arrayUnion([moduleId])
            : FieldValue.arrayRemove([moduleId]),
        'progress': progress,
        'status': progress >= 1 ? 'complete' : 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (progress >= 1) await _issueCertificate(course);
    });
  }

  /// Records a quiz attempt; a pass also completes the module.
  /// Returns the error message, or null.
  Future<String?> submitQuiz(
    Course course,
    String moduleId,
    double score,
  ) async {
    final e = _enrolments[course.id];
    if (e == null) return 'You are not enrolled on this course.';
    final best = max(score, e.quizScores[moduleId] ?? 0);
    e.quizScores[moduleId] = best;
    final err = await _guard(
      () => _ref(course.id).update({
        FieldPath(['quizScores', moduleId]): best,
      }),
    );
    if (err != null) return err;
    if (score >= CourseModule.passMark) {
      return setModuleComplete(course, moduleId, true);
    }
    return null;
  }

  Future<void> _issueCertificate(Course course) async {
    if (certificateFor(course.id) != null) return;
    final user = _auth.currentUser!;
    final code =
        'MTA-${course.id.substring(0, 3).toUpperCase()}-${user.id.substring(0, 6).toUpperCase()}';
    await _backend.col('certificates').doc(code).set({
      'userId': user.id,
      'userName': user.name,
      'courseId': course.id,
      'courseTitle': course.title,
      'issuedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Public lookup used by the certificate verification page.
  Future<Certificate?> verify(String code) async {
    final snap = await _backend.col('certificates').doc(code).get();
    final data = snap.data();
    return data == null ? null : Certificate.fromMap(snap.id, data);
  }

  Future<String?> _guard(Future<void> Function() op) async {
    try {
      await op();
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
