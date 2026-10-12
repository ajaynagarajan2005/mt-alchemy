import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/models/course.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'app_icon.dart';
import 'ink_art.dart';

final gbp = NumberFormat.currency(
  locale: 'en_GB',
  symbol: '£',
  decimalDigits: 0,
);

/// Course summary: artwork, level, title and duration / price.
///
/// CONTAINER (card): the Container draws the white card surface, hairline
/// border and rounded corners that group one course's details.
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.cardAll,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 150, child: InkArt(seed: course.id, intensity: 0.9)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LevelChip(label: course.level.label),
                  const SizedBox(height: Space.sm),
                  Text(
                    course.title,
                    style: AppText.h3.copyWith(fontSize: 21),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      AppIcon(
                        HugeIcons.strokeRoundedClock01,
                        size: 16,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${course.modules.length} lessons, ${course.totalMinutes} min',
                        style: AppText.small,
                      ),
                      const Spacer(),
                      Text(gbp.format(course.price), style: AppText.label),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: Radii.pillAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: AppText.small.copyWith(color: AppColors.grey700),
        ),
      ),
    );
  }
}
