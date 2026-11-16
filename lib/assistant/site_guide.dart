import '../data/mock/founders.dart';
import '../data/mock/services.dart';
import '../data/models/article.dart';
import '../data/models/product.dart';
import '../router/routes.dart';
import '../state/cart_store.dart';

/// A button in a chat answer that opens a page.
class SiteLink {
  const SiteLink(this.label, this.path);
  final String label;
  final String path;
}

/// What the guide knows about the live catalogue when it answers.
class SiteFacts {
  const SiteFacts({
    this.products = const [],
    this.articles = const [],
    this.signedIn = false,
  });
  final List<Product> products;
  final List<Article> articles;
  final bool signedIn;
}

/// One answer from the guide: text, then buttons to the right pages.
class SiteAnswer {
  const SiteAnswer(this.text, this.links, {this.followUps = const []});
  final String text;
  final List<SiteLink> links;
  final List<String> followUps;
}

/// A question about the website or the company, rather than about course
/// content or the user's own records.
class SiteTopic {
  const SiteTopic({
    required this.id,
    required this.words,
    this.phrases = const [],
    required this.answer,
  });

  final String id;

  /// Single words that point at this topic. Each one found scores 2.
  final Set<String> words;

  /// Phrases that point at it strongly. Each one found scores 4.
  final List<String> phrases;
  final SiteAnswer Function(SiteFacts facts) answer;

  int score(String q, Set<String> w) {
    final hits =
        w.where(words.contains).length * 2 +
        phrases.where(q.contains).length * 4;
    // "your email", "do you offer", "contact us": a site word in a question
    // put to the company is about the site, not the course material.
    const toUs = {'you', 'your', 'us', 'our', 'site', 'website'};
    return hits > 0 && w.any(toUs.contains) ? hits + 2 : hits;
  }
}

String _money(double v) =>
    '£${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}';

String _list(List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}

const _email = 'hello@mtalchemy.co.uk';
const _phone = '+44 20 7946 0123';

