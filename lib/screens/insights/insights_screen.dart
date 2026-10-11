import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/mock/articles.dart';
import '../../data/models/article.dart';
import '../../router/routes.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/ink_art.dart';
import '../../widgets/common/reveal.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';
import '../about/content_shared.dart';
import 'article_row.dart';
import 'insights_logic.dart';

/// Insights index: category filter, featured article, editorial rows.
///
/// SCAFFOLD: AppShell supplies Scaffold + AppBar; this is the page body.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String? _category; // null = All

  @override
  Widget build(BuildContext context) {
    final shown = filterArticles(articles, _category);
    final featured = shown.isEmpty ? null : shown.first;
    final rest = shown.length > 1 ? shown.sublist(1) : <Article>[];

    return PageScroll(
      underNav: true,
      children: [
        const ContentHeader(
          title: 'Ideas you can use on Monday',
          lead: 'Short, practical writing on leadership, teams and well-being at work.',
        ),
        Section(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Filters(
                selected: _category,
                onSelect: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: Space.xl),
              if (featured == null)
                const _Empty()
              else
                // Keyed so a new filter replays the reveal.
                Reveal(
                  key: ValueKey('f-${featured.slug}'),
                  child: _Featured(article: featured),
                ),
              if (rest.isNotEmpty) ...[
                const SizedBox(height: Space.xl),
                for (var i = 0; i < rest.length; i++) ...[
                  const Divider(),
                  Reveal(
                    key: ValueKey('r-${rest[i].slug}'),
                    delay: Motion.stagger * i,
                    child: ArticleRow(article: rest[i]),
                  ),
                ],
                const Divider(),
              ],
            ],
          ),
        ),
        const ClosingCta(
          title: 'Want this applied to your team?',
          text: 'Talk to us about what you are seeing and we will suggest a first step.',
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onSelect});
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        _Chip(
          label: 'All',
          selected: selected == null,
          onTap: () => onSelect(null),
        ),
        for (final c in categoriesOf(articles))
          _Chip(label: c, selected: selected == c, onTap: () => onSelect(c)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          // CONTAINER (decoration): pill chip, soft red fill when selected.
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.redSoft : AppColors.surface,
              borderRadius: Radii.pillAll,
              border: Border.all(
                color: selected ? AppColors.red : AppColors.grey300,
              ),
            ),
            child: Text(
              label,
              style: AppText.label.copyWith(
                color: selected ? AppColors.redDeep : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Featured extends StatefulWidget {
  const _Featured({required this.article});
  final Article article;

  @override
  State<_Featured> createState() => _FeaturedState();
}

class _FeaturedState extends State<_Featured> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final compact = context.isCompact;

    // CONTAINER (decoration): clipped rounded frame for the cover art.
    final art = AspectRatio(
      aspectRatio: compact ? 16 / 10 : 4 / 3,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(borderRadius: Radii.cardAll),
        child: AnimatedScale(
          scale: _hover && !Motion.reduced(context) ? 1.03 : 1,
          duration: Motion.medium,
          curve: Motion.ease,
          child: InkArt(seed: a.slug),
        ),
      ),
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatDate(a.published)}, ${a.category}, ${a.readMinutes} min read',
          style: AppText.small,
        ),
        const SizedBox(height: Space.md),
        Text(a.title, style: AppText.h2(context)),
        const SizedBox(height: Space.md),
        Text(a.excerpt, style: AppText.lead),
        const SizedBox(height: Space.lg),
        ArrowLink(
          label: 'Read the article',
          onTap: () => context.go(Routes.article(a.slug)),
        ),
      ],
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(Routes.article(a.slug)),
        child: SplitRow(
          flexA: 7,
          flexB: 5,
          gap: Space.xxl,
          stackBelow: 800,
          a: art,
          b: text,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nothing here yet', style: AppText.h3),
          const SizedBox(height: Space.xs),
          Text(
            'We have not published in this category. Try another, or see everything.',
            style: AppText.bodyMuted,
          ),
        ],
      ),
    );
  }
}
