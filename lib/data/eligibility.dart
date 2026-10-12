import 'models/course.dart';
import 'models/people.dart';

/// Where a learner is in their career. Chosen at registration; it decides
/// which course levels they can enrol on.
enum CareerStage { student, professional, manager, seniorLeader }

extension CareerStageX on CareerStage {
  String get label => switch (this) {
    CareerStage.student => 'Student or graduate',
    CareerStage.professional => 'Professional',
    CareerStage.manager => 'Manager or team lead',
    CareerStage.seniorLeader => 'Senior leader',
  };

  String get blurb => switch (this) {
    CareerStage.student => 'Foundation courses',
    CareerStage.professional => 'Foundation and Practitioner courses',
    CareerStage.manager => 'Practitioner and Leader courses',
    CareerStage.seniorLeader => 'Leader courses',
  };

  /// Course levels this stage may enrol on.
  Set<CourseLevel> get levels => switch (this) {
    CareerStage.student => {CourseLevel.foundation},
    CareerStage.professional => {
      CourseLevel.foundation,
      CourseLevel.practitioner,
    },
    CareerStage.manager => {CourseLevel.practitioner, CourseLevel.leader},
    CareerStage.seniorLeader => {CourseLevel.leader},
  };
}

CareerStage? careerStageFrom(Object? name) {
  for (final s in CareerStage.values) {
    if (s.name == name) return s;
  }
  return null;
}

/// Why a learner can or cannot take a course.
enum Eligibility { eligible, wrongLevel, wrongArea }

extension LearnerEligibility on AppUser {
  CareerStage? get stage => careerStageFrom(careerStage);

  /// A course is open when its level suits the learner's career stage AND
  /// its practice area is one of their chosen interests. Learners without a
  /// profile yet (staff, employer-invited staff, older accounts) see all.
  Eligibility eligibilityFor(Course course) {
    final s = stage;
    if (s != null && !s.levels.contains(course.level)) {
      return Eligibility.wrongLevel;
    }
    if (interests.isNotEmpty && !interests.contains(course.serviceSlug)) {
      return Eligibility.wrongArea;
    }
    return Eligibility.eligible;
  }

  bool canEnrol(Course course) =>
      eligibilityFor(course) == Eligibility.eligible;
}

String eligibilityMessage(Eligibility e, AppUser user) => switch (e) {
  Eligibility.eligible => 'In your learning pathway',
  Eligibility.wrongLevel =>
    'Not for your career stage (${user.stage?.label ?? ''}). '
        'You can take ${user.stage?.blurb.toLowerCase() ?? 'other courses'}.',
  Eligibility.wrongArea => 'Outside your chosen interest areas. Add this area in your profile to unlock it.',
};
