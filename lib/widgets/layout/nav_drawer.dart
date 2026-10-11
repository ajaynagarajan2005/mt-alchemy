import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../common/alchemy_button.dart';
import '../common/app_icon.dart';
import '../common/theme_toggle.dart';

/// Navigation for screens narrower than 1024px.
class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final auth = context.watch<AuthStore>();

    void go(String path) {
      Navigator.of(context).pop();
      context.go(path);
    }

    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Menu', style: AppText.h4),
                  const Spacer(),
                  const ThemeToggleButton(),
                  IconButton(
                    tooltip: 'Close menu',
                    icon: const AppIcon(HugeIcons.strokeRoundedCancel01),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              for (final link in [
                const NavLink('Home', Routes.home),
                ...primaryNav,
              ])
                _DrawerLink(
                  label: link.label,
                  active: link.path == Routes.home
                      ? location == Routes.home
                      : location.startsWith(link.path),
                  onTap: () => go(link.path),
                ),
              const Spacer(),
              AlchemyButton(
                label: auth.isSignedIn ? 'My portal' : 'Sign in',
                expand: true,
                onPressed: () =>
                    go(auth.isSignedIn ? Routes.portal : Routes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  const _DrawerLink({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Text(
          label,
          style: AppText.h3.copyWith(
            color: active ? AppColors.red : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
