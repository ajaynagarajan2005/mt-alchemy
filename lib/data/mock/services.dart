import '../models/service.dart';

const services = <Service>[
  Service(
    slug: 'emotional-intelligence',
    title: 'Emotional Intelligence',
    short: 'Notice, name and work with emotion at work.',
    summary:
        'Practical programmes that help people read themselves and others more accurately, '
        'stay steady under pressure and have the conversations they have been avoiding.',
    outcomes: [
      'Clearer self-awareness and fewer reactive moments',
      'Better quality feedback conversations',
      'A shared language for emotion across the team',
    ],
    formats: ['Half-day workshop', 'Four-week cohort', '1:1 coaching'],
  ),
  Service(
    slug: 'leadership-development',
    title: 'Leadership Development',
    short: 'Grow leaders people actually want to follow.',
    summary:
        'From first-time managers to senior teams, we build the habits behind trusted leadership: '
        'clarity, care, decision making and holding others to account without losing them.',
    outcomes: [
      'Confident first-line managers within one quarter',
      'Leadership behaviours tied to your values',
      'Peer learning groups that keep going after we leave',
    ],
    formats: ['Leadership pathway', 'Executive team offsite', '1:1 coaching'],
  ),
  Service(
    slug: 'team-engagement',
    title: 'Team Engagement',
    short: 'Turn a group of people into a team.',
    summary:
        'Facilitated sessions that rebuild trust, sort out how work really gets done and give '
        'teams rituals they keep using. Not activities for the sake of it.',
    outcomes: [
      'Agreed team charter and ways of working',
      'Healthier conflict and faster decisions',
      'Engagement actions owned by the team, not HR',
    ],
    formats: ['Team diagnostic', 'Away day', 'Quarterly pulse sessions'],
  ),
  Service(
    slug: 'workplace-wellbeing',
    title: 'Workplace Well-being',
    short: 'Sustainable performance without burning people out.',
    summary:
        'Evidence-informed well-being work that looks at workload, boundaries and psychological '
        'safety, so support is part of how the organisation runs rather than an app nobody opens.',
    outcomes: [
      'Managers who spot and support early signs of strain',
      'Practical boundaries and recovery habits',
      'A well-being plan linked to real workload data',
    ],
    formats: ['Manager briefing', 'Well-being audit', 'Resilience series'],
  ),
];

Service? serviceBySlug(String slug) {
  for (final s in services) {
    if (s.slug == slug) return s;
  }
  return null;
}
