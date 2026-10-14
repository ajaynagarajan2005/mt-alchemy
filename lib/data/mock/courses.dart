import '../models/course.dart';

const _baseCourses = <Course>[
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
  Course(
    id: 'ei-in-practice',
    title: 'Emotional Intelligence in Practice',
    serviceSlug: 'emotional-intelligence',
    level: CourseLevel.practitioner,
    price: 199,
    summary: 'Use emotional intelligence in real conversations: feedback, conflict and influence.',
    outcomes: [
      'Stay steady in a heated conversation',
      'Give feedback that lands without defensiveness',
      'Influence peers without positional power',
    ],
    trainer: 'Maya Thompson',
    modules: [
      CourseModule(
        id: 'eip-1',
        title: 'Emotions in everyday decisions',
        minutes: 16,
        body:
            'Every decision at work carries feeling. Learn to notice it early and use it as '
            'data instead of letting it steer you quietly.',
      ),
      CourseModule(
        id: 'eip-2',
        title: 'Feedback without the sting',
        minutes: 22,
        body:
            'A short structure for feedback that describes behaviour, names the impact and '
            'invites the other person into the solution.',
      ),
      CourseModule(
        id: 'eip-3',
        title: 'Working through conflict',
        minutes: 20,
        body:
            'Conflict is information about what people care about. Practise slowing a '
            'disagreement down until both sides feel heard.',
      ),
    ],
  ),
  Course(
    id: 'emotionally-intelligent-leader',
    title: 'The Emotionally Intelligent Leader',
    serviceSlug: 'emotional-intelligence',
    level: CourseLevel.leader,
    price: 349,
    summary: 'Shape the emotional climate of your organisation and lead others through pressure.',
    outcomes: [
      'Read and shape team climate deliberately',
      'Model calm under organisational pressure',
      'Coach managers to grow their own EI',
    ],
    trainer: 'Maya Thompson',
    modules: [
      CourseModule(
        id: 'eil-1',
        title: 'Leaders set the weather',
        minutes: 18,
        body:
            'How a leader shows up spreads through a team within days. Map the signals you '
            'send in meetings, messages and corridors.',
      ),
      CourseModule(
        id: 'eil-2',
        title: 'Leading under pressure',
        minutes: 24,
        body:
            'Routines that keep your judgement clear when the stakes rise, and how to make '
            'it safe for others to say they are struggling.',
      ),
      CourseModule(
        id: 'eil-3',
        title: 'Growing EI in your managers',
        minutes: 20,
        body:
            'Turn one-to-ones into coaching moments that build emotional intelligence across '
            'the layer of managers below you.',
      ),
    ],
  ),
  Course(
    id: 'leadership-essentials',
    title: 'Leadership Essentials',
    serviceSlug: 'leadership-development',
    level: CourseLevel.foundation,
    price: 139,
    summary: 'The habits of good leadership, whatever your title: ownership, clarity and trust.',
    outcomes: [
      'Take ownership without taking over',
      'Communicate a clear next step',
      'Build trust through small kept promises',
    ],
    trainer: 'Daniel Okafor',
    modules: [
      CourseModule(
        id: 'le-1',
        title: 'Leadership is a behaviour',
        minutes: 15,
        body:
            'You do not need a title to lead. Learn the behaviours people follow: noticing, '
            'deciding and following through.',
      ),
      CourseModule(
        id: 'le-2',
        title: 'Clarity beats charisma',
        minutes: 18,
        body:
            'Most confusion at work comes from unclear asks. Practise turning a vague request '
            'into a clear outcome, owner and date.',
      ),
      CourseModule(
        id: 'le-3',
        title: 'Earning trust',
        minutes: 17,
        body:
            'Trust grows from small, visible reliability. Build a simple habit of making and '
            'keeping commitments in public.',
      ),
    ],
  ),
  Course(
    id: 'team-foundations',
    title: 'Team Foundations',
    serviceSlug: 'team-engagement',
    level: CourseLevel.foundation,
    price: 119,
    summary: 'What makes a team work, and how to be the colleague everyone wants on theirs.',
    outcomes: [
      'Understand what healthy teams have in common',
      'Contribute well in meetings',
      'Raise concerns early and kindly',
    ],
    trainer: 'Priya Raman',
    modules: [
      CourseModule(
        id: 'tf-1',
        title: 'What great teams share',
        minutes: 14,
        body:
            'Psychological safety, clear goals and reliable follow-through. See what each '
            'looks like on an ordinary Tuesday.',
      ),
      CourseModule(
        id: 'tf-2',
        title: 'Meetings that matter',
        minutes: 18,
        body:
            'Simple ways any team member can make a meeting better: prepare, contribute, '
            'summarise and follow up.',
      ),
      CourseModule(
        id: 'tf-3',
        title: 'Speaking up',
        minutes: 16,
        body:
            'How to raise a concern so it is heard, and how to respond when a colleague '
            'raises one with you.',
      ),
    ],
  ),
  Course(
    id: 'high-performing-teams',
    title: 'Building High-Performing Teams',
    serviceSlug: 'team-engagement',
    level: CourseLevel.leader,
    price: 339,
    summary: 'Design the rhythms, roles and culture that let teams of teams perform and stay well.',
    outcomes: [
      'Diagnose what is holding a team back',
      'Design team rituals that stick',
      'Align several teams around shared goals',
    ],
    trainer: 'Priya Raman',
    modules: [
      CourseModule(
        id: 'hpt-1',
        title: 'Diagnosing a team',
        minutes: 20,
        body:
            'A quick health check across trust, clarity and energy, and how to share the '
            'results without blame.',
      ),
      CourseModule(
        id: 'hpt-2',
        title: 'Rituals that stick',
        minutes: 22,
        body:
            'Most team agreements fade by Wednesday. Design the few rituals that keep them '
            'alive week after week.',
      ),
      CourseModule(
        id: 'hpt-3',
        title: 'Teams of teams',
        minutes: 24,
        body:
            'Scaling engagement across departments: shared goals, clear interfaces and '
            'leaders who connect rather than control.',
      ),
    ],
  ),
  Course(
    id: 'wellbeing-strategy-for-leaders',
    title: 'Well-being Strategy for Leaders',
    serviceSlug: 'workplace-wellbeing',
    level: CourseLevel.leader,
    price: 319,
    summary: 'Make well-being part of how the organisation runs: workload, policy and measurement.',
    outcomes: [
      'Link well-being to workload and design of work',
      'Build a well-being plan with real measures',
      'Make support part of everyday management',
    ],
    trainer: 'Daniel Okafor',
    modules: [
      CourseModule(
        id: 'wsl-1',
        title: 'Beyond the wellness app',
        minutes: 18,
        body:
            'Why perks rarely move the needle, and where the real drivers of strain sit in '
            'how work is designed.',
      ),
      CourseModule(
        id: 'wsl-2',
        title: 'Measuring what matters',
        minutes: 22,
        body:
            'Choose a handful of measures, from workload data to pulse surveys, that show '
            'whether things are actually improving.',
      ),
      CourseModule(
        id: 'wsl-3',
        title: 'Policy into practice',
        minutes: 20,
        body:
            'Turn a well-being policy into the everyday habits of managers, with training, '
            'prompts and follow-up.',
      ),
    ],
  ),
];

