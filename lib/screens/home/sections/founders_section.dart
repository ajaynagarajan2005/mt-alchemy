import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../data/models/founder.dart';
import '../../../data/models/people.dart';
import '../../../state/auth_store.dart';
import '../../../state/catalog_store.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../utils/validators.dart';
import '../../../widgets/common/alchemy_button.dart';
import '../../../widgets/common/app_icon.dart';
import '../../../widgets/common/card_image.dart';
import '../../../widgets/common/labeled_field.dart';
import '../../../widgets/common/reveal.dart';
import '../../../widgets/layout/section.dart';

/// "Meet the founders": one animated card per founder with a photo slot.
///
/// A founder without a photo shows a branded placeholder. The super admin
/// sees "Upload photo" on each card; the picture is cropped, shrunk and saved
/// with the founder, so it appears for every visitor straight away.
class FoundersSection extends StatelessWidget {
  const FoundersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final founders = context.watch<CatalogStore>().founders;
    if (founders.isEmpty) return const SizedBox.shrink();
    final compact = context.isCompact;
    final medium = context.screenSize == ScreenSize.medium;
    final columns = compact ? 1 : (medium ? 2 : founders.length.clamp(1, 3));

    return Section(
      color: AppColors.grey50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: Text('THE FOUNDERS', style: AppText.eyebrow)),
          const SizedBox(height: Space.sm),
          Reveal(
            child: Text(
              'Meet the people behind MT Alchemy',
              style: AppText.h2(context),
            ),
          ),
          const SizedBox(height: Space.sm),
          Reveal(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                'Three founders who believe change sticks when people feel it, '
                'practise it, and see it modelled.',
                style: AppText.lead,
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - Space.lg * (columns - 1)) / columns;
              return Wrap(
                spacing: Space.lg,
                runSpacing: Space.lg,
                children: [
                  for (var i = 0; i < founders.length; i++)
                    SizedBox(
                      width: w,
                      child: Reveal(
                        delay: Duration(milliseconds: 110 * i),
                        child: FounderCard(founder: founders[i]),
                      ),
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

class FounderCard extends StatefulWidget {
  const FounderCard({super.key, required this.founder});

  final Founder founder;

  @override
  State<FounderCard> createState() => _FounderCardState();
}

class _FounderCardState extends State<FounderCard> {
  bool _busy = false;

  Founder get founder => widget.founder;

  /// Crops to a 4:5 portrait, shrinks to 480px wide and stores it as JPEG.
  Future<void> _upload() async {
    final messenger = ScaffoldMessenger.of(context);
    final catalog = context.read<CatalogStore>();
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.pickFiles(type: FileType.image);
      if (picked.isEmpty) return;
      final bytes = await picked.first.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('That file is not a picture we can read.'),
          ),
        );
        return;
      }
      // Centre-crop to 4:5, then shrink.
      final targetRatio = 4 / 5;
      final ratio = decoded.width / decoded.height;
      final cropW = ratio > targetRatio
          ? (decoded.height * targetRatio).round()
          : decoded.width;
      final cropH = ratio > targetRatio
          ? decoded.height
          : (decoded.width / targetRatio).round();
      final cropped = img.copyCrop(
        decoded,
        x: (decoded.width - cropW) ~/ 2,
        y: (decoded.height - cropH) ~/ 2,
        width: cropW,
        height: cropH,
      );
      final small = img.copyResize(cropped, width: 480);
      final jpg = img.encodeJpg(small, quality: 82);
      final error = await catalog.setFounderPhoto(
        founder,
        'data:image/jpeg;base64,${base64Encode(jpg)}',
      );
      messenger.showSnackBar(
        SnackBar(content: Text(error ?? 'Photo saved for ${founder.name}.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not upload that photo. Try another.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() => showDialog<void>(
    context: context,
    builder: (_) => _EditFounderDialog(founder: founder),
  );

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        context.watch<AuthStore>().currentUser?.role == UserRole.superAdmin;
    final hasPhoto = founder.imageUrl != null && founder.imageUrl!.isNotEmpty;

    return AnimatedCard(
      // CONTAINER (card): portrait photo slot above the founder's details.
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.cardAll,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPhoto)
                    CardImage(seed: founder.id, src: founder.imageUrl)
                  else
                    _PhotoPlaceholder(founder: founder, admin: isAdmin),
                  if (isAdmin)
                    Positioned(
                      right: Space.sm,
                      bottom: Space.sm,
                      child: AlchemyButton(
                        label: hasPhoto ? 'Change photo' : 'Upload photo',
                        icon: HugeIcons.strokeRoundedCamera01,
                        variant: ButtonVariant.secondary,
                        loading: _busy,
                        onPressed: _upload,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    founder.name,
                    style: AppText.h3.copyWith(
                      fontSize: 22,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  // CONTAINER (decoration): red role pill.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.redSoft,
                      borderRadius: Radii.pillAll,
                    ),
                    child: Text(
                      founder.role,
                      style: AppText.small.copyWith(color: AppColors.red),
                    ),
                  ),
                  if (founder.bio.isNotEmpty) ...[
                    const SizedBox(height: Space.sm),
                    Text(founder.bio, style: AppText.bodyMuted),
                  ],
                  if (isAdmin) ...[
                    const SizedBox(height: Space.sm),
                    TextButton(
                      onPressed: _edit,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.red,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Edit details'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Branded stand-in until a photo is added: red-to-white wash with initials.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.founder, required this.admin});

  final Founder founder;
  final bool admin;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.redSoft, AppColors.surface, AppColors.grey100],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: AppColors.red,
              child: Text(
                founder.initials,
                style: AppText.h2(context).copyWith(color: AppColors.onAccent),
              ),
            ),
            const SizedBox(height: Space.md),
            AppIcon(
              HugeIcons.strokeRoundedCamera01,
              size: 22,
              color: AppColors.grey500,
            ),
            const SizedBox(height: Space.xxs),
            Text(
              admin ? 'Add a photo' : 'Photo coming soon',
              style: AppText.small,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditFounderDialog extends StatefulWidget {
  const _EditFounderDialog({required this.founder});
  final Founder founder;

  @override
  State<_EditFounderDialog> createState() => _EditFounderDialogState();
}

class _EditFounderDialogState extends State<_EditFounderDialog> {
  // FORM: founder details with a required name.
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.founder.name);
  late final _role = TextEditingController(text: widget.founder.role);
  late final _bio = TextEditingController(text: widget.founder.bio);
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _role, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = await context.read<CatalogStore>().saveFounder(
      widget.founder.copyWith(
        name: _name.text.trim(),
        role: _role.text.trim().isEmpty ? 'Founder' : _role.text.trim(),
        bio: _bio.text.trim(),
      ),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Edit founder', style: AppText.h3),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledField(
                label: 'Name',
                controller: _name,
                validator: (v) => Validators.required(v, 'a name'),
              ),
              const SizedBox(height: Space.md),
              LabeledField(label: 'Role', controller: _role),
              const SizedBox(height: Space.md),
              LabeledField(
                label: 'Short bio',
                controller: _bio,
                maxLines: 4,
                minLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AlchemyButton(label: 'Save', loading: _busy, onPressed: _save),
      ],
    );
  }
}
