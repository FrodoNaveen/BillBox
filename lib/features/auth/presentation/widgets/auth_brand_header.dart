import 'package:flutter/material.dart';

/// The logo tile, wordmark and tagline at the top of the login screen.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 32,
            color: scheme.onPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'BillBox',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Capture once. Get reminded in time.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
