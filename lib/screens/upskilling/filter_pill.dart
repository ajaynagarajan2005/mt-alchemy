import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';

/// Pill-shaped filter chip. Selected state uses the soft red tint.
///
/// CONTAINER (decoration): the AnimatedContainer draws the pill fill and border.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.redSoft : AppColors.glassFill,
              borderRadius: Radii.pillAll,
              border: Border.all(
                color: selected ? AppColors.red : AppColors.grey300,
              ),
            ),
            child: Text(
              label,
              style: AppText.label.copyWith(
                color: selected ? AppColors.redDeep : AppColors.grey700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
