import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/routes.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/card_image.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/common/reveal.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';
import '../../widgets/media/brand_video_player.dart';

/// Virtual tour: the page the landing page's QR code opens. A cartoon
/// explainer film, then one card per part of the site to try for yourself.
class TourScreen extends StatelessWidget {
  const TourScreen({super.key});

  static const _chapters = [
    (
      HugeIcons.strokeRoundedBookOpen01,
      'Learn',
      'Courses matched to your career stage and interests, with video, PDF and quiz lessons, progress tracking and certificates.',
      Routes.upskilling,
      'Browse courses',
    ),
    (
      HugeIcons.strokeRoundedShoppingBag01,
      'Shop',
      'Toolkits and planners download instantly. Card decks and books are shipped, and you can follow the parcel.',
      Routes.store,
      'Visit the store',
    ),
    (
      HugeIcons.strokeRoundedUserGroup,
      'Teams',
      'Employers buy course seats, assign them to people and watch progress in live charts.',
      Routes.organisations,
      'For organisations',
    ),
    (
      HugeIcons.strokeRoundedTask01,
      'Trainers and admins',
      'Build courses, see who joined and who paid, and give people free access in a click.',
      Routes.login,
      'Sign in',
    ),
    (
      HugeIcons.strokeRoundedBrain02,
      'Know yourself',
      'A five-minute EQ self-assessment gives you a profile and a course to help you grow.',
      Routes.assessment,
      'Take the check',
    ),
    (
      HugeIcons.strokeRoundedNews01,
      'Read and be inspired',
      'Short, practical writing on leadership, teams and well-being at work.',
      Routes.insights,
      'Read insights',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
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
                  Reveal(child: Text('VIRTUAL TOUR', style: AppText.eyebrow)),
                  const SizedBox(height: Space.sm),
                  Reveal(
                    child: Text(
                      'See MT Alchemy in under a minute',
                      style: AppText.h1(context),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  Reveal(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Text(
                        'Meet Alchy, our crystal guide. A short cartoon shows what '
                        'the site does and how it helps you, your team and your trainers.',
                        style: AppText.lead,
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.xl),
                  Reveal(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: const BrandVideoPlayer(
                        asset: 'assets/videos/site_tour.mp4',
                        poster: 'assets/images/tour_poster.jpg',
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    'Tap play. The film has captions and no sound.',
                    style: AppText.small,
                  ),
                ],
              ),
            ),
          ),
        ),
        Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Reveal(
                child: Text('Try it yourself', style: AppText.h2(context)),
              ),
              const SizedBox(height: Space.xl),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = compact ? 1 : (c.maxWidth > 900 ? 3 : 2);
                  final w = (c.maxWidth - Space.lg * (cols - 1)) / cols;
                  return Wrap(
                    spacing: Space.lg,
                    runSpacing: Space.lg,
                    children: [
                      for (var i = 0; i < _chapters.length; i++)
                        SizedBox(
                          width: w,
                          child: Reveal(
                            delay: Duration(milliseconds: 70 * (i % 3)),
                            child: _ChapterCard(
                              number: i + 1,
                              icon: _chapters[i].$1,
                              title: _chapters[i].$2,
                              text: _chapters[i].$3,
                              route: _chapters[i].$4,
                              action: _chapters[i].$5,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: Space.xl),
              AlchemyButton(
                label: 'Create a free account',
                onPressed: () => context.go(Routes.register),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
    required this.route,
    required this.action,
  });

  final int number;
  final AppIconData icon;
  final String title;
  final String text;
  final String route;
  final String action;

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: () => context.go(route),
      // CONTAINER (card): one part of the site, with a link to try it.
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.cardAll,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.redSoft,
                  child: AppIcon(icon, size: 24, color: AppColors.red),
                ),
                const Spacer(),
                Text(
                  '$number',
                  style: AppText.h2(context).copyWith(color: AppColors.grey300),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            Text(title, style: AppText.h4),
            const SizedBox(height: Space.xs),
            Text(text, style: AppText.bodyMuted),
            const SizedBox(height: Space.md),
            Text(action, style: AppText.label.copyWith(color: AppColors.red)),
          ],
        ),
      ),
    );
  }
}
