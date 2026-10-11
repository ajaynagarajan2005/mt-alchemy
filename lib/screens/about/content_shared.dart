import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/common/reveal.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';

/// Page title block that sits under the glass nav, over soft blobs.
///
/// CONTAINER (padding): clears the nav bar and keeps the headline readable.
class ContentHeader extends StatelessWidget {
  const ContentHeader({
    super.key,
    required this.title,
    this.lead,
    this.eyebrow,
  });

  final String title;
  final String? lead;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    return GradientBackdrop(
      child: Padding(
        padding: EdgeInsets.only(top: navClearance(context)),
        child: Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggerIn(context, [
              if (eyebrow != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: Text(eyebrow!.toUpperCase(), style: AppText.eyebrow),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Text(title, style: AppText.h1(context)),
              ),
              if (lead != null)
                Padding(
                  padding: const EdgeInsets.only(top: Space.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Text(lead!, style: AppText.lead),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Dark closing band shared by the content pages. Sits above the footer.
///
/// CONTAINER (grouping): [Section] paints the dark ground behind the CTA.
class ClosingCta extends StatelessWidget {
  const ClosingCta({
    super.key,
    this.title = 'Ready to shift how your team works?',
    this.text = 'Tell us what is happening in your organisation and we will suggest where to start.',
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Section(
      color: AppColors.grey900,
      child: Reveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                title,
                style: AppText.h2(context).copyWith(color: AppColors.white),
              ),
            ),
            const SizedBox(height: Space.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                text,
                style: AppText.lead.copyWith(color: AppColors.grey300),
              ),
            ),
            const SizedBox(height: Space.xl),
            AlchemyButton(
              label: 'Book a call',
              onPressed: () => context.go(Routes.contact),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when a slug does not match any service or article.
class NotFoundView extends StatelessWidget {
  const NotFoundView({
    super.key,
    required this.title,
    required this.backLabel,
    required this.backTo,
  });

  final String title;
  final String backLabel;
  final String backTo;

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      underNav: true,
      children: [
        GradientBackdrop(
          child: Padding(
            padding: EdgeInsets.only(top: navClearance(context)),
            child: Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIcon(
                    HugeIcons.strokeRoundedCompass01,
                    size: 40,
                    color: AppColors.red,
                  ),
                  const SizedBox(height: Space.lg),
                  Text(title, style: AppText.h1(context)),
                  const SizedBox(height: Space.md),
                  Text(
                    'The page may have moved, or the link may be mistyped.',
                    style: AppText.lead,
                  ),
                  const SizedBox(height: Space.xl),
                  ArrowLink(label: backLabel, onTap: () => context.go(backTo)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Two columns when there is room, stacked below [stackBelow] px wide.
/// [flexA] and [flexB] set the asymmetry.
class SplitRow extends StatelessWidget {
  const SplitRow({
    super.key,
    required this.a,
    required this.b,
    this.flexA = 1,
    this.flexB = 1,
    this.gap = Space.xxl,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.stackBelow = 760,
  });

  final Widget a;
  final Widget b;
  final int flexA;
  final int flexB;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;
  final double stackBelow;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.sizeOf(context).width < stackBelow;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          a,
          SizedBox(height: gap * 0.6),
          b,
        ],
      );
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Expanded(flex: flexA, child: a),
        SizedBox(width: gap),
        Expanded(flex: flexB, child: b),
      ],
    );
  }
}
