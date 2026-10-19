import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/schediel_theme.dart';
import '../theme/tokens.dart';

/// The label stays inside the filled field, not across its outline.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final int maxLines;
  final bool enabled;
  final bool autofocus;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.scheduleColors;
    final radius = BorderRadius.circular(colors.style == StyleFamily.pixel ? 0 : Tokens.radiusControl);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: errorText == null ? colors.inputBoundary : Theme.of(context).colorScheme.error),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: TextField(
          controller: controller,
          enabled: enabled,
          autofocus: autofocus,
          minLines: 1,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            floatingLabelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.secondaryInk),
            errorText: errorText,
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: colors.surface,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          ),
        ),
      ),
    );
  }
}
