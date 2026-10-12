import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/mock/services.dart';
import '../../router/routes.dart';
import '../../state/admin_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/validators.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/check_field.dart';
import '../../widgets/common/labeled_field.dart';
import '../../widgets/layout/split_form_page.dart';

/// Journey E: Organisations, Submit Enquiry, Customised Programme.
/// The enquiry is saved to Firestore and appears in the super admin inbox,
/// where it moves through New, In discussion, Proposal and Agreed.
class OrganisationsScreen extends StatefulWidget {
  const OrganisationsScreen({super.key});

  @override
  State<OrganisationsScreen> createState() => _OrganisationsScreenState();
}

class _OrganisationsScreenState extends State<OrganisationsScreen> {
  static const _sizes = ['1 to 49', '50 to 249', '250 to 999', '1000+'];

  // FORM: corporate enquiry with required fields and a consent check.
  final _formKey = GlobalKey<FormState>();
  final _org = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _goal = TextEditingController();
  String? _size;
  String? _interest;
  bool _consent = false;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_org, _name, _email, _goal]) {
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
    final error = await context.read<AdminStore>().submitEnquiry(
      organisation: _org.text,
      name: _name.text,
      email: _email.text,
      size: '${_size!} employees',
      interest: _interest!,
      message: _goal.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      _sent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SplitFormPage(
      headline: 'Programmes shaped around your people',
      copy:
          'Tell us what is happening in your organisation. We will design a '
          'customised programme: workshops, coaching and online learning, '
          'measured against the change you want to see.',
      aside: const _Steps(),
      panel: _sent ? _success(context) : _form(),
    );
  }

  Widget _success(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(
          HugeIcons.strokeRoundedCheckmarkCircle02,
          size: 40,
          color: AppColors.red,
        ),
        const SizedBox(height: Space.md),
        Text('Thank you. Your enquiry is with us.', style: AppText.h3),
        const SizedBox(height: Space.xs),
        Text(
          'A consultant will reply within two working days to book a '
          'discovery call. After that call we send a programme proposal.',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: Space.lg),
        AlchemyButton(
          label: 'Register your organisation',
          onPressed: () => context.go(
            Uri(
              path: Routes.register,
              queryParameters: {'type': 'organisation'},
            ).toString(),
          ),
        ),
        const SizedBox(height: Space.md),
        ArrowLink(
          label: 'See our services',
          onTap: () => context.go(Routes.services),
        ),
      ],
    );
  }

  Widget _form() {
    const gap = SizedBox(height: Space.lg);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledField(
            label: 'Organisation',
            controller: _org,
            autofillHints: const [AutofillHints.organizationName],
            validator: (v) => Validators.required(v, 'your organisation'),
          ),
          gap,
          LabeledField(
            label: 'Your name',
            controller: _name,
            autofillHints: const [AutofillHints.name],
            validator: (v) => Validators.required(v, 'your name'),
          ),
          gap,
          LabeledField(
            label: 'Work email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
          ),
          gap,
          LabeledDropdown<String>(
            label: 'Organisation size',
            hint: 'Choose a size',
            value: _size,
            items: [
              for (final s in _sizes)
                DropdownMenuItem(value: s, child: Text('$s employees')),
            ],
            onChanged: (v) => setState(() => _size = v),
            validator: (v) => v == null ? 'Choose a size.' : null,
          ),
          gap,
          LabeledDropdown<String>(
            label: 'Main interest',
            hint: 'Choose an area',
            value: _interest,
            items: [
              for (final s in services)
                DropdownMenuItem(value: s.title, child: Text(s.title)),
            ],
            onChanged: (v) => setState(() => _interest = v),
            validator: (v) => v == null ? 'Choose an area.' : null,
          ),
          gap,
          LabeledField(
            label: 'What would you like to change?',
            controller: _goal,
            maxLines: 5,
            minLines: 4,
            helper: 'For example: new managers avoid difficult conversations.',
            validator: (v) => Validators.required(v, 'a short description'),
          ),
          gap,
          CheckField(
            label: 'I agree to MT Alchemy contacting me about this enquiry.',
            value: _consent,
            onChanged: (v) => setState(() => _consent = v),
            requiredMessage: 'Please agree so we can reply.',
          ),
          gap,
          if (_error != null) ...[
            Text(
              _error!,
              style: AppText.small.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: Space.md),
          ],
          AlchemyButton(
            label: 'Send enquiry',
            loading: _busy,
            expand: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Enquiry', 'Share your goals and context.'),
      ('Discovery call', 'We listen to leaders and a few team members.'),
      (
        'Customised programme',
        'A proposal with formats, timings and measures.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.redSoft,
                  child: Text(
                    '${i + 1}',
                    style: AppText.label.copyWith(color: AppColors.red),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i].$1, style: AppText.label),
                      Text(steps[i].$2, style: AppText.small),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
