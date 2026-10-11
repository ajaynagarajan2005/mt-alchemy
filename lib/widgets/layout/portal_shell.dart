import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/people.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../common/app_icon.dart';
import '../common/gradient_backdrop.dart';
import '../common/tappable.dart';

class _PortalDest {
  const _PortalDest(this.label, this.path, this.icon);
  final String label;
  final String path;
  final AppIconData icon;
}

List<_PortalDest> _destinationsFor(UserRole role) => switch (role) {
  UserRole.employer => const [
    _PortalDest('Overview', Routes.employer, HugeIcons.strokeRoundedHome01),
    _PortalDest(
      'Employees',
      Routes.employerEmployees,
      HugeIcons.strokeRoundedUserGroup,
    ),
    _PortalDest(
      'Assign courses',
      Routes.employerAssign,
      HugeIcons.strokeRoundedTask01,
    ),
    _PortalDest(
      'Progress',
      Routes.employerProgress,
      HugeIcons.strokeRoundedChartLineData01,
    ),
  ],
  UserRole.individual => const [
    _PortalDest(
      'My learning',
      Routes.portalMe,
      HugeIcons.strokeRoundedBookOpen01,
    ),
    _PortalDest(
      'Browse courses',
      Routes.upskilling,
      HugeIcons.strokeRoundedBook02,
    ),
  ],
  UserRole.trainer => const [
    _PortalDest('Overview', Routes.admin, HugeIcons.strokeRoundedHome01),
  ],
};

String _portalTitle(UserRole role) => switch (role) {
  UserRole.employer => 'Employer portal',
  UserRole.individual => 'Learner portal',
  UserRole.trainer => 'Trainer and admin',
};

/// Chrome for every signed-in portal page.
///
/// SCAFFOLD: a second Scaffold, separate from the public AppShell. It owns
/// the portal AppBar, the Drawer used below 1024px and the body that
/// go_router swaps per portal route.
class PortalShell extends StatelessWidget {
  const PortalShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    // The router redirect keeps signed-out visitors out; this is a safe fallback.
    if (user == null) return const SizedBox.shrink();

