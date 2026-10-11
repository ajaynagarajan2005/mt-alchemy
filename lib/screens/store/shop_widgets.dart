import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';

/// Shared page frame for the store journey: scrolling page, soft backdrop
/// behind the glass nav, standard section rhythm.
///
/// SCAFFOLD note: these pages sit inside the AppShell Scaffold (AppBar nav).
class ShopPage extends StatelessWidget {
  const ShopPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      underNav: true,
      children: [
        GradientBackdrop(
          child: Padding(
            padding: EdgeInsets.only(top: pageHeaderTop(context)),
            child: Section(top: false, child: child),
          ),
        ),
      ],
    );
  }
}

/// Friendly empty or not-found state with one primary action.
class ShopMessage extends StatelessWidget {
  const ShopMessage({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.route,
  });

  final String title;
  final String message;
  final String actionLabel;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: GlassPanel(
          strong: true,
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h2(context)),
              const SizedBox(height: Space.md),
              Text(message, style: AppText.lead),
              const SizedBox(height: Space.lg),
              AlchemyButton(
                label: actionLabel,
                onPressed: () => context.go(route),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quantity control with accessible, tooltipped buttons. Range [min]..[max].
///
/// CONTAINER (decoration): a pill-shaped outlined Container groups the
/// minus button, the count and the plus button.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 10,
    this.itemName,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// Used in tooltips, e.g. "Decrease quantity of Leading With Care".
  final String? itemName;

  @override
  Widget build(BuildContext context) {
    final suffix = itemName == null ? '' : ' of $itemName';
    return Container(
      decoration: BoxDecoration(
        borderRadius: Radii.pillAll,
        border: Border.all(color: AppColors.grey300),
        color: AppColors.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease quantity$suffix',
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const AppIcon(HugeIcons.strokeRoundedMinusSign, size: 18),
          ),
          Semantics(
            liveRegion: true,
            label: 'Quantity $value',
            child: SizedBox(
              width: 32,
              child: ExcludeSemantics(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: AppText.label,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity$suffix',
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const AppIcon(HugeIcons.strokeRoundedAdd01, size: 18),
          ),
        ],
      ),
    );
  }
}
