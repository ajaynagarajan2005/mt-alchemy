import '../data/eligibility.dart';
import '../data/models/course.dart';
import '../data/models/people.dart';
import '../state/commerce_store.dart';
import '../state/learning_store.dart';
import 'knowledge.dart';

// ---------------------------------------------------------------- blocks

/// One visual piece of an answer.
sealed class ReplyBlock {
  const ReplyBlock();
}

class TextBlock extends ReplyBlock {
  const TextBlock(this.text);
  final String text;
}

class ProgressItem {
  const ProgressItem({
    required this.course,
    required this.done,
    required this.total,
    this.nextLesson,
    this.certificateCode,
  });

  final Course course;
  final int done;
  final int total;
  final String? nextLesson;
  final String? certificateCode;

  double get progress => total == 0 ? 0 : done / total;
}

/// Progress across the learner's courses, drawn as bars.
class ProgressBlock extends ReplyBlock {
  const ProgressBlock(this.items);
  final List<ProgressItem> items;

  int get completed => items.where((i) => i.progress >= 1).length;
  double get average => items.isEmpty
      ? 0
      : items.fold<double>(0, (s, i) => s + i.progress) / items.length;
}

class PaymentItem {
  const PaymentItem({
    required this.number,
    required this.date,
    required this.summary,
    required this.amount,
  });
  final String number;
  final DateTime? date;
  final String summary;
  final double amount;
}

/// What the learner has paid, as totals, a chart and a list.
class PaymentBlock extends ReplyBlock {
  const PaymentBlock({required this.title, required this.items});
  final String title;
  final List<PaymentItem> items;

  double get total => items.fold(0, (s, i) => s + i.amount);
}

class CourseSuggestion {
  const CourseSuggestion({
    required this.course,
    required this.reason,
    this.enrolled = false,
    this.canBuy = true,
  });
  final Course course;
  final String reason;
  final bool enrolled;

  /// False when the course is outside the learner's pathway or already owned.
  final bool canBuy;
}

class CoursesBlock extends ReplyBlock {
  const CoursesBlock(this.items);
  final List<CourseSuggestion> items;
}

/// A passage from the course material that answers a question.
class AnswerBlock extends ReplyBlock {
  const AnswerBlock({
    required this.passage,
    required this.excerpt,
    required this.courseTitle,
    this.related = const [],
  });
  final Passage passage;
  final String excerpt;
  final String courseTitle;
  final List<Passage> related;
}

class CertificateItem {
  const CertificateItem(this.code, this.courseTitle, this.issuedAt);
  final String code;
  final String courseTitle;
  final DateTime issuedAt;
}

class CertificatesBlock extends ReplyBlock {
  const CertificatesBlock(this.items);
  final List<CertificateItem> items;
}

/// One passage the server used to answer.
class RagSource {
  const RagSource({
    required this.title,
    required this.courseTitle,
    required this.courseId,
    required this.kind,
    required this.score,
  });

  final String title;
  final String courseTitle;
  final String courseId;

  /// `course` for course material, `record` for the learner's own records.
  final String kind;
  final double score;
}

class RagAnswer {
  const RagAnswer({
    required this.answer,
    required this.mode,
    required this.sources,
    required this.personalised,
  });

  final String answer;

  /// `llm` when a language model wrote it, `extractive` when it is taken
  /// straight from the best passages.
  final String mode;
  final List<RagSource> sources;
  final bool personalised;
}

/// A server answer as a reply block.
class RagAnswerBlock extends ReplyBlock {
  const RagAnswerBlock(this.answer);
  final RagAnswer answer;
}

/// Tappable follow-up questions.
class SuggestionsBlock extends ReplyBlock {
  const SuggestionsBlock(this.questions);
  final List<String> questions;
}

class SignInBlock extends ReplyBlock {
  const SignInBlock();
}

class AssistantReply {
  const AssistantReply(this.intent, this.blocks);
  final String intent;
  final List<ReplyBlock> blocks;
}

// --------------------------------------------------------------- context

