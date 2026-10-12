import '../models/product.dart';

const products = <Product>[
  Product(
    id: 'feedback-conversation-cards',
    stock: 120,
    name: 'Feedback Conversation Cards',
    category: ProductCategory.cards,
    price: 24,
    summary: '52 prompts for honest, useful feedback conversations.',
    description:
        'A deck of prompts that help managers and peers start feedback conversations '
        'without the awkwardness. Use one card per one-to-one or work through a set in a team '
        'session.',
    details: [
      '52 cards in a recycled box',
      'Facilitator guide included',
      'Ships in 2 to 3 days',
    ],
  ),
  Product(
    id: 'ei-self-coaching-toolkit',
    type: ProductType.digital,
    fileUrl: '/downloads/ei-self-coaching-toolkit.pdf',
    name: 'EI Self-Coaching Toolkit',
    category: ProductCategory.toolkit,
    price: 39,
    summary: 'A six-week workbook for building emotional intelligence.',
    description:
        'A guided workbook with weekly reflections, trigger maps and practice routines '
        'drawn from our Emotional Intelligence programmes.',
    details: [
      '120-page workbook',
      'Printable trigger map',
      'Six weekly practice routines',
    ],
  ),
  Product(
    id: 'team-charter-workshop-kit',
    stock: 35,
    name: 'Team Charter Workshop Kit',
    category: ProductCategory.workshop,
    price: 89,
    summary: 'Everything you need to run a two-hour team charter session.',
    description:
        'A ready-to-run kit with a facilitator script, slides, canvas posters and '
        'follow-up templates so your team leaves with a charter they wrote themselves.',
    details: [
      'Facilitator script and slides',
      'A1 charter canvas x2',
      'Follow-up templates',
    ],
  ),
  Product(
    id: 'leading-with-care-book',
    stock: 80,
    name: 'Leading With Care',
    category: ProductCategory.book,
    price: 18,
    summary: 'Short essays on leadership that keeps people at the centre.',
    description:
        'A collection of short, practical essays from the MT Alchemy team on '
        'leadership, accountability and care. Easy to read between meetings.',
    details: [
      'Paperback, 180 pages',
      'Discussion questions per chapter',
      'Ships in 2 to 3 days',
    ],
  ),
  Product(
    id: 'wellbeing-check-in-deck',
    stock: 60,
    name: 'Well-being Check-in Deck',
    category: ProductCategory.cards,
    price: 22,
    summary: 'Gentle prompts for team well-being check-ins.',
    description:
        'Forty prompts that make it easier for teams to talk about energy, workload '
        'and support in a safe, light-touch way.',
    details: ['40 cards', 'Guidance for managers', 'Suitable for remote teams'],
  ),
  Product(
    id: 'manager-one-to-one-planner',
    type: ProductType.digital,
    fileUrl: '/downloads/manager-one-to-one-planner.pdf',
    name: 'Manager One-to-One Planner',
    category: ProductCategory.toolkit,
    price: 29,
    summary: 'A twelve-month planner for better one-to-ones.',
    description:
        'A structured planner that keeps one-to-ones focused on the other person, '
        'with space for goals, notes and follow-ups for up to eight team members.',
    details: [
      'Hardback planner',
      'Pages for 8 team members',
      'Quarterly review prompts',
    ],
  ),
];

Product? productById(String id) {
  for (final p in products) {
    if (p.id == id) return p;
  }
  return null;
}
