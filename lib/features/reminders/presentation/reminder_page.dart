import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/time/local_date.dart';
import '../application/alert_planner.dart';
import '../application/capabilities.dart';

/// In-app full-page reminder shown when a reminder or alarm comes due while
/// the app is open (spec 7.1). Stop and Done never change the schedule.
class ReminderPage extends ConsumerWidget {
  const ReminderPage({
    super.key,
    required this.seriesId,
    required this.originalKey,
    required this.isAlarm,
    required this.requestKey,
  });

  final String seriesId;
  final LocalDate? originalKey;
  final bool isAlarm;
  final String requestKey;

  /// Stops the native alarm or clears the delivered notification.
  Future<void> _acknowledge(WidgetRef ref) async {
    if (requestKey.isEmpty) return;
    if (isAlarm) {
      await ref.read(nativeBridgeProvider).stopAlarm(requestKey);
    } else {
      await ref.read(notificationGatewayProvider).cancel(notificationIdFor(requestKey));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = originalKey;
    final series = ref.watch(seriesByIdProvider(seriesId));
    final zone = ref.watch(deviceZoneProvider);
    final occurrence = switch (series) {
      AsyncData(:final value) when value != null && key != null =>
        ref.watch(occurrenceLookupProvider).find(value, key, zone),
      _ => null,
    };
    final loading = series is AsyncLoading;
    final f = Formats.of(context);
    final text = Theme.of(context).textTheme;
    final secondary = context.scheduleColors.secondaryInk;

    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator.adaptive());
    } else if (occurrence == null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: EmptyState(title: 'Schedule no longer available')),
          FilledButton(
            onPressed: () async {
              await _acknowledge(ref);
              if (context.mounted) context.pop();
            },
            child: const Text('Close'),
          ),
        ],
      );
    } else {
      final timing = occurrence.timing;
      final time = switch (timing) {
        TimedTiming() => OccurrenceTimeText.of(timing, ref.watch(zoneResolverProvider), zone, f).range,
        DateOnlyTiming() => 'All day',
        UnresolvedTiming() => 'Time needs review',
      };
      final details = occurrence.details;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            AppIcon(isAlarm ? AppIcons.alarm : AppIcons.notification, size: 20, color: secondary),
            const SizedBox(width: Tokens.sm),
            Text(isAlarm ? 'Alarm' : 'Reminder', style: text.labelLarge?.copyWith(color: secondary)),
          ]),
          const SizedBox(height: Tokens.lg),
          Semantics(
            header: true,
            child: Text(occurrence.title, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: Tokens.sm),
          Text(time, style: text.titleMedium?.copyWith(color: secondary)),
          const SizedBox(height: Tokens.md),
          if (details.location != null) DetailLine(icon: AppIcons.location, text: details.location!),
          if (details.professor != null) DetailLine(icon: AppIcons.person, text: details.professor!),
          if (details.subtitle != null) DetailLine(icon: AppIcons.text, text: details.subtitle!),
          const Spacer(),
          FilledButton(
            onPressed: () async {
              await _acknowledge(ref);
              if (context.mounted) context.pop();
            },
            child: Text(isAlarm ? 'Stop' : 'Done'),
          ),
          const SizedBox(height: Tokens.sm),
          OutlinedButton(
            onPressed: () async {
              await _acknowledge(ref);
              if (context.mounted) context.pushReplacement('/occurrence/$seriesId/${key!.toIso()}');
            },
            child: const Text('Open details'),
          ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Tokens.lg, Tokens.xl, Tokens.lg, Tokens.lg),
          child: body,
        ),
      ),
    );
  }
}
