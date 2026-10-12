import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/catalog_store.dart';

import '../../data/mock/services.dart';
import '../../data/models/course.dart';
import '../../router/routes.dart';
import '../../theme/breakpoints.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/common/crystal_view.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/common/reveal.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';
import 'course_tile.dart';
import 'filter_pill.dart';

/// Course catalogue with practice area and level filters.
///
/// SCAFFOLD note: lives inside the AppShell Scaffold (AppBar nav).
/// CONTAINER (grouping): the filter bar and the empty state sit in
/// GlassPanels over the GradientBackdrop; the course grid is a Wrap of
/// fixed-height cards.
class UpskillingScreen extends StatefulWidget {
  const UpskillingScreen({super.key});

  @override
  State<UpskillingScreen> createState() => _UpskillingScreenState();
}

class _UpskillingScreenState extends State<UpskillingScreen> {
  String? _area; // service slug, null = All
  CourseLevel? _level; // null = all levels

  static const _cardHeight = 400.0;
  static const _gap = Space.lg;

  List<Course> get _filtered => context
      .watch<CatalogStore>()
      .courses
      .where(
        (c) =>
            (_area == null || c.serviceSlug == _area) &&
            (_level == null || c.level == _level),
      )
      .toList();

  void _clear() => setState(() {
    _area = null;
    _level = null;
  });

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    return PageScroll(
      underNav: true,
      children: [
        GradientBackdrop(
          child: Padding(
            padding: EdgeInsets.only(top: pageHeaderTop(context)),
            child: Section(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context),
                  const SizedBox(height: Space.xl),
                  _filters(context),
                  const SizedBox(height: Space.xl),
                  results.isEmpty ? _empty() : _grid(context, results),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final intro = Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upskilling', style: AppText.h1(context)),
          const SizedBox(height: Space.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'Short, practical courses you can take at your own pace. '
              'Pick a practice area, choose a level and start when you are ready.',
              style: AppText.lead,
            ),
          ),
        ],
      ),
    );
    // The 3D crystal is decorative and only shown from medium width up.
    if (context.isCompact) return intro;
    return Row(
      children: [
        Expanded(child: intro),
        const SizedBox(width: Space.xl),
        const Expanded(child: CrystalView()),
      ],
    );
  }

  Widget _filters(BuildContext context) {
    // CONTAINER (card): glass panel groups the two filter rows.
    return GlassPanel(
      padding: EdgeInsets.all(context.isCompact ? Space.md : Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Practice area', style: AppText.small),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              FilterPill(
                label: 'All',
                selected: _area == null,
                onTap: () => setState(() => _area = null),
              ),
              for (final s in services)
                FilterPill(
                  label: s.title,
                  selected: _area == s.slug,
                  onTap: () => setState(() => _area = s.slug),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text('Level', style: AppText.small),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              FilterPill(
                label: 'All levels',
                selected: _level == null,
                onTap: () => setState(() => _level = null),
              ),
              for (final l in CourseLevel.values)
                FilterPill(
                  label: l.label,
                  selected: _level == l,
                  onTap: () => setState(() => _level = l),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, List<Course> results) {
    // Compact: 1 column, medium: 2, expanded: 3.
    final cols = switch (context.screenSize) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      ScreenSize.expanded => 3,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - _gap * (cols - 1)) / cols;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (var i = 0; i < results.length; i++)
              SizedBox(
                width: width,
                height: _cardHeight,
                child: Reveal(
                  delay: Duration(milliseconds: 60 * (i % cols)),
                  child: CourseTile(
                    course: results[i],
                    onTap: () => context.go(Routes.course(results[i].id)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _empty() {
    // CONTAINER (card): friendly empty state when no course matches.
    return GlassPanel(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No courses match those filters', style: AppText.h3),
          const SizedBox(height: Space.xs),
          Text(
            'Try a different practice area or level, or start again.',
            style: AppText.bodyMuted,
          ),
          const SizedBox(height: Space.lg),
          AlchemyButton(
            label: 'Clear filters',
            variant: ButtonVariant.secondary,
            onPressed: _clear,
          ),
        ],
      ),
    );
  }
}
