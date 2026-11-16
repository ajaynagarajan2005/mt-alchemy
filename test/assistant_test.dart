import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/assistant/assistant_engine.dart';
import 'package:mt_alchemy/assistant/knowledge.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/data/mock/products.dart';
import 'package:mt_alchemy/router/routes.dart';
import 'package:mt_alchemy/data/models/people.dart';
import 'package:mt_alchemy/state/commerce_store.dart';
import 'package:mt_alchemy/state/learning_store.dart';

KnowledgeBase _knowledge() {
  final raw = json.decode(
    File('assets/data/course_knowledge.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final notes = [
    for (final e in raw.entries)
      for (final p in e.value as List)
        Passage(
          id: p['id'] as String,
          courseId: e.key,
          title: p['title'] as String,
          text: p['text'] as String,
        ),
  ];
  return KnowledgeBase([...notes, ...KnowledgeBase.fromCourses(courses)]);
}

void main() {
  final kb = _knowledge();
  const engine = AssistantEngine();
  final user = AppUser(
    id: 'u1',
    name: 'Amara Osei',
    email: 'amara@example.com',
    role: UserRole.individual,
    careerStage: 'professional',
    interests: const [
      'emotional-intelligence',
      'leadership-development',
      'team-engagement',
    ],
  );
  final ei = courses.firstWhere((c) => c.id == 'ei-foundations');
  final enrolment = Enrolment(
    id: 'u1_ei-foundations',
    userId: 'u1',
    courseId: ei.id,
    enrolledAt: DateTime(2026, 10, 1),
    completedModuleIds: {for (final m in ei.modules.take(4)) m.id},
    source: 'purchase',
    orderId: 'MTA-1',
  );
  final order = Order(
    number: 'MTA-1',
    userId: 'u1',
    email: 'amara@example.com',
    items: const [
      OrderLine(
        id: 'ei-foundations',
        name: 'Emotional Intelligence Foundations',
        kind: 'course',
        price: 149,
        quantity: 1,
      ),
    ],
    subtotal: 149,
    shipping: 0,
    total: 149,
    status: 'paid',
    createdAt: DateTime(2026, 10, 1),
  );
  AssistantContext ctx({AppUser? u, bool enrolled = true}) => AssistantContext(
    user: u,
    courses: courses,
    enrolments: enrolled ? {ei.id: enrolment} : {},
    certificates: const [],
    orders: enrolled ? [order] : const [],
    knowledge: kb,
    products: products,
  );

  test('a concept question is answered from the lecture notes', () {
    final r = engine.answer('Explain the ninety second pause', ctx(u: user));
    expect(r.intent, 'doubt');
    final a = r.blocks.whereType<AnswerBlock>().single;
    expect(a.passage.courseId, 'ei-foundations');
    expect(a.excerpt.toLowerCase(), contains('breathe'));
  });

  test('"what is psychological safety" finds a team course', () {
    final r = engine.answer('what is psychological safety?', ctx(u: user));
    final a = r.blocks.whereType<AnswerBlock>().single;
    expect(a.passage.text.toLowerCase(), contains('psychological safety'));
  });

  test('progress is drawn from the user\'s own enrolments', () {
    final r = engine.answer('How am I doing in my courses?', ctx(u: user));
    expect(r.intent, 'progress');
    final p = r.blocks.whereType<ProgressBlock>().single;
    expect(p.items.single.course.id, 'ei-foundations');
    expect(p.items.single.done, 4);
    expect(p.items.single.nextLesson, isNotNull);
  });

  test('payments add up the user\'s orders', () {
    final r = engine.answer('How much have I paid so far?', ctx(u: user));
    expect(r.intent, 'payment');
    final p = r.blocks.whereType<PaymentBlock>().single;
    expect(p.total, 149);
    expect(p.items.single.number, 'MTA-1');
  });

  test('extra courses skip the ones already taken and fit the pathway', () {
    final r = engine.answer('Which courses can I add?', ctx(u: user));
    expect(r.intent, 'recommend');
    final block = r.blocks.whereType<CoursesBlock>().single;
    expect(block.items, isNotEmpty);
    expect(block.items.any((s) => s.course.id == 'ei-foundations'), isFalse);
    expect(block.items.every((s) => s.canBuy), isTrue);
  });

  test('asking to pay for a named course returns that course to buy', () {
    final r = engine.answer(
      'I want to pay for The First-Time Manager',
      ctx(u: user),
    );
    final block = r.blocks.whereType<CoursesBlock>().single;
    expect(block.items.single.course.id, 'first-time-manager');
    expect(block.items.single.canBuy, isTrue);
  });

  test('a course already owned cannot be bought again', () {
    final r = engine.answer(
      'buy Emotional Intelligence Foundations',
      ctx(u: user),
    );
    final s = r.blocks.whereType<CoursesBlock>().single.items.single;
    expect(s.enrolled, isTrue);
    expect(s.canBuy, isFalse);
  });

  test('guests are asked to sign in for personal data', () {
    final r = engine.answer('what is my progress', ctx(enrolled: false));
    expect(r.blocks.whereType<SignInBlock>(), isNotEmpty);
    final p = engine.answer('what have I paid', ctx(enrolled: false));
    expect(p.blocks.whereType<SignInBlock>(), isNotEmpty);
  });

  test('guests can still ask about course content', () {
    final r = engine.answer('how do I run a one to one', ctx(enrolled: false));
    expect(r.blocks.whereType<AnswerBlock>(), isNotEmpty);
  });

  test('unrelated questions get an honest "not found"', () {
    final r = engine.answer('what is the capital of Peru', ctx(u: user));
    expect(r.blocks.whereType<AnswerBlock>(), isEmpty);
    expect(
      r.blocks.whereType<TextBlock>().first.text,
      contains('do not have an answer'),
    );
    expect(r.blocks.whereType<LinksBlock>(), isNotEmpty);
  });

  test('greetings offer starter questions', () {
    final r = engine.answer('hello', ctx(u: user));
    expect(r.blocks.whereType<SuggestionsBlock>(), isNotEmpty);
  });

  group('questions about the website', () {
    String topic(String q, {bool signedIn = true}) {
      final r = engine.answer(q, ctx(u: signedIn ? user : null));
      return r.intent == 'site'
          ? r.blocks.whereType<LinksBlock>().firstOrNull?.links.first.path ??
                'site'
          : r.intent;
    }

    test('each common site question opens the right page', () {
      final cases = {
        'what services do you offer': Routes.services,
        'How do I contact you?': Routes.contact,
        'what is your phone number': Routes.contact,
        'who are the founders of mt alchemy': Routes.about,
        'what do you sell in the store': Routes.store,
        'how much is shipping': Routes.myOrders,
        'can I get a refund': Routes.myOrders,
        'how do I pay': Routes.cart,
        'which test card can I use': Routes.cart,
        'I forgot my password': Routes.portal,
        'do you train teams for my company': Routes.organisations,
        'is there an eq test': Routes.assessment,
        'show me your blog articles': Routes.insights,
      };
      final wrong = [
        for (final e in cases.entries)
          if (topic(e.key) != e.value) '${e.key} -> ${topic(e.key)}',
      ];
      expect(wrong, isEmpty);
      expect(topic('I forgot my password', signedIn: false), Routes.login);
    });

    test('site answers carry real facts', () {
      final r = engine.answer('How do I contact you?', ctx(u: user));
      final text = r.blocks.whereType<TextBlock>().first.text;
      expect(text, contains('hello@mtalchemy.co.uk'));
      final ship = engine.answer('how much is shipping', ctx(u: user));
      expect(ship.blocks.whereType<TextBlock>().first.text, contains('£50'));
      final store = engine.answer('what do you sell', ctx(u: user));
      expect(
        store.blocks.whereType<TextBlock>().first.text,
        contains('Feedback Conversation Cards'),
      );
    });

    test('personal questions still use the user\'s own records', () {
      expect(topic('what have I paid so far'), 'payment');
      expect(topic('where is my order'), 'orders');
      expect(topic('How am I doing in my courses?'), 'progress');
      expect(topic('Which courses can I add?'), 'recommend');
      expect(topic('what courses do you have'), 'recommend');
    });

    test('course content questions are not taken over by site words', () {
      expect(topic('Explain the ninety second pause'), 'doubt');
      expect(topic('how do I deliver feedback'), 'doubt');
      expect(topic('what is psychological safety'), 'doubt');
    });

    test('product names are not mistaken for payment questions', () {
      expect(topic('tell me about the conversation cards'), Routes.store);
    });

    test('thanks gets a polite reply, not a greeting', () {
      final r = engine.answer('thanks!', ctx(u: user));
      expect(r.intent, 'thanks');
    });
  });
}
