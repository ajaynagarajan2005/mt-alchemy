import 'dart:ui' show ImageFilter;

import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/cart_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../common/alchemy_button.dart';
import '../common/app_icon.dart';

/// Frosted-glass top bar. Wraps a real Material [AppBar] (rubric: AppBar on main screens).
class SiteNav extends StatelessWidget implements PreferredSizeWidget {
  const SiteNav({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(Space.navHeight);

  @override
  Widget build(BuildContext context) {
    final expanded = context.isExpanded;
    final gutter = Breakpoints.gutter(context);
    final location = GoRouterState.of(context).uri.path;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.glassFill,
            border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
          ),
          // APPBAR: the site-wide app bar; actions collapse into a drawer below 1024px.
          child: AppBar(
            toolbarHeight: Space.navHeight,
            automaticallyImplyLeading: false,
            titleSpacing: gutter,
            title: _Wordmark(onTap: () => context.go(Routes.home)),
            actions: [
              if (expanded)
                for (final link in primaryNav)
                  _NavItem(link: link, active: location.startsWith(link.path)),
              const SizedBox(width: Space.xs),
              const _CartButton(),
              if (expanded) ...[
                const SizedBox(width: Space.xs),
                const _AccountButton(),
              ] else
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Menu',
                    icon: const AppIcon(
                      HugeIcons.strokeRoundedMenu01,
                      size: 26,
                    ),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              SizedBox(width: gutter - Space.xs),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'MT Alchemy home',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
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

class _NavItem extends StatelessWidget {
  const _NavItem({required this.link, required this.active});
  final NavLink link;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: () => context.go(link.path),
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => active || s.contains(WidgetState.hovered)
                ? AppColors.red
                : AppColors.ink,
          ),
          textStyle: WidgetStatePropertyAll(AppText.nav),
        ),
        child: Text(link.label),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartStore>().count;
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => context.go(Routes.cart),
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: AppColors.red,
        label: Text('$count'),
        child: const AppIcon(
          HugeIcons.strokeRoundedShoppingBag01,
          size: 24,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AuthStore>().isSignedIn;
    return AlchemyButton(
      label: signedIn ? 'My portal' : 'Sign in',
      variant: ButtonVariant.secondary,
      onPressed: () => context.go(signedIn ? Routes.portal : Routes.login),
    );
  }
}
