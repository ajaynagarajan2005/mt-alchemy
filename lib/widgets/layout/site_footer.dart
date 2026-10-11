import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/routes.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'content_frame.dart';
import '../common/tappable.dart';

/// The only dark block on the site.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final light = AppText.body.copyWith(color: AppColors.inverseMuted);

    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'MT ',
                style: AppText.wordmark.copyWith(color: AppColors.red),
              ),
              TextSpan(
                text: 'Alchemy',
                style: AppText.wordmark.copyWith(color: AppColors.onInverse),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            "We don't just run activities. We shift mindsets, behaviours, and team culture.",
            style: light,
          ),
        ),
      ],
    );

    final columns = [
      _FooterColumn(
        title: 'Company',
        links: const [
          NavLink('About', Routes.about),
          NavLink('Services', Routes.services),
          NavLink('Insights', Routes.insights),
          NavLink('Contact', Routes.contact),
        ],
      ),
      _FooterColumn(
        title: 'Learn and shop',
        links: const [
          NavLink('Upskilling', Routes.upskilling),
          NavLink('Store', Routes.store),
          NavLink('Cart', Routes.cart),
        ],
      ),
      _FooterColumn(
        title: 'Account',
        links: const [
          NavLink('Sign in', Routes.login),
          NavLink('Register', Routes.register),
          NavLink('My portal', Routes.portal),
        ],
      ),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.inverseSurface,
      padding: const EdgeInsets.symmetric(vertical: Space.xxxl),
      child: ContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (context.isExpanded)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: brand),
                  for (final c in columns) Expanded(child: c),
                ],
              )
            else ...[
              brand,
              const SizedBox(height: Space.xl),
              Wrap(spacing: Space.xxl, runSpacing: Space.xl, children: columns),
            ],
            const SizedBox(height: Space.xxl),
            Divider(color: AppColors.inverseLine),
            const SizedBox(height: Space.lg),
            Text(
              '© 2026 MT Alchemy. Prototype built for NET4207.',
              style: AppText.small.copyWith(color: AppColors.inverseFaint),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.links});
  final String title;
  final List<NavLink> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppText.label.copyWith(color: AppColors.onInverse)),
        const SizedBox(height: Space.md),
        for (final l in links) _FooterLink(link: l),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({required this.link});
  final NavLink link;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Semantics(
          link: true,
          child: Tappable(
            onTap: () => context.go(widget.link.path),
            child: Text(
              widget.link.label,
              style: AppText.body.copyWith(
                color: _hover ? AppColors.red : AppColors.inverseMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