/// A snapshot of the signed-in user's own records plus the catalogue. The
/// engine only reads this, so it can be tested without Firebase.
class AssistantContext {
  const AssistantContext({
    required this.user,
    required this.courses,
    required this.enrolments,
    required this.certificates,
    required this.orders,
    required this.knowledge,
    this.assigned = const [],
  });

  final AppUser? user;

  /// Courses the user may see (published ones for learners).
  final List<Course> courses;
  final Map<String, Enrolment> enrolments;
  final List<Certificate> certificates;
  final List<Order> orders;
  final List<AssignedCourse> assigned;
  final KnowledgeBase knowledge;

  bool get signedIn => user != null;
}

// ---------------------------------------------------------------- engine

enum Intent {
  greeting,
  progress,
  payment,
  recommend,
  price,
  certificate,
  orders,
  doubt,
}

const _startQuestions = [
  'How am I doing in my courses?',
  'What have I paid so far?',
  'Which courses can I add?',
  'Explain the ninety second pause',
];

class AssistantEngine {
  const AssistantEngine();

  static const suggestions = _startQuestions;

  AssistantReply answer(String query, AssistantContext ctx) {
    final q = query.toLowerCase();
    final words = RegExp(r'[a-z0-9]+')
        .allMatches(q)
        .map((m) => m.group(0)!)
        .toSet();
    final mentioned = _mentionedCourse(q, ctx.courses);
    final intent = _intent(q, words, mentioned != null, ctx);

    switch (intent) {
      case Intent.greeting:
        return _greeting(ctx);
      case Intent.progress:
        return ctx.signedIn
            ? _progress(ctx, mentioned)
            : _needSignIn('your progress');
      case Intent.payment:
        return ctx.signedIn
            ? _payment(ctx, mentioned, orders: false)
            : _needSignIn('your payments');
      case Intent.orders:
        return ctx.signedIn
            ? _payment(ctx, mentioned, orders: true)
            : _needSignIn('your orders');
      case Intent.certificate:
        return ctx.signedIn
            ? _certificates(ctx)
            : _needSignIn('your certificates');
      case Intent.price:
        return _price(ctx, mentioned);
      case Intent.recommend:
        return _recommend(ctx, mentioned, q);
      case Intent.doubt:
        return _doubt(query, ctx, mentioned);
    }
  }

  // ---- intent detection

  static const _greetWords = {
    'hi',
    'hello',
    'hey',
    'help',
    'start',
    'thanks',
    'thank',
  };
  static const _progressWords = {
    'progress',
    'complete',
    'completed',
    'finish',
    'finished',
    'status',
    'remaining',
    'left',
    'percent',
    'doing',
    'far',
    'enrolled',
    'studying',
    'learning',
    'continue',
    'resume',
  };
  static const _paymentWords = {
    'paid',
    'pay',
    'payment',
    'payments',
    'spent',
    'spend',
    'receipt',
    'invoice',
    'refund',
    'billing',
    'transaction',
    'transactions',
    'charged',
    'charge',
    'card',
  };
  static const _recommendWords = {
    'add',
    'recommend',
    'suggest',
    'next',
    'extra',
    'another',
    'more',
    'new',
    'eligible',
    'buy',
    'enrol',
    'enroll',
    'join',
    'purchase',
    'available',
    'options',
    'take',
  };
  static const _priceWords = {
    'price',
    'cost',
    'costs',
    'much',
    'fee',
    'cheap',
    'free',
  };
  static const _certWords = {
    'certificate',
    'certificates',
    'certified',
    'certification',
  };
  static const _orderWords = {
    'order',
    'orders',
    'shipping',
    'delivery',
    'track',
    'parcel',
    'download',
    'downloads',
  };
  static const _questionWords = {
    'what',
    'why',
    'how',
    'explain',
    'difference',
    'meaning',
    'mean',
    'define',
    'example',
    'steps',
  };

