import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/mock/demo_accounts.dart';
import '../../data/models/people.dart';
import '../../router/app_router.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/validators.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/labeled_field.dart';
import '../../widgets/layout/split_form_page.dart';

/// Sign in screen (Journey A and C entry point).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.from});

  /// Where to go after signing in (the `from` query parameter).
  final String? from;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // FORM: the key lets us validate every field at once on submit.
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthStore>();
    setState(() => _busy = true);
    final error = await auth.signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (auth.currentUser == null) return; // Router redirects once loaded.
    final from = widget.from;
    // Only follow in-app paths so the link cannot send people elsewhere.
    final target = (from != null && from.startsWith('/'))
        ? from
        : portalHomeFor(auth.currentUser!.role);
    context.go(target);
  }

  Future<void> _forgot() async {
    final messenger = ScaffoldMessenger.of(context);
    if (Validators.email(_email.text) != null) {
      setState(() => _error = 'Enter your email above, then tap Forgot password.');
      return;
    }
    final error = await context.read<AuthStore>().sendPasswordReset(
      _email.text,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'If that email has an account, a reset link is on its way.',
        ),
      ),
    );
  }

  void _useDemo(String email) {
    _formKey.currentState?.reset(); // clears any validation errors
    setState(() => _error = null);
    _email.text = email;
    _password.text = demoPassword;
  }

  @override
  Widget build(BuildContext context) {
    return SplitFormPage(
      headline: 'Welcome back',
      copy:
          'Sign in to pick up your learning, or to manage your team and '
          'their progress.',
      aside: Row(
        children: [
          Text('New here?', style: AppText.bodyMuted),
          const SizedBox(width: Space.sm),
          ArrowLink(
            label: 'Create an account',
            onTap: () => context.go(Routes.register),
          ),
        ],
      ),
      panel: AutofillGroup(
        // FORM: Form with required-field validation on email and password.
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                label: 'Password',
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (v) => Validators.required(v, 'your password'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Space.lg),
              if (_error != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: AppText.small.copyWith(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: Space.md),
              ],
              // One primary (red) button per view.
              AlchemyButton(
                label: 'Sign in',
                onPressed: _submit,
                loading: _busy,
                expand: true,
              ),
              const SizedBox(height: Space.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgot,
                  style: TextButton.styleFrom(foregroundColor: AppColors.red),
                  child: Text('Forgot password?', style: AppText.label),
                ),
              ),
              const SizedBox(height: Space.xl),
              _DemoAccounts(onUse: _useDemo),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plain panel (not glass, since it sits inside the glass form panel).
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.onUse});

  final ValueChanged<String> onUse;

  @override
  Widget build(BuildContext context) {
    // CONTAINER (grouping + decoration): a quiet bordered box for demo logins.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: Radii.inputAll,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demo accounts', style: AppText.label),
          const SizedBox(height: Space.xxs),
          Text('Password for all: $demoPassword', style: AppText.small),
          const SizedBox(height: Space.xs),
          for (final user in demoUsers)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xxs),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.name}, ${user.role.label}',
                          style: AppText.label,
                        ),
                        Text(
                          user.email,
                          style: AppText.small,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => onUse(user.email),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.red,
                      textStyle: AppText.label,
                    ),
                    child: const Text('Use'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
