import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/data/models/course.dart';
import 'package:mt_alchemy/data/review_writer.dart';

void main() {
  group('seed courses', () {
    test('every course has three phases, three videos and three quizzes', () {
      for (final c in courses) {
        expect(c.phases.length, 3, reason: c.id);
        expect(c.modules.length, greaterThanOrEqualTo(9), reason: c.id);
        expect(
          c.modules.where((m) => m.type == LessonType.video).length,
          3,
          reason: c.id,
        );
        expect(
          c.modules.where((m) => m.type == LessonType.quiz).length,
          3,
          reason: c.id,
        );
        expect(c.modules.map((m) => m.id).toSet().length, c.modules.length);
      }
    });

    test('every quiz can be passed with a correct answer key', () {
      for (final c in courses) {
        for (final m in c.modules.where((m) => m.type == LessonType.quiz)) {
          expect(m.quiz.length, greaterThanOrEqualTo(4), reason: m.id);
          for (final q in m.quiz) {
            expect(q.answer, inInclusiveRange(0, q.options.length - 1));
            expect(q.options.toSet().length, q.options.length, reason: m.id);
          }
        }
      }
    });
  });

  group('writeReview', () {
    final course = courses.first;
    final quizzes = course.modules.where((m) => m.type == LessonType.quiz);

    test('praises first-attempt passes and names the learner', () {
      final text = writeReview(
        ReviewInput(
          name: 'Amara Osei',
          course: course,
          quizScores: {for (final q in quizzes) q.id: 1.0},
          quizAttempts: {for (final q in quizzes) q.id: 1},
          days: 5,
        ),
      );
      expect(text, startsWith('Amara,'));
      expect(text, contains('first attempt'));
      expect(text, contains('5 days'));
    });

    test('mentions the quiz that needed a retry', () {
      final first = quizzes.first;
      final text = writeReview(
        ReviewInput(
          name: 'Amara Osei',
          course: course,
          quizScores: {for (final q in quizzes) q.id: 0.75},
          quizAttempts: {first.id: 3},
          days: 1,
        ),
      );
      expect(text, contains(first.title.toLowerCase()));
      expect(text, contains('single day'));
    });
  });
}
