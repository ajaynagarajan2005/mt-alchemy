import '../models/article.dart';

final articles = <Article>[
  Article(
    slug: 'why-team-away-days-fade',
    title: 'Why team away days fade by Wednesday',
    category: 'Team Engagement',
    readMinutes: 5,
    published: DateTime(2026, 9, 22),
    excerpt: 'The energy of an away day rarely survives the first full inbox. Here is how to make it last.',
    body: [
      'Most teams come back from an away day feeling closer and clearer. By the following '
          'Wednesday, most of that has gone. The problem is rarely the day itself.',
      'What fades is anything that was not turned into a habit. Agreements written on '
          'flipcharts need an owner, a date and a place they will be seen again.',
      'Before your next away day, decide which one or two rituals you want the team to keep, '
          'and plan the first three repetitions before anyone leaves the room.',
    ],
  ),
  Article(
    slug: 'feedback-is-a-skill',
    title: 'Feedback is a skill, not a personality trait',
    category: 'Leadership',
    readMinutes: 4,
    published: DateTime(2026, 9, 8),
    excerpt: 'Good feedback givers are made, not born. Three habits that make the difference.',
    body: [
      'We often describe people as naturally good at feedback. In our experience, the people '
          'who are good at it have simply practised more.',
      'Three habits make the biggest difference: describe behaviour rather than character, '
          'explain the impact, and ask what the other person sees.',
      'Practise these in low-stakes conversations first so they are available when it matters.',
    ],
  ),
  Article(
    slug: 'wellbeing-starts-with-workload',
    title: 'Well-being starts with workload',
    category: 'Well-being',
    readMinutes: 6,
    published: DateTime(2026, 8, 25),
    excerpt:
        'Resilience training cannot fix a job that does not fit in the week.',
    body: [
      'Well-being programmes often focus on helping people cope. That matters, but it is only '
          'half the picture.',
      'If a role reliably needs fifty hours a week, the most effective well-being intervention '
          'is a conversation about priorities, not a breathing exercise.',
      'Start with a simple workload review in each team and act on what you find.',
    ],
  ),
  Article(
    slug: 'naming-emotions-at-work',
    title: 'The surprising power of naming emotions at work',
    category: 'Emotional Intelligence',
    readMinutes: 4,
    published: DateTime(2026, 8, 11),
    excerpt: 'Putting a feeling into words takes some of its heat away. Here is how to use that.',
    body: [
      'Research on affect labelling suggests that naming a feeling can reduce its intensity. '
          'At work, that gives us a simple, practical tool.',
      'Try adding a feelings check to the start of difficult meetings. One word each is enough.',
      'Over time the team builds a shared vocabulary that makes hard conversations easier.',
    ],
  ),
];

Article? articleBySlug(String slug) {
  for (final a in articles) {
    if (a.slug == slug) return a;
  }
  return null;
}

/// Sample testimonials (illustrative content for the prototype).
const testimonials = <Testimonial>[
  Testimonial(
    quote:
        'Our managers stopped avoiding the hard conversations. You can feel the difference '
        'in every team meeting.',
    name: 'Helen Marsh',
    role: 'Head of People, regional housing association',
  ),
  Testimonial(
    quote: 'It was the first leadership programme where people kept using the tools months later.',
    name: 'Rajesh Patel',
    role: 'Operations Director, logistics firm',
  ),
  Testimonial(
    quote: 'Practical, warm and honest. Our team charter is still on the wall and still used.',
    name: 'Siobhan Kelly',
    role: 'Team Lead, public health service',
  ),
];
