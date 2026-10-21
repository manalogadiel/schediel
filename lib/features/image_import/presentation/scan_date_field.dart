import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/widgets/labeled_field.dart';
import '../../../core/time/local_date.dart';

/// Calendar selection only: no numeric keyboard or date-format entry required.
class ScanDateField extends ConsumerWidget {
  const ScanDateField({super.key, required this.label, required this.value,
    required this.onChanged, this.firstDate, this.focusDate, this.errorText,
    this.allowClear = false});

  final String label;
  final LocalDate? value, firstDate, focusDate;
  final ValueChanged<LocalDate?> onChanged;
  final String? errorText;
  final bool allowClear;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    FocusScope.of(context).unfocus();
    final first = firstDate ?? LocalDate(LocalDate.minYear, 1, 1);
    final last = LocalDate(LocalDate.maxYear, 12, 31);
    final today = ref.read(todayProvider);
    var initial = value ?? focusDate ?? today;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    DateTime date(LocalDate d) => DateTime(d.year, d.month, d.day);
    final picked = await showDatePicker(context: context,
      initialDate: date(initial), firstDate: date(first), lastDate: date(last),
      currentDate: date(today), initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: label, confirmText: 'Done', cancelText: 'Cancel');
    if (!context.mounted || picked == null) return;
    final next = LocalDate.fromDateTime(picked);
    if (next != value) onChanged(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => FieldLabel(label: label,
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Semantics(button: true, child: InkWell(
        onTap: () => _pick(context, ref),
        child: InputDecorator(decoration: InputDecoration(errorText: errorText,
          suffixIcon: const Padding(padding: EdgeInsets.all(12), child: AppIcon(AppIcons.calendar))),
          child: Text(value == null ? 'Choose date' : Formats.of(context).fullDate(value!),
            style: Theme.of(context).textTheme.bodyLarge)),
      ))),
      if (allowClear && value != null)
        IconButton(tooltip: 'Clear $label', onPressed: () => onChanged(null),
          icon: const AppIcon(AppIcons.close)),
    ]));
}
