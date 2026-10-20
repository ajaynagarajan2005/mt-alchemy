import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mt_alchemy/state/catalog_store.dart';

import 'helpers/fake_backend.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/assistant/assistant_engine.dart';
import 'package:mt_alchemy/assistant/knowledge.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/widgets/assistant/reply_blocks.dart';

void main() {
  final ei = courses.first;
  final actions = BlockActions(ask: (_) {}, go: (_) {}, buy: (_) {});

  Future<void> pumpBlock(WidgetTester t, ReplyBlock b) async {
    final s = (await t.runAsync(() => FakeSession.signedIn()))!;
    await t.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CatalogStore(s.backend),
        child: MaterialApp(
          home: Material(
            child: SizedBox(
              width: 400,
              height: 600,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [ReplyBlockView(block: b, actions: actions)],
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 100));
  }

  testWidgets('payment block lays out with its chart and list', (t) async {
    await pumpBlock(
      t,
      PaymentBlock(
        title: 'Your payments',
        items: [
          PaymentItem(
            number: 'MTA-10001',
            date: DateTime(2026, 10, 2),
            summary: 'Emotional Intelligence Foundations',
            amount: 149,
          ),
          PaymentItem(
            number: 'MTA-10002',
            date: DateTime(2026, 10, 5),
            summary: 'Cards, toolkit',
            amount: 63,
          ),
          PaymentItem(
            number: 'MTA-V12345',
            date: DateTime(2026, 10, 7),
            summary: 'Team Trust Reset',
            amount: 199,
          ),
        ],
      ),
    );
    expect(tester(t), isNull);
  });

  testWidgets('progress block lays out', (t) async {
    await pumpBlock(
      t,
      ProgressBlock([
        ProgressItem(
          course: ei,
          done: 3,
          total: ei.modules.length,
          nextLesson: 'Mapping your triggers',
        ),
      ]),
    );
    expect(tester(t), isNull);
  });

  testWidgets('courses block lays out', (t) async {
    await pumpBlock(
      t,
      CoursesBlock([
        CourseSuggestion(course: ei, reason: 'In your learning pathway'),
      ]),
    );
    expect(tester(t), isNull);
  });

  testWidgets('answer blocks lay out', (t) async {
    const p = Passage(
      id: 'a',
      courseId: 'ei-foundations',
      title: 'Lecture: The pause',
      text: 'Breathe. Name it.',
    );
    await pumpBlock(
      t,
      const AnswerBlock(
        passage: p,
        excerpt: 'Breathe.',
        courseTitle: 'EI',
        related: [p],
      ),
    );
    expect(tester(t), isNull);
    await pumpBlock(
      t,
      const RagAnswerBlock(
        RagAnswer(
          answer: 'Breathe, name the feeling.',
          mode: 'extractive',
          personalised: false,
          sources: [
            RagSource(
              title: 'Lecture: The pause',
              courseTitle: 'EI',
              courseId: 'ei-foundations',
              kind: 'course',
              score: 0.6,
            ),
            RagSource(
              title: 'Your order MTA-1',
              courseTitle: '',
              courseId: '',
              kind: 'record',
              score: 0.5,
            ),
          ],
        ),
      ),
    );
    expect(tester(t), isNull);
  });

  testWidgets('suggestions and sign-in lay out', (t) async {
    await pumpBlock(t, const SuggestionsBlock(['One', 'Two']));
    expect(tester(t), isNull);
    await pumpBlock(t, const SignInBlock());
    expect(tester(t), isNull);
  });
}

Object? tester(WidgetTester t) => t.takeException();
