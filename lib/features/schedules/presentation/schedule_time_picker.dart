import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';

/// Wheel and typed input share a temporary value; only Done commits it.
Future<TimeOfDay?> showScheduleTimePicker(BuildContext context, {required TimeOfDay initialTime}) {
  var selected = initialTime;
  final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    sheetAnimationStyle: AnimationStyle(duration: AppMotion.screen(context), reverseDuration: AppMotion.control(context)),
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select time', style: Theme.of(sheet).textTheme.titleLarge),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: use24h,
                initialDateTime: DateTime(2000, 1, 1, selected.hour, selected.minute),
                onDateTimeChanged: (time) => selected = TimeOfDay(hour: time.hour, minute: time.minute),
              ),
            ),
            Row(
              children: [
                TextButton(onPressed: () => Navigator.of(sheet).pop(), child: const Text('Cancel')),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.keyboard_outlined, size: 20),
                    label: const Text('Keyboard input'),
                    onPressed: () async {
                      final value = await showTimePicker(
                        context: sheet,
                        initialTime: selected,
                        initialEntryMode: TimePickerEntryMode.input,
                        builder: (context, child) => MediaQuery(
                          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24h),
                          child: child!,
                        ),
                      );
                      if (value != null && sheet.mounted) Navigator.of(sheet).pop(value);
                    },
                  ),
                ),
                FilledButton(onPressed: () => Navigator.of(sheet).pop(selected), child: const Text('Done')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
