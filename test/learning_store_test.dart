import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/data/models/course.dart';
import 'package:mt_alchemy/state/learning_store.dart';

import 'helpers/fake_backend.dart';

void main() {
  group('LearningStore (fake Firestore)', () {
    final course = courses[1]; // four lessons plus a quiz

    Future<(FakeSession, LearningStore)> enrolled() async {
      final s = await FakeSession.signedIn();
      await s.db.collection('orders').doc('MTA-1').set({'userId': s.user.id});
      final store = LearningStore(s.backend, s.auth);
      expect(await store.enrolFromOrder(course.id, 'MTA-1'), isNull);
      await settle();
      return (s, store);
    }

    test('enrolling from an order creates the enrolment document', () async {
      final (s, store) = await enrolled();
      expect(store.isEnrolled(course.id), isTrue);
      final doc = await s.db
          .collection('enrolments')
          .doc('${s.user.id}_${course.id}')
          .get();
      expect(doc.data()!['orderId'], 'MTA-1');
      expect(doc.data()!['status'], 'active');
    });

    test('progress is the share of lessons completed', () async {
      final (_, store) = await enrolled();
      await store.setModuleComplete(course, course.modules[0].id, true);
      await settle();
      final e = store.enrolment(course.id)!;
      expect(e.progressIn(course), 1 / course.modules.length);
      await store.setModuleComplete(course, course.modules[0].id, false);
      await settle();
      expect(store.enrolment(course.id)!.progressIn(course), 0);
    });

    test('a failed quiz does not complete the lesson; a pass does', () async {
      final (_, store) = await enrolled();
      final quiz = course.modules.firstWhere((m) => m.type == LessonType.quiz);
      await store.submitQuiz(course, quiz.id, 0.33);
      await settle();
      expect(
        store.enrolment(course.id)!.completedModuleIds,
        isNot(contains(quiz.id)),
      );
      expect(
        store.enrolment(course.id)!.quizScores[quiz.id],
        closeTo(0.33, 0.001),
      );
      await store.submitQuiz(course, quiz.id, 1);
      await settle();
      expect(store.enrolment(course.id)!.completedModuleIds, contains(quiz.id));
    });

    test(
      'finishing every lesson does not issue the certificate by itself',
      () async {
        final (_, store) = await enrolled();
        for (final m in course.modules) {
          await store.setModuleComplete(course, m.id, true);
        }
        await settle();
        expect(store.enrolment(course.id)!.isCompleteIn(course), isTrue);
        expect(store.certificateFor(course.id), isNull);
      },
    );

    test('issuing after the last lesson gives a verifiable certificate with a review', () async {
      final (s, store) = await enrolled();
      for (final m in course.modules) {
        if (m.type == LessonType.quiz) {
          await store.submitQuiz(course, m.id, 1);
        } else {
          await store.setModuleComplete(course, m.id, true);
        }
      }
      await settle();
      final cert = await store.issueCertificate(course);
      await settle();
      expect(cert, isNotNull);
      expect(cert!.review, contains(s.user.name.split(' ').first));
      final verified = await store.verify(cert.code);
      expect(verified!.userName, s.user.name);
      expect(verified.courseTitle, course.title);
      expect(verified.review, cert.review);
    });

    test('a certificate is refused until the course is complete', () async {
      final (_, store) = await enrolled();
      expect(await store.issueCertificate(course), isNull);
    });

    test('quiz attempts are counted', () async {
      final (_, store) = await enrolled();
      final quiz = course.modules.firstWhere((m) => m.type == LessonType.quiz);
      await store.submitQuiz(course, quiz.id, 0.25);
      await store.submitQuiz(course, quiz.id, 1);
      await settle();
      expect(store.enrolment(course.id)!.quizAttempts[quiz.id], 2);
    });

    test('assigned courses can be started by the employee', () async {
      final s = await FakeSession.signedIn(email: 'callum@org.example.com');
      await s.db.collection('assignments').doc('a1').set({
        'orgId': 'org-1',
        'employeeId': 'e-1',
        'employeeEmail': 'callum@org.example.com',
        'courseId': course.id,
      });
      final store = LearningStore(s.backend, s.auth);
      await settle();
      final a = store.assignmentFor(course.id);
      expect(a, isNotNull);
      await store.startAssigned(a!);
      await settle();
      expect(store.enrolment(course.id)!.orgId, 'org-1');
    });
  });
}
