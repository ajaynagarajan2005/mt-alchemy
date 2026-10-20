import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../router/nav_history.dart';
import '../../router/routes.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../common/app_icon.dart';

/// Arrow that returns to the previous page. Hidden on the home page.
class PageBackButton extends StatelessWidget {
  const PageBackButton({super.key, this.fallback = Routes.home});

  /// Where to go when there is no earlier page.
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == Routes.home) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Back to the previous page',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: () => context.read<NavHistory>().back(fallback: fallback),
      icon: AppIcon(
        HugeIcons.strokeRoundedArrowLeft01,
        size: 24,
        color: AppColors.ink,
      ),
    );
  }
}

/// One entry in a [NavStrip].
class StripItem {
  const StripItem(this.label, this.path, {this.icon, this.active = false});
  final String label;
  final String path;
  final AppIconData? icon;
  final bool active;
}

/// A single row of links that scrolls sideways when it does not fit, so every
/// page stays one tap away on phones and tablets without a hidden menu.
class NavStrip extends StatelessWidget {
  const NavStrip({super.key, required this.items, this.onTap});

  final List<StripItem> items;
  final void Function(BuildContext context, StripItem item)? onTap;

  static const height = Space.navStrip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
        itemBuilder: (context, i) {
          final item = items[i];
          return Semantics(
            button: true,
            selected: item.active,
            child: InkWell(
              borderRadius: Radii.pillAll,
              onTap: () =>
                  onTap != null ? onTap!(context, item) : context.go(item.path),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: item.active
                      ? AppColors.accentFill
                      : Colors.transparent,
                  borderRadius: Radii.pillAll,
                  border: Border.all(
                    color: item.active ? AppColors.accentFill : AppColors.line,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.icon != null) ...[
                      AppIcon(
                        item.icon!,
                        size: 18,
                        color: item.active ? AppColors.onAccent : AppColors.ink,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      item.label,
                      style: AppText.label.copyWith(
                        color: item.active ? AppColors.onAccent : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
