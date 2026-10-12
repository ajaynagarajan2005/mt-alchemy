import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../data/eligibility.dart';
import '../../../router/routes.dart';
import '../../../state/auth_store.dart';
import '../../../state/commerce_store.dart';
import '../../../state/learning_store.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../utils/validators.dart';
import '../../../widgets/common/alchemy_button.dart';
import '../../../widgets/common/app_icon.dart';
import '../../../widgets/common/labeled_field.dart';
import '../../../widgets/common/pathway_fields.dart';
import '../../../widgets/common/product_card.dart' show gbpExact;
import '../../learn/lesson_views.dart' show openDocument;
import '../portal_widgets.dart';

/// Journey B and C: order history with payment and the shipping timeline
/// (Processing, Shipped, Delivered) for physical goods.
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final orders = store.orders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalHeader(
          title: 'Orders',
          subtitle:
              'Receipts for courses and products, and where your parcels are.',
        ),
        if (orders.isEmpty)
          EmptyState(
            title: 'No orders yet',
            message: 'Anything you buy from the store or the learning library appears here.',
            actionLabel: 'Visit the store',
            onAction: () => context.go(Routes.store),
          ),
        for (final o in orders)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: _OrderCard(order: o, shipment: store.shipmentFor(o.number)),
          ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, this.shipment});

  final Order order;
  final Shipment? shipment;

  @override
  Widget build(BuildContext context) {
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
                    if (order.createdAt != null)
                      Text(formatDate(order.createdAt!), style: AppText.small),
                  ],
                ),
              ),
              Text(gbpExact.format(order.total), style: AppText.h4),
            ],
          ),
          const SizedBox(height: Space.sm),
          for (final i in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  _KindIcon(kind: i.kind),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: Text(
                      i.quantity > 1 ? '${i.name} x ${i.quantity}' : i.name,
                      style: AppText.body,
                    ),
                  ),
                  Text(gbpExact.format(i.lineTotal), style: AppText.small),
                ],
              ),
            ),
          if (shipment != null) ...[
            const SizedBox(height: Space.md),
            ShippingTimeline(shipment: shipment!),
          ],
        ],
      ),
    );
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    return AppIcon(
      switch (kind) {
        'course' => HugeIcons.strokeRoundedBookOpen01,
        'seats' => HugeIcons.strokeRoundedUserGroup,
        'digital' => HugeIcons.strokeRoundedDownload01,
        _ => HugeIcons.strokeRoundedPackage,
      },
      size: 18,
      color: AppColors.grey600,
    );
  }
}

