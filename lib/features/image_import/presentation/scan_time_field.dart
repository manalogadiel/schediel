import 'package:flutter/material.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/widgets/labeled_field.dart';
import '../../../core/time/local_time.dart';
import '../../schedules/presentation/schedule_time_picker.dart';

/// Missing OCR times stay blank until the user confirms a wheel selection.
class ScanTimeField extends StatelessWidget {
  const ScanTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final LocalTime? value;
  final ValueChanged<LocalTime> onChanged;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final current = value;
    final picked = await showScheduleTimePicker(
      context,
      initialTime: current == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: current.hour, minute: current.minute),
      allowKeyboardInput: false,
    );
    if (!context.mounted || picked == null) return;
    final next = LocalTime(picked.hour, picked.minute);
    if (next != value) onChanged(next);
  }

  @override
  Widget build(BuildContext context) => FieldLabel(
    label: label,
    child: Semantics(
      button: true,
      child: InkWell(
        onTap: () => _pick(context),
        child: InputDecorator(
          decoration: InputDecoration(
            errorText: errorText,
            suffixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: AppIcon(AppIcons.time),
            ),
          ),
          child: Text(
            value == null ? 'Choose time' : Formats.of(context).clock(value!),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    ),
  );
}