  Intent _intent(
    String q,
    Set<String> w,
    bool hasCourse,
    AssistantContext ctx,
  ) {
    int score(Set<String> set) => w.where(set.contains).length;
    if (w.length <= 2 && score(_greetWords) > 0) return Intent.greeting;
    if (q.contains('what can you do')) return Intent.greeting;

    final scores = <Intent, int>{
      Intent.certificate: score(_certWords) * 3,
      Intent.orders: score(_orderWords) * 2,
      Intent.payment: score(_paymentWords) * 2,
      Intent.progress: score(_progressWords) * 2,
      Intent.price: score(_priceWords) * 2,
      Intent.recommend: score(_recommendWords),
    };
    // "pay for <course>" or "buy <course>" is a purchase request.
    if (hasCourse &&
        (w.contains('pay') ||
            w.contains('buy') ||
            w.contains('purchase') ||
            w.contains('enrol') ||
            w.contains('enroll'))) {
      return Intent.recommend;
    }
    // "how much did I pay" is about payments, not prices.
    if (scores[Intent.payment]! > 0 &&
        (w.contains('i') || w.contains('my') || w.contains('so'))) {
      scores[Intent.payment] = scores[Intent.payment]! + 2;
    }
    // "my progress", "my courses": personal words lift the personal intents.
    if (w.contains('my')) {
      scores[Intent.progress] = scores[Intent.progress]! + 1;
    }
    final best = scores.entries.reduce((a, b) => b.value > a.value ? b : a);

    // A concept question that matches the course material beats a weak
    // keyword hit, e.g. "what is a boundary" or "how does delegation work".
    final concept = w.any(_questionWords.contains) && !w.contains('my');
    if (concept && best.value < 4) {
      final top = ctx.knowledge.search(q, limit: 1);
      if (top.isNotEmpty && top.first.score > 2.5) return Intent.doubt;
    }
    if (best.value == 0) return Intent.doubt;
    return best.key;
  }

  Course? _mentionedCourse(String q, List<Course> courses) {
    Course? best;
    var bestRatio = 0.0;
    final qt = tokenize(q).toSet();
    for (final c in courses) {
      final tt = tokenize(c.title).toSet();
      if (tt.isEmpty) continue;
      if (q.contains(c.title.toLowerCase())) return c;
      final ratio = tt.where(qt.contains).length / tt.length;
      if (ratio > bestRatio) {
        bestRatio = ratio;
        best = c;
      }
    }
    return bestRatio >= 0.67 ? best : null;
  }

  // ---- replies

  AssistantReply _greeting(AssistantContext ctx) {
    final name = ctx.user?.firstName;
    return AssistantReply('greeting', [
      TextBlock(
        '${name == null ? 'Hello' : 'Hello, $name'}. I can show your course '
        'progress, your payments and orders, courses you can add, and answer '
        'questions about what is taught in the courses. What would you like to know?',
      ),
      const SuggestionsBlock(_startQuestions),
    ]);
  }

  AssistantReply _needSignIn(String what) => AssistantReply('signin', [
    TextBlock(
      'To show $what I need you to sign in first. Your records stay private to your account.',
    ),
    const SignInBlock(),
  ]);

  AssistantReply _progress(AssistantContext ctx, Course? only) {
    var items = <ProgressItem>[];
    for (final e in ctx.enrolments.values) {
      final c = _course(ctx, e.courseId);
      if (c == null) continue;
      if (only != null && c.id != only.id) continue;
      final done = c.modules
          .where((m) => e.completedModuleIds.contains(m.id))
          .length;
      final next = c.modules
          .where((m) => !e.completedModuleIds.contains(m.id))
          .firstOrNull;
      final cert = ctx.certificates
          .where((x) => x.courseId == c.id)
          .firstOrNull;
      items.add(
        ProgressItem(
          course: c,
          done: done,
          total: c.modules.length,
          nextLesson: next?.title,
          certificateCode: cert?.code,
        ),
      );
    }
    items.sort((a, b) => b.progress.compareTo(a.progress));
    if (items.isEmpty) {
      return AssistantReply('progress', [
        TextBlock(
          only == null
              ? 'You are not on any course yet. Ask me which courses you can add and I will show the ones that fit your pathway.'
              : 'You are not enrolled on ${only.title} yet.',
        ),
        const SuggestionsBlock(['Which courses can I add?']),
      ]);
    }
    final block = ProgressBlock(items);
    final assigned = ctx.assigned
        .where((a) => !ctx.enrolments.containsKey(a.courseId))
        .length;
    return AssistantReply('progress', [
      TextBlock(
        'You are on ${items.length} course${items.length == 1 ? '' : 's'}, '
        '${block.completed} finished, with ${(block.average * 100).round()}% done on average.'
        '${assigned > 0 ? ' Your employer has also assigned $assigned course${assigned == 1 ? '' : 's'} you have not started.' : ''}',
      ),
      block,
      const SuggestionsBlock([
        'What have I paid so far?',
        'Which courses can I add?',
      ]),
    ]);
  }

