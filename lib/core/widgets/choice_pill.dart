import 'package:flutter/material.dart';

/// The small chip used wherever something is picked from a short list — the
/// search filters and the reminder lead times on the add-item form.
///
/// Filled with a tick when it is on, outlined when it is off.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.trailing,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Used when the label alone is not clear out of context, such as "30 days"
  /// on the reminder row.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Semantics(
      label: semanticLabel,
      selected: selected,
      button: onTap != null,
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: selected ? null : Border.all(color: scheme.outline),
            ),
            child: Row(
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 16, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: foreground,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 5), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
