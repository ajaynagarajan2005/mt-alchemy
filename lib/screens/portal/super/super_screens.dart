import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../data/models/course.dart';
import '../../../data/models/people.dart';
import '../../../router/routes.dart';
import '../../../state/admin_store.dart';
import '../../../state/auth_store.dart';
import '../../../state/catalog_store.dart';
import '../../../state/commerce_store.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../utils/validators.dart';
import '../../../widgets/common/alchemy_button.dart';
import '../../../widgets/common/app_icon.dart';
import '../../../widgets/common/labeled_field.dart';
import '../../../widgets/common/product_card.dart' show gbpExact;
import '../learner/learner_screens.dart' show ShippingTimeline;
import '../portal_widgets.dart';

/// Super admin home: platform totals, the enquiry pipeline and recent orders.
class SuperDashboardScreen extends StatefulWidget {
  const SuperDashboardScreen({super.key});

  @override
  State<SuperDashboardScreen> createState() => _SuperDashboardScreenState();
}

class _SuperDashboardScreenState extends State<SuperDashboardScreen> {
  Stream<Map<String, int>>? _counts;

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminStore>();
    final user = context.watch<AuthStore>().currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalHeader(
          title: 'Welcome, ${user?.firstName ?? ''}',
          subtitle: 'Everything happening across MT Alchemy today.',
        ),
        const LivePill(),
        const SizedBox(height: Space.sm),
        StreamBuilder<Map<String, int>>(
          stream: _counts ??= admin.liveCounts(),
          builder: (context, snap) {
            final c = snap.data ?? const {};
            String v(String k) => snap.hasData ? '${c[k] ?? 0}' : '…';
            return PortalGrid(
              expandedColumns: 5,
              mediumColumns: 3,
              children: [
                StatTile(value: v('users'), label: 'Users'),
                StatTile(value: v('orders'), label: 'Orders'),
                StatTile(value: v('enrolments'), label: 'Enrolments'),
                StatTile(value: v('certificates'), label: 'Certificates'),
                StatTile(value: v('enquiries'), label: 'Enquiries'),
              ],
            );
          },
        ),
        const SizedBox(height: Space.xl),
        Text('Enquiry pipeline', style: AppText.h3),
        const SizedBox(height: Space.md),
        StreamBuilder<List<Enquiry>>(
          stream: admin.enquiries(),
          builder: (context, snap) {
            final list = snap.data ?? const <Enquiry>[];
            return PortalGrid(
              expandedColumns: 5,
              mediumColumns: 3,
              children: [
                for (final s in EnquiryStatus.values)
                  PortalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${list.where((e) => e.status == s).length}',
                          style: AppText.h2(context),
                        ),
                        Text(s.label, style: AppText.small),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            AlchemyButton(
              label: 'Open enquiries',
              onPressed: () => context.go(Routes.superEnquiries),
            ),
            AlchemyButton(
              label: 'Manage users',
              variant: ButtonVariant.secondary,
              onPressed: () => context.go(Routes.superUsers),
            ),
            AlchemyButton(
              label: 'Orders and shipping',
              variant: ButtonVariant.secondary,
              onPressed: () => context.go(Routes.superOrders),
            ),
          ],
        ),
      ],
    );
  }
}

