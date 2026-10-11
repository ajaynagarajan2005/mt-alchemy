import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../data/mock/articles.dart';
import '../../../data/models/article.dart';
import '../../../router/routes.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/motion.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/common/app_icon.dart';
import '../../../widgets/common/arrow_link.dart';
import '../../../widgets/common/reveal.dart';
import '../../../widgets/layout/section.dart';
import '../../../widgets/common/tappable.dart';

/// Three latest articles as editorial rows (not cards).
class InsightsList extends StatelessWidget {
  const InsightsList({super.key});

  @override
  Widget build(BuildContext context) {
    final latest = articles.take(3).toList();
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: Text('Latest insights', style: AppText.h2(context))),
          const SizedBox(height: Space.xl),
          for (var i = 0; i < latest.length; i++) ...[
            if (i > 0) const Divider(),
            Reveal(
              delay: Motion.stagger * i,
              child: _ArticleRow(article: latest[i]),
            ),
          ],
          const SizedBox(height: Space.xl),
          ArrowLink(
            label: 'All insights',
            onTap: () => context.go(Routes.insights),
          ),
        ],
      ),
    );
  }
}

class _ArticleRow extends StatefulWidget {
  const _ArticleRow({required this.article});
  final Article article;

  @override
  State<_ArticleRow> createState() => _ArticleRowState();
}

class _ArticleRowState extends State<_ArticleRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final color = _hover ? AppColors.red : AppColors.ink;

    final title = Text(a.title, style: AppText.h3.copyWith(color: color));
    final meta = Text(
      '${a.category}, ${a.readMinutes} min read',
      style: AppText.small,
    );

    return Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Tappable(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go(Routes.article(a.slug)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.lg),
            child: context.isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      meta,
                      const SizedBox(height: Space.xs),
                      title,
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(width: 260, child: meta),
                      Expanded(child: title),
                      AnimatedPadding(
                        duration: Motion.fast,
                        padding: EdgeInsets.only(
                          left: _hover ? Space.lg : Space.sm,
                        ),
                        child: AppIcon(
                          HugeIcons.strokeRoundedArrowUpRight01,
                          color: color,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
