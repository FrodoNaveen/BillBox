import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Name and phone number, editable. The email is what the account is keyed
/// on, so it is shown but not editable here.
class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final saved = await context.read<AuthProvider>().updateProfile(
      name: _name.text,
      phone: _phone.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    final messenger = ScaffoldMessenger.of(context);
    if (saved) {
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
      Navigator.of(context).pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().errorMessage ??
                'Could not save your details.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            AppTextField(
              label: 'Full name',
              controller: _name,
              hint: 'Naveen Kumar',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: Validators.name,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Mobile number',
              controller: _phone,
              hint: '98765 43210',
              optional: true,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              maxLength: 12,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
              ],
              validator: Validators.optionalIndianMobile,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Email',
              controller: _email,
              enabled: false,
              helper:
                  'This is what you log in with, so it cannot be '
                  'changed here.',
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
