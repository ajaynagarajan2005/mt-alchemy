import 'models/course.dart';

/// What the review is written from.
class ReviewInput {
  const ReviewInput({
    required this.name,
    required this.course,
    required this.quizScores,
    required this.quizAttempts,
    required this.days,
  });

  final String name;
  final Course course;

  /// Best score per quiz lesson, 0 to 1.
  final Map<String, double> quizScores;

  /// Number of attempts per quiz lesson.
  final Map<String, int> quizAttempts;

  /// Calendar days from enrolment to finishing, at least 1.
  final int days;
}

/// Writes a short personal review of how someone worked through a course.
///
/// This runs on the device from the learner's own results (quiz scores,
/// attempts and pace). It is a rule-based writer, not a language model: a
/// model needs a server and an API key, which this free-plan app does not
/// have. The wording changes with the results, so two learners rarely get the
/// same text.
String writeReview(ReviewInput r) {
  final first = r.name.trim().split(RegExp(r'\s+')).first;
  final quizzes = r.course.modules
      .where((m) => m.type == LessonType.quiz)
      .toList();
  final scores = [for (final q in quizzes) r.quizScores[q.id] ?? 0.0];
  final avg = scores.isEmpty
      ? 1.0
      : scores.reduce((a, b) => a + b) / scores.length;
  final firstTry = [
    for (final q in quizzes)
      if ((r.quizAttempts[q.id] ?? 1) <= 1) q,
  ];
  final retried = [
    for (final q in quizzes)
      if ((r.quizAttempts[q.id] ?? 1) > 1) q,
  ];
  final pct = (avg * 100).round();
  final lessons = r.course.modules.length;
  final phases = r.course.phases.where((p) => p.name.isNotEmpty).length;

  final out = StringBuffer();

  // Opening: what they did.
  out.write(
    '$first, you worked through all $lessons lessons of ${r.course.title}'
    '${phases > 1 ? ' across $phases phases' : ''} in '
    '${r.days == 1 ? 'a single day' : '${r.days} days'}. ',
  );

  // Pace.
  if (r.days <= 2) {
    out.write(
      'That is a fast, focused run, so it is worth coming back to the '
      'action plan in a week to see what has stuck. ',
    );
  } else if (r.days <= 14) {
    out.write(
      'Finishing within two weeks is a steady rhythm: long enough to try '
      'ideas at work between lessons, short enough to keep momentum. ',
    );
  } else {
    out.write(
      'You took your time and kept coming back, which is how habits tend to '
      'form. ',
    );
  }

  // Quizzes.
  if (quizzes.isNotEmpty) {
    if (firstTry.length == quizzes.length) {
      out.write(
        'You passed every quiz on the first attempt, with an average of '
        '$pct%, so the core ideas were clear from the start. ',
      );
    } else if (retried.isEmpty) {
      out.write('Your quiz average was $pct%. ');
    } else {
      final names = retried.map((q) => q.title.toLowerCase()).join(' and ');
      final one = retried.length == 1;
      out.write(
        'Your quiz average was $pct%. You retried the $names, so '
        '${one ? 'that is the part' : 'those are the parts'} to revisit, and '
        'going back to try again is the right instinct. ',
      );
    }
  }

  // Closing: one outcome to carry forward.
  if (r.course.outcomes.isNotEmpty) {
    final o = r.course.outcomes.first;
    out.write(
      'A good next step is to pick one situation this week where you can '
      '${o[0].toLowerCase()}${o.substring(1)}.',
    );
  }
  return out.toString().trim();
}
