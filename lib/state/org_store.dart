import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/backend.dart';
import '../data/models/people.dart';
import 'auth_store.dart';

class Assignment {
  Assignment({
    required this.employeeId,
    required this.courseId,
    required this.assignedAt,
    this.id = '',
    this.employeeEmail = '',
    this.progress = 0,
    this.lastActive,
  });

  final String id;
  final String employeeId;
  final String employeeEmail;
  final String courseId;
  final DateTime assignedAt;

  /// 0 to 1, from the employee's enrolment in the LMS.
  double progress;
  DateTime? lastActive;
}

enum ProgressStatus { notStarted, inProgress, complete }

extension ProgressStatusLabel on ProgressStatus {
  String get label => switch (this) {
    ProgressStatus.notStarted => 'Not started',
    ProgressStatus.inProgress => 'In progress',
    ProgressStatus.complete => 'Complete',
  };
}

extension AssignmentStatus on Assignment {
  ProgressStatus get status => progress >= 1
      ? ProgressStatus.complete
      : progress > 0
      ? ProgressStatus.inProgress
      : ProgressStatus.notStarted;
}

/// Roll-up of one course across an organisation's assignments.
class CourseSummary {
  const CourseSummary({
    required this.courseId,
    required this.assigned,
    required this.completed,
    required this.averageProgress,
  });

  final String courseId;
  final int assigned;
  final int completed;
  final double averageProgress;
}

/// Employer data for the signed-in employer's organisation: employees,
/// course assignments and the learning progress behind them.
class OrgStore extends ChangeNotifier {
  OrgStore(this._backend, this._auth) {
    _auth.addListener(_onAuth);
    _onAuth();
  }

  final Backend _backend;
  final AuthStore _auth;
  final _subs = <StreamSubscription<Object?>>[];
  String? _orgId;

  List<Employee> _employees = [];
  List<Assignment> _assignments = [];

  /// Enrolment progress keyed by "email|courseId".
  Map<String, (double, DateTime?)> _progress = {};
  bool _loaded = false;
  bool get loaded => _loaded;

  void _onAuth() {
    final user = _auth.currentUser;
    final orgId = user?.role == UserRole.employer ? user?.organisationId : null;
    if (orgId == _orgId) return;
    _orgId = orgId;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _employees = [];
    _assignments = [];
    _progress = {};
    _loaded = false;
    notifyListeners();
    if (orgId == null) return;

    _subs
      ..add(
        _backend
            .col('employees')
            .where('orgId', isEqualTo: orgId)
            .snapshots()
            .listen((s) {
              _employees = [
                for (final d in s.docs) Employee.fromMap(d.id, d.data()),
              ]..sort((a, b) => a.name.compareTo(b.name));
              _loaded = true;
              notifyListeners();
            }, onError: (_) {}),
      )
      ..add(
        _backend
            .col('assignments')
            .where('orgId', isEqualTo: orgId)
            .snapshots()
            .listen((s) {
              _assignments = [
                for (final d in s.docs)
                  Assignment(
                    id: d.id,
                    employeeId: d.data()['employeeId'] as String? ?? '',
                    employeeEmail: d.data()['employeeEmail'] as String? ?? '',
                    courseId: d.data()['courseId'] as String? ?? '',
                    assignedAt:
                        dateFrom(d.data()['assignedAt']) ?? DateTime.now(),
                  ),
              ];
              _applyProgress();
            }, onError: (_) {}),
      )
      ..add(
        _backend
            .col('enrolments')
            .where('orgId', isEqualTo: orgId)
            .snapshots()
            .listen((s) {
              _progress = {
                for (final d in s.docs)
                  '${d.data()['userEmail']}|${d.data()['courseId']}': (
                    (d.data()['progress'] as num?)?.toDouble() ?? 0,
                    dateFrom(d.data()['updatedAt']),
                  ),
              };
              _applyProgress();
            }, onError: (_) {}),
      );
  }

  void _applyProgress() {
    for (final a in _assignments) {
      final p = _progress['${a.employeeEmail}|${a.courseId}'];
      a.progress = p?.$1 ?? 0;
      a.lastActive = p?.$2;
    }
    notifyListeners();
  }

  List<Employee> employees(String orgId) =>
      orgId == _orgId ? List.unmodifiable(_employees) : const [];
  List<Assignment> assignments(String orgId) =>
      orgId == _orgId ? List.unmodifiable(_assignments) : const [];

  bool emailInUse(String orgId, String email) => employees(
    orgId,
  ).any((e) => e.email.toLowerCase() == email.trim().toLowerCase());

  /// Adds an employee. They join the organisation automatically when they
  /// register with this email. Returns an error message or null.
  Future<String?> addEmployee(
    String orgId, {
    required String name,
    required String email,
    required String team,
  }) => _guard(
    () => _backend
        .col('employees')
        .add(
          Employee(
            id: '',
            name: name.trim(),
            email: email.trim(),
            team: team.trim(),
            orgId: orgId,
          ).toMap(),
        ),
  );

