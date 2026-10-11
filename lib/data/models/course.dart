enum CourseLevel { foundation, practitioner, leader }

extension CourseLevelLabel on CourseLevel {
  String get label => switch (this) {
    CourseLevel.foundation => 'Foundation',
    CourseLevel.practitioner => 'Practitioner',
    CourseLevel.leader => 'Leader',
  };
}

class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.minutes,
    required this.body,
  });

  final String id;
  final String title;
  final int minutes;
  final String body;
}

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.serviceSlug,
    required this.level,
    required this.price,
    required this.summary,
    required this.outcomes,
    required this.modules,
    required this.trainer,
  });

  final String id;
  final String title;

  /// Links the course to a [Service] practice area.
  final String serviceSlug;
  final CourseLevel level;

  /// Price in GBP for individual learners. Employer seats are covered by the organisation.
  final double price;
  final String summary;
  final List<String> outcomes;
  final List<CourseModule> modules;
  final String trainer;

  int get totalMinutes => modules.fold(0, (sum, m) => sum + m.minutes);
}
