import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/mock/services.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/validators.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/check_field.dart';
import '../../widgets/common/labeled_field.dart';
import '../../widgets/layout/split_form_page.dart';

/// Contact screen. No backend: a valid submit shows a success state.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  static const _other = 'Something else';

  // FORM: one key validates the contact form on submit.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _org = TextEditingController();
  final _message = TextEditingController();

  String? _topic;
  bool _consent = false;
  String? _sentTo; // first name once sent

  List<String> get _topics => [for (final s in services) s.title, _other];

  @override
  void dispose() {
    for (final c in [_name, _email, _org, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sentTo = _name.text.trim().split(' ').first);
  }

  void _reset() {
    for (final c in [_name, _email, _org, _message]) {
      c.clear();
    }
    setState(() {
      _topic = null;
      _consent = false;
      _sentTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SplitFormPage(
      headline: 'Book a call',
      copy:
          'Tell us what is going on in your team. We will suggest a first '
          'conversation, with no obligation.',
      aside: const _ContactRows(),
      panel: _sentTo != null ? _success() : _form(),
    );
  }

  Widget _success() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(
          HugeIcons.strokeRoundedCheckmarkCircle02,
          size: 40,
          color: AppColors.success,
        ),
        const SizedBox(height: Space.md),
        Semantics(
          liveRegion: true,
          child: Text(
            'Thanks, $_sentTo. We will reply within two working days.',
            style: AppText.h3,
          ),
        ),
        const SizedBox(height: Space.lg),
        AlchemyButton(
          label: 'Send another message',
          variant: ButtonVariant.secondary,
          onPressed: _reset,
        ),
      ],
    );
  }

  Widget _form() {
    return AutofillGroup(
      // FORM: Form with required fields, a topic dropdown and a message minimum.
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledField(
              label: 'Your name',
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) => Validators.required(v, 'your name'),
            ),
            const SizedBox(height: Space.lg),
            LabeledField(
              label: 'Email address',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
            ),
            const SizedBox(height: Space.lg),
            LabeledField(
              label: 'Organisation (optional)',
              controller: _org,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.organizationName],
            ),
            const SizedBox(height: Space.lg),
            LabeledDropdown<String>(
              label: 'What would you like to talk about?',
              hint: 'Choose a topic',
              value: _topic,
              items: [
                for (final t in _topics)
                  DropdownMenuItem(
                    value: t,
                    child: Text(t, style: AppText.body),
                  ),
              ],
              onChanged: (v) => setState(() => _topic = v),
              validator: (v) => v == null ? 'Choose a topic.' : null,
            ),
            const SizedBox(height: Space.lg),
            LabeledField(
              label: 'Message',
              controller: _message,
              helper: 'At least 20 characters.',
              minLines: 4,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              validator: (v) => Validators.minLength(v, 20, 'a message'),
            ),
            const SizedBox(height: Space.lg),
            CheckField(
              label: 'I agree to MT Alchemy contacting me about this enquiry.',
              value: _consent,
              onChanged: (v) => setState(() => _consent = v),
              requiredMessage: 'Please give your consent so we can reply.',
            ),
            const SizedBox(height: Space.lg),
            // One primary (red) button per view.
            AlchemyButton(
              label: 'Send message',
              onPressed: _submit,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRows extends StatelessWidget {
  const _ContactRows();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (HugeIcons.strokeRoundedMail01, 'hello@mtalchemy.co.uk'),
      (HugeIcons.strokeRoundedCall, '+44 20 7946 0123'),
      (
        HugeIcons.strokeRoundedLocation01,
        'Based in the UK, working remotely and on site',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (icon, text) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(icon, size: 22, color: AppColors.grey700),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(text, style: AppText.body)),
              ],
            ),
          ),
      ],
    );
  }
}
