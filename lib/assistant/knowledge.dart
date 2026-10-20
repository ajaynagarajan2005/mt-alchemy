import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../data/models/course.dart';

/// One searchable piece of course content.
class Passage {
  const Passage({
    required this.id,
    required this.courseId,
    required this.title,
    required this.text,
  });

  final String id;
  final String courseId;

  /// Where it came from, for example "Lecture: The ninety second pause".
  final String title;
  final String text;
}

/// A passage that matched a question, with its score.
class Hit {
  const Hit(this.passage, this.score);
  final Passage passage;
  final double score;
}

const _stop = {
  'a',
  'an',
  'the',
  'and',
  'or',
  'but',
  'if',
  'of',
  'to',
  'in',
  'on',
  'for',
  'with',
  'at',
  'by',
  'from',
  'is',
  'are',
  'was',
  'were',
  'be',
  'been',
  'it',
  'this',
  'that',
  'these',
  'those',
  'i',
  'me',
  'my',
  'we',
  'you',
  'your',
  'do',
  'does',
  'did',
  'can',
  'could',
  'should',
  'would',
  'will',
  'what',
  'whats',
  'how',
  'why',
  'when',
  'where',
  'who',
  'which',
  'about',
  'as',
  'so',
  'than',
  'then',
  'there',
  'their',
  'they',
  'them',
  'not',
  'no',
  'yes',
  'please',
  'tell',
  'explain',
  'mean',
  'means',
  'meaning',
  'course',
  'lesson',
  'have',
  'has',
  'had',
  'am',
  'any',
  'some',
  'get',
  'got',
};

/// Lower-case words with filler removed and endings trimmed, so "triggers"
/// and "trigger", or "delegating" and "delegate", match.
List<String> tokenize(String text) {
  final words = RegExp(r"[a-z0-9]+").allMatches(text.toLowerCase());
  return [
    for (final m in words)
      if (!_stop.contains(m.group(0)!) && m.group(0)!.length > 1)
        _stem(m.group(0)!),
  ];
}

String _stem(String w) {
  if (w.length > 5 && w.endsWith('ing')) return w.substring(0, w.length - 3);
  if (w.length > 4 && w.endsWith('ed')) return w.substring(0, w.length - 2);
  if (w.length > 4 && w.endsWith('es')) return w.substring(0, w.length - 2);
  if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) {
    return w.substring(0, w.length - 1);
  }
  if (w.length > 4 && w.endsWith('e')) return w.substring(0, w.length - 1);
  return w;
}

/// Everything the assistant can look up about the courses, searched with
/// BM25 (a standard keyword-ranking formula). This is retrieval only: the
/// answer shown is a passage taken from the course, never invented text.
class KnowledgeBase {
  KnowledgeBase(this.passages) {
    var total = 0;
    for (final p in passages) {
      final t = tokenize('${p.title} ${p.text}');
      _tokens.add(t);
      total += t.length;
      for (final w in t.toSet()) {
        _docFreq[w] = (_docFreq[w] ?? 0) + 1;
      }
    }
    _avgLen = passages.isEmpty ? 1 : total / passages.length;
  }

  final List<Passage> passages;
  final _tokens = <List<String>>[];
  final _docFreq = <String, int>{};
  double _avgLen = 1;

  bool get isEmpty => passages.isEmpty;

  /// Loads the lecture notes shipped with the app and adds each course's own
  /// lessons, so the assistant knows what is taught in every lesson.
  static Future<KnowledgeBase> load(List<Course> courses) async {
    final passages = <Passage>[];
    try {
      final raw = await rootBundle.loadString(
        'assets/data/course_knowledge.json',
      );
      final map = json.decode(raw) as Map<String, dynamic>;
      for (final e in map.entries) {
        for (final p in (e.value as List)) {
          final m = Map<String, dynamic>.from(p as Map);
          passages.add(
            Passage(
              id: m['id'] as String,
              courseId: e.key,
              title: m['title'] as String,
              text: m['text'] as String,
            ),
          );
        }
      }
    } catch (_) {
      // Without the notes the assistant still answers from the lessons.
    }
    return KnowledgeBase([...passages, ...fromCourses(courses)]);
  }

  /// Passages built from the course records: summary, aims and lesson text.
  static List<Passage> fromCourses(List<Course> courses) => [
    for (final c in courses) ...[
      Passage(
        id: '${c.id}-about',
        courseId: c.id,
        title: 'About ${c.title}',
        text:
            '${c.summary} You will learn to: ${c.outcomes.join('; ')}. '
            'Led by ${c.trainer}. Level: ${c.level.label}.',
      ),
      for (final m in c.modules)
        if (m.type != LessonType.quiz && m.body.length > 40)
          Passage(
            id: '${c.id}-${m.id}',
            courseId: c.id,
            title: 'Lesson: ${m.title}',
            text: m.body,
          ),
    ],
  ];

  /// Best passages for [query], best first. [boost] multiplies the score of
  /// a course's passages, used for courses the learner is taking.
  List<Hit> search(String query, {int limit = 3, Map<String, double>? boost}) {
    final q = tokenize(query);
    if (q.isEmpty || passages.isEmpty) return const [];
    final n = passages.length;
    final hits = <Hit>[];
    for (var i = 0; i < n; i++) {
      final doc = _tokens[i];
      var score = 0.0;
      for (final term in q.toSet()) {
        final tf = doc.where((w) => w == term).length;
        if (tf == 0) continue;
        final df = _docFreq[term] ?? 0;
        final idf = math.log(1 + (n - df + 0.5) / (df + 0.5));
        score +=
            idf *
            (tf * 2.5) /
            (tf + 1.5 * (1 - 0.75 + 0.75 * doc.length / _avgLen));
      }
      if (score > 0) {
        final b = boost?[passages[i].courseId] ?? 1.0;
        hits.add(Hit(passages[i], score * b));
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.take(limit).toList();
  }

  /// The one or two sentences of [passage] that best match [query].
  static String excerpt(Passage passage, String query, {int sentences = 2}) {
    final q = tokenize(query).toSet();
    final parts = passage.text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (parts.length <= sentences) return passage.text;
    final scored = [
      for (var i = 0; i < parts.length; i++)
        (i, tokenize(parts[i]).where(q.contains).length),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final pick = scored.take(sentences).map((e) => e.$1).toList()..sort();
    return pick.map((i) => parts[i]).join(' ');
  }
}
