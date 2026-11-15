import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';

/// Three bars plus a short label, as on the sign-up screen.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final score = Validators.passwordStrength(password);

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: i < score ? scheme.primary : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Expanded(
            child: Text(
              password.isEmpty
                  ? 'At least ${Validators.minPasswordLength} characters'
                  : Validators.passwordStrengthLabel(password),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
