import 'package:flutter/foundation.dart';

import '../data/mock/courses.dart';
import '../data/models/course.dart';

class Enrolment {
  Enrolment({required this.courseId, required this.enrolledAt});

  final String courseId;
  final DateTime enrolledAt;
  final Set<String> completedModuleIds = {};

  Course get course => courseById(courseId)!;

  double get progress => course.modules.isEmpty
      ? 0
      : completedModuleIds.length / course.modules.length;

  bool get isComplete => progress >= 1;
}

/// Enrolments keyed by user id (individual learners).
class LearningStore extends ChangeNotifier {
  LearningStore() {
    // Seed the demo individual with one course in progress.
    final seeded = Enrolment(
      courseId: 'ei-foundations',
      enrolledAt: DateTime(2026, 9, 30),
    )..completedModuleIds.addAll(['ei-1', 'ei-2']);
    _byUser['u-amara'] = {seeded.courseId: seeded};
  }

  final Map<String, Map<String, Enrolment>> _byUser = {};

  List<Enrolment> enrolmentsFor(String userId) =>
      _byUser[userId]?.values.toList() ?? const [];

  Enrolment? enrolment(String userId, String courseId) =>
      _byUser[userId]?[courseId];

  bool isEnrolled(String userId, String courseId) =>
      enrolment(userId, courseId) != null;

  void enrol(String userId, String courseId) {
    final forUser = _byUser.putIfAbsent(userId, () => {});
    forUser.putIfAbsent(
      courseId,
      () => Enrolment(courseId: courseId, enrolledAt: DateTime.now()),
    );
    notifyListeners();
  }

  void setModuleComplete(
    String userId,
    String courseId,
    String moduleId,
    bool complete,
  ) {
    final e = enrolment(userId, courseId);
    if (e == null) return;
    complete
        ? e.completedModuleIds.add(moduleId)
        : e.completedModuleIds.remove(moduleId);
    notifyListeners();
  }
}
