import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A labelled text field: the label sits above the box, as in the design,
/// instead of floating inside it.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.optional = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;

  /// Shows a quieter "(optional)" next to the label.
  final bool optional;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffixIcon;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool autofocus;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.primary,
                ),
              ),
              if (optional)
                Text(
                  ' (optional)',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          enabled: enabled,
          autofocus: autofocus,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperStyle: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
            counterText: '',
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 20, color: scheme.onSurfaceVariant),
            prefix: prefix,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
