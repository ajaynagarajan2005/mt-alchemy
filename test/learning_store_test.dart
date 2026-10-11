import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/state/learning_store.dart';

void main() {
  group('LearningStore', () {
    const user = 'u-test';
    final course = courses[1]; // four modules

    test('enrol is idempotent and keeps progress', () {
      final store = LearningStore();
      expect(store.isEnrolled(user, course.id), isFalse);
      store.enrol(user, course.id);
      store.setModuleComplete(user, course.id, course.modules.first.id, true);
      store.enrol(user, course.id);
      expect(store.enrolmentsFor(user), hasLength(1));
      expect(
        store.enrolment(user, course.id)!.completedModuleIds,
        hasLength(1),
      );
    });

    test('progress maths', () {
      final store = LearningStore()..enrol(user, course.id);
      final e = store.enrolment(user, course.id)!;
      expect(e.progress, 0);
      store.setModuleComplete(user, course.id, course.modules[0].id, true);
      expect(e.progress, 0.25);
      store.setModuleComplete(user, course.id, course.modules[0].id, true);
      expect(e.progress, 0.25);
      store.setModuleComplete(user, course.id, course.modules[0].id, false);
      expect(e.progress, 0);
    });

    test('completes when every module is done', () {
      final store = LearningStore()..enrol(user, course.id);
      for (final m in course.modules) {
        store.setModuleComplete(user, course.id, m.id, true);
      }
      expect(store.enrolment(user, course.id)!.isComplete, isTrue);
    });

    test('ignores completion when not enrolled', () {
      final store = LearningStore();
      store.setModuleComplete(user, course.id, course.modules[0].id, true);
      expect(store.enrolment(user, course.id), isNull);
    });
  });
}
