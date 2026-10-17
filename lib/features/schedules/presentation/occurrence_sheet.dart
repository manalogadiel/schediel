import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../core/schedule/models.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/time/local_date.dart';
import '../../reminders/application/clock_handoff.dart';
import '../../reminders/application/reconciliation_service.dart';
import '../../reminders/domain/alert_rule.dart';
import '../../../integrations/native/native_bridge.dart';
import '../../reminders/presentation/alert_status_line.dart';

/// Compact detail sheet for one occurrence (spec 4.5).
Future<void> showOccurrenceSheet(BuildContext context, Occurrence occurrence) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, controller) => OccurrenceDetails(
        seriesId: occurrence.seriesId,
        originalKey: occurrence.originalKey,
        scrollController: controller,
        inSheet: true,
      ),
    ),
  );
}

/// Full-page details, used by widget deep links.
class OccurrenceDetailsPage extends StatelessWidget {
  const OccurrenceDetailsPage({super.key, required this.seriesId, required this.originalKey});

  final String seriesId;
  final LocalDate? originalKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: originalKey == null
          ? const EmptyState(title: 'Schedule no longer available')
          : OccurrenceDetails(seriesId: seriesId, originalKey: originalKey!, inSheet: false),
    );
  }
}

class OccurrenceDetails extends ConsumerWidget {
  const OccurrenceDetails({
    super.key,
    required this.seriesId,
    required this.originalKey,
    this.scrollController,
    required this.inSheet,
  });

  final String seriesId;
  final LocalDate originalKey;
  final ScrollController? scrollController;
  final bool inSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesByIdProvider(seriesId));
    final zone = ref.watch(deviceZoneProvider);
    return seriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (_, _) => const EmptyState(title: 'Unable to load this schedule'),
      data: (series) {
        final occurrence = series == null ? null : ref.watch(occurrenceLookupProvider).find(series, originalKey, zone);
        if (series == null || occurrence == null) {
          return const EmptyState(title: 'Schedule no longer available');
        }
        return _DetailsBody(series: series, occurrence: occurrence, controller: scrollController, inSheet: inSheet);
      },
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  const _DetailsBody({required this.series, required this.occurrence, required this.controller, required this.inSheet});

  final ScheduleSeries series;
  final Occurrence occurrence;
  final ScrollController? controller;
  final bool inSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = Formats.of(context);
    final text = Theme.of(context).textTheme;
    final colors = context.scheduleColors;
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(deviceZoneProvider);
    final category = ref.watch(categoryByIdProvider(series.categoryId));
    final rules = (ref.watch(alertRulesProvider).value ?? const <AlertRule>[])
        .where((r) => r.seriesId == series.id && r.preference.enabled)
        .toList();
    final details = occurrence.details;
    final timing = occurrence.timing;

    final lines = <Widget>[];
    switch (timing) {
      case TimedTiming():
        final t = OccurrenceTimeText.of(timing, zones, zone, f);
        final localDate = zones.localDateOf(timing.startUtc, zone);
        lines.add(DetailLine(icon: AppIcons.time, text: '${f.fullDate(localDate)} · ${t.range}', style: text.bodyLarge));
        if (t.sourceNote != null) {
          lines.add(DetailLine(icon: AppIcons.info, text: 'Set in ${timing.sourceZone} (${t.sourceNote})'));
        }
      case DateOnlyTiming():
        final last = timing.endDateExclusive.addDays(-1);
        lines.add(DetailLine(
          icon: AppIcons.calendar,
          text: last == timing.startDate ? '${f.fullDate(timing.startDate)} · All day' : f.range(timing.startDate, last),
          style: text.bodyLarge,
        ));
      case UnresolvedTiming():
        lines.add(DetailLine(
          icon: AppIcons.time,
          text: '${f.fullDate(timing.localDate)} · ${f.clock(timing.localStartTime)} ${zoneCity(timing.sourceZone)} time',
          style: text.bodyLarge,
        ));
        lines.add(DetailLine(icon: AppIcons.warning, text: 'Needs time review. ${reviewReasonLabel(timing.reason)}'));
    }
    lines.add(DetailLine(icon: AppIcons.repeat, text: f.repeatSummary(series.recurrence)));
    if (occurrence.isOverride) lines.add(const DetailLine(icon: AppIcons.edit, text: 'This occurrence was changed'));
    if (category != null) lines.add(DetailLine(icon: AppIcons.category, text: category.name, semanticPrefix: 'Category'));
    if (details.location != null) lines.add(DetailLine(icon: AppIcons.location, text: details.location!, semanticPrefix: 'Room'));
    if (details.professor != null) lines.add(DetailLine(icon: AppIcons.person, text: details.professor!, semanticPrefix: 'Person'));
    if (details.subtitle != null) lines.add(DetailLine(icon: AppIcons.text, text: details.subtitle!, semanticPrefix: 'Subtitle'));

    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(Tokens.lg, inSheet ? 0 : Tokens.md, Tokens.lg, Tokens.xl),
      children: [
        Semantics(header: true, child: Text(occurrence.title, style: text.titleLarge)),
        const SizedBox(height: Tokens.md),
        ...lines.map((l) => Padding(padding: const EdgeInsets.only(bottom: 6), child: l)),
        if (details.notes != null) ...[
          const SizedBox(height: Tokens.sm),
          Text('Notes', style: text.labelMedium?.copyWith(color: colors.secondaryInk)),
          const SizedBox(height: 4),
          SelectableText(details.notes!, style: text.bodyMedium),
        ],
        if (rules.isNotEmpty) ...[
          const SizedBox(height: Tokens.md),
          for (final rule in rules) AlertStatusLine(rule: rule, occurrence: occurrence),
        ],
        _ClockHandoff(series: series, occurrence: occurrence),
        if (timing is UnresolvedTiming) ...[
          const SizedBox(height: Tokens.md),
          _TimeReviewActions(series: series, occurrence: occurrence, timing: timing),
        ],
        const SizedBox(height: Tokens.lg),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: AppIcon(AppIcons.edit, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                label: const Text('Edit'),
                onPressed: () => editOccurrence(context, occurrence),
              ),
            ),
            const SizedBox(width: Tokens.sm),
            Expanded(
              child: OutlinedButton.icon(
                icon: AppIcon(AppIcons.remove, size: 18, color: Theme.of(context).colorScheme.error),
                label: Text(occurrence.isRecurring ? 'Remove' : 'Delete'),
                style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => removeOccurrence(context, ref, occurrence, inSheet: inSheet),
              ),
            ),
          ],
        ),
        if (occurrence.isOverride) ...[
          const SizedBox(height: Tokens.sm),
          TextButton.icon(
            icon: AppIcon(AppIcons.restore, size: 18, color: Theme.of(context).colorScheme.primary),
            label: const Text('Restore original occurrence'),
            onPressed: () async {
              await ref.read(scheduleRepositoryProvider).restoreOccurrence(series.id, occurrence.originalKey);
              if (context.mounted && inSheet) Navigator.of(context).pop();
            },
          ),
        ],
      ],
    );
  }
}