/// Seed catalogue: every base course is rebuilt into three phases with an
/// introduction video, readings, a workbook where one exists, three quizzes
/// and a recap video, so the player shows every lesson type and progress is
/// visible phase by phase.
final courses = <Course>[for (final c in _baseCourses) _phased(c)];

const _workbooks = {
  'ei-foundations',
  'first-time-manager',
  'leading-through-change',
  'manager-wellbeing-conversations',
  'sustainable-performance',
  'team-trust-reset',
};

const _areaNames = {
  'emotional-intelligence': 'Emotional Intelligence',
  'leadership-development': 'Leadership Development',
  'team-engagement': 'Team Engagement',
  'workplace-wellbeing': 'Workplace Well-being',
};

const phaseOrientation = 'Phase 1: Orientation';
const phaseCore = 'Phase 2: Core skills';
const phaseApply = 'Phase 3: Put it to work';

/// Puts [correct] at a position that varies by [seed], so answers are not
/// always first.
QuizQuestion _question(
  String prompt,
  String correct,
  List<String> wrong,
  int seed,
) {
  final options = [...wrong.take(2)];
  final at = seed % 3;
  options.insert(at, correct);
  return QuizQuestion(prompt: prompt, options: options, answer: at);
}

/// Outcomes from other courses, used as believable wrong answers.
List<String> _otherOutcomes(Course c, int n) {
  final out = <String>[];
  for (final o in _baseCourses) {
    if (o.id == c.id) continue;
    out.add(o.outcomes[out.length % o.outcomes.length]);
    if (out.length >= n + 3) break;
  }
  return out;
}

