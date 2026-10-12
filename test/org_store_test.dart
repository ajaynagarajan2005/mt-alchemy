import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/data/models/people.dart';
import 'package:mt_alchemy/state/org_store.dart';

import 'helpers/fake_backend.dart';

void main() {
  const org = 'org-test';

  Future<(FakeSession, OrgStore)> employer({int seats = 2}) async {
    final s = await FakeSession.signedIn(
      uid: 'u-boss',
      email: 'boss@org.example.com',
      role: UserRole.employer,
      orgId: org,
      organisation: {
        'name': 'Test Org',
        'sector': 'Housing',
        'size': '50 to 249',
        'seats': {'ei-foundations': seats},
      },
    );
    final store = OrgStore(s.backend, s.auth);
    for (final (id, name, email) in [
      ('e-1', 'Ada Lovelace', 'ada@org.example.com'),
      ('e-2', 'Grace Hopper', 'grace@org.example.com'),
      ('e-3', 'Alan Turing', 'alan@org.example.com'),
    ]) {
      await s.db.collection('employees').doc(id).set({
        'orgId': org,
        'name': name,
        'email': email,
        'team': 'Ops',
      });
    }
    await settle();
    return (s, store);
  }

  group('OrgStore (fake Firestore)', () {
    test('adds an employee and detects duplicate emails', () async {
      final (_, store) = await employer();
      final error = await store.addEmployee(
        org,
        name: ' Joan Clarke ',
        email: 'Joan@org.example.com',
        team: 'Finance',
      );
      await settle();
      expect(error, isNull);
      expect(store.employees(org), hasLength(4));
      expect(store.emailInUse(org, ' JOAN@org.example.com '), isTrue);
      expect(store.emailInUse(org, 'nobody@example.com'), isFalse);
    });

    test('assigning uses purchased seats and skips duplicates', () async {
      final (s, store) = await employer(seats: 2);
      final (added, error) = await store.assign(org, 'ei-foundations', [
        'e-1',
        'e-2',
      ]);
      await settle();
      expect(error, isNull);
      expect(added, 2);
      final orgDoc = await s.db.collection('organizations').doc(org).get();
      expect(orgDoc.data()!['seats']['ei-foundations'], 0);
      final again = await store.assign(org, 'ei-foundations', ['e-1']);
      expect(again.$1, 0);
    });

    test('assigning without enough seats is refused', () async {
      final (_, store) = await employer(seats: 1);
      final (added, error) = await store.assign(org, 'ei-foundations', [
        'e-1',
        'e-2',
      ]);
      expect(added, 0);
      expect(error, contains('1 seat left'));
      final none = await store.assign(org, 'team-trust-reset', ['e-1']);
      expect(none.$2, contains('no seats'));
    });

    test('progress, status and summaries come from enrolments', () async {
      final (s, store) = await employer(seats: 3);
      await store.assign(org, 'ei-foundations', ['e-1', 'e-2', 'e-3']);
      await s.db.collection('enrolments').doc('x1').set({
        'orgId': org,
        'userEmail': 'ada@org.example.com',
        'courseId': 'ei-foundations',
        'progress': 1.0,
      });
      await s.db.collection('enrolments').doc('x2').set({
        'orgId': org,
        'userEmail': 'grace@org.example.com',
        'courseId': 'ei-foundations',
        'progress': 0.5,
      });
      await settle();
      final byEmployee = {
        for (final a in store.assignments(org)) a.employeeId: a.status,
      };
      expect(byEmployee['e-1'], ProgressStatus.complete);
      expect(byEmployee['e-2'], ProgressStatus.inProgress);
      expect(byEmployee['e-3'], ProgressStatus.notStarted);
      expect(store.averageProgress(org), closeTo(0.5, 1e-9));
      expect(store.completedCount(org), 1);
      final summary = store.courseSummaries(org).single;
      expect(summary.assigned, 3);
      expect(summary.completed, 1);
    });

    test('removing an employee removes their assignments', () async {
      final (_, store) = await employer(seats: 2);
      await store.assign(org, 'ei-foundations', ['e-1']);
      await settle();
      expect(store.courseCountFor(org, 'e-1'), 1);
      await store.removeEmployee(org, 'e-1');
      await settle();
      expect(store.employeeById(org, 'e-1'), isNull);
      expect(store.courseCountFor(org, 'e-1'), 0);
    });

    test('weekly activity buckets by last activity', () async {
      final (s, store) = await employer(seats: 2);
      await store.assign(org, 'ei-foundations', ['e-1', 'e-2']);
      final now = DateTime(2026, 10, 12);
      await s.db.collection('enrolments').doc('x1').set({
        'orgId': org,
        'userEmail': 'ada@org.example.com',
        'courseId': 'ei-foundations',
        'progress': 0.4,
        'updatedAt': now.subtract(const Duration(days: 2)),
      });
      await s.db.collection('enrolments').doc('x2').set({
        'orgId': org,
        'userEmail': 'grace@org.example.com',
        'courseId': 'ei-foundations',
        'progress': 0.2,
        'updatedAt': now.subtract(const Duration(days: 15)),
      });
      await settle();
      expect(store.weeklyActivity(org, now: now), [0, 0, 0, 1, 0, 1]);
    });
  });
}
