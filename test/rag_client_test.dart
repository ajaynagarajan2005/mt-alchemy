import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mt_alchemy/assistant/assistant_engine.dart';
import 'package:mt_alchemy/assistant/knowledge.dart';
import 'package:mt_alchemy/assistant/rag_client.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/data/models/people.dart';
import 'package:mt_alchemy/state/learning_store.dart';

void main() {
  final reply = json.encode({
    'answer': 'Breathe, name the feeling, decide the next step.',
    'mode': 'extractive',
    'personalised': true,
    'sources': [
      {
        'kind': 'course',
        'title': 'Lecture: The ninety second pause',
        'course_id': 'ei-foundations',
        'course_title': 'EI Foundations',
        'score': 0.71,
      },
    ],
  });

  test('parses the service reply and sends the token and question', () async {
    late http.Request seen;
    final client = RagClient(
      url: 'http://rag.test',
      client: MockClient((r) async {
        seen = r;
        return http.Response(
          reply,
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final a = await client.ask(
      'what is the pause?',
      idToken: 'tok',
      snapshot: {
        'user': {'name': 'A'},
      },
    );
    expect(a!.answer, startsWith('Breathe'));
    expect(a.sources.single.courseId, 'ei-foundations');
    expect(a.personalised, isTrue);
    expect(seen.url.path, '/chat');
    expect(seen.headers['Authorization'], 'Bearer tok');
    expect(json.decode(seen.body)['question'], 'what is the pause?');
  });

  test(
    'returns null when the service is down, so the app falls back',
    () async {
      final client = RagClient(
        url: 'http://rag.test',
        client: MockClient((_) async => throw Exception('offline')),
      );
      expect(await client.ask('hello'), isNull);
      // And it does not retry on every question straight away.
      var calls = 0;
      final second = RagClient(
        url: 'http://rag.test',
        client: MockClient((_) async {
          calls++;
          return http.Response('no', 500);
        }),
      );
      await second.ask('a');
      await second.ask('b');
      expect(calls, 1);
    },
  );

  test('an empty address turns the service off', () async {
    final client = RagClient(
      url: '',
      client: MockClient((_) async => http.Response(reply, 200)),
    );
    expect(client.configured, isFalse);
    expect(await client.ask('hello'), isNull);
  });

  test(
    'the snapshot holds the learner\'s own progress, orders and pathway',
    () {
      final ei = courses.firstWhere((c) => c.id == 'ei-foundations');
      final ctx = AssistantContext(
        user: AppUser(
          id: 'u',
          name: 'Amara Osei',
          email: 'a@x.com',
          role: UserRole.individual,
          careerStage: 'professional',
          interests: const ['emotional-intelligence'],
        ),
        courses: courses,
        enrolments: {
          ei.id: Enrolment(
            id: 'u_ei',
            userId: 'u',
            courseId: ei.id,
            enrolledAt: DateTime(2026, 10, 1),
            completedModuleIds: {ei.modules.first.id},
            source: 'purchase',
            amountPaid: 149,
          ),
        },
        certificates: const [],
        orders: const [],
        knowledge: KnowledgeBase(const []),
      );
      final s = snapshotOf(ctx)!;
      expect(s['user']['name'], 'Amara Osei');
      final e = (s['enrolments'] as List).single as Map;
      expect(e['done'], 1);
      expect(e['total'], ei.modules.length);
      expect(e['amountPaid'], 149);
      expect(
        snapshotOf(
          AssistantContext(
            user: null,
            courses: courses,
            enrolments: const {},
            certificates: const [],
            orders: const [],
            knowledge: KnowledgeBase(const []),
          ),
        ),
        isNull,
      );
    },
  );
}
