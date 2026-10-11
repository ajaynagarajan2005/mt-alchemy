import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/data/mock/demo_accounts.dart';
import 'package:mt_alchemy/state/org_store.dart';

void main() {
  final org = demoOrganisation.id;

  group('OrgStore', () {
    test('adds an employee and detects duplicate emails', () {
      final store = OrgStore();
      final before = store.employees(org).length;
      store.addEmployee(
        org,
        name: ' Ada Lovelace ',
        email: 'ada@northlight.example.com',
        team: 'Finance',
      );
      expect(store.employees(org).length, before + 1);
      expect(store.employees(org).last.name, 'Ada Lovelace');
      expect(store.emailInUse(org, ' ADA@northlight.example.com '), isTrue);
      expect(store.emailInUse(org, 'nobody@example.com'), isFalse);
    });

    test('removing an employee also removes their assignments', () {
      final store = OrgStore();
      expect(store.courseCountFor(org, 'e-1'), 1);
      store.removeEmployee(org, 'e-1');
      expect(store.employeeById(org, 'e-1'), isNull);
      expect(store.courseCountFor(org, 'e-1'), 0);
      expect(store.assignments(org).any((a) => a.employeeId == 'e-1'), isFalse);
    });

    test('assign skips duplicates and reports how many were added', () {
      final store = OrgStore();
      // e-1 already has first-time-manager; e-4 does not.
      final added = store.assign(org, 'first-time-manager', ['e-1', 'e-4']);
      expect(added, 1);
      expect(store.assign(org, 'first-time-manager', ['e-1', 'e-4']), 0);
      expect(store.courseCountFor(org, 'e-4'), 2);
    });

    test('unassign removes only the matching assignment', () {
      final store = OrgStore();
      final before = store.assignments(org).length;
      expect(store.unassign(org, 'first-time-manager', 'e-1'), isTrue);
      expect(store.unassign(org, 'first-time-manager', 'e-1'), isFalse);
      expect(store.assignments(org).length, before - 1);
    });

    test('status follows progress', () {
      final store = OrgStore();
      final byEmployee = {
        for (final a in store.assignments(org)) a.employeeId: a.status,
      };
      expect(byEmployee['e-1'], ProgressStatus.inProgress);
      expect(byEmployee['e-3'], ProgressStatus.complete);
      expect(byEmployee['e-4'], ProgressStatus.notStarted);
    });

    test('progress summaries and averages', () {
      final store = OrgStore();
      // Seed progress: 0.75, 0.25, 1, 0.
      expect(store.averageProgress(org), closeTo(0.5, 1e-9));
      expect(store.completedCount(org), 1);
      final ftm = store
          .courseSummaries(org)
          .firstWhere((s) => s.courseId == 'first-time-manager');
      expect(ftm.assigned, 2);
      expect(ftm.completed, 0);
      expect(ftm.averageProgress, closeTo(0.5, 1e-9));
      expect(store.averageProgress('empty-org'), 0);
      expect(store.courseSummaries('empty-org'), isEmpty);
    });
  });
}
