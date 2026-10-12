import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/validators.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/check_field.dart';
import '../../widgets/common/labeled_field.dart';
import '../../widgets/layout/split_form_page.dart';

enum AccountType { individual, organisation }

/// Register screen: Journey A (individual) and Journey C (organisation) start here.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialType = AccountType.individual});

  final AccountType initialType;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _sizes = ['1 to 49', '50 to 249', '250 to 999', '1000+'];
  static const _genders = ['Female', 'Male', 'Prefer not to say'];
  static const _countries = [
    'Malaysia',
    'Singapore',
    'Indonesia',
    'Thailand',
    'United Kingdom',
    'Other',
  ];
  static const _hobbyOptions = ['Reading', 'Sports', 'Music', 'Travel'];

  // FORM: one key validates the whole registration form on submit.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _orgName = TextEditingController();
  final _sector = TextEditingController();

  late AccountType _type = widget.initialType;
  String? _size;
  bool _terms = false;
  String? _emailError;
  String? _gender;
  String? _country;
  final Set<String> _hobbies = {};
  bool _busy = false;

  bool get _isOrg => _type == AccountType.organisation;

  @override
  void didUpdateWidget(RegisterScreen old) {
    super.didUpdateWidget(old);
    if (old.initialType != widget.initialType) _type = widget.initialType;
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm, _orgName, _sector]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _emailError = null);
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthStore>();
    setState(() => _busy = true);
    final error = _isOrg
        ? await auth.registerOrganisation(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            organisationName: _orgName.text,
            sector: _sector.text,
            size: _size!,
          )
        : await auth.registerIndividual(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            gender: _gender,
            country: _country,
            hobbies: _hobbies.toList(),
          );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      // Account problems (e.g. email in use) show inline on the email field.
      setState(() => _emailError = error);
      _formKey.currentState!.validate();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome, ${_name.text.trim().split(' ').first}')),
    );
    // Journey A goes to Browse Learning; Journey D goes to the employer portal.
    context.go(_isOrg ? Routes.employer : Routes.upskilling);
  }

  Widget _personalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Space.lg),
        // Gender: radio buttons wrapped in a FormField so it validates
        // with the rest of the form.
        FormField<String>(
          validator: (_) => _gender == null ? 'Choose an option.' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gender', style: AppText.label),
              RadioGroup<String>(
                groupValue: _gender,
                onChanged: (v) {
                  setState(() => _gender = v);
                  field.didChange(v);
                },
                child: Wrap(
                  spacing: Space.md,
                  children: [
                    for (final g in _genders)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(value: g, activeColor: AppColors.red),
                          Text(g, style: AppText.body),
                        ],
                      ),
                  ],
                ),
              ),
              if (field.hasError)
                Text(
                  field.errorText!,
                  style: AppText.small.copyWith(color: AppColors.error),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        LabeledDropdown<String>(
          label: 'Country',
          hint: 'Choose your country',
          value: _country,
          items: [
            for (final c in _countries)
              DropdownMenuItem(value: c, child: Text(c, style: AppText.body)),
          ],
          onChanged: (v) => setState(() => _country = v),
          validator: (v) => v == null ? 'Choose your country.' : null,
        ),
        const SizedBox(height: Space.lg),
        Text('Hobbies (optional)', style: AppText.label),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final h in _hobbyOptions)
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SplitFormPage(
      headline: _isOrg ? 'Set up your organisation' : 'Create your account',
      copy: _isOrg
          ? 'Register your organisation, add your people and assign them '
                'courses. You can see how everyone is getting on.'
          : 'Browse the learning library, enrol in a course and keep track '
                'of your progress in one place.',
      aside: Row(
        children: [
          Text('Already registered?', style: AppText.bodyMuted),
          const SizedBox(width: Space.sm),
          ArrowLink(label: 'Sign in', onTap: () => context.go(Routes.login)),
        ],
      ),
      panel: AutofillGroup(
        // FORM: Form with TextFormFields, required-field and format validation.
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('I am registering as', style: AppText.label),
              const SizedBox(height: Space.xs),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  for (final t in AccountType.values)
                    ChoiceChip(
                      label: Text(
                        t == AccountType.individual
                            ? 'Individual'
                            : 'Organisation',
                      ),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                ],
              ),
              const SizedBox(height: Space.lg),
              LabeledField(
                label: 'Full name',
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) => Validators.required(v, 'your full name'),
              ),
              const SizedBox(height: Space.lg),
              LabeledField(
                label: 'Email address',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                validator: (v) => Validators.email(v) ?? _emailError,
              ),
              if (!_isOrg) _personalDetails(),
              if (_isOrg) ...[
                const SizedBox(height: Space.lg),
                LabeledField(
                  label: 'Organisation name',
                  controller: _orgName,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.organizationName],
                  validator: (v) =>
                      Validators.required(v, 'your organisation name'),
                ),
                const SizedBox(height: Space.lg),
                LabeledField(
                  label: 'Sector',
                  controller: _sector,
                  helper: 'For example housing, retail or health.',
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'your sector'),
                ),
                const SizedBox(height: Space.lg),
                LabeledDropdown<String>(
                  label: 'Organisation size',
                  hint: 'Choose a size',
                  value: _size,
                  items: [
                    for (final s in _sizes)
                      DropdownMenuItem(
                        value: s,
                        child: Text('$s employees', style: AppText.body),
                      ),
                  ],
                  onChanged: (v) => setState(() => _size = v),
                  validator: (v) => v == null ? 'Choose a size.' : null,
                ),
              ],
              const SizedBox(height: Space.lg),
              LabeledField(
                label: 'Password',
                controller: _password,
                obscure: true,
                helper: 'At least 8 characters, with a letter and a number.',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
              ),
              const SizedBox(height: Space.lg),
              LabeledField(
                label: 'Confirm password',
                controller: _confirm,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => Validators.confirm(v, _password.text),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Space.lg),
              CheckField(
                label: 'I agree to the terms of use and privacy notice.',
                value: _terms,
                onChanged: (v) => setState(() => _terms = v),
                requiredMessage: 'Please agree to the terms to continue.',
              ),
              const SizedBox(height: Space.lg),
              // One primary (red) button per view.
              AlchemyButton(
                label: _isOrg ? 'Register organisation' : 'Create account',
                onPressed: _submit,
                loading: _busy,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
