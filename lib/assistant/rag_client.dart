import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/models/course.dart';
import 'assistant_engine.dart';

/// Talks to the retrieval service in `server/` (LangChain and a Chroma vector
/// database). When the service is not reachable, every call returns null and
/// the app falls back to its built-in keyword search.
///
/// The address is set at build time: `--dart-define=RAG_URL=https://...`.
/// An empty value turns the service off.
class RagClient {
  RagClient({String? url, http.Client? client})
    : _url =
          url ??
          const String.fromEnvironment(
            'RAG_URL',
            defaultValue: 'http://localhost:8710',
          ),
      _http = client ?? http.Client();

  final String _url;
  final http.Client _http;
  DateTime? _downUntil;

  bool get configured => _url.isNotEmpty;

  /// Asks the service. Returns null if it is off, down or slow.
  Future<RagAnswer?> ask(
    String question, {
    String? idToken,
    Map<String, dynamic>? snapshot,
  }) async {
    if (!configured) return null;
    final until = _downUntil;
    if (until != null && DateTime.now().isBefore(until)) return null;
    try {
      final r = await _http
          .post(
            Uri.parse('$_url/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': ?(idToken == null ? null : 'Bearer $idToken'),
            },
            body: json.encode({'question': question, 'snapshot': snapshot}),
          )
          .timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) {
        _downUntil = DateTime.now().add(const Duration(seconds: 20));
        return null;
      }
      final m = json.decode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      return RagAnswer(
        answer: m['answer'] as String? ?? '',
        mode: m['mode'] as String? ?? 'extractive',
        personalised: m['personalised'] as bool? ?? false,
        sources: [
          for (final s in (m['sources'] as List? ?? const []))
            RagSource(
              title: s['title'] as String? ?? '',
              courseTitle: s['course_title'] as String? ?? '',
              courseId: s['course_id'] as String? ?? '',
              kind: s['kind'] as String? ?? 'course',
              score: (s['score'] as num?)?.toDouble() ?? 0,
            ),
        ],
      );
    } catch (_) {
      // Not running, blocked or timed out: stop trying for a little while so
      // each question is not delayed.
      _downUntil = DateTime.now().add(const Duration(seconds: 30));
      return null;
    }
  }
}

String _date(DateTime? d) {
  if (d == null) return 'an unknown date';
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// The learner's own records in the form the service indexes them.
Map<String, dynamic>? snapshotOf(AssistantContext ctx) {
  final u = ctx.user;
  if (u == null) return null;
  Course? course(String id) {
    for (final c in ctx.courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  return {
    'user': {
      'name': u.name,
      'careerStage': u.careerStage,
      'interests': u.interests,
    },
    'enrolments': [
      for (final e in ctx.enrolments.values)
        if (course(e.courseId) != null)
          {
            'courseId': e.courseId,
            'courseTitle': course(e.courseId)!.title,
            'done': course(e.courseId)!.modules
                .where((m) => e.completedModuleIds.contains(m.id))
                .length,
            'total': course(e.courseId)!.modules.length,
            'progress': e.progressIn(course(e.courseId)!),
            'next': course(e.courseId)!.modules
                .where((m) => !e.completedModuleIds.contains(m.id))
                .firstOrNull
                ?.title,
            'accessType': e.accessType,
            'amountPaid': e.amountPaid,
          },
    ],
    'orders': [
      for (final o in ctx.orders)
        {
          'number': o.number,
          'date': _date(o.createdAt),
          'total': o.total,
          'items': o.items
              .map((i) => i.quantity > 1 ? '${i.name} x${i.quantity}' : i.name)
              .join(', '),
        },
    ],
    'certificates': [
      for (final c in ctx.certificates)
        {
          'code': c.code,
          'courseTitle': c.courseTitle,
          'issuedAt': _date(c.issuedAt),
          'review': c.review,
        },
    ],
    'assigned': [
      for (final a in ctx.assigned)
        if (course(a.courseId) != null)
          {'courseId': a.courseId, 'courseTitle': course(a.courseId)!.title},
    ],
  };
}
