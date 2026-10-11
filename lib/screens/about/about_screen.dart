import 'package:material_ui/material_ui.dart';

import '../../data/mock/team.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/common/ink_art.dart';
import '../../widgets/common/reveal.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';
import 'content_shared.dart';

/// About page: hero, principles, story, team, closing CTA.
///
/// SCAFFOLD: the AppShell route above supplies Scaffold + AppBar; this page
/// is the scrolling body.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      underNav: true,
      children: const [
        _AboutHero(),
        _Principles(),
        _Story(),
        _Team(),
        ClosingCta(),
      ],
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: staggerIn(context, [
        Text('Culture shifts when behaviour does.', style: AppText.h1(context)),
        const SizedBox(height: Space.lg),
        Text(
          'MT Alchemy is a people development consultancy. We help teams change how they work, not just how they feel for a day.',
          style: AppText.lead,
        ),
      ]),
    );

    // CONTAINER (decoration): rounded, clipped frame for the artwork.
    final art = AspectRatio(
      aspectRatio: context.isCompact ? 16 / 10 : 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          borderRadius: Radii.cardAll,
          color: AppColors.grey100,
        ),
        child: const InkArt(seed: 'about-hero'),
      ),
    );

    return GradientBackdrop(
      child: Padding(
        padding: EdgeInsets.only(top: navClearance(context)),
        child: Section(
          child: SplitRow(
            flexA: 6,
            flexB: 5,
            stackBelow: 900,
            a: text,
            b: Reveal(
              child: Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: art,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Principle {
  const _Principle(this.title, this.text);
  final String title;
  final String text;
}

const _principles = [
  _Principle(
    'Behaviour over inspiration',
    'We plan for what people will do on Monday, not how they feel on Friday.',
  ),
  _Principle(
    'Start with your context',
    'Every programme begins with a conversation about your people, pressures and goals.',
  ),
  _Principle(
    'Practise, then repeat',
    'Skills stick through small, repeated practice with real work, not one big day.',
  ),
  _Principle(
    'Leave it with the team',
    'We build habits and tools your managers own, so you do not depend on us.',
  ),
];

/// Heading on the left, a numbered editorial list on the right.
class _Principles extends StatelessWidget {
  const _Principles();

  @override
  Widget build(BuildContext context) {
    return Section(
      child: SplitRow(
        flexA: 4,
        flexB: 7,
        gap: Space.xxxl,
        crossAxisAlignment: CrossAxisAlignment.start,
        a: Reveal(child: Text('How we work', style: AppText.h2(context))),
        b: Column(
          children: [
            for (var i = 0; i < _principles.length; i++) ...[
              if (i > 0) const Divider(),
              Reveal(
                delay: Motion.stagger * i,
                child: _PrincipleRow(index: i, principle: _principles[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrincipleRow extends StatelessWidget {
  const _PrincipleRow({required this.index, required this.principle});
  final int index;
  final _Principle principle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.isCompact ? 48 : 72,
            child: Text(
              '0${index + 1}',
              style: AppText.h2(context).copyWith(color: AppColors.red),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(principle.title, style: AppText.h3),
                const SizedBox(height: Space.xs),
                Text(principle.text, style: AppText.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A short story set in glass over soft blobs, offset to the right.
class _Story extends StatelessWidget {
  const _Story();

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return GradientBackdrop(
      blobs: const [
        Blob(alignment: Alignment(-0.9, 0.2), size: 620),
        Blob(
          alignment: Alignment(0.9, -0.6),
          size: 520,
          color: AppColors.grey400,
          opacity: 0.3,
        ),
      ],
      child: Section(
        child: Align(
          alignment: compact ? Alignment.center : Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Reveal(
              // GlassPanel is a Container with a blurred, translucent fill.
              child: GlassPanel(
                strong: true,
                padding: EdgeInsets.all(compact ? Space.lg : Space.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Why we started', style: AppText.h2(context)),
                    const SizedBox(height: Space.lg),
                    Text(
                      'We kept seeing the same thing. A good workshop, a warm room, and then nothing changed.',
                      style: AppText.body,
                    ),
                    const SizedBox(height: Space.md),
                    Text(
                      'So we built MT Alchemy around follow-through. Short sessions, real practice, and tools managers use in the next one-to-one.',
                      style: AppText.bodyMuted,
                    ),
                    const SizedBox(height: Space.md),
                    Text(
                      'We work with organisations of every size, from ten people to several thousand.',
                      style: AppText.bodyMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Team extends StatelessWidget {
  const _Team();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1024 ? 4 : (width >= 600 ? 2 : 1);
    return Section(
      color: AppColors.grey50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: Text('The people', style: AppText.h2(context))),
          const SizedBox(height: Space.sm),
          Reveal(
            child: Text(
              'Small team, hands-on. The person you meet is the person who runs your session.',
              style: AppText.lead,
            ),
          ),
          const SizedBox(height: Space.xxl),
          LayoutBuilder(
            builder: (context, c) {
              const gap = Space.lg;
              final w = (c.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: columns == 1 ? Space.xl : Space.xxl,
                children: [
                  for (var i = 0; i < team.length; i++)
                    Padding(
                      // Alternate cards drop down on wide screens for a
                      // slightly staggered, less grid-like rhythm.
                      padding: EdgeInsets.only(
                        top: columns == 4 && i.isOdd ? Space.xxl : 0,
                      ),
                      child: SizedBox(
                        width: w,
                        child: Reveal(
                          delay: Motion.stagger * i,
                          child: _Person(member: team[i], row: columns == 1),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.member, required this.row});
  final TeamMember member;
  final bool row;

  @override
  Widget build(BuildContext context) {
    // PLACEHOLDER: seeded InkArt stands in for real portrait photography.
    // CONTAINER (decoration): clipped rounded frame for the portrait.
    Widget portrait(double? size) => Container(
      width: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: Radii.cardAll,
        border: Border.all(color: AppColors.line),
      ),
      child: AspectRatio(
        aspectRatio: size == null ? 4 / 5 : 1,
        child: InkArt(seed: member.name, intensity: 0.85),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(member.name, style: AppText.h3),
        const SizedBox(height: Space.xxs),
        Text(member.role, style: AppText.label.copyWith(color: AppColors.red)),
        const SizedBox(height: Space.sm),
        Text(member.bio, style: AppText.bodyMuted),
      ],
    );

    if (row) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          portrait(96),
          const SizedBox(width: Space.md),
          Expanded(child: info),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        portrait(null),
        const SizedBox(height: Space.md),
        info,
      ],
    );
  }
}
