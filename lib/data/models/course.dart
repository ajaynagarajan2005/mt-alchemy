enum CourseLevel { foundation, practitioner, leader }

extension CourseLevelLabel on CourseLevel {
  String get label => switch (this) {
    CourseLevel.foundation => 'Foundation',
    CourseLevel.practitioner => 'Practitioner',
    CourseLevel.leader => 'Leader',
  };
}

/// How a module is delivered in the course player.
enum LessonType { text, video, pdf, quiz }

extension LessonTypeLabel on LessonType {
  String get label => switch (this) {
    LessonType.text => 'Reading',
    LessonType.video => 'Video',
    LessonType.pdf => 'PDF',
    LessonType.quiz => 'Quiz',
  };
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
  });

  final String prompt;
  final List<String> options;

  /// Index into [options] of the correct answer.
  final int answer;

  Map<String, dynamic> toMap() => {
    'prompt': prompt,
    'options': options,
    'answer': answer,
  };

  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
    prompt: m['prompt'] as String? ?? '',
    options: List<String>.from(m['options'] as List? ?? const []),
    answer: (m['answer'] as num?)?.toInt() ?? 0,
  );
}

/// One unit of the course player: a reading, video, PDF or quiz.
class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.minutes,
    required this.body,
    this.type = LessonType.text,
    this.mediaUrl,
    this.quiz = const [],
    this.phase,
  });

  final String id;
  final String title;
  final int minutes;
  final String body;
  final LessonType type;

  /// Phase this lesson belongs to, such as "Orientation". Lessons with the
  /// same phase name are grouped in the player. Null means no phase.
  final String? phase;

  /// Video or PDF location. `asset:` prefix means a bundled app asset.
  final String? mediaUrl;
  final List<QuizQuestion> quiz;

  /// Share of correct answers needed to pass a quiz module.
  static const passMark = 0.7;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'minutes': minutes,
    'body': body,
    'type': type.name,
    'mediaUrl': mediaUrl,
    'quiz': [for (final q in quiz) q.toMap()],
    'phase': phase,
  };

  factory CourseModule.fromMap(Map<String, dynamic> m) => CourseModule(
    id: m['id'] as String,
    title: m['title'] as String? ?? '',
    minutes: (m['minutes'] as num?)?.toInt() ?? 0,
    body: m['body'] as String? ?? '',
    type: _enumByName(LessonType.values, m['type'], LessonType.text),
    mediaUrl: m['mediaUrl'] as String?,
    quiz: [
      for (final q in (m['quiz'] as List? ?? const []))
        QuizQuestion.fromMap(Map<String, dynamic>.from(q as Map)),
    ],
    phase: m['phase'] as String?,
  );

  CourseModule copyWith({
    String? title,
    int? minutes,
    String? body,
    LessonType? type,
    String? mediaUrl,
    List<QuizQuestion>? quiz,
    String? phase,
  }) => CourseModule(
    id: id,
    title: title ?? this.title,
    minutes: minutes ?? this.minutes,
    body: body ?? this.body,
    type: type ?? this.type,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    quiz: quiz ?? this.quiz,
    phase: phase ?? this.phase,
  );
}

/// A downloadable PDF that goes with a course.
class StudyMaterial {
  const StudyMaterial(this.title, this.description, this.path);
  final String title;
  final String description;

  /// Site path such as `/downloads/ei-foundations-workbook.pdf`.
  final String path;
}

/// A run of lessons that share a phase name, in course order.
class CoursePhase {
  const CoursePhase(this.name, this.modules);
  final String name;
  final List<CourseModule> modules;

  int doneIn(Set<String> done) =>
      modules.where((m) => done.contains(m.id)).length;
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
    this.published = true,
    this.imageUrl,
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

  /// Unpublished courses are visible to trainers and admins only.
  final bool published;

  /// Card photo: an `asset:` path or an https URL.
  final String? imageUrl;

  /// Lessons grouped by phase, keeping course order. Lessons without a phase
  /// form one unnamed group so older courses still work.
  List<CoursePhase> get phases {
    final out = <CoursePhase>[];
    for (final m in modules) {
      final name = m.phase ?? '';
      if (out.isNotEmpty && out.last.name == name) {
        out.last.modules.add(m);
      } else {
        out.add(CoursePhase(name, [m]));
      }
    }
    return out;
  }

  /// Study guide, workbook and quick reference. The PDFs are named after the
  /// course id and built by `tools/make_pdfs.py`.
  List<StudyMaterial> get materials => [
    StudyMaterial(
      'Study guide',
      'The lecture as notes, with a glossary. Read it before the quizzes.',
      '/downloads/$id-study-guide.pdf',
    ),
    StudyMaterial(
      'Workbook',
      'Reflection questions, an exercise and a seven-day action plan.',
      '/downloads/$id-workbook.pdf',
    ),
    StudyMaterial(
      'Quick reference',
      'The key ideas and words on one page to keep nearby.',
      '/downloads/$id-quick-reference.pdf',
    ),
  ];

  int get totalMinutes => modules.fold(0, (sum, m) => sum + m.minutes);

  Map<String, dynamic> toMap() => {
    'title': title,
    'serviceSlug': serviceSlug,
    'level': level.name,
    'price': price,
    'summary': summary,
    'outcomes': outcomes,
    'modules': [for (final m in modules) m.toMap()],
    'trainer': trainer,
    'published': published,
    'imageUrl': imageUrl,
  };

  factory Course.fromMap(String id, Map<String, dynamic> m) => Course(
    id: id,
    title: m['title'] as String? ?? '',
    serviceSlug: m['serviceSlug'] as String? ?? '',
    level: _enumByName(CourseLevel.values, m['level'], CourseLevel.foundation),
    price: (m['price'] as num?)?.toDouble() ?? 0,
    summary: m['summary'] as String? ?? '',
    outcomes: List<String>.from(m['outcomes'] as List? ?? const []),
    modules: [
      for (final mod in (m['modules'] as List? ?? const []))
        CourseModule.fromMap(Map<String, dynamic>.from(mod as Map)),
    ],
    trainer: m['trainer'] as String? ?? '',
    published: m['published'] as bool? ?? true,
    imageUrl: m['imageUrl'] as String?,
  );

  Course copyWith({
    String? title,
    String? serviceSlug,
    CourseLevel? level,
    double? price,
    String? summary,
    List<String>? outcomes,
    List<CourseModule>? modules,
    String? trainer,
    bool? published,
    String? imageUrl,
  }) => Course(
    id: id,
    title: title ?? this.title,
    serviceSlug: serviceSlug ?? this.serviceSlug,
    level: level ?? this.level,
    price: price ?? this.price,
    summary: summary ?? this.summary,
    outcomes: outcomes ?? this.outcomes,
    modules: modules ?? this.modules,
    trainer: trainer ?? this.trainer,
    published: published ?? this.published,
    imageUrl: imageUrl ?? this.imageUrl,
  );
}
