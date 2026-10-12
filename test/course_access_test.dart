import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/data/models/people.dart';
import 'package:mt_alchemy/state/admin_store.dart';
import 'package:mt_alchemy/state/learning_store.dart';

import 'helpers/fake_backend.dart';

void main() {
  final course = courses.first;
  const learner = AppUser(
    id: 'u-sam',
    name: 'Sam Student',
    email: 'sam@example.com',
    role: UserRole.individual,
  );

  Future<(FakeSession, AdminStore)> admin({
    UserRole role = UserRole.superAdmin,
  }) async {
    final s = await FakeSession.signedIn(
      uid: 'u-admin',
      name: 'Admin',
      email: 'admin@example.com',
      role: role,
    );
    await s.db.collection('users').doc(learner.id).set(learner.toMap());
    return (s, AdminStore(s.backend, s.auth));
  }

  group('Course access for staff', () {
    test(
      'granting creates a free enrolment and notifies the learner',
      () async {
        final (s, store) = await admin();
        expect(await store.grantAccess(learner, course), isNull);
        final doc = await s.db
            .collection('enrolments')
            .doc('${learner.id}_${course.id}')
            .get();
        expect(doc.data()!['source'], 'granted');
        expect(doc.data()!['grantedBy'], 'u-admin');
        expect(doc.data()!.containsKey('orderId'), isFalse);
        final notes = await s.db.collection('notifications').get();
        expect(notes.docs.single.data()['userId'], learner.id);
      },
    );

    test('trainers can grant too; individuals cannot', () async {
      final (_, trainer) = await admin(role: UserRole.trainer);
      expect(await trainer.grantAccess(learner, course), isNull);
      final s = await FakeSession.signedIn(role: UserRole.individual);
      final blocked = AdminStore(s.backend, s.auth);
      expect(await blocked.grantAccess(learner, course), contains('Only'));
    });

    test('removing deletes the enrolment', () async {
      final (s, store) = await admin();
      await store.grantAccess(learner, course);
      final list = await store.enrolmentsFor(course.id).first;
      expect(list, hasLength(1));
      await store.removeAccess(list.single);
      expect(await store.enrolmentsFor(course.id).first, isEmpty);
      expect((await s.db.collection('enrolments').get()).docs, isEmpty);
    });

    test(
      'stats split paid, employer and free; revenue counts purchases only',
      () async {
        final (s, store) = await admin();
        final col = s.db.collection('enrolments');
        await col.doc('a').set({
          'userId': 'a',
          'courseId': course.id,
          'orderId': 'o1',
          'source': 'purchase',
          'amountPaid': 100.0,
        });
        // Older purchase without a recorded amount falls back to list price.
        await col.doc('b').set({
          'userId': 'b',
          'courseId': course.id,
          'orderId': 'o2',
        });
        await col.doc('c').set({
          'userId': 'c',
          'courseId': course.id,
          'assignmentId': 'as1',
        });
        await store.grantAccess(learner, course);
        final stats = (await store
            .courseStats((_) => course.price)
            .first)[course.id]!;
        expect(stats.enrolled, 4);
        expect(stats.paid, 2);
        expect(stats.assigned, 1);
        expect(stats.granted, 1);
        expect(stats.revenue, 100 + course.price);
      },
    );

    test('accessType is inferred for older records', () {
      Enrolment e(Map<String, dynamic> m) =>
          Enrolment.fromMap('x', {'userId': 'u', 'courseId': 'c', ...m});
      expect(e({'orderId': 'o'}).accessType, 'purchase');
      expect(e({'assignmentId': 'a'}).accessType, 'assignment');
      expect(e({}).accessType, 'granted');
      expect(e({'source': 'granted', 'orderId': 'o'}).accessType, 'granted');
    });
  });
}
