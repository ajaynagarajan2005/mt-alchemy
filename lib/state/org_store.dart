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
}
