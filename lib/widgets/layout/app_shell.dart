import 'package:material_ui/material_ui.dart';

import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import 'nav_drawer.dart';
import 'site_footer.dart';
import 'site_nav.dart';

/// Persistent chrome for every public screen.
///
/// SCAFFOLD: the single Scaffold for public pages. It provides the glass
/// AppBar (SiteNav), the end drawer used below 1024px, and the body that
/// go_router swaps per route. The body extends behind the app bar so the
/// glass can blur the hero video and page backdrops.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.white,
      appBar: const SiteNav(),
      endDrawer: context.isExpanded ? null : const NavDrawer(),
      // Clean white canvas: no grain overlay.
      body: child,
    );
  }
}

/// Height of the glass app bar plus the status-bar inset.
double navClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).top + Space.navHeight;

/// Top padding for the first section of a page that starts under the glass
/// nav: nav clearance plus a modest gap. Pair with `Section(top: false)` so
/// the heading is not pushed down by the section's own large top padding.
double pageHeaderTop(BuildContext context) =>
    navClearance(context) + (context.isCompact ? Space.xl : Space.xxl);

/// Scrollable page body with the footer at the end.
/// Pages that do not start with a full-bleed hero get top padding so
/// their content clears the glass app bar.
class PageScroll extends StatelessWidget {
  const PageScroll({
    super.key,
    required this.children,
    this.controller,
    this.underNav = false,
    this.eager = false,
  });

  final List<Widget> children;
  final ScrollController? controller;

  /// True when the first child is a hero that should sit behind the nav.
  final bool underNav;

  /// Build every child up front (not lazily) so sections can be scrolled to
  /// by key. Used by the landing page, which has a fixed set of sections.
  final bool eager;

  @override
  Widget build(BuildContext context) {
    final top = underNav ? 0.0 : navClearance(context);
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: top),
          sliver: eager
              ? SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                )
              : SliverList.list(children: children),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Align(alignment: Alignment.bottomCenter, child: SiteFooter()),
        ),
      ],
    );
  }
}
