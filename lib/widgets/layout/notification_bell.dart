import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/notification_store.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../common/app_icon.dart';

/// Portal bar bell: unread badge and a dropdown of recent notifications.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NotificationStore>();
    final items = store.items.take(8).toList();

    return MenuAnchor(
      alignmentOffset: const Offset(-260, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.surface),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: Radii.cardAll),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: Space.xs),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: 320,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.md,
              Space.xs,
              Space.xs,
              Space.xs,
            ),
            child: Row(
              children: [
                Expanded(child: Text('Notifications', style: AppText.h4)),
                if (store.unread > 0)
                  TextButton(
                    onPressed: store.markAllRead,
                    child: Text(
                      'Mark all read',
                      style: AppText.small.copyWith(color: AppColors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Text('You are all caught up.', style: AppText.small),
          ),
        for (final n in items)
          MenuItemButton(
            onPressed: () {
              store.markRead(n.id);
              if (n.link != null) context.go(n.link!);
            },
            child: SizedBox(
              width: 296,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: Space.sm),
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: n.read
                            ? Colors.transparent
                            : AppColors.red,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title, style: AppText.label),
                          if (n.body.isNotEmpty)
                            Text(n.body, style: AppText.small),
                          if (n.createdAt != null)
                            Text(
                              DateFormat('d MMM, HH:mm').format(n.createdAt!),
                              style: AppText.small.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: 'Notifications',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: Badge(
          isLabelVisible: store.unread > 0,
          backgroundColor: AppColors.red,
          label: Text('${store.unread}'),
          child: AppIcon(
            HugeIcons.strokeRoundedNotification01,
            size: 22,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
