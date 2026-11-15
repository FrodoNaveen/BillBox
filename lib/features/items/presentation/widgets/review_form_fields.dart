import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatting.dart';

/// The little "read from bill" tag under a field the photo filled in.
class ReadFromBillChip extends StatelessWidget {
  const ReadFromBillChip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded,
              size: 12,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 5),
            Text(
              'read from bill',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The label that sits above every field on this form.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// A field-shaped button that opens a picker — used for the category and both
/// dates, so they line up with the text fields beside them.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.placeholder,
  });

  final String label;

  /// Null shows [placeholder] in the quieter colour.
  final String? value;
  final String? placeholder;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final empty = value == null || value!.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        Semantics(
          button: true,
          label: '$label, ${empty ? (placeholder ?? 'not set') : value}',
          child: Material(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 54,
                padding: const EdgeInsets.only(left: 14, right: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        empty ? (placeholder ?? 'Not set') : value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          color: empty
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The photo this item came from: thumbnail, file name, and a way back to the
/// camera. Shown only when a photo was taken.
class CapturedPhotoRow extends StatelessWidget {
  const CapturedPhotoRow({
    super.key,
    required this.imageName,
    required this.sourceLabel,
    required this.onRetake,
  });

  final String imageName;
  final String sourceLabel;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 62,
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PaperLine(width: 0.8, strong: true),
              _PaperLine(width: 1),
              _PaperLine(width: 0.9),
              _PaperLine(width: 0.95),
              _PaperLine(width: 0.7),
              const Spacer(),
              _PaperLine(width: 0.55, strong: true),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                imageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$sourceLabel · stays on this device',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onRetake,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: const Text('Retake'),
        ),
      ],
    );
  }
}

class _PaperLine extends StatelessWidget {
  const _PaperLine({required this.width, this.strong = false});

  final double width;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FractionallySizedBox(
        widthFactor: width,
        alignment: Alignment.centerLeft,
        child: Container(
          height: strong ? 4 : 3,
          decoration: BoxDecoration(
            color: strong ? scheme.onSurfaceVariant : AppColors.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// The amber "check the details" banner at the top of the review form.
class ScanReviewBanner extends StatelessWidget {
  const ScanReviewBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 22,
            color: scheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats a date for a [PickerField], or null when there is none.
String? pickerDateLabel(DateTime? date) =>
    date == null ? null : formatItemDate(date);
