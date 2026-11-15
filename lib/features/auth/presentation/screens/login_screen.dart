import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/password_field.dart';
import '../widgets/privacy_note.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await auth.logIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    // On success AuthGate swaps this screen out; nothing to do here.
    if (!mounted || success) return;
    messenger.showSnackBar(
      SnackBar(content: Text(auth.errorMessage ?? 'Could not log in.')),
    );
  }

  void _notYet(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature comes after v1.')));
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().isSubmitting;

    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 72,
                    ),
                    // IntrinsicHeight gives the Column a bounded height, so
                    // the Spacer below can push the note to the bottom on
                    // tall screens while short screens still scroll.
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AuthBrandHeader(),
                          const SizedBox(height: 36),
                          AppTextField(
                            label: 'Email',
                            controller: _emailController,
                            hint: 'you@example.com',
                            enabled: !busy,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            prefixIcon: Icons.mail_outline_rounded,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _passwordController,
                            enabled: !busy,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            validator: Validators.loginPassword,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: busy
                                  ? null
                                  : () => _notYet('Password reset'),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FilledButton(
                            onPressed: busy ? null : _submit,
                            child: busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Log in'),
                          ),
                          const SizedBox(height: 18),
                          const _OrDivider(),
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: busy
                                ? null
                                : () => _notYet('Phone sign-in'),
                            icon: const Icon(
                              Icons.phone_iphone_rounded,
                              size: 20,
                            ),
                            label: const Text('Continue with phone (OTP)'),
                          ),
                          const SizedBox(height: 28),
                          const Spacer(),
                          const PrivacyNote(
                            text:
                                'Your bills stay on this phone. '
                                'Sign in only to sync later.',
                          ),
                          const SizedBox(height: 18),
                          _FooterPrompt(
                            question: 'New here?',
                            actionLabel: 'Create account',
                            onPressed: busy
                                ? null
                                : () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.signUp),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = Expanded(
      child: Container(height: 1, color: scheme.outlineVariant),
    );

    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        line,
      ],
    );
  }
}

class _FooterPrompt extends StatelessWidget {
  const _FooterPrompt({
    required this.question,
    required this.actionLabel,
    required this.onPressed,
  });

  final String question;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Wrap, not Row: at 390 px with a long label the two parts would
    // otherwise overflow sideways.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(0, 44),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
