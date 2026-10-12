import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/common/card_image.dart';
import '../../state/catalog_store.dart';

import '../../data/models/article.dart';
import '../../router/routes.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/common/reveal.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';
import '../about/content_shared.dart';
import 'article_row.dart';
import 'insights_logic.dart';

/// A single article in a readable column.
///
/// SCAFFOLD: AppShell supplies Scaffold + AppBar; this is the page body.
class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogStore>();
    final article = catalog.articleBySlug(slug);
    if (article == null) {
      return const NotFoundView(
        title: 'We could not find that article',
        backLabel: 'All insights',
        backTo: Routes.insights,
      );
    }
    final related = relatedArticles(article, catalog.articles, 2);

    return PageScroll(
      underNav: true,
      children: [
        _Head(article: article),
        _Body(article: article),
        if (related.isNotEmpty) _Related(items: related),
        const ClosingCta(
          title: 'Want this applied to your team?',
          text: 'Talk to us about what you are seeing and we will suggest a first step.',
        ),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.article});
  final Article article;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return GradientBackdrop(
      child: Padding(
        padding: EdgeInsets.only(top: pageHeaderTop(context)),
        child: Section(
          top: false,
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArrowLink(
                label: 'All insights',
                color: AppColors.inkMuted,
                onTap: () => context.go(Routes.insights),
              ),
              const SizedBox(height: Space.xl),
              Text(
                article.category,
                style: AppText.label.copyWith(color: AppColors.red),
              ),
              const SizedBox(height: Space.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Text(article.title, style: AppText.h1(context)),
              ),
              const SizedBox(height: Space.md),
              Text(
                '${formatDate(article.published)}, ${article.readMinutes} min read',
                style: AppText.small,
              ),
              const SizedBox(height: Space.xl),
              // CONTAINER (decoration): clipped rounded frame for the cover.
              AspectRatio(
                aspectRatio: compact ? 16 / 10 : 21 / 9,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(borderRadius: Radii.cardAll),
                  child: CardImage(
                    seed: article.slug,
                    src: bundledImage('article-${article.slug}'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.article});
  final Article article;

  @override
  Widget build(BuildContext context) {
    return Section(
      child: Align(
        alignment: Alignment.centerLeft,
        // About 68 characters per line at body size.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < article.body.length; i++)
                Reveal(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Space.lg),
                    child: Text(
                      article.body[i],
                      style: i == 0
                          ? AppText.lead.copyWith(color: AppColors.ink)
                          : AppText.body.copyWith(height: 1.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Related extends StatelessWidget {
  const _Related({required this.items});
  final List<Article> items;

  @override
  Widget build(BuildContext context) {
    return Section(
      color: AppColors.grey50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: Text('Related reading', style: AppText.h2(context))),
          const SizedBox(height: Space.lg),
          for (final a in items) ...[const Divider(), ArticleRow(article: a)],
          const Divider(),
        ],
      ),
    );
  }
}
