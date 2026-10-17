import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/time/local_time.dart';
import '../domain/alert_rule.dart';
import 'capability_note.dart';

const _presetOffsets = [0, 5, 10, 15, 30, 60];

/// Independent notification and alarm preferences (spec 4.5, 7.1). These
/// are desired settings; actual scheduling status is shown separately.
class AlertEditor extends ConsumerWidget {
  const AlertEditor({
    super.key,
    required this.notification,
    required this.alarm,
    required this.dateOnly,
    required this.deviceZone,
    required this.errors,
    required this.onChanged,
  });

  final AlertPreference notification;
  final AlertPreference alarm;
  final bool dateOnly;
  final String deviceZone;
  final Map<String, String> errors;
  final void Function(AlertPreference notification, AlertPreference alarm) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AlertBlock(
          preference: notification,
          title: 'Notification',
          dateOnly: dateOnly,
          deviceZone: deviceZone,
          error: errors['alerts/notification'],
          onChanged: (p) => onChanged(p, alarm),
        ),
        Padding(padding: const EdgeInsets.only(left: Tokens.md), child: Divider(color: context.scheduleColors.divider)),
        _AlertBlock(
          preference: alarm,
          title: 'Alarm',
          dateOnly: dateOnly,
          deviceZone: deviceZone,
          error: errors['alerts/alarm'],
          onChanged: (p) => onChanged(notification, p),
        ),
        const SizedBox(height: Tokens.sm),
      ],
    );
  }
}

class _AlertBlock extends StatelessWidget {
  const _AlertBlock({
    required this.preference,
    required this.title,
    required this.dateOnly,
    required this.deviceZone,
    required this.error,
    required this.onChanged,
  });

  final AlertPreference preference;
  final String title;
  final bool dateOnly;
  final String deviceZone;
  final String? error;
  final ValueChanged<AlertPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final f = Formats.of(context);
    final p = preference;
    final secondary = context.scheduleColors.secondaryInk;
    final isAlarm = p.kind == AlertKind.alarm;
    final custom = !_presetOffsets.contains(p.offsetMinutes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: Text(title),
          subtitle: Text(p.enabled ? f.offsetLabel(p.offsetMinutes) : 'Off'),
          value: p.enabled,
          onChanged: (v) => onChanged(p.copyWith(enabled: v)),
        ),
        if (p.enabled) ...[
          CapabilityNote(kind: p.kind),
          Padding(
            padding: const EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, Tokens.sm),
            child: Wrap(
              spacing: Tokens.sm,
              runSpacing: Tokens.sm,
              children: [
                for (final m in _presetOffsets)
                  ChoiceChip(
                    label: Text(m == 0 ? 'At start' : f.offsetLabel(m).replaceAll(' before', '')),
                    selected: p.offsetMinutes == m,
                    onSelected: (_) => onChanged(p.copyWith(offsetMinutes: m)),
                  ),
                ChoiceChip(
                  label: Text(custom ? f.offsetLabel(p.offsetMinutes).replaceAll(' before', '') : 'Custom'),
                  selected: custom,
                  onSelected: (_) async {
                    final value = await _askMinutes(context, p.offsetMinutes);
                    if (value != null) onChanged(p.copyWith(offsetMinutes: value));
                  },
                ),
              ],
            ),
          ),
          if (dateOnly)
            ListTile(
              title: const Text('Reminder time'),
              subtitle: error != null
                  ? Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))
                  : Text(p.dateOnlyAnchorTime == null
                      ? 'All-day schedules need a chosen time'
                      : '${f.clock(p.dateOnlyAnchorTime!)} · ${p.dateOnlyAnchorZone}'),
              trailing: Text(p.dateOnlyAnchorTime == null ? 'Choose' : 'Change', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              onTap: () async {
                final initial = p.dateOnlyAnchorTime ?? LocalTime(9, 0);
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
                );
                if (picked != null) {
                  onChanged(p.copyWith(
                    dateOnlyAnchorTime: () => LocalTime(picked.hour, picked.minute),
                    dateOnlyAnchorZone: () => p.dateOnlyAnchorZone ?? deviceZone,
                  ));
                }
              },
            ),
          SwitchListTile(
            title: const Text('Show details on lock screen'),
            subtitle: Text(
              p.lockScreenDetails == LockScreenDetails.detailsRequested
                  ? 'Requests room and person. Device privacy settings still apply.'
                  : 'Title only',
              style: TextStyle(color: secondary),
            ),
            value: p.lockScreenDetails == LockScreenDetails.detailsRequested,
            onChanged: (v) => onChanged(p.copyWith(
              lockScreenDetails: v ? LockScreenDetails.detailsRequested : LockScreenDetails.titleOnly,
            )),
          ),
          if (isAlarm) ...[
            SwitchListTile(
              title: const Text('Prominent alarm when allowed'),
              subtitle: Text('Uses a full-screen alarm only where the device permits it.', style: TextStyle(color: secondary)),
              value: p.presentationPreference == PresentationPreference.prominentIfSupported,
              onChanged: (v) => onChanged(p.copyWith(
                presentationPreference: v ? PresentationPreference.prominentIfSupported : PresentationPreference.standard,
              )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, Tokens.sm),
              child: Row(
                children: [
                  Expanded(child: Text('Snooze', style: Theme.of(context).textTheme.bodyLarge)),
                  DropdownButton<int?>(
                    value: p.snoozeMinutes,
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Off')),
                      for (final m in supportedSnoozeMinutes) DropdownMenuItem(value: m, child: Text('$m min')),
                    ],
                    onChanged: (v) => onChanged(p.copyWith(snoozeMinutes: () => v)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<int?> _askMinutes(BuildContext context, int current) {
    final controller = TextEditingController(text: '$current');
    return showDialog<int>(
      context: context,
      builder: (context) {
        String? error;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Minutes before'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: 'Minutes', errorText: error),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value == null || value < 0 || value > maxAlertOffsetMinutes) {
                    setState(() => error = 'Enter 0 to $maxAlertOffsetMinutes');
                    return;
                  }
                  Navigator.of(context).pop(value);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }
}