  /// Assigns [courseId] to each employee, using one purchased seat each.
  /// Skips anyone already assigned. Returns (added, error).
  Future<(int, String?)> assign(
    String orgId,
    String courseId,
    Iterable<String> employeeIds,
  ) async {
    final fresh = [
      for (final id in employeeIds)
        if (!_assignments.any(
          (a) => a.employeeId == id && a.courseId == courseId,
        ))
          id,
    ];
    if (fresh.isEmpty) return (0, null);
    final seats = _auth.currentOrganisation?.seatsFor(courseId) ?? 0;
    if (seats < fresh.length) {
      return (
        0,
        seats == 0
            ? 'You have no seats for this course yet. Buy seats first.'
            : 'You have $seats seat${seats == 1 ? '' : 's'} left for this course. '
                  'Select fewer people or buy more seats.',
      );
    }
    final course = courseId;
    final error = await _guard(() async {
      final batch = _backend.db.batch();
      for (final id in fresh) {
        final e = employeeById(orgId, id);
        if (e == null) continue;
        batch.set(_backend.col('assignments').doc('${orgId}_${id}_$course'), {
          'orgId': orgId,
          'employeeId': id,
          'employeeEmail': e.email.toLowerCase(),
          'courseId': course,
          'assignedAt': FieldValue.serverTimestamp(),
        });
      }
      batch.update(_backend.col('organizations').doc(orgId), {
        FieldPath(['seats', course]): FieldValue.increment(-fresh.length),
      });
      await batch.commit();
    });
    return error == null ? (fresh.length, null) : (0, error);
  }

  /// Removes an employee and any course assignments they held.
  Future<String?> removeEmployee(String orgId, String employeeId) =>
      _guard(() async {
        final batch = _backend.db.batch();
        batch.delete(_backend.col('employees').doc(employeeId));
        for (final a in _assignments.where((a) => a.employeeId == employeeId)) {
          batch.delete(_backend.col('assignments').doc(a.id));
        }
        await batch.commit();
      });

  /// Removes one assignment. Returns false if it did not exist.
  Future<bool> unassign(String orgId, String courseId, String employeeId) async {
    final match = _assignments.where(
      (a) => a.employeeId == employeeId && a.courseId == courseId,
    );
    if (match.isEmpty) return false;
    final error = await _guard(
      () => _backend.col('assignments').doc(match.first.id).delete(),
    );
    return error == null;
  }

  Employee? employeeById(String orgId, String employeeId) {
    for (final e in employees(orgId)) {
      if (e.id == employeeId) return e;
    }
    return null;
  }

  int courseCountFor(String orgId, String employeeId) =>
      assignments(orgId).where((a) => a.employeeId == employeeId).length;

  /// Mean progress across all assignments, 0 when there are none.
  double averageProgress(String orgId, {String? courseId}) {
    final list = assignments(
      orgId,
    ).where((a) => courseId == null || a.courseId == courseId).toList();
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (total, a) => total + a.progress) / list.length;
  }

  int completedCount(String orgId) => assignments(
    orgId,
  ).where((a) => a.status == ProgressStatus.complete).length;

  int countWith(String orgId, ProgressStatus status) =>
      assignments(orgId).where((a) => a.status == status).length;

  /// One summary per course that has at least one assignment.
  List<CourseSummary> courseSummaries(String orgId) {
    final ids = <String>[];
    for (final a in assignments(orgId)) {
      if (!ids.contains(a.courseId)) ids.add(a.courseId);
    }
    return [
      for (final id in ids)
        CourseSummary(
          courseId: id,
          assigned: assignments(orgId).where((a) => a.courseId == id).length,
          completed: assignments(orgId)
              .where(
                (a) => a.courseId == id && a.status == ProgressStatus.complete,
              )
              .length,
          averageProgress: averageProgress(orgId, courseId: id),
        ),
    ];
  }

  /// Learning activity per week for the last [weeks] weeks (oldest first),
  /// counted from when each assignment was last worked on.
  List<int> weeklyActivity(String orgId, {int weeks = 6, DateTime? now}) {
    final today = now ?? DateTime.now();
    final counts = List<int>.filled(weeks, 0);
    for (final a in assignments(orgId)) {
      final t = a.lastActive;
      if (t == null) continue;
      final weeksAgo = today.difference(t).inDays ~/ 7;
      if (weeksAgo >= 0 && weeksAgo < weeks) counts[weeks - 1 - weeksAgo]++;
    }
    return counts;
  }

  /// Number of employees an organisation has registered.
  int employeeCount(String orgId) => employees(orgId).length;

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
