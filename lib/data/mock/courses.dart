import '../models/course.dart';

const courses = <Course>[
  Course(
    id: 'ei-foundations',
    title: 'Emotional Intelligence Foundations',
    serviceSlug: 'emotional-intelligence',
    level: CourseLevel.foundation,
    price: 149,
    summary:
        'Build self-awareness and learn to respond rather than react at work.',
    outcomes: [
      'Recognise your own emotional patterns',
      'Use a simple pause routine under pressure',
      'Read the room in meetings more accurately',
    ],
    trainer: 'Maya Thompson',
    modules: [
      CourseModule(
        id: 'ei-1',
        title: 'What emotional intelligence is (and is not)',
        minutes: 18,
        body:
            'Emotional intelligence is the ability to notice emotion, understand what it is '
            'telling you and choose a useful response. It is a skill, not a personality type, '
            'which means it can be practised and improved.',
      ),
      CourseModule(
        id: 'ei-2',
        title: 'Mapping your triggers',
        minutes: 24,
        body:
            'Most reactive moments follow a pattern. In this module you will map the '
            'situations, people and times of day that tend to pull you off balance.',
      ),
      CourseModule(
        id: 'ei-3',
        title: 'The ninety second pause',
        minutes: 15,
        body:
            'A short, repeatable routine for the gap between a trigger and your response: '
            'breathe, name the feeling, decide the next useful step.',
      ),
      CourseModule(
        id: 'ei-4',
        title: 'Reading the room',
        minutes: 21,
        body:
            'Practise noticing the signals other people give off in meetings and adjust how '
            'you contribute so your point lands.',
      ),
    ],
  ),
  Course(
    id: 'first-time-manager',
    title: 'The First-Time Manager',
    serviceSlug: 'leadership-development',
    level: CourseLevel.practitioner,
    price: 249,
    summary: 'The conversations, habits and boundaries that make the first year of managing work.',
    outcomes: [
      'Run one-to-ones people find useful',
      'Delegate without disappearing',
      'Give feedback that changes behaviour',
    ],
    trainer: 'Daniel Okafor',
    modules: [
      CourseModule(
        id: 'ftm-1',
        title: 'From doing the work to leading it',
        minutes: 20,
        body:
            'The shift from individual contributor to manager is mostly about where you '
            'spend your attention. We look at what to let go of first.',
      ),
      CourseModule(
        id: 'ftm-2',
        title: 'One-to-ones that matter',
        minutes: 26,
        body:
            'A simple structure for weekly one-to-ones that puts the other person first and '
            'surfaces problems early.',
      ),
      CourseModule(
        id: 'ftm-3',
        title: 'Delegation without disappearing',
        minutes: 22,
        body:
            'Match the level of support to the person and the task, and agree check-ins '
            'before you hand anything over.',
      ),
      CourseModule(
        id: 'ftm-4',
        title: 'Feedback that lands',
        minutes: 25,
        body:
            'Describe the behaviour, its impact and what you would like instead. Then stop '
            'talking and listen.',
      ),
    ],
  ),
  Course(
    id: 'leading-through-change',
    title: 'Leading Through Change',
    serviceSlug: 'leadership-development',
    level: CourseLevel.leader,
    price: 329,
    summary: 'Help your team understand, shape and commit to change instead of enduring it.',
    outcomes: [
      'Explain the why of a change in plain language',
      'Spot and address resistance early',
      'Keep momentum after the launch',
    ],
    trainer: 'Maya Thompson',
    modules: [
      CourseModule(
        id: 'ltc-1',
        title: 'Why people resist change',
        minutes: 19,
        body:
            'Resistance is usually information. We look at the losses people expect and how '
            'to talk about them honestly.',
      ),
      CourseModule(
        id: 'ltc-2',
        title: 'The change story',
        minutes: 23,
        body:
            'Write a short, honest narrative that covers where we are, where we are going and '
            'what will not change.',
      ),
      CourseModule(
        id: 'ltc-3',
        title: 'Keeping momentum',
        minutes: 17,
        body:
            'Most change efforts fade after launch. Build small rituals that keep progress '
            'visible.',
      ),
    ],
  ),
  Course(
    id: 'team-trust-reset',
    title: 'Team Trust Reset',
    serviceSlug: 'team-engagement',
    level: CourseLevel.practitioner,
    price: 189,
    summary: 'Tools for team leads to rebuild trust and agree how the team works together.',
    outcomes: [
      'Run a team charter session',
      'Name and work through team tensions',
      'Set up a monthly team health check',
    ],
    trainer: 'Daniel Okafor',
    modules: [
      CourseModule(
        id: 'ttr-1',
        title: 'What trust looks like in practice',
        minutes: 16,
        body:
            'Trust shows up in small behaviours: following through, admitting mistakes and '
            'asking for help. We make those visible.',
      ),
      CourseModule(
        id: 'ttr-2',
        title: 'Writing a team charter',
        minutes: 28,
        body:
            'A one-page agreement on how the team makes decisions, communicates and handles '
            'disagreement.',
      ),
      CourseModule(
        id: 'ttr-3',
        title: 'The monthly health check',
        minutes: 14,
        body:
            'Ten minutes a month to ask how the team is really doing, using five simple '
            'questions.',
      ),
    ],
  ),
  Course(
    id: 'sustainable-performance',
    title: 'Sustainable Performance',
    serviceSlug: 'workplace-wellbeing',
    level: CourseLevel.foundation,
    price: 129,
    summary: 'Practical habits for energy, focus and recovery during demanding seasons of work.',
    outcomes: [
      'Plan your week around energy, not just time',
      'Set boundaries you can keep',
      'Notice early signs of overload',
    ],
    trainer: 'Grace Whitfield',
    modules: [
      CourseModule(
        id: 'sp-1',
        title: 'Energy is the real resource',
        minutes: 17,
        body:
            'Time management only works if you have the energy to use the time. Track what '
            'gives and drains your energy for one week.',
      ),
      CourseModule(
        id: 'sp-2',
        title: 'Boundaries you can keep',
        minutes: 21,
        body:
            'Small, specific boundaries beat big promises. Choose one and tell your manager '
            'about it.',
      ),
      CourseModule(
        id: 'sp-3',
        title: 'Recognising overload early',
        minutes: 19,
        body:
            'Learn the physical, emotional and behavioural signs that you or a colleague are '
            'running on empty.',
      ),
    ],
  ),
  Course(
    id: 'manager-wellbeing-conversations',
    title: 'Well-being Conversations for Managers',
    serviceSlug: 'workplace-wellbeing',
    level: CourseLevel.practitioner,
    price: 179,
    summary: 'Start supportive conversations about well-being and know where your role ends.',
    outcomes: [
      'Open a well-being conversation with confidence',
      'Listen without trying to fix',
      'Signpost to the right support',
    ],
    trainer: 'Grace Whitfield',
    modules: [
      CourseModule(
        id: 'mwc-1',
        title: 'Opening the conversation',
        minutes: 18,
        body:
            'Simple, low-pressure ways to check in, and how to choose the right time and '
            'place.',
      ),
      CourseModule(
        id: 'mwc-2',
        title: 'Listening without fixing',
        minutes: 20,
        body:
            'Most people want to be heard before they want advice. Practise reflective '
            'listening.',
      ),
      CourseModule(
        id: 'mwc-3',
        title: 'Knowing your limits',
        minutes: 15,
        body:
            'You are a manager, not a therapist. Learn when and how to signpost to '
            'professional support.',
      ),
    ],
  ),
];

Course? courseById(String id) {
  for (final c in courses) {
    if (c.id == id) return c;
  }
  return null;
}
