import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/models/article.dart';
import '../../router/routes.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/app_icon.dart';
import 'insights_logic.dart';
import '../../widgets/common/tappable.dart';

/// Editorial row: date, category and read time beside title and excerpt.
class ArticleRow extends StatefulWidget {
  const ArticleRow({super.key, required this.article});
  final Article article;

  @override
  State<ArticleRow> createState() => _ArticleRowState();
}

class _ArticleRowState extends State<ArticleRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final color = _hover ? AppColors.red : AppColors.ink;

    final meta = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formatDate(a.published), style: AppText.label),
        const SizedBox(height: Space.xxs),
        Text('${a.category}, ${a.readMinutes} min read', style: AppText.small),
      ],
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(a.title, style: AppText.h3.copyWith(color: color)),
        const SizedBox(height: Space.xs),
        Text(a.excerpt, style: AppText.bodyMuted),
      ],
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
                      const SizedBox(height: Space.sm),
                      body,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 240, child: meta),
                      Expanded(child: body),
                      AnimatedPadding(
                        duration: Motion.fast,
                        padding: EdgeInsets.only(
                          left: _hover ? Space.lg : Space.md,
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
