import 'package:flutter/material.dart';

import '../../../../core/widgets/coming_soon_view.dart';

/// Placeholder for the reminders tab.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: const ComingSoonView(
        icon: Icons.notifications_none_rounded,
        title: 'Reminders',
        message:
            'Everything due soon will be listed here, with a nudge 30, 7 and '
            '1 day before anything expires.',
      ),
    );
  }
}
