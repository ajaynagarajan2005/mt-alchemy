import 'package:flutter/foundation.dart';

import '../data/mock/demo_accounts.dart';
import '../data/models/people.dart';

class Assignment {
  Assignment({
    required this.employeeId,
    required this.courseId,
    required this.assignedAt,
    this.progress = 0,
  });

  final String employeeId;
  final String courseId;
  final DateTime assignedAt;

  /// 0 to 1. Mock value; in a real system this comes from the LMS.
  double progress;
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

/// Employer data per organisation: employees and course assignments.
class OrgStore extends ChangeNotifier {
  OrgStore() {
    _employees[demoOrganisation.id] = [...demoEmployees];
    _assignments[demoOrganisation.id] = [
      Assignment(
        employeeId: 'e-1',
        courseId: 'first-time-manager',
        assignedAt: DateTime(2026, 9, 15),
        progress: 0.75,
      ),
      Assignment(
        employeeId: 'e-2',
        courseId: 'first-time-manager',
        assignedAt: DateTime(2026, 9, 15),
        progress: 0.25,
      ),
      Assignment(
        employeeId: 'e-3',
        courseId: 'sustainable-performance',
        assignedAt: DateTime(2026, 9, 22),
        progress: 1,
      ),
      Assignment(
        employeeId: 'e-4',
        courseId: 'ei-foundations',
        assignedAt: DateTime(2026, 10, 1),
      ),
    ];
  }

  final Map<String, List<Employee>> _employees = {};
  final Map<String, List<Assignment>> _assignments = {};

  List<Employee> employees(String orgId) =>
      List.unmodifiable(_employees[orgId] ?? const []);
  List<Assignment> assignments(String orgId) =>
      List.unmodifiable(_assignments[orgId] ?? const []);

  bool emailInUse(String orgId, String email) =>
      employees(orgId)
          .any((e) => e.email.toLowerCase() == email.trim().toLowerCase());

  void addEmployee(
    String orgId, {
    required String name,
    required String email,
    required String team,
  }) {
    _employees
        .putIfAbsent(orgId, () => [])
        .add(
          Employee(
            id: 'e-${DateTime.now().microsecondsSinceEpoch}',
            name: name.trim(),
            email: email.trim(),
            team: team.trim(),
          ),
        );
    notifyListeners();
  }

  /// Assigns [courseId] to each employee; skips anyone already assigned. Returns how many were added.
  int assign(String orgId, String courseId, Iterable<String> employeeIds) {
    final list = _assignments.putIfAbsent(orgId, () => []);
    var added = 0;
    for (final id in employeeIds) {
      if (list.any((a) => a.employeeId == id && a.courseId == courseId)) {
        continue;
      }
      list.add(
        Assignment(
          employeeId: id,
          courseId: courseId,
          assignedAt: DateTime.now(),
        ),
      );
      added++;
    }
    notifyListeners();
    return added;
  }

  /// Removes an employee and any course assignments they held.
  void removeEmployee(String orgId, String employeeId) {
    _employees[orgId]?.removeWhere((e) => e.id == employeeId);
    _assignments[orgId]?.removeWhere((a) => a.employeeId == employeeId);
    notifyListeners();
  }

  /// Removes one assignment. Returns false if it did not exist.
  bool unassign(String orgId, String courseId, String employeeId) {
    final list = _assignments[orgId];
    if (list == null) return false;
    final before = list.length;
    list.removeWhere(
      (a) => a.employeeId == employeeId && a.courseId == courseId,
    );
    final removed = list.length != before;
    if (removed) notifyListeners();
    return removed;
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
    final list = assignments(orgId)
        .where((a) => courseId == null || a.courseId == courseId)
        .toList();
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (sum, a) => sum + a.progress) / list.length;
  }

  int completedCount(String orgId) =>
      assignments(orgId)
          .where((a) => a.status == ProgressStatus.complete)
          .length;

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

  /// Number of employees an organisation has registered.
  int employeeCount(String orgId) => employees(orgId).length;
}
