import 'package:flutter/material.dart';

import '../../../../core/widgets/coming_soon_view.dart';

/// Placeholder for the capture flow the add button opens.
class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add item')),
      body: const ComingSoonView(
        icon: Icons.photo_camera_outlined,
        title: 'Capture a bill',
        message:
            'Camera, gallery and file picker, then on-device OCR filling in '
            'the title, amount and dates.',
      ),
    );
  }
}