List<QuizQuestion> _warmUpQuiz(Course c) {
  final others = _otherOutcomes(c, 6);
  final trainers = {for (final o in _baseCourses) o.trainer}.toList();
  return [
    for (var i = 0; i < c.outcomes.length && i < 3; i++)
      _question(
        'Which of these is something "${c.title}" helps you do?',
        c.outcomes[i],
        [others[(i * 2) % others.length], others[(i * 2 + 1) % others.length]],
        i + c.id.length,
      ),
    _question(
      'Who leads this course?',
      c.trainer,
      trainers.where((t) => t != c.trainer).take(2).toList(),
      c.id.length + 1,
    ),
  ];
}

List<QuizQuestion> _midQuiz(Course c) {
  final bank = _quizzes[c.id] ?? _quizzes['ei-foundations']!;
  final levels = CourseLevel.values.where((l) => l != c.level).toList();
  final areas = _areaNames.entries.where((e) => e.key != c.serviceSlug);
  return [
    ...bank.take(2),
    _question(
      'Which practice area does this course belong to?',
      _areaNames[c.serviceSlug] ?? 'Leadership Development',
      [for (final a in areas) a.value],
      c.id.length + 2,
    ),
    _question('This course is pitched at which level?', c.level.label, [
      for (final l in levels) l.label,
    ], c.id.length),
  ];
}

List<QuizQuestion> _finalQuiz(Course c) {
  final bank = _quizzes[c.id] ?? _quizzes['ei-foundations']!;
  final others = _otherOutcomes(c, 4);
  return [
    ...bank,
    _question('Which of these is an aim of this course?', c.outcomes.last, [
      others[0],
      others[1],
    ], c.id.length + 2),
  ];
}

Course _phased(Course c) {
  final b = c.modules;
  CourseModule at(int i, String phase) => b[i].copyWith(phase: phase);
  final modules = <CourseModule>[
    // Phase 1: Orientation
    CourseModule(
      id: '${c.id}-intro',
      title: 'Welcome: what this course will do for you',
      minutes: 4,
      body:
          '${c.trainer} introduces ${c.title}: what you will learn, how the three '
          'phases fit together and how to get the most from each lesson.',
      type: LessonType.video,
      mediaUrl: 'asset:assets/videos/courses/${c.id}-intro.mp4',
      phase: phaseOrientation,
    ),
    at(0, phaseOrientation),
    CourseModule(
      id: '${c.id}-q1',
      title: 'Warm-up quiz',
      minutes: 4,
      body: 'Four quick questions on what the course covers.',
      type: LessonType.quiz,
      quiz: _warmUpQuiz(c),
      phase: phaseOrientation,
    ),
    // Phase 2: Core skills
    at(1, phaseCore),
    if (_workbooks.contains(c.id))
      CourseModule(
        id: '${c.id}-workbook',
        title: 'Workbook: practise it on paper',
        minutes: 15,
        body:
            'Work through the exercises in the workbook. Save your answers; you '
            'will use them in the final phase.',
        type: LessonType.pdf,
        mediaUrl: '/downloads/${c.id}-workbook.pdf',
        phase: phaseCore,
      ),
    if (b.length > 2) at(2, phaseCore),
    CourseModule(
      id: '${c.id}-q2',
      title: 'Mid-course quiz',
      minutes: 6,
      body: 'Four questions to check the core ideas have landed.',
      type: LessonType.quiz,
      quiz: _midQuiz(c),
      phase: phaseCore,
    ),
    // Phase 3: Put it to work
    if (b.length > 3) at(3, phaseApply),
    CourseModule(
      id: '${c.id}-recap',
      title: 'Recap and next steps',
      minutes: 4,
      body:
          'A short recap of the outcomes you are aiming for and how to carry '
          'them into your week.',
      type: LessonType.video,
      mediaUrl: 'asset:assets/videos/courses/${c.id}-recap.mp4',
      phase: phaseApply,
    ),
    CourseModule(
      id: '${c.id}-plan',
      title: 'Your action plan',
      minutes: 10,
      body:
          'Pick one outcome and write what you will do differently in the next '
          'seven days:\n\n'
          '${[for (final o in c.outcomes) '• $o'].join('\n')}\n\n'
          'Choose a day, a situation and one person who can hold you to it.',
      phase: phaseApply,
    ),
    CourseModule(
      id: '${c.id}-quiz',
      title: 'Final quiz',
      minutes: 8,
      body: 'Answer every question. You need 70% to pass and unlock your certificate.',
      type: LessonType.quiz,
      quiz: _finalQuiz(c),
      phase: phaseApply,
    ),
  ];
  return c.copyWith(
    modules: modules,
    imageUrl: 'asset:assets/images/cards/course-${c.id}.webp',
  );
}