/// Explicit resolution for a wall time skipped or repeated by a clock change.
class _TimeReviewActions extends ConsumerWidget {
  const _TimeReviewActions({required this.series, required this.occurrence, required this.timing});

  final ScheduleSeries series;
  final Occurrence occurrence;
  final UnresolvedTiming timing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambiguous = timing.reason == TimeReviewReason.startAmbiguous || timing.reason == TimeReviewReason.endAmbiguous;
    Future<void> choose(TimeResolution resolution) async {
      final base = (occurrence.isOverride ? series.exceptionFor(occurrence.originalKey)!.replacement!.time : series.time) as TimedSpec;
      final resolved = timing.reason == TimeReviewReason.startAmbiguous
          ? base.copyWith(startDate: timing.localDate, seedTimeResolution: () => resolution)
          : base.copyWith(startDate: timing.localDate, endTimeResolution: () => resolution);
      await ref.read(scheduleRepositoryProvider).overrideOccurrence(
            series.id,
            occurrence.originalKey,
            OccurrenceReplacement(title: occurrence.title, time: resolved, details: occurrence.details),
          );
    }

    if (!ambiguous) {
      return OutlinedButton(
        onPressed: () => context.push('/schedule/${series.id}/edit?scope=occurrence&key=${occurrence.originalKey.toIso()}'),
        child: const Text('Choose a time for this occurrence'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(onPressed: () => choose(TimeResolution.earlier), child: const Text('Use the first time')),
        const SizedBox(height: Tokens.sm),
        OutlinedButton(onPressed: () => choose(TimeResolution.later), child: const Text('Use the second time')),
      ],
    );
  }
}

