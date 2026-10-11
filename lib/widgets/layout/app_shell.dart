import 'package:material_ui/material_ui.dart';

import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../common/grain_overlay.dart';
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
      body: Stack(
        children: [
          Positioned.fill(child: child),
          const Positioned.fill(child: GrainOverlay()),
        ],
      ),
    );
  }
}

/// Height of the glass app bar plus the status-bar inset.
double navClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).top + Space.navHeight;

/// Scrollable page body with the footer at the end.
/// Pages that do not start with a full-bleed hero get top padding so
/// their content clears the glass app bar.
class PageScroll extends StatelessWidget {
  const PageScroll({
    super.key,
    required this.children,
    this.controller,
    this.underNav = false,
  });

  final List<Widget> children;
  final ScrollController? controller;

  /// True when the first child is a hero that should sit behind the nav.
  final bool underNav;

  @override
  Widget build(BuildContext context) {
    final top = underNav ? 0.0 : navClearance(context);
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: top),
          sliver: SliverList.list(children: children),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Align(alignment: Alignment.bottomCenter, child: SiteFooter()),
        ),
      ],
    );
  }
}