const _quizzes = <String, List<QuizQuestion>>{
  'ei-foundations': [
    QuizQuestion(
      prompt: 'Emotional intelligence is best described as...',
      options: [
        'A fixed personality trait',
        'A skill that can be practised',
        'Hiding your feelings at work',
      ],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'What comes first in the ninety second pause?',
      options: ['Breathe', 'Reply to the email', 'Explain your view'],
      answer: 0,
    ),
    QuizQuestion(
      prompt: 'Mapping triggers helps you to...',
      options: [
        'Avoid difficult people',
        'Spot patterns before you react',
        'Win arguments',
      ],
      answer: 1,
    ),
  ],
  'first-time-manager': [
    QuizQuestion(
      prompt: 'The most useful first habit for a new manager is...',
      options: [
        'Regular one-to-ones',
        'Doing the work yourself',
        'Avoiding feedback',
      ],
      answer: 0,
    ),
    QuizQuestion(
      prompt: 'Good feedback is...',
      options: [
        'Saved for the annual review',
        'Specific and timely',
        'Only ever positive',
      ],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'Delegation works best when you share...',
      options: [
        'The task only',
        'The outcome and the why',
        'Nothing until it fails',
      ],
      answer: 1,
    ),
  ],
  'leading-through-change': [
    QuizQuestion(
      prompt: 'People resist change mostly because of...',
      options: ['Laziness', 'Uncertainty and loss', 'Too much information'],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'During change, leaders should communicate...',
      options: [
        'Once, at the start',
        'Early, often and honestly',
        'Only when asked',
      ],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'A quick win during change helps to...',
      options: [
        'Build momentum and trust',
        'Hide the real plan',
        'Replace listening',
      ],
      answer: 0,
    ),
  ],
  'team-trust-reset': [
    QuizQuestion(
      prompt: 'Psychological safety means people feel able to...',
      options: ['Avoid all conflict', 'Speak up without fear', 'Skip meetings'],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'A team charter should be...',
      options: [
        'Written once and filed',
        'Visible and revisited',
        'Kept by the manager only',
      ],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'Trust is rebuilt mostly through...',
      options: ['Small kept promises', 'One big speech', 'New job titles'],
      answer: 0,
    ),
  ],
  'sustainable-performance': [
    QuizQuestion(
      prompt: 'Sustainable performance depends on...',
      options: [
        'Working longer hours',
        'Recovery as well as effort',
        'Never saying no',
      ],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'An early sign of burnout is...',
      options: [
        'Ongoing exhaustion and cynicism',
        'Taking a holiday',
        'Asking questions',
      ],
      answer: 0,
    ),
    QuizQuestion(
      prompt: 'A healthy boundary sounds like...',
      options: [
        '"I can do that on Thursday"',
        '"Yes to everything"',
        'Silence',
      ],
      answer: 0,
    ),
  ],
  'manager-wellbeing-conversations': [
    QuizQuestion(
      prompt: 'In a wellbeing conversation, a manager should mainly...',
      options: [
        'Diagnose the problem',
        'Listen and signpost support',
        'Share their own story',
      ],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'A good opening question is...',
      options: [
        '"What is wrong with you?"',
        '"How are things, really?"',
        '"Can this wait?"',
      ],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'If someone needs professional help you should...',
      options: [
        'Become their therapist',
        'Signpost to the right support',
        'Ignore it',
      ],
      answer: 1,
    ),
  ],
  'ei-in-practice': [
    QuizQuestion(
      prompt: 'Useful feedback describes...',
      options: [
        'The person\'s character',
        'Behaviour and its impact',
        'How annoyed you are',
      ],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'In conflict, the first goal is to...',
      options: [
        'Win the point',
        'Make both sides feel heard',
        'End it quickly',
      ],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'Emotions in decisions are best treated as...',
      options: ['Data to notice', 'Weakness to hide', 'Irrelevant'],
      answer: 0,
    ),
  ],
  'emotionally-intelligent-leader': [
    QuizQuestion(
      prompt: 'A leader\'s mood tends to...',
      options: ['Stay private', 'Spread through the team', 'Only affect peers'],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'Under pressure, good leaders...',
      options: ['Make it safe to speak up', 'Hide all concern', 'Decide alone'],
      answer: 0,
    ),
    QuizQuestion(
      prompt: 'Growing EI in managers works best through...',
      options: ['A memo', 'Coaching in one-to-ones', 'An annual test'],
      answer: 1,
    ),
  ],
  'leadership-essentials': [
    QuizQuestion(
      prompt: 'Leadership is mainly...',
      options: ['A job title', 'A set of behaviours', 'Being the loudest'],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'A clear request includes...',
      options: [
        'An outcome, owner and date',
        'Only a deadline',
        'Nothing specific',
      ],
      answer: 0,
    ),
    QuizQuestion(
      prompt: 'Trust grows from...',
      options: ['Small kept promises', 'Big speeches', 'Avoiding mistakes'],
      answer: 0,
    ),
  ],
  'team-foundations': [
    QuizQuestion(
      prompt: 'Psychological safety lets people...',
      options: ['Speak up without fear', 'Skip work', 'Avoid feedback'],
      answer: 0,
    ),
    QuizQuestion(
      prompt: 'Anyone can improve a meeting by...',
      options: [
        'Staying silent',
        'Summarising and following up',
        'Arriving late',
      ],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'Concerns are best raised...',
      options: ['Early and kindly', 'Only in exit interviews', 'Never'],
      answer: 0,
    ),
  ],
  'high-performing-teams': [
    QuizQuestion(
      prompt: 'A team health check looks at...',
      options: ['Trust, clarity and energy', 'Only output', 'Desk layout'],
      answer: 0,
    ),
    QuizQuestion(
      prompt: 'Team agreements survive when they become...',
      options: ['Posters', 'Regular rituals', 'Rules with fines'],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'Leaders of several teams should...',
      options: [
        'Connect rather than control',
        'Micromanage each team',
        'Stay out of sight',
      ],
      answer: 0,
    ),
  ],
  'wellbeing-strategy-for-leaders': [
    QuizQuestion(
      prompt: 'The biggest driver of strain is usually...',
      options: ['Lack of perks', 'How work is designed', 'Office colours'],
      answer: 1,
    ),
    QuizQuestion(
      prompt: 'A good well-being plan has...',
      options: ['Real measures', 'A logo', 'No owner'],
      answer: 0,
    ),
    QuizQuestion(
      prompt: 'Policy becomes practice through...',
      options: [
        'Manager habits and follow-up',
        'One announcement',
        'A new app',
      ],
      answer: 0,
    ),
  ],
};

Course? courseById(String id) {
  for (final c in courses) {
    if (c.id == id) return c;
  }
  return null;
}