/// Every topic the guide can answer. The order breaks ties.
final siteTopics = <SiteTopic>[
  SiteTopic(
    id: 'contact',
    words: {
      'contact',
      'email',
      'phone',
      'call',
      'reach',
      'telephone',
      'number',
      'address',
      'located',
      'location',
      'office',
      'speak',
      'talk',
      'whatsapp',
    },
    phrases: [
      'get in touch',
      'where are you',
      'book a call',
      'talk to someone',
      'speak to someone',
      'customer service',
      'customer support',
    ],
    answer: (_) => const SiteAnswer(
      'You can reach the MT Alchemy team by email at $_email or by phone on '
      '$_phone. We are based in the UK and work both remotely and on site. '
      'The Contact page has a form if you would rather write to us, and we '
      'reply within two working days.',
      [SiteLink('Open the Contact page', Routes.contact)],
      followUps: [
        'What services do you offer?',
        'Do you work with organisations?',
      ],
    ),
  ),
  SiteTopic(
    id: 'services',
    words: {
      'services',
      'service',
      'offer',
      'offering',
      'programmes',
      'programme',
      'programs',
      'program',
      'workshops',
      'workshop',
      'consultancy',
      'coaching',
      'provide',
    },
    phrases: ['what do you do', 'what does mt alchemy do', 'help my team'],
    answer: (_) => SiteAnswer(
      'MT Alchemy is a people development consultancy. We run four kinds of '
      'programme:\n'
      '${services.map((s) => '• ${s.title}: ${s.short} (${s.formats.join(', ')})').join('\n')}\n'
      'Each one can be a workshop, a cohort or one-to-one coaching, and you '
      'can also learn on your own through our online courses.',
      [
        const SiteLink('See all services', Routes.services),
        const SiteLink('Browse online courses', Routes.upskilling),
      ],
      followUps: const [
        'Do you work with organisations?',
        'How do I contact you?',
      ],
    ),
  ),
  SiteTopic(
    id: 'about',
    words: {
      'company',
      'founders',
      'founder',
      'founded',
      'owner',
      'owns',
      'mission',
      'alchemy',
    },
    phrases: [
      'who are you',
      'about you',
      'about mt alchemy',
      'about the company',
      'who runs',
      'who founded',
      'who owns',
      'who made',
      'who created',
    ],
    answer: (_) => SiteAnswer(
      'MT Alchemy is a people development consultancy: we shift mindsets, '
      'behaviours and team culture through emotional intelligence, leadership '
      'and well-being programmes. The platform was founded by '
      '${_list([for (final f in founders) f.name])}. The About page has our '
      'story, values and team.',
      const [SiteLink('Open the About page', Routes.about)],
      followUps: const ['What services do you offer?'],
    ),
  ),
  SiteTopic(
    id: 'store',
    words: {
      'store',
      'shop',
      'products',
      'product',
      'toolkit',
      'toolkits',
      'books',
      'book',
      'cards',
      'deck',
      'kit',
      'kits',
      'planner',
      'merchandise',
      'sell',
    },
    phrases: ['what do you sell', 'what can i buy'],
    answer: (f) {
      final items = f.products.take(6).toList();
      return SiteAnswer(
        items.isEmpty
            ? 'The Store sells toolkits, card decks, books and workshop kits.'
            : 'The Store has ${f.products.length} products, for example:\n'
                  '${items.map((p) => '• ${p.name}: ${_money(p.price)} (${p.type == ProductType.digital ? 'digital download' : 'shipped to you'})').join('\n')}\n'
                  'Digital products appear in Portal › My downloads straight after payment.',
        const [SiteLink('Open the Store', Routes.store)],
        followUps: const ['How much is shipping?'],
      );
    },
  ),
  SiteTopic(
    id: 'shipping',
    words: {
      'shipping',
      'postage',
      'ship',
      'deliver',
      'delivery',
      'dispatch',
      'arrive',
      'returns',
      'return',
      'refund',
      'refunds',
      'cancel',
      'exchange',
    },
    phrases: [
      'how much is shipping',
      'how much is delivery',
      'shipping cost',
      'cost of shipping',
      'shipping fee',
      'shipping charge',
      'delivery cost',
      'delivery charge',
      'delivery fee',
      'free shipping',
      'free delivery',
      'how long does delivery',
      'how long does shipping',
      'how long will it take',
      'return policy',
      'refund policy',
      'get a refund',
      'money back',
    ],
    answer: (_) => SiteAnswer(
      'Shipping is a flat ${_money(CartStore.shippingFlat)} and free on orders '
      'over ${_money(CartStore.freeShippingFrom)} of physical products. Courses '
      'and digital downloads never ship, so they have no shipping charge. You '
      'can follow each order in Portal › Orders: it moves from Processing to '
      'Shipped to Delivered, and you get a notification at each step. For a '
      'return or refund, email $_email with your order number.',
      const [
        SiteLink('My orders', Routes.myOrders),
        SiteLink('Contact us', Routes.contact),
      ],
    ),
  ),
  SiteTopic(
    id: 'checkout',
    words: {'checkout', 'secure', 'methods', 'method', 'paypal', 'visa'},
    phrases: [
      'how do i pay',
      'how can i pay',
      'payment method',
      'test card',
      'which card',
      'what card',
      'pay by',
    ],
    answer: (_) => const SiteAnswer(
      'Add a course or product to your cart, then press Checkout. Payments on '
      'this site run in test mode, so no real money is taken: use the card '
      'number 4242 4242 4242 4242 with any future expiry date and any '
      'three-digit CVC.',
      [SiteLink('Open my cart', Routes.cart)],
    ),
  ),
  SiteTopic(
    id: 'account',
    words: {
      'register',
      'signup',
      'login',
      'logout',
      'password',
      'account',
      'forgot',
      'reset',
      'username',
      'profile',
    },
    phrases: [
      'sign up',
      'sign in',
      'log in',
      'log out',
      'sign out',
      'create an account',
      'make an account',
    ],
    answer: (f) => SiteAnswer(
      f.signedIn
          ? 'You are signed in. Your profile, courses, orders, downloads and '
                'certificates are all in your Portal. To change your password, '
                'sign out and use Forgot password on the sign-in page.'
          : 'Press Sign in at the top right. New here? Choose Create an account '
                'and register as an individual learner or as an organisation. '
                'Forgot your password? Type your email on the sign-in page and '
                'press Forgot password: a reset link is emailed to you.',
      f.signedIn
          ? const [
              SiteLink('Open my portal', Routes.portal),
              SiteLink('My profile', Routes.myProfile),
            ]
          : const [
              SiteLink('Sign in', Routes.login),
              SiteLink('Create an account', Routes.register),
            ],
    ),
  ),
  SiteTopic(
    id: 'organisations',
    words: {
      'organisation',
      'organisations',
      'organization',
      'organizations',
      'employer',
      'employers',
      'corporate',
      'business',
      'businesses',
      'seats',
      'enquiry',
      'enquiries',
      'inquiry',
      'quote',
      'bespoke',
      'proposal',
      'staff',
      'employees',
    },
    phrases: ['for my team', 'for my company', 'train my team'],
    answer: (_) => const SiteAnswer(
      'Yes, we work with organisations. Send us an enquiry from the For '
      'organisations page and we will design a programme around your team. '
      'Employers can also register an organisation account, add employees, '
      'buy course seats, assign courses and follow everyone\'s progress in '
      'reports and charts.',
      [
        SiteLink('For organisations', Routes.organisations),
        SiteLink('Register an organisation', Routes.register),
      ],
    ),
  ),
  SiteTopic(
    id: 'assessment',
    words: {'assessment', 'eq', 'eqi'},
    phrases: [
      'test my',
      'measure my',
      'emotional intelligence test',
      'eq test',
      'self assessment',
      'self-assessment',
    ],
    answer: (_) => const SiteAnswer(
      'Try our free EQ self-assessment: ten short statements, one at a time, '
      'and you get a profile across the areas of emotional intelligence with a '
      'course matched to it. Anyone can take it; if you are signed in, your '
      'result is saved.',
      [SiteLink('Take the EQ self-assessment', Routes.assessment)],
    ),
  ),
  SiteTopic(
    id: 'insights',
    words: {'insights', 'articles', 'article', 'blog', 'news', 'posts'},
    answer: (f) => SiteAnswer(
      f.articles.isEmpty
          ? 'The Insights page has short articles on teams, feedback and well-being.'
          : 'Our latest articles:\n'
                '${f.articles.take(4).map((a) => '• ${a.title}').join('\n')}',
      const [SiteLink('Open Insights', Routes.insights)],
    ),
  ),
  SiteTopic(
    id: 'tour',
    words: {'tour', 'virtual', '360', 'walkthrough'},
    answer: (_) => const SiteAnswer(
      'The virtual tour is a short explainer film, then one card for each part '
      'of the site so you can try it yourself.',
      [SiteLink('Start the virtual tour', Routes.tour)],
    ),
  ),
  SiteTopic(
    id: 'display',
    words: {
      'dark',
      'theme',
      'bigger',
      'smaller',
      'font',
      'accessibility',
      'zoom',
    },
    phrases: ['text size', 'night mode', 'light mode'],
    answer: (_) => const SiteAnswer(
      'Use the buttons at the top right of every page: the moon switches '
      'between light and dark mode, and the Tт button changes the text size. '
      'Both are remembered next time you visit.',
      [],
    ),
  ),
];

/// The best topic for [q], or null when no topic scores at least [min].
(SiteTopic, int)? matchSiteTopic(String q, Set<String> w, {int min = 2}) {
  SiteTopic? best;
  var bestScore = 0;
  for (final t in siteTopics) {
    final s = t.score(q, w);
    if (s > bestScore) {
      best = t;
      bestScore = s;
    }
  }
  if (best == null || bestScore < min) return null;
  return (best, bestScore);
}
