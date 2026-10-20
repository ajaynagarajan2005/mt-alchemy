import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../router/routes.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/common/alchemy_button.dart';
import '../../../widgets/common/app_icon.dart';
import '../../../widgets/common/arrow_link.dart';
import '../../../widgets/common/card_image.dart';
import '../../../widgets/common/reveal.dart';
import '../../../widgets/layout/section.dart';

/// Landing "About" section: who MT Alchemy are, with a photo and key numbers.
class AboutTeaser extends StatelessWidget {
  const AboutTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    final expanded = context.isExpanded;
    final photo = Reveal(
      child: AnimatedCard(
        child: ClipRRect(
          borderRadius: Radii.cardAll,
          child: AspectRatio(
            aspectRatio: expanded ? 4 / 3 : 16 / 10,
            child: CardImage(
              seed: 'about-team',
              src: bundledImage('about-team'),
            ),
          ),
        ),
      ),
    );
    final copy = Reveal(
      delay: const Duration(milliseconds: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ABOUT MT ALCHEMY', style: AppText.eyebrow),
          const SizedBox(height: Space.sm),
          Text(
            'Human-centred people development, since 2014.',
            style: AppText.h2(context),
          ),
          const SizedBox(height: Space.md),
          Text(
            'We are coaches, facilitators and organisational psychologists. '
            'We work with leaders and teams on the skills that make work '
            'feel better and perform better: emotional intelligence, '
            'leadership, engagement and well-being.',
            style: AppText.lead,
          ),
          const SizedBox(height: Space.xl),
          Wrap(
            spacing: Space.xl,
            runSpacing: Space.md,
            children: const [
              _Stat(value: '12k+', label: 'People developed'),
              _Stat(value: '180', label: 'Organisations'),
              _Stat(value: '4.9/5', label: 'Average rating'),
            ],
          ),
          const SizedBox(height: Space.xl),
          ArrowLink(label: 'Our story', onTap: () => context.go(Routes.about)),
        ],
      ),
    );
    return Section(
      child: expanded
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: photo),
                const SizedBox(width: Space.xxl),
                Expanded(child: copy),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                photo,
                const SizedBox(height: Space.xl),
                copy,
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppText.h2(context).copyWith(color: AppColors.red)),
        Text(label, style: AppText.small),
      ],
    );
  }
}

/// Landing "Contact" section: three animated contact cards and a CTA.
class ContactTeaser extends StatelessWidget {
  const ContactTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        HugeIcons.strokeRoundedMail01,
        'Email us',
        'hello@mtalchemy.example.com',
      ),
      (
        HugeIcons.strokeRoundedCall,
        'Call the studio',
        '+60 3 2161 4207  ·  Mon to Fri, 9 to 6',
      ),
      (
        HugeIcons.strokeRoundedLocation01,
        'Visit us',
        'Level 12, Menara Alchemy, Kuala Lumpur',
      ),
    ];
    final compact = context.isCompact;
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: Text('CONTACT', style: AppText.eyebrow)),
          const SizedBox(height: Space.sm),
          Reveal(
            child: Text(
              'Let’s talk about your people',
              style: AppText.h2(context),
            ),
          ),
          const SizedBox(height: Space.xl),
          LayoutBuilder(
            builder: (context, c) {
              final cols = compact ? 1 : 3;
              final w = (c.maxWidth - Space.md * (cols - 1)) / cols;
              return Wrap(
                spacing: Space.md,
                runSpacing: Space.md,
                children: [
                  for (var i = 0; i < cards.length; i++)
                    SizedBox(
                      width: w,
                      child: Reveal(
                        delay: Duration(milliseconds: 90 * i),
                        child: AnimatedCard(
                          onTap: () => context.go(Routes.contact),
                          // CONTAINER (card): one contact channel.
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
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.redSoft,
                                  child: AppIcon(
                                    cards[i].$1,
                                    size: 22,
                                    color: AppColors.red,
                                  ),
                                ),
                                const SizedBox(height: Space.md),
                                Text(cards[i].$2, style: AppText.h4),
                                const SizedBox(height: Space.xxs),
                                Text(cards[i].$3, style: AppText.small),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: Space.xl),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              AlchemyButton(
                label: 'Book a call',
                onPressed: () => context.go(Routes.contact),
              ),
              AlchemyButton(
                label: 'For organisations',
                variant: ButtonVariant.secondary,
                onPressed: () => context.go(Routes.organisations),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Last section of the landing page: a QR code that opens the virtual tour
/// (a cartoon explainer film). The code encodes this site's own address plus
/// `/tour`, so it is correct on whatever host the site is published to.
class TourQrSection extends StatelessWidget {
  const TourQrSection({super.key});

  @override
  Widget build(BuildContext context) {
    // The site may live under a sub-path (GitHub Pages serves it from
    // /<repo>/), so the tour address includes the build's base path.
    const base = String.fromEnvironment('SITE_BASE', defaultValue: '/');
    final tourUrl = '${Uri.base.origin}${base}tour';
    final local = const {'localhost', '127.0.0.1'}.contains(Uri.base.host);
    final expanded = context.isExpanded;

    final qr = Reveal(
      child: AnimatedCard(
        // CONTAINER (card): white tile so the code scans in dark mode too.
        child: Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: Radii.cardAll,
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: tourUrl,
                size: 200,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF1B2A78),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF141836),
                ),
                semanticsLabel:
                    'QR code that opens the MT Alchemy virtual tour',
              ),
              const SizedBox(height: Space.sm),
              Text(
                'Scan with your phone camera',
                style: AppText.small.copyWith(color: const Color(0xFF4A4F73)),
              ),
            ],
          ),
        ),
      ),
    );

    final copy = Reveal(
      delay: const Duration(milliseconds: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VIRTUAL TOUR', style: AppText.eyebrow),
          const SizedBox(height: Space.sm),
          Text(
            'Scan to take a tour in under a minute',
            style: AppText.h2(context),
          ),
          const SizedBox(height: Space.md),
          Text(
            'Meet Alchy and friends in a short cartoon that shows what '
            'MT Alchemy does and how it helps learners, teams and trainers.',
            style: AppText.lead,
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              AlchemyButton(
                label: 'Open the tour',
                icon: HugeIcons.strokeRoundedPlayCircle,
                onPressed: () => context.go(Routes.tour),
              ),
              AlchemyButton(
                label: 'Copy link',
                variant: ButtonVariant.secondary,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: tourUrl));
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Tour link copied.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          SelectableText(tourUrl, style: AppText.small),
          if (local) ...[
            const SizedBox(height: Space.xs),
            Text(
              'This copy runs on your computer, so the code only opens here. '
              'Publish the site and it will scan from any phone.',
              style: AppText.small.copyWith(color: AppColors.red),
            ),
          ],
        ],
      ),
    );

    final preview = Reveal(
      delay: const Duration(milliseconds: 200),
      child: AnimatedCard(
        onTap: () => context.go(Routes.tour),
        child: ClipRRect(
          borderRadius: Radii.cardAll,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CardImage(
                  seed: 'tour',
                  src: 'asset:assets/images/tour_poster.jpg',
                  tint: false,
                ),
                Center(
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.red,
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Section(
      child: expanded
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                qr,
                const SizedBox(width: Space.xxl),
                Expanded(flex: 5, child: copy),
                const SizedBox(width: Space.xxl),
                Expanded(flex: 5, child: preview),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: Space.xl),
                Center(child: qr),
                const SizedBox(height: Space.xl),
                preview,
              ],
            ),
    );
  }
}