/// CRUD for Users: create accounts for any role, change role, disable, delete.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _query = '';
  UserRole? _role;

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _NewUserDialog(),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Account created.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminStore>();
    final me = context.watch<AuthStore>().currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalHeader(
          title: 'Users',
          subtitle: 'Every account on the platform and its role.',
          trailing: AlchemyButton(
            label: 'New user',
            icon: HugeIcons.strokeRoundedUserAdd01,
            onPressed: _create,
          ),
        ),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search name or email',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            ChoiceChip(
              label: const Text('All'),
              selected: _role == null,
              onSelected: (_) => setState(() => _role = null),
            ),
            for (final r in UserRole.values)
              ChoiceChip(
                label: Text(r.label),
                selected: _role == r,
                selectedColor: AppColors.redSoft,
                onSelected: (_) => setState(() => _role = r),
              ),
          ],
        ),
        const SizedBox(height: Space.lg),
        StreamBuilder<List<AppUser>>(
          stream: admin.users(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = snap.data!
                .where((u) => _role == null || u.role == _role)
                .where(
                  (u) =>
                      _query.isEmpty ||
                      u.name.toLowerCase().contains(_query) ||
                      u.email.toLowerCase().contains(_query),
                )
                .toList();
            return Column(
              children: [
                for (final u in users)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: _UserRow(user: u, isMe: u.id == me?.id),
                  ),
                if (users.isEmpty)
                  const EmptyState(
                    title: 'No matching users',
                    message: 'Try a different search or role.',
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.isMe});

  final AppUser user;
  final bool isMe;

  Future<void> _run(BuildContext context, Future<String?> op, String ok) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await op;
    messenger.showSnackBar(SnackBar(content: Text(error ?? ok)));
  }

  /// Free access to any course, with no payment and no employer seat.
  Future<void> _addToCourse(BuildContext context) async {
    final catalog = context.read<CatalogStore>();
    final admin = context.read<AdminStore>();
    final messenger = ScaffoldMessenger.of(context);
    final courses = catalog.allCourses;
    final picked = await showDialog<Course>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: Text('Add ${user.name} to a course', style: AppText.h3),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Text(
              'They get free access, with no payment and no employer seat.',
              style: AppText.small,
            ),
          ),
          const SizedBox(height: Space.sm),
          for (final c in courses)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, c),
              child: Text(
                '${c.title}${c.published ? '' : ' (draft)'}',
                style: AppText.body,
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    final error = await admin.grantAccess(user, picked);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ?? '${user.name} now has free access to ${picked.title}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminStore>();
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: Text(user.name, style: AppText.h4)),
            if (user.disabled) ...[
              const SizedBox(width: Space.xs),
              Text(
                'Disabled',
                style: AppText.small.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
        Text(user.email, style: AppText.small),
      ],
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<UserRole>(
          value: user.role,
          underline: const SizedBox.shrink(),
          items: [
            for (final r in UserRole.values)
              DropdownMenuItem(value: r, child: Text(r.label)),
          ],
          onChanged: isMe
              ? null
              : (r) {
                  if (r != null && r != user.role) {
                    _run(
                      context,
                      admin.setRole(user.id, r),
                      '${user.firstName} is now ${r.label}.',
                    );
                  }
                },
        ),
        IconButton(
          tooltip: user.disabled ? 'Enable account' : 'Disable account',
          onPressed: isMe
              ? null
              : () => _run(
                  context,
                  admin.setDisabled(user.id, !user.disabled),
                  user.disabled ? 'Account enabled.' : 'Account disabled.',
                ),
          icon: Icon(
            user.disabled ? Icons.lock_open : Icons.block,
            size: 20,
            color: AppColors.grey600,
          ),
        ),
        TextButton.icon(
          onPressed: () => _addToCourse(context),
          icon: AppIcon(
            HugeIcons.strokeRoundedBookOpen01,
            size: 18,
            color: AppColors.red,
          ),
          label: const Text('Add to course'),
        ),
        IconButton(
          tooltip: 'Delete profile',
          onPressed: isMe
              ? null
              : () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Text('Delete ${user.name}?', style: AppText.h3),
                      content: Text(
                        'Their profile is removed and they lose portal access.',
                        style: AppText.bodyMuted,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    _run(
                      context,
                      admin.deleteUser(user.id),
                      'Profile deleted.',
                    );
                  }
                },
          icon: AppIcon(
            HugeIcons.strokeRoundedDelete02,
            size: 20,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
    return PortalCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.sm,
      ),
      child: context.isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, controls],
            )
          : Row(
              children: [
                Expanded(child: info),
                controls,
              ],
            ),
    );
  }
}

class _NewUserDialog extends StatefulWidget {
  const _NewUserDialog();

  @override
  State<_NewUserDialog> createState() => _NewUserDialogState();
}

class _NewUserDialogState extends State<_NewUserDialog> {
  // FORM: create-account form for admins.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.trainer;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await context.read<AdminStore>().createUser(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: _role,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('New user', style: AppText.h3),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledField(
                label: 'Full name',
                controller: _name,
                validator: (v) => Validators.required(v, 'a name'),
              ),
              const SizedBox(height: Space.md),
              LabeledField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: Space.md),
              LabeledField(
                label: 'Temporary password',
                controller: _password,
                obscure: true,
                validator: Validators.password,
              ),
              const SizedBox(height: Space.md),
              LabeledDropdown<UserRole>(
                label: 'Role',
                value: _role,
                items: [
                  for (final r in UserRole.values)
                    DropdownMenuItem(value: r, child: Text(r.label)),
                ],
                onChanged: (r) => setState(() => _role = r ?? _role),
              ),
              if (_error != null) ...[
                const SizedBox(height: Space.md),
                Text(
                  _error!,
                  style: AppText.small.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        AlchemyButton(label: 'Create', loading: _busy, onPressed: _submit),
      ],
    );
  }
}

