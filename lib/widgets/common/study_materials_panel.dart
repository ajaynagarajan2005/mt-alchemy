import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/models/course.dart';
import '../../screens/learn/lesson_views.dart' show openDocument;
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'app_icon.dart';
import 'glass_panel.dart';
import 'tappable.dart';

/// The PDFs and notes that go with one course, shown on that course's page.
class StudyMaterialsPanel extends StatelessWidget {
  const StudyMaterialsPanel({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    // CONTAINER (card): glass panel groups the course's study material.
    return GlassPanel(
      padding: EdgeInsets.all(compact ? Space.md : Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Study materials', style: AppText.h3),
          const SizedBox(height: Space.xxs),
          Text(
            'PDFs for ${course.title}. They open in a new tab and can be saved or printed.',
            style: AppText.small,
          ),
          const SizedBox(height: Space.md),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth < 640 ? 1 : 3;
              final w = (c.maxWidth - Space.md * (cols - 1)) / cols;
              return Wrap(
                spacing: Space.md,
                runSpacing: Space.md,
                children: [
                  for (final m in course.materials)
                    SizedBox(
                      width: w,
                      child: _MaterialTile(material: m),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.material});
  final StudyMaterial material;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${material.title} (PDF)',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tappable(
          onTap: () => openDocument(material.path),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: Radii.inputAll,
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.redSoft,
                  child: AppIcon(
                    HugeIcons.strokeRoundedPdf01,
                    size: 22,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(material.title, style: AppText.h4),
                      const SizedBox(height: 2),
                      Text(material.description, style: AppText.small),
                      const SizedBox(height: Space.xs),
                      Text(
                        'Open PDF',
                        style: AppText.label.copyWith(color: AppColors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