/// Three-step delivery tracker.
class ShippingTimeline extends StatelessWidget {
  const ShippingTimeline({super.key, required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final reached = shipment.status.index;
    DateTime? at(ShippingStatus s) {
      for (final h in shipment.history) {
        if (h.$1 == s) return h.$2;
      }
      return null;
    }

    // CONTAINER (grouping): tinted strip holding the delivery steps.
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: Radii.inputAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shipment.tracking == null
                ? 'Delivery'
                : 'Delivery  ·  tracking ${shipment.tracking}',
            style: AppText.label,
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              for (final s in ShippingStatus.values) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: s.index <= reached
                              ? AppColors.red
                              : AppColors.grey200,
                          borderRadius: Radii.pillAll,
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        s.label,
                        style: AppText.small.copyWith(
                          color: s.index <= reached
                              ? AppColors.ink
                              : AppColors.grey500,
                          fontWeight: s.index == reached
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      if (at(s) != null)
                        Text(formatDate(at(s)!), style: AppText.small),
                    ],
                  ),
                ),
                if (s != ShippingStatus.delivered)
                  const SizedBox(width: Space.xs),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Journey B: digital products the learner owns, ready to download.
class MyDownloadsScreen extends StatelessWidget {
  const MyDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final items = store.downloads;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalHeader(
          title: 'My digital products',
          subtitle: 'Download your toolkits and planners as often as you like.',
        ),
        if (items.isEmpty)
          EmptyState(
            title: 'No digital products yet',
            message:
                'Workbooks and planners you buy from the store appear here.',
            actionLabel: 'Browse the store',
            onAction: () => context.go(Routes.store),
          ),
        for (final d in items)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: PortalCard(
              child: Row(
                children: [
                  AppIcon(
                    HugeIcons.strokeRoundedPdf01,
                    size: 32,
                    color: AppColors.red,
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: AppText.h4),
                        Text(
                          'PDF  ·  downloaded ${d.downloadCount} '
                          'time${d.downloadCount == 1 ? '' : 's'}',
                          style: AppText.small,
                        ),
                      ],
                    ),
                  ),
                  AlchemyButton(
                    label: 'Download',
                    icon: HugeIcons.strokeRoundedDownload01,
                    onPressed: () async {
                      final url = await context
                          .read<CommerceStore>()
                          .recordDownload(d);
                      await openDocument(url);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Journey A: certificates earned by completing courses.
class MyCertificatesScreen extends StatelessWidget {
  const MyCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final certs = context.watch<LearningStore>().certificates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalHeader(
          title: 'Certificates',
          subtitle:
              'Each certificate has a public link anyone can use to verify it.',
        ),
        if (certs.isEmpty)
          EmptyState(
            title: 'No certificates yet',
            message: 'Finish every lesson and pass the quiz in a course to earn one.',
            actionLabel: 'Open the course catalogue',
            onAction: () => context.go(Routes.myCourses),
          ),
        PortalGrid(
          expandedColumns: 2,
          compactColumns: 1,
          children: [
            for (final c in certs)
              PortalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(
                      HugeIcons.strokeRoundedAward01,
                      size: 32,
                      color: AppColors.red,
                    ),
                    const SizedBox(height: Space.sm),
                    Text(c.courseTitle, style: AppText.h4),
                    Text(
                      'Issued ${formatDate(c.issuedAt)}  ·  ${c.code}',
                      style: AppText.small,
                    ),
                    const SizedBox(height: Space.md),
                    AlchemyButton(
                      label: 'View certificate',
                      variant: ButtonVariant.secondary,
                      onPressed: () => context.go(Routes.certificate(c.code)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Edit your own name and profile details.
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  // FORM: profile form with a required name.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String? _country;
  final Set<String> _hobbies = {};
  CareerStage? _stage;
  final Set<String> _interests = {};
  bool _busy = false;
  bool _filled = false;

  static const _countries = [
    'Malaysia',
    'Singapore',
    'Indonesia',
    'Thailand',
    'United Kingdom',
    'Other',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final u = context.read<AuthStore>().currentUser;
    if (_filled || u == null) return;
    _filled = true;
    _name.text = u.name;
    _country = _countries.contains(u.country) ? u.country : null;
    _hobbies.addAll(u.hobbies);
    _stage = u.stage;
    _interests.addAll(u.interests);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final error = await context.read<AuthStore>().updateProfile(
      name: _name.text,
      country: _country,
      hobbies: _hobbies.toList(),
      careerStage: _stage?.name,
      interests: _interests.toList(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Profile saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    if (user == null) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortalHeader(title: 'Profile', subtitle: user.email),
          PortalCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledField(
                    label: 'Full name',
                    controller: _name,
                    validator: (v) => Validators.required(v, 'your name'),
                  ),
                  const SizedBox(height: Space.md),
                  LabeledDropdown<String>(
                    label: 'Country',
                    hint: 'Choose your country',
                    value: _country,
                    items: [
                      for (final c in _countries)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setState(() => _country = v),
                  ),
                  const SizedBox(height: Space.md),
                  Text('Hobbies', style: AppText.label),
                  const SizedBox(height: Space.xs),
                  Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      for (final h in const [
                        'Reading',
                        'Sports',
                        'Music',
                        'Travel',
                      ])
                        FilterChip(
                          label: Text(h),
                          selected: _hobbies.contains(h),
                          selectedColor: AppColors.redSoft,
                          checkmarkColor: AppColors.red,
                          onSelected: (on) => setState(
                            () => on ? _hobbies.add(h) : _hobbies.remove(h),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  const Divider(),
                  const SizedBox(height: Space.md),
                  Text('Learning pathway', style: AppText.h4),
                  const SizedBox(height: Space.sm),
                  PathwayFields(
                    stage: _stage,
                    interests: _interests,
                    onStage: (s) => setState(() => _stage = s),
                    onInterest: (slug, on) => setState(
                      () => on ? _interests.add(slug) : _interests.remove(slug),
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  AlchemyButton(
                    label: 'Save profile',
                    loading: _busy,
                    expand: context.isCompact,
                    onPressed: _save,
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