  AssistantReply _payment(
    AssistantContext ctx,
    Course? only, {
    required bool orders,
  }) {
    final list = <PaymentItem>[];
    for (final o in ctx.orders) {
      if (only != null && !o.items.any((i) => i.id == only.id)) continue;
      list.add(
        PaymentItem(
          number: o.number,
          date: o.createdAt,
          summary: o.items
              .map((i) => i.quantity > 1 ? '${i.name} x${i.quantity}' : i.name)
              .join(', '),
          amount: o.total,
        ),
      );
    }
    list.sort(
      (a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)),
    );
    final free = ctx.enrolments.values
        .where((e) => e.accessType == 'granted')
        .length;
    final seats = ctx.enrolments.values
        .where((e) => e.accessType == 'assignment')
        .length;
    if (list.isEmpty) {
      return AssistantReply('payment', [
        TextBlock(
          'I cannot see any payments on your account yet.'
          '${free > 0 ? ' You have free access to $free course${free == 1 ? '' : 's'} added by the team.' : ''}'
          '${seats > 0 ? ' $seats course${seats == 1 ? ' is' : 's are'} covered by an employer seat.' : ''}',
        ),
        const SuggestionsBlock(['Which courses can I add?']),
      ]);
    }
    final block = PaymentBlock(
      title: orders ? 'Your orders' : 'Your payments',
      items: list,
    );
    return AssistantReply(orders ? 'orders' : 'payment', [
      TextBlock(
        'You have paid £${block.total.toStringAsFixed(2)} across ${list.length} order${list.length == 1 ? '' : 's'}. '
        'Payments here run in test mode, so no real card was charged.'
        '${free > 0 ? ' $free course${free == 1 ? ' was' : 's were'} added for free by the team.' : ''}'
        '${seats > 0 ? ' $seats ${seats == 1 ? 'is' : 'are'} covered by an employer seat.' : ''}',
      ),
      block,
      const SuggestionsBlock([
        'How am I doing in my courses?',
        'Which courses can I add?',
      ]),
    ]);
  }

  AssistantReply _certificates(AssistantContext ctx) {
    if (ctx.certificates.isEmpty) {
      final nearly =
          ctx.enrolments.values
              .map((e) => (e, _course(ctx, e.courseId)))
              .where((p) => p.$2 != null && p.$1.progressIn(p.$2!) < 1)
              .toList()
            ..sort(
              (a, b) =>
                  b.$1.progressIn(b.$2!).compareTo(a.$1.progressIn(a.$2!)),
            );
      return AssistantReply('certificate', [
        TextBlock(
          nearly.isEmpty
              ? 'You have no certificates yet. Finish a course and press Finish course on the last lesson to receive one.'
              : 'You have no certificates yet. The closest is ${nearly.first.$2!.title}, '
                    'which is ${(nearly.first.$1.progressIn(nearly.first.$2!) * 100).round()}% done.',
        ),
        const SuggestionsBlock(['How am I doing in my courses?']),
      ]);
    }
    return AssistantReply('certificate', [
      TextBlock(
        'You have ${ctx.certificates.length} certificate${ctx.certificates.length == 1 ? '' : 's'}.',
      ),
      CertificatesBlock([
        for (final c in ctx.certificates)
          CertificateItem(c.code, c.courseTitle, c.issuedAt),
      ]),
    ]);
  }

  AssistantReply _price(AssistantContext ctx, Course? course) {
    final list = course != null ? [course] : ctx.courses.take(4).toList();
    return AssistantReply('price', [
      TextBlock(
        course != null
            ? '${course.title} costs £${course.price.toStringAsFixed(0)}. Employers can buy seats for their team instead.'
            : 'Here are some course prices. Ask about a course by name for its own price.',
      ),
      CoursesBlock([for (final c in list) _suggestion(ctx, c)]),
    ]);
  }

  AssistantReply _recommend(AssistantContext ctx, Course? course, String q) {
    if (course != null) {
      final s = _suggestion(ctx, course);
      return AssistantReply('recommend', [
        TextBlock(
          s.enrolled
              ? 'You are already on ${course.title}. Open it from My learning.'
              : s.canBuy
              ? '${course.title} costs £${course.price.toStringAsFixed(0)}. Press Add to cart and pay to go to checkout. Payments are in test mode.'
              : '${course.title} is outside your learning pathway. ${s.reason}',
        ),
        CoursesBlock([s]),
      ]);
    }
    final owned = ctx.enrolments.keys.toSet();
    final all = ctx.courses.where((c) => !owned.contains(c.id)).toList();
    final fit = [
      for (final c in all)
        if (ctx.user == null || ctx.user!.canEnrol(c)) c,
    ];
    final shown = (fit.isNotEmpty ? fit : all).take(4).toList();
    if (shown.isEmpty) {
      return AssistantReply('recommend', [
        const TextBlock(
          'You are already on every course available. Well done.',
        ),
      ]);
    }
    return AssistantReply('recommend', [
      TextBlock(
        ctx.signedIn && fit.isNotEmpty
            ? 'These courses fit your learning pathway and you have not started them. Pick one to add and pay.'
            : ctx.signedIn
            ? 'Nothing else fits your pathway right now. These are the other courses; you can change your pathway in your profile.'
            : 'These are some of our courses. Sign in to see the ones that fit your pathway.',
      ),
      CoursesBlock([for (final c in shown) _suggestion(ctx, c)]),
    ]);
  }

  AssistantReply _doubt(String query, AssistantContext ctx, Course? mentioned) {
    final boost = <String, double>{
      for (final id in ctx.enrolments.keys) id: 1.25,
      if (mentioned != null) mentioned.id: 1.8,
    };
    final hits = ctx.knowledge.search(query, limit: 3, boost: boost);
    if (hits.isEmpty || hits.first.score < 1.2) {
      return AssistantReply('doubt', [
        const TextBlock(
          'I could not find that in the course material. Try different words, '
          'or ask about a lesson by name. For anything else, your trainer can help.',
        ),
        const SuggestionsBlock(_startQuestions),
      ]);
    }
    final top = hits.first.passage;
    final course = _course(ctx, top.courseId);
    return AssistantReply('doubt', [
      const TextBlock('Here is what the course material says:'),
      AnswerBlock(
        passage: top,
        excerpt: KnowledgeBase.excerpt(top, query),
        courseTitle: course?.title ?? 'Course material',
        related: [for (final h in hits.skip(1)) h.passage],
      ),
    ]);
  }

  // ---- helpers

  Course? _course(AssistantContext ctx, String id) {
    for (final c in ctx.courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  CourseSuggestion _suggestion(AssistantContext ctx, Course c) {
    final enrolled = ctx.enrolments.containsKey(c.id);
    final u = ctx.user;
    if (enrolled) {
      return CourseSuggestion(
        course: c,
        reason: 'You are already on this course.',
        enrolled: true,
        canBuy: false,
      );
    }
    if (u == null) {
      return CourseSuggestion(
        course: c,
        reason: 'Sign in to see if it fits your pathway.',
      );
    }
    final e = u.eligibilityFor(c);
    return CourseSuggestion(
      course: c,
      reason: eligibilityMessage(e, u),
      canBuy: e == Eligibility.eligible,
    );
  }
}