    final location = GoRouterState.of(context).uri.path;
    final dests = _destinationsFor(user.role);
    final expanded = context.isExpanded;
    final selected = _selectedIndex(dests, location);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _PortalBar(user: user, showMenu: !expanded),
      drawer: expanded
          ? null
          : _PortalDrawer(user: user, dests: dests, selected: selected),
      body: GradientBackdrop(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (expanded) _PortalRail(dests: dests, selected: selected),
            Expanded(
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    // CONTAINER (padding): gutters around every portal page.
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: Breakpoints.gutter(context).clamp(16, 48),
                        vertical: context.isCompact ? Space.lg : Space.xl,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _selectedIndex(List<_PortalDest> dests, String location) {
    int? best;
    var bestLen = -1;
    for (var i = 0; i < dests.length; i++) {
      final p = dests[i].path;
      final match = location == p || location.startsWith('$p/');
      if (match && p.length > bestLen) {
        best = i;
        bestLen = p.length;
      }
    }
    return best;
  }
}

class _PortalBar extends StatelessWidget implements PreferredSizeWidget {
  const _PortalBar({required this.user, required this.showMenu});

  final AppUser user;
  final bool showMenu;

  @override
  Size get preferredSize => const Size.fromHeight(Space.navHeight);

  @override
  Widget build(BuildContext context) {
    final expanded = context.isExpanded;
    final gutter = Breakpoints.gutter(context).clamp(16.0, 48.0);

    // APPBAR: portal app bar with wordmark, portal title, user and sign out.
    return AppBar(
      toolbarHeight: Space.navHeight,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surface,
      shape: const Border(bottom: BorderSide(color: AppColors.line)),
      titleSpacing: showMenu ? 0 : gutter,
      leading: showMenu
          ? Builder(
              builder: (context) => IconButton(
                tooltip: 'Open portal menu',
                icon: const AppIcon(HugeIcons.strokeRoundedMenu01, size: 26),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
      title: Row(
        children: [
          const _Wordmark(),
          if (expanded) ...[
            const SizedBox(width: Space.lg),
            Container(width: 1, height: 24, color: AppColors.line),
            const SizedBox(width: Space.lg),
            Text(_portalTitle(user.role), style: AppText.label),
          ],
        ],
      ),
      actions: [
        if (expanded) ...[
          Text(user.name, style: AppText.small),
          const SizedBox(width: Space.md),
          TextButton(
            onPressed: () => context.go(Routes.home),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
            child: Text('Back to site', style: AppText.label),
          ),
          const SizedBox(width: Space.xs),
        ],
        if (context.isCompact)
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
            icon: const AppIcon(HugeIcons.strokeRoundedLogout01, size: 22),
          )
        else
          TextButton.icon(
            onPressed: () => _signOut(context),
            icon: const AppIcon(HugeIcons.strokeRoundedLogout01, size: 18),
            label: Text('Sign out', style: AppText.label),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          ),
        SizedBox(width: gutter - Space.xs),
      ],
    );
  }
}

void _signOut(BuildContext context) {
  context.read<AuthStore>().signOut();
  context.go(Routes.home);
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'MT Alchemy home',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tappable(
          onTap: () => context.go(Routes.home),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'MT ',
                  style: AppText.wordmark.copyWith(color: AppColors.red),
                ),
                TextSpan(text: 'Alchemy', style: AppText.wordmark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortalRail extends StatelessWidget {
  const _PortalRail({required this.dests, required this.selected});

  final List<_PortalDest> dests;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    // CONTAINER (decoration): the rail's frosted fill and divider line.
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: AppColors.glassFillStrong,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: Space.lg, horizontal: 12),
      child: NavigationRailTheme(
        data: NavigationRailThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.redSoft,
          indicatorShape: const StadiumBorder(),
          selectedIconTheme: const IconThemeData(color: AppColors.red),
          unselectedIconTheme: const IconThemeData(color: AppColors.grey600),
          selectedLabelTextStyle: AppText.label.copyWith(color: AppColors.red),
          unselectedLabelTextStyle: AppText.label.copyWith(
            color: AppColors.grey700,
          ),
        ),
        child: NavigationRail(
          extended: true,
          minExtendedWidth: 224,
          selectedIndex: selected,
          onDestinationSelected: (i) => context.go(dests[i].path),
          destinations: [
            for (final d in dests)
              NavigationRailDestination(
                icon: AppIcon(d.icon, size: 22),
                label: Text(d.label),
              ),
          ],
        ),
      ),
    );
  }
}

class _PortalDrawer extends StatelessWidget {
  const _PortalDrawer({
    required this.user,
    required this.dests,
    required this.selected,
  });

  final AppUser user;
  final List<_PortalDest> dests;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    void go(String path) {
      Navigator.of(context).pop();
      context.go(path);
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_portalTitle(user.role), style: AppText.h3),
                  const SizedBox(height: Space.xxs),
                  Text(user.name, style: AppText.small),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: Space.xs),
            for (var i = 0; i < dests.length; i++)
              ListTile(
                selected: selected == i,
                selectedColor: AppColors.red,
                selectedTileColor: AppColors.redSoft,
                shape: const StadiumBorder(),
                leading: AppIcon(dests[i].icon, size: 22),
                title: Text(
                  dests[i].label,
                  style: AppText.label.copyWith(
                    color: selected == i ? AppColors.red : AppColors.ink,
                  ),
                ),
                onTap: () => go(dests[i].path),
              ),
            const Divider(),
            ListTile(
              shape: const StadiumBorder(),
              leading: const AppIcon(
                HugeIcons.strokeRoundedArrowLeft01,
                size: 22,
              ),
              title: Text('Back to site', style: AppText.label),
              onTap: () => go(Routes.home),
            ),
          ],
        ),
      ),
    );
  }
}
