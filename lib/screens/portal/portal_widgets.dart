import 'package:material_ui/material_ui.dart';

import '../../state/org_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';

/// Page title block used at the top of every portal page.
class PortalHeader extends StatelessWidget {
  const PortalHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.h2(context)),
        if (subtitle != null) ...[
          const SizedBox(height: Space.xs),
          Text(subtitle!, style: AppText.bodyMuted),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: trailing == null || context.isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                if (trailing != null) ...[
                  const SizedBox(height: Space.md),
                  trailing!,
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: text),
                trailing!,
              ],
            ),
    );
  }
}

/// Plain white card for lists, forms and stat tiles.
///
/// CONTAINER (decoration): rounded white surface with a hairline border.
class PortalCard extends StatelessWidget {
  const PortalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.cardAll,
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

/// Number plus caption on a frosted tile.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Plain bordered card: nothing to blur on the white portal, and no
    // BackdropFilter edge artefacts.
    return PortalCard(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppText.h2(context)),
          const SizedBox(height: Space.xxs),
          Text(label, style: AppText.small),
        ],
      ),
    );
  }
}

/// Lays children out in [columns] equal columns that wrap.
class PortalGrid extends StatelessWidget {
  const PortalGrid({
    super.key,
    required this.children,
    this.compactColumns = 2,
    this.mediumColumns = 2,
    this.expandedColumns = 4,
  });

  final List<Widget> children;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;

  @override
  Widget build(BuildContext context) {
    final columns = switch (context.screenSize) {
      ScreenSize.compact => compactColumns,
      ScreenSize.medium => mediumColumns,
      ScreenSize.expanded => expandedColumns,
    };
    return LayoutBuilder(
      builder: (context, c) {
        final width = (c.maxWidth - Space.md * (columns - 1)) / columns;
        return Wrap(
          spacing: Space.md,
          runSpacing: Space.md,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Slim themed progress bar with no heavy filled track.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.complete = false});

  final double value;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progress ${(value * 100).round()} percent',
      child: ClipRRect(
        borderRadius: Radii.pillAll,
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 6,
          backgroundColor: AppColors.grey200,
          color: complete ? AppColors.success : AppColors.red,
        ),
      ),
    );
  }
}

/// Pill showing a [ProgressStatus]. Green is reserved for Complete.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ProgressStatus status;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (status) {
      ProgressStatus.complete => (
        AppColors.success,
        AppColors.success.withValues(alpha: 0.12),
      ),
      ProgressStatus.inProgress => (AppColors.red, AppColors.redSoft),
      ProgressStatus.notStarted => (AppColors.grey600, AppColors.grey100),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.pillAll),
      child: Text(status.label, style: AppText.small.copyWith(color: fg)),
    );
  }
}

/// Friendly empty state with an optional single action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondary = false,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h3),
          const SizedBox(height: Space.xs),
          Text(message, style: AppText.bodyMuted),
          if (actionLabel != null) ...[
            const SizedBox(height: Space.lg),
            AlchemyButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: secondary
                  ? ButtonVariant.secondary
                  : ButtonVariant.primary,
            ),
          ],
        ],
      ),
    );
  }
}

String formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