/// Every order, with shipping controls for physical goods (Journey C).
class OrdersAdminScreen extends StatelessWidget {
  const OrdersAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final commerce = context.read<CommerceStore>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalHeader(
          title: 'Orders and shipping',
          subtitle:
              'Move parcels from processing to shipped to delivered. '
              'Buyers are notified at each step.',
        ),
        StreamBuilder<List<Shipment>>(
          stream: commerce.allShipments(),
          builder: (context, shipSnap) {
            final shipments = {
              for (final s in shipSnap.data ?? const <Shipment>[]) s.orderId: s,
            };
            return StreamBuilder<List<Order>>(
              stream: commerce.allOrders(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snap.data!;
                if (orders.isEmpty) {
                  return const EmptyState(
                    title: 'No orders yet',
                    message:
                        'Orders appear here as soon as someone checks out.',
                  );
                }
                return Column(
                  children: [
                    for (final o in orders)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.md),
                        child: _AdminOrderCard(
                          order: o,
                          shipment: shipments[o.number],
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order, this.shipment});

  final Order order;
  final Shipment? shipment;

  @override
  Widget build(BuildContext context) {
    final next = shipment?.status.next;
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.number, style: AppText.h4),
                    Text(
                      '${order.email}'
                      '${order.createdAt == null ? '' : '  ·  ${formatDate(order.createdAt!)}'}',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              Text(gbpExact.format(order.total), style: AppText.h4),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            order.items
                .map(
                  (i) => i.quantity > 1 ? '${i.name} x ${i.quantity}' : i.name,
                )
                .join(', '),
            style: AppText.body,
          ),
          if (shipment != null) ...[
            const SizedBox(height: Space.md),
            ShippingTimeline(shipment: shipment!),
            if (shipment!.address.isNotEmpty) ...[
              const SizedBox(height: Space.xs),
              Text(
                [
                  shipment!.address['name'],
                  shipment!.address['line1'],
                  shipment!.address['city'],
                  shipment!.address['postcode'],
                ].where((p) => p != null && '$p'.isNotEmpty).join(', '),
                style: AppText.small,
              ),
            ],
            if (next != null) ...[
              const SizedBox(height: Space.md),
              AlchemyButton(
                label: 'Mark as ${next.label.toLowerCase()}',
                icon: HugeIcons.strokeRoundedDeliveryTruck01,
                variant: ButtonVariant.secondary,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final error = await context
                      .read<CommerceStore>()
                      .advanceShipment(shipment!);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        error ??
                            '${order.number} marked ${next.label.toLowerCase()}.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Journey E inbox: corporate enquiries moving to a customised programme.
class EnquiriesScreen extends StatelessWidget {
  const EnquiriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalHeader(
          title: 'Enquiries',
          subtitle: 'Corporate enquiries from the For Organisations page.',
        ),
        StreamBuilder<List<Enquiry>>(
          stream: context.read<AdminStore>().enquiries(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data!;
            if (list.isEmpty) {
              return const EmptyState(
                title: 'No enquiries yet',
                message: 'They arrive here when organisations get in touch.',
              );
            }
            return Column(
              children: [
                for (final e in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.md),
                    child: _EnquiryCard(key: ValueKey(e.id), enquiry: e),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EnquiryCard extends StatefulWidget {
  const _EnquiryCard({super.key, required this.enquiry});
  final Enquiry enquiry;

  @override
  State<_EnquiryCard> createState() => _EnquiryCardState();
}

class _EnquiryCardState extends State<_EnquiryCard> {
  late final _proposal = TextEditingController(text: widget.enquiry.proposal);
  bool _busy = false;

  @override
  void dispose() {
    _proposal.dispose();
    super.dispose();
  }

  Future<void> _update({
    EnquiryStatus? status,
    bool saveProposal = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final error = await context.read<AdminStore>().updateEnquiry(
      widget.enquiry.id,
      status: status,
      proposal: saveProposal ? _proposal.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Enquiry updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.enquiry;
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.organisation, style: AppText.h4),
                    Text(
                      '${e.name}  ·  ${e.email}  ·  ${e.size}',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
                  borderRadius: Radii.pillAll,
                ),
                child: Text(
                  e.interest,
                  style: AppText.small.copyWith(color: AppColors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(e.message, style: AppText.body),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final s in EnquiryStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: e.status == s,
                  selectedColor: AppColors.redSoft,
                  onSelected: _busy ? null : (_) => _update(status: s),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          LabeledField(
            label: 'Customised programme proposal',
            controller: _proposal,
            maxLines: 4,
            minLines: 2,
            hint: 'Cohorts, formats, timings and how impact will be measured.',
          ),
          const SizedBox(height: Space.sm),
          AlchemyButton(
            label: 'Save proposal',
            variant: ButtonVariant.secondary,
            loading: _busy,
            onPressed: () => _update(
              saveProposal: true,
              status: e.status.index < EnquiryStatus.proposal.index
                  ? EnquiryStatus.proposal
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small pulsing "Live" badge: the numbers below update in real time.
class LivePill extends StatelessWidget {
  const LivePill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: Radii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Live',
            style: AppText.small.copyWith(color: AppColors.onYellow),
          ),
        ],
      ),
    );
  }
}