/// Asks for the edit scope of a recurring schedule before opening the editor.
Future<void> editOccurrence(BuildContext context, Occurrence occurrence) async {
  final key = occurrence.originalKey.toIso();
  if (!occurrence.isRecurring) {
    await context.push('/schedule/${occurrence.seriesId}/edit?scope=series');
    return;
  }
  final scope = await showChoiceDialog<String>(
    context,
    title: 'Edit repeating schedule',
    message: 'Change only this occurrence, or every occurrence in the series? Changes to one occurrence do not affect the others.',
    choices: const [('occurrence', 'This occurrence', false), ('series', 'Entire series', false)],
  );
  if (scope == null || !context.mounted) return;
  await context.push('/schedule/${occurrence.seriesId}/edit?scope=$scope&key=$key');
}

Future<void> removeOccurrence(BuildContext context, WidgetRef ref, Occurrence occurrence, {required bool inSheet}) async {
  final repo = ref.read(scheduleRepositoryProvider);
  final f = Formats.of(context);
  if (!occurrence.isRecurring) {
    final confirmed = await showChoiceDialog<bool>(
      context,
      title: 'Delete schedule?',
      message: 'This removes the schedule and its reminders from this device.',
      choices: const [(true, 'Delete', true)],
    );
    if (confirmed != true) return;
    await repo.deleteSeries(occurrence.seriesId);
  } else {
    final choice = await showChoiceDialog<String>(
      context,
      title: 'Remove repeating schedule',
      message: 'Cancel only the occurrence on ${f.fullDate(occurrence.originalKey)}, or delete the entire series and its reminders?',
      choices: const [('occurrence', 'Cancel this occurrence', false), ('series', 'Delete entire series', true)],
    );
    if (choice == null) return;
    if (choice == 'occurrence') {
      await repo.cancelOccurrence(occurrence.seriesId, occurrence.originalKey);
    } else {
      await repo.deleteSeries(occurrence.seriesId);
    }
  }
  if (!context.mounted) return;
  if (inSheet) {
    Navigator.of(context).pop();
  } else if (context.canPop()) {
    context.pop();
  }
}

/// Optional Android Clock hand-off with honest, unverified status.
class _ClockHandoff extends ConsumerWidget {
  const _ClockHandoff({required this.series, required this.occurrence});

  final ScheduleSeries series;
  final Occurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(scheduledAlertsProvider).value ?? const [];
    final record = clockRecordFor(rows, series.id);
    final available = ref.watch(clockHandoffAvailableProvider);
    final rules = ref.watch(alertRulesProvider).value ?? const <AlertRule>[];
    final service = ref.read(clockHandoffProvider);
    final plan = available ? service.planFor(series, occurrence, clockOffsetFor(rules, series.id)) : null;
    final f = Formats.of(context);
    final children = <Widget>[];
    if (record != null) {
      children.add(const DetailLine(icon: AppIcons.alarm, text: 'Sent to Clock · not verified'));
      if (record.sourceRevision != series.revision) {
        children.add(const DetailLine(
          icon: AppIcons.warning,
          text: 'This schedule changed after it was sent to Clock. Update that alarm in the Clock app.',
        ));
      }
    }
    if (plan != null) {
      final days = plan.weekdays == null
          ? 'once'
          : plan.weekdays!.length == 7
              ? 'every day'
              : 'every ${plan.weekdays!.map(f.weekdayShort).join(', ')}';
      children.add(Padding(
        padding: const EdgeInsets.only(top: Tokens.sm),
        child: OutlinedButton.icon(
          icon: const AppIcon(AppIcons.alarm, size: 18),
          label: const Text('Add to Clock'),
          onPressed: () async {
            final confirmed = await showChoiceDialog<bool>(
              context,
              title: 'Add to Clock?',
              message: 'Sends an alarm for ${f.clock(plan.time)}, $days, to your Clock app. '
                  'Schediel cannot confirm it was saved and will not update it if this schedule changes. '
                  'End dates and cancelled occurrences are not included.',
              choices: const [(true, 'Send to Clock', false)],
            );
            if (confirmed != true) return;
            final result = await service.send(series, occurrence, plan);
            if (!context.mounted) return;
            showMessage(
              context,
              switch (result) {
                ClockLaunchResult.launched => 'Opened your Clock app',
                ClockLaunchResult.unavailable => 'No Clock app can receive this alarm',
                ClockLaunchResult.failed => 'Could not open the Clock app',
              },
            );
          },
        ),
      ));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Tokens.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}
