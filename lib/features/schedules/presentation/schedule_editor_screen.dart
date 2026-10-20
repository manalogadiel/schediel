import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/schediel_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../app/widgets/labeled_field.dart';
import 'schedule_time_picker.dart';
import '../../../core/schedule/limits.dart';
import '../../../core/schedule/models.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/schedule/overlap.dart';
import '../../../core/schedule/validation.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/local_time.dart';
import '../../categories/domain/category.dart';
import '../../imports/domain/import_entry.dart';
import '../../reminders/domain/alert_rule.dart';
import '../../reminders/presentation/alert_editor.dart';
import '../data/schedule_repository.dart';

enum EditorScope { create, series, occurrence, review }

enum _EditorStep { details, time, alerts }

/// The schedule editor (spec 4.5). Values survive save errors; leaving with
/// unsaved changes asks first.
class ScheduleEditorScreen extends ConsumerStatefulWidget {
  const ScheduleEditorScreen({
    super.key,
    required this.scope,
    this.seriesId,
    this.occurrenceKey,
    this.initialDate,
    this.initialDraft,
    this.initialAlerts = const [],
    this.initialExceptions = const [],
  });

  final EditorScope scope;
  final String? seriesId;
  final LocalDate? occurrenceKey;
  final LocalDate? initialDate;
  final ScheduleDraft? initialDraft;
  final List<AlertPreference> initialAlerts;
  final List<OccurrenceException> initialExceptions;

  @override
  ConsumerState<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends ConsumerState<ScheduleEditorScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _professor = TextEditingController();
  final _subtitle = TextEditingController();
  final _notes = TextEditingController();

  _EditorStep _step = _EditorStep.details;
  bool _initialized = false;
  bool _loadFailed = false;
  bool _saving = false;
  bool _dirty = false;
  ScheduleSeries? _original;

  String? _categoryId;
  bool _dateOnly = false;
  late LocalDate _date;
  late LocalTime _start;
  bool _hasEnd = false;
  late LocalTime _end;
  late String _zone;
  late LocalDate _lastDate;
  TimeResolution? _seedResolution;
  TimeResolution? _endResolution;
  RecurrenceFrequency? _frequency;
  Set<int> _weekdays = {};
  LocalDate? _until;
  bool _detailsOpen = true;
  bool _repeatsOpen = false;
  bool _alertsOpen = false;
  late AlertPreference _notification;
  late AlertPreference _alarm;
  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    for (final c in [_title, _location, _professor, _subtitle, _notes]) {
      c.addListener(_markDirty);
    }
    _notification = const AlertPreference(kind: AlertKind.notification, enabled: false, offsetMinutes: 10);
    _alarm = const AlertPreference(kind: AlertKind.alarm, enabled: false, offsetMinutes: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final c in [_title, _location, _professor, _subtitle, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (_initialized && !_dirty) setState(() => _dirty = true);
  }

  void _change(VoidCallback update) => setState(() {
    update();
    _dirty = true;
  });

  Future<void> _load() async {
    final zone = ref.read(deviceZoneProvider);
    final now = ref.read(nowProvider);
    final zones = ref.read(zoneResolverProvider);
    final local = zones.toLocal(now, zone);
    _zone = zone;
    _date = widget.initialDate ?? local.date;
    _start = LocalTime.fromMinutes(((local.time.minutesOfDay ~/ 60) + 1) % 24 * 60);
    _end = LocalTime.fromMinutes((_start.minutesOfDay + 60) % (24 * 60));
    _lastDate = _date;
    _hasEnd = widget.scope == EditorScope.create;

    if (widget.scope != EditorScope.create) {
      final repo = ref.read(scheduleRepositoryProvider);
      final d = widget.initialDraft;
      final series = widget.scope == EditorScope.review && d != null
          ? ScheduleSeries(
              id: 'review',
              revision: 1,
              title: d.title,
              time: d.time,
              categoryId: d.categoryId,
              recurrence: d.recurrence,
              details: d.details,
              exceptions: widget.initialExceptions,
            )
          : await repo.load(widget.seriesId!);
      if (!mounted) return;
      if (series == null) {
        setState(() => _loadFailed = true);
        return;
      }
      _original = series;
      final preferences = widget.scope == EditorScope.review
          ? widget.initialAlerts
          : [for (final r in await repo.alertRules(series.id)) r.preference];
      for (final a in preferences) {
        if (a.kind == AlertKind.notification) _notification = a;
        if (a.kind == AlertKind.alarm) _alarm = a;
      }
      var title = series.title;
      var time = series.time;
      var details = series.details;
      if (widget.scope == EditorScope.occurrence) {
        final key = widget.occurrenceKey!;
        final replacement = series.exceptionFor(key)?.replacement;
        if (replacement != null) {
          title = replacement.title;
          time = replacement.time;
          details = replacement.details;
        } else {
          time = switch (time) {
            TimedSpec() => time.copyWith(startDate: key, seedTimeResolution: () => null, endTimeResolution: () => null),
            DateOnlySpec() => DateOnlySpec(startDate: key, endDateExclusive: key.addDays(time.spanDays)),
          };
        }
      }
      _title.text = title;
      _categoryId = series.categoryId;
      _location.text = details.location ?? '';
      _professor.text = details.professor ?? '';
      _subtitle.text = details.subtitle ?? '';
      _notes.text = details.notes ?? '';
      _detailsOpen = true;
      switch (time) {
        case TimedSpec():
          _dateOnly = false;
          _date = time.startDate;
          _start = time.startTime;
          _zone = time.timeZone;
          _hasEnd = time.endTime != null;
          if (time.endTime != null) _end = time.endTime!;
          _seedResolution = time.seedTimeResolution;
          _endResolution = time.endTimeResolution;
        case DateOnlySpec():
          _dateOnly = true;
          _date = time.startDate;
          _lastDate = time.lastDate;
      }
      final rule = series.recurrence;
      if ((widget.scope == EditorScope.series || widget.scope == EditorScope.review) && rule != null) {
        _frequency = rule.frequency;
        _weekdays = {...rule.weekdays};
        _until = rule.untilDateInclusive;
        _repeatsOpen = true;
      }
      _alertsOpen = _notification.enabled || _alarm.enabled;
    }
    if (mounted) setState(() => _initialized = true);
  }

  bool get _isOccurrence => widget.scope == EditorScope.occurrence;

  int? get _endDayOffset {
    if (_dateOnly || !_hasEnd) return null;
    final original = _original?.time;
    if (original is TimedSpec && original.startTime == _start && original.endTime == _end) {
      return original.endDayOffset;
    }
    return _end.isBefore(_start) ? 1 : 0;
  }

  TimeSpec _timeSpec() {
    if (_dateOnly) return DateOnlySpec(startDate: _date, endDateExclusive: _lastDate.addDays(1));
    final original = _original?.time;
    final sameWall =
        original is TimedSpec && original.startDate == _date && original.startTime == _start && original.timeZone == _zone;
    return TimedSpec(
      startDate: _date,
      startTime: _start,
      timeZone: _zone,
      endTime: _hasEnd ? _end : null,
      endDayOffset: _endDayOffset,
      seedTimeResolution: sameWall ? _seedResolution : null,
      endTimeResolution: sameWall && _hasEnd && original.endTime == _end ? _endResolution : null,
    );
  }

  RecurrenceSpec? _recurrence() {
    final f = _frequency;
    if (f == null || _isOccurrence) return null;
    return RecurrenceSpec(
      frequency: f,
      weekdays: f == RecurrenceFrequency.weekly ? _weekdays : const [],
      untilDateInclusive: _until,
    );
  }

  ScheduleDraft _draft() => ScheduleDraft(
    title: _title.text,
    categoryId: _categoryId,
    time: _timeSpec(),
    recurrence: _recurrence(),
    details: ScheduleDetails(location: _location.text, professor: _professor.text, subtitle: _subtitle.text, notes: _notes.text),
  ).normalized();

  Map<String, String> _messages(List<ValidationIssue> issues) {
    String message(ValidationIssue i) {
      switch (i.path) {
        case 'title':
          return i.code == 'too_long' ? 'Use at most ${ScheduleLimits.titleMax} characters' : 'Enter a title';
        case 'time/endTime':
          return 'End time must be after the start time';
        case 'time/timeZone':
          return 'Choose a valid time zone';
        case 'time/endDateExclusive':
          return _frequency != null
              ? 'A repeating all-day schedule can only last one day'
              : 'End date must be on or after the start date, within ${ScheduleLimits.dateOnlyMaxSpanDays} days';
        case 'recurrence/weekdays':
          return 'Choose at least one weekday';
        case 'recurrence/untilDateInclusive':
          return 'The last date must be on or after the start date';
      }
      if (i.path.startsWith('details/')) return i.code == 'too_long' ? 'This text is too long' : 'Check this field';
      return 'Check this schedule';
    }

    return {for (final i in issues) i.path: message(i)};
  }

  List<String> _alertErrors() {
    final errors = <String>[];
    for (final a in [_notification, _alarm]) {
      if (_dateOnly && a.enabled && (a.dateOnlyAnchorTime == null || a.dateOnlyAnchorZone == null)) {
        errors.add('alerts/${a.kind.name}');
      }
    }
    return errors;
  }

  Map<String, String> _validate(ScheduleDraft draft) {
    final validator = ref.read(seriesValidatorProvider);
    final probe = ScheduleSeries(
      id: _original?.id ?? 'draft',
      revision: 1,
      title: draft.title,
      categoryId: draft.categoryId,
      time: draft.time,
      recurrence: draft.recurrence,
      details: draft.details,
      exceptions: widget.scope == EditorScope.review ? widget.initialExceptions : const [],
    );
    final errors = _messages(validator.validate(probe));
    for (final path in _alertErrors()) {
      errors[path] = 'Choose a reminder time for this all-day schedule';
    }
    return errors;
  }

  _EditorStep _stepFor(String path) => path == 'title' || path.startsWith('details/')
      ? _EditorStep.details
      : path.startsWith('alerts/')
      ? _EditorStep.alerts
      : _EditorStep.time;

  void _advance() {
    if (_saving || !_initialized) return;
    if (_step == _EditorStep.alerts) {
      _save();
      return;
    }
    final errors = _validate(_draft())..removeWhere((path, _) => _stepFor(path) != _step);
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _detailsOpen = true;
        _repeatsOpen = true;
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _errors = {};
      _step = _EditorStep.values[_step.index + 1];
      _alertsOpen = true;
    });
  }

  void _close() {
    if (_saving) return;
    if (_dirty) {
      _confirmDiscard();
    } else {
      Navigator.of(context).pop(widget.scope == EditorScope.review ? null : false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final draft = _draft();
    final errors = _validate(draft);
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _step = errors.keys.map(_stepFor).reduce((a, b) => a.index < b.index ? a : b);
        if (errors.keys.any((k) => k.startsWith('details/'))) _detailsOpen = true;
        if (errors.keys.any((k) => k.startsWith('recurrence/'))) _repeatsOpen = true;
        if (errors.keys.any((k) => k.startsWith('alerts/'))) _alertsOpen = true;
      });
      showMessage(context, 'Check the highlighted fields');
      return;
    }
    setState(() {
      _errors = {};
      _saving = true;
    });
    final repo = ref.read(scheduleRepositoryProvider);
    final alerts = [_notification, _alarm];
    if (widget.scope == EditorScope.review) {
      setState(() => _dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(ReviewEdit(draft, alerts.where((a) => a.enabled).toList()));
      });
      return;
    }
    try {
      switch (widget.scope) {
        case EditorScope.review:
          return;
        case EditorScope.create:
          await repo.create(draft, alerts: alerts);
        case EditorScope.occurrence:
          await repo.overrideOccurrence(
            _original!.id,
            widget.occurrenceKey!,
            OccurrenceReplacement(title: draft.title, time: draft.time, details: draft.details),
          );
        case EditorScope.series:
          final current = await repo.load(_original!.id);
          if (current == null) throw ScheduleNotFoundException(_original!.id);
          InvalidExceptionChoice? choice;
          final invalid = repo.invalidatedExceptions(current, draft);
          if (invalid.isNotEmpty) {
            if (!mounted) return;
            final moved = invalid.where((e) => e.action == ExceptionAction.override).length;
            choice = await showChoiceDialog<InvalidExceptionChoice>(
              context,
              title: 'Changed occurrences no longer fit',
              message:
                  '${invalid.length} changed or cancelled occurrence${invalid.length == 1 ? '' : 's'} '
                  'will not match the new repeat rule.'
                  '${moved > 0 ? ' Moved occurrences can be kept as separate one-time schedules.' : ''}',
              choices: [
                if (moved > 0) (InvalidExceptionChoice.keepChangesAsOneTime, 'Keep as one-time', false),
                (InvalidExceptionChoice.discard, 'Remove changes', true),
              ],
            );
            if (choice == null) {
              setState(() => _saving = false);
              return;
            }
          }
          await repo.updateSeries(current.id, draft, onInvalidExceptions: choice, alerts: alerts);
      }
      if (!mounted) return;
      _dirty = false;
      Navigator.of(context).pop(true);
    } on ScheduleValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _errors = _messages(e.issues);
        _saving = false;
      });
      showMessage(context, 'Check the highlighted fields');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Unable to save. Your changes are still here.');
    }
  }

  Future<void> _confirmDiscard() async {
    if (_saving) return;
    final discard = await showChoiceDialog<bool>(
      context,
      title: 'Discard changes?',
      message: 'Your unsaved changes will be lost.',
      choices: const [(true, 'Discard', true)],
    );
    if (discard == true && mounted) {
      _dirty = false;
      Navigator.of(context).pop(widget.scope == EditorScope.review ? null : false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.scope) {
      EditorScope.create => 'New schedule',
      EditorScope.series => 'Edit schedule',
      EditorScope.occurrence => 'Edit occurrence',
      EditorScope.review => 'Edit before adding',
    };
    return PopScope(
      canPop: !_dirty && !_saving && _step == _EditorStep.details,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _saving) return;
        if (_step != _EditorStep.details) {
          setState(() => _step = _EditorStep.values[_step.index - 1]);
        } else {
          _confirmDiscard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: 'Close', icon: const AppIcon(AppIcons.close), onPressed: _saving ? null : _close),
          title: Text(title),
        ),
        body: _loadFailed
            ? const EmptyState(title: 'Schedule no longer available')
            : !_initialized
            ? const Center(child: CircularProgressIndicator.adaptive())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Tokens.md, vertical: Tokens.sm),
                    child: _StepIndicator(
                      index: _step.index,
                      label: switch (_step) {
                        _EditorStep.details => 'Details',
                        _EditorStep.time => 'Time',
                        _EditorStep.alerts => 'Alerts',
                      },
                    ),
                  ),
                  Expanded(
                    child: IgnorePointer(ignoring: _saving, child: _form(context)),
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.sm),
            child: Row(
              children: [
                if (_step != _EditorStep.details)
                  TextButton(
                    onPressed: _saving ? null : () => setState(() => _step = _EditorStep.values[_step.index - 1]),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _initialized && !_saving ? _advance : null,
                  child: Text(
                    _saving
                        ? 'Saving…'
                        : _step == _EditorStep.alerts
                        ? widget.scope == EditorScope.review
                              ? 'Use changes'
                              : 'Save'
                        : 'Next',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final f = Formats.of(context);
    final text = Theme.of(context).textTheme;
    final colors = context.scheduleColors;
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final category = categories.where((c) => c.id == _categoryId).firstOrNull;
    final scopeNote = switch (widget.scope) {
      EditorScope.occurrence => 'Changes apply only to the occurrence on ${f.fullDate(widget.occurrenceKey!)}.',
      EditorScope.series when _original?.isRecurring ?? false => 'Changes apply to every occurrence in this series.',
      _ => null,
    };

    return ListView(
      key: ValueKey(_step),
      padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.xxl),
      children: [
        if (_errors.keys.any((k) => k.startsWith('exceptions/')))
          const Padding(
            padding: EdgeInsets.only(bottom: Tokens.md),
            child: Text(
              'This repeat change leaves a changed or cancelled occurrence outside the series. Keep the original repeat rule before adding.',
            ),
          ),
        if (scopeNote != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Tokens.md),
            child: DetailLine(icon: AppIcons.info, text: scopeNote, style: text.bodyMedium),
          ),
        if (_step == _EditorStep.details)
          SectionGroup(
            children: [
              Padding(
                padding: const EdgeInsets.all(Tokens.md),
                child: LabeledField(
                  label: 'Title',
                  controller: _title,
                  autofocus: widget.scope == EditorScope.create,
                  errorText: _errors['title'],
                ),
              ),
            ],
          ),
        if (_step == _EditorStep.time)
          SectionGroup(
            children: [
              if (!_isOccurrence)
                ListTile(
                  leading: const AppIcon(AppIcons.category),
                  title: const Text('Category'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (category != null) CategoryDot(colorKey: category.colorKey),
                      Text(category?.name ?? 'Uncategorized', style: text.bodyMedium?.copyWith(color: colors.secondaryInk)),
                    ],
                  ),
                  onTap: () => _pickCategory(categories),
                ),
              if (!_isOccurrence)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Tokens.md, vertical: Tokens.sm),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Timed')),
                      ButtonSegment(value: true, label: Text('All day')),
                    ],
                    selected: {_dateOnly},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => _change(() {
                      _dateOnly = s.first;
                      if (_dateOnly && _lastDate.isBefore(_date)) _lastDate = _date;
                    }),
                  ),
                ),
              ..._timeFields(context, f),
            ],
          ),
        if (_step == _EditorStep.time && !_isOccurrence) _repeatsSection(context, f),
        if (_step == _EditorStep.details) _detailsSection(context),
        if (_step == _EditorStep.alerts && !_isOccurrence)
          _Disclosure(
            title: 'Reminders and alarms',
            summary: _alertSummary(f),
            open: _alertsOpen,
            onToggle: () => setState(() => _alertsOpen = !_alertsOpen),
            child: AlertEditor(
              notification: _notification,
              alarm: _alarm,
              dateOnly: _dateOnly,
              deviceZone: ref.read(deviceZoneProvider),
              errors: _errors,
              onChanged: (n, a) => _change(() {
                _notification = n;
                _alarm = a;
              }),
            ),
          ),
        if (_step == _EditorStep.time && widget.scope == EditorScope.series && (_original?.exceptions.isNotEmpty ?? false))
          _changedOccurrences(context, f),
        if (_step == _EditorStep.time) _overlapWarning(context, f),
      ],
    );
  }

  List<Widget> _timeFields(BuildContext context, Formats f) {
    final text = Theme.of(context).textTheme;
    final secondary = context.scheduleColors.secondaryInk;
    Widget value(String s) => Text(s, style: text.bodyMedium?.copyWith(color: secondary));
    if (_dateOnly) {
      return [
        ListTile(
          leading: const AppIcon(AppIcons.calendar),
          title: Text(_isOccurrence ? 'Date' : 'Starts'),
          trailing: value(f.fullDate(_date)),
          onTap: () => _pickDate(_date, (d) {
            final span = _date.daysUntil(_lastDate);
            _date = d;
            _lastDate = d.addDays(span < 0 ? 0 : span);
          }),
        ),
        ListTile(
          leading: const SizedBox(width: Tokens.iconSize),
          title: const Text('Ends'),
          subtitle: _errors['time/endDateExclusive'] == null
              ? null
              : Text(_errors['time/endDateExclusive']!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          trailing: value(f.fullDate(_lastDate)),
          onTap: () => _pickDate(_lastDate, (d) => _lastDate = d),
        ),
      ];
    }
    final overnight = _endDayOffset == 1;
    return [
      ListTile(
        leading: const AppIcon(AppIcons.calendar),
        title: const Text('Date'),
        trailing: value(f.fullDate(_date)),
        onTap: () => _pickDate(_date, (d) => _date = d),
      ),
      ListTile(
        leading: const AppIcon(AppIcons.time),
        title: const Text('Starts'),
        trailing: value(f.clock(_start)),
        onTap: () => _pickTime(_start, (t) => _start = t),
      ),
      SwitchListTile(
        secondary: const SizedBox(width: Tokens.iconSize),
        title: const Text('End time'),
        subtitle: _hasEnd ? null : const Text('No end time'),
        value: _hasEnd,
        onChanged: (v) => _change(() => _hasEnd = v),
      ),
      if (_hasEnd)
        ListTile(
          leading: const SizedBox(width: Tokens.iconSize),
          title: const Text('Ends'),
          subtitle: _errors['time/endTime'] != null
              ? Text(_errors['time/endTime']!, style: TextStyle(color: Theme.of(context).colorScheme.error))
              : overnight
              ? const Text('Ends the next day')
              : null,
          trailing: value(f.clock(_end)),
          onTap: () => _pickTime(_end, (t) => _end = t),
        ),
      ListTile(
        leading: const SizedBox(width: Tokens.iconSize),
        title: const Text('Time zone'),
        subtitle: _errors['time/timeZone'] == null
            ? null
            : Text(_errors['time/timeZone']!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            _zone,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(color: secondary),
          ),
        ),
        onTap: _pickZone,
      ),
    ];
  }

  Widget _repeatsSection(BuildContext context, Formats f) {
    final error = Theme.of(context).colorScheme.error;
    final summary = f.repeatSummary(_recurrence());
    return _Disclosure(
      title: 'Repeats',
      summary: summary,
      open: _repeatsOpen,
      onToggle: () => setState(() => _repeatsOpen = !_repeatsOpen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Tokens.md),
            child: SegmentedButton<RecurrenceFrequency?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Never')),
                ButtonSegment(value: RecurrenceFrequency.daily, label: Text('Daily')),
                ButtonSegment(value: RecurrenceFrequency.weekly, label: Text('Weekly')),
              ],
              selected: {_frequency},
              showSelectedIcon: false,
              onSelectionChanged: (s) => _change(() {
                _frequency = s.first;
                if (_frequency == RecurrenceFrequency.weekly && _weekdays.isEmpty) _weekdays = {_date.weekday};
              }),
            ),
          ),
          if (_frequency == RecurrenceFrequency.weekly)
            Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, Tokens.sm),
              child: Wrap(
                spacing: Tokens.sm,
                runSpacing: Tokens.sm,
                children: [
                  for (final d in [1, 2, 3, 4, 5, 6, 7])
                    FilterChip(
                      label: Text(f.weekdayShort(d)),
                      tooltip: f.weekdayLong(d),
                      selected: _weekdays.contains(d),
                      onSelected: (on) => _change(() => on ? _weekdays.add(d) : _weekdays.remove(d)),
                    ),
                ],
              ),
            ),
          if (_errors['recurrence/weekdays'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, Tokens.sm),
              child: Text(_errors['recurrence/weekdays']!, style: TextStyle(color: error)),
            ),
          if (_frequency != null) ...[
            SwitchListTile(
              title: const Text('Last date'),
              subtitle: _errors['recurrence/untilDateInclusive'] != null
                  ? Text(_errors['recurrence/untilDateInclusive']!, style: TextStyle(color: error))
                  : Text(_until == null ? 'Repeats with no last date' : f.fullDate(_until!)),
              value: _until != null,
              onChanged: (on) => _change(() => _until = on ? _date.addDays(7 * 16) : null),
            ),
            if (_until != null)
              ListTile(
                title: const Text('Change last date'),
                trailing: const AppIcon(AppIcons.next, size: 18),
                onTap: () => _pickDate(_until!, (d) => _until = d),
              ),
          ],
        ],
      ),
    );
  }

  Widget _detailsSection(BuildContext context) {
    final parts = [_location.text.trim(), _professor.text.trim(), _subtitle.text.trim()].where((s) => s.isNotEmpty).toList();
    Widget field(TextEditingController c, String label, String path, {int maxLines = 1, AppIcons? icon}) => Padding(
      padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.sm),
      child: LabeledField(
        label: label,
        controller: c,
        maxLines: maxLines,
        errorText: _errors[path],
        prefixIcon: icon == null ? null : Padding(padding: const EdgeInsets.all(12), child: AppIcon(icon, size: 18)),
      ),
    );
    return _Disclosure(
      title: 'Details',
      summary: parts.isEmpty ? 'Room, person, subtitle, notes' : parts.join(' · '),
      open: _detailsOpen,
      onToggle: () => setState(() => _detailsOpen = !_detailsOpen),
      child: Column(
        children: [
          field(_location, 'Room or location', 'details/location', icon: AppIcons.location),
          field(_professor, 'Professor or person', 'details/professor', icon: AppIcons.person),
          field(_subtitle, 'Subtitle', 'details/subtitle', icon: AppIcons.text),
          field(_notes, 'Notes', 'details/notes', maxLines: 6),
          const SizedBox(height: Tokens.sm),
        ],
      ),
    );
  }

  String _alertSummary(Formats f) {
    final parts = [
      if (_notification.enabled) 'Notification ${f.offsetLabel(_notification.offsetMinutes).toLowerCase()}',
      if (_alarm.enabled) 'Alarm ${f.offsetLabel(_alarm.offsetMinutes).toLowerCase()}',
    ];
    return parts.isEmpty ? 'Off' : parts.join(' · ');
  }

  Widget _changedOccurrences(BuildContext context, Formats f) {
    final repo = ref.read(scheduleRepositoryProvider);
    final exceptions = _original!.exceptions;
    return SectionGroup(
      header: 'Changed occurrences',
      children: [
        for (final e in exceptions)
          ListTile(
            title: Text(f.fullDate(e.originalKey)),
            subtitle: Text(e.action == ExceptionAction.cancel ? 'Cancelled' : 'Changed'),
            trailing: TextButton(
              onPressed: () async {
                await repo.restoreOccurrence(_original!.id, e.originalKey);
                final refreshed = await repo.load(_original!.id);
                if (mounted) setState(() => _original = refreshed);
              },
              child: const Text('Restore'),
            ),
          ),
      ],
    );
  }

  Widget _overlapWarning(BuildContext context, Formats f) {
    final all = ref.watch(allSeriesProvider).value;
    if (all == null || _dateOnly) return const SizedBox.shrink();
    final draft = _draft();
    final probe = ScheduleSeries(
      id: _original?.id ?? '__draft__',
      revision: 0,
      title: draft.title.isEmpty ? 'This schedule' : draft.title,
      time: draft.time,
      recurrence: draft.recurrence,
    );
    if (ref.read(seriesValidatorProvider).validate(probe.copyWith(title: 'x')).isNotEmpty) return const SizedBox.shrink();
    final engine = ref.read(occurrenceEngineProvider);
    final zones = ref.read(zoneResolverProvider);
    final zone = ref.read(deviceZoneProvider);
    final from = draft.time.startDate;
    final windowStart = zones.startOfDay(from, zone);
    final windowEnd = zones.startOfDay(from.addDays(14), zone);
    final mine = engine.expand(probe, windowStart: windowStart, windowEnd: windowEnd, viewZone: zone).occurrences;
    if (mine.isEmpty) return const SizedBox.shrink();
    for (final other in all) {
      if (other.id == probe.id) continue;
      final theirs = engine.expand(other, windowStart: windowStart, windowEnd: windowEnd, viewZone: zone).occurrences;
      for (final a in mine) {
        for (final b in theirs) {
          if (a.timing is TimedTiming &&
              b.timing is TimedTiming &&
              timedOverlap(a.timing as TimedTiming, b.timing as TimedTiming)) {
            final day = zones.localDateOf((a.timing as TimedTiming).startUtc, zone);
            return Padding(
              padding: const EdgeInsets.only(top: Tokens.sm),
              child: DetailLine(icon: AppIcons.warning, text: 'Overlaps “${b.title}” on ${f.fullDate(day)}. You can still save.'),
            );
          }
        }
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> _pickCategory(List<Category> categories) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Uncategorized'),
              trailing: _categoryId == null ? const AppIcon(AppIcons.confirm) : null,
              onTap: () => Navigator.of(context).pop(''),
            ),
            for (final c in categories)
              ListTile(
                leading: CategoryDot(colorKey: c.colorKey, size: 10),
                title: Text(c.name),
                trailing: _categoryId == c.id ? const AppIcon(AppIcons.confirm) : null,
                onTap: () => Navigator.of(context).pop(c.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) _change(() => _categoryId = picked.isEmpty ? null : picked);
  }

  Future<void> _pickDate(LocalDate current, void Function(LocalDate) apply) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(LocalDate.minYear),
      lastDate: DateTime(LocalDate.maxYear, 12, 31),
    );
    if (picked != null) _change(() => apply(LocalDate.fromDateTime(picked)));
  }

  Future<void> _pickTime(LocalTime current, void Function(LocalTime) apply) async {
    final picked = await showScheduleTimePicker(
      context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) _change(() => apply(LocalTime(picked.hour, picked.minute)));
  }

  Future<void> _pickZone() async {
    final zones = ref.read(zoneResolverProvider).zoneIds;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ZonePickerSheet(zones: zones, current: _zone),
    );
    if (picked != null) _change(() => _zone = picked);
  }
}

/// Collapsible editor group with a one-line summary of actual values.
class _Disclosure extends StatelessWidget {
  const _Disclosure({
    required this.title,
    required this.summary,
    required this.open,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String summary;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionGroup(
      children: [
        Semantics(
          button: true,
          expanded: open,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Tokens.md, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.titleMedium),
                        if (!open) Text(summary, style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: AppMotion.control(context),
                    child: const AppIcon(AppIcons.expand, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.control(context),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open ? child : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class ZonePickerSheet extends StatefulWidget {
  const ZonePickerSheet({super.key, required this.zones, required this.current});

  final List<String> zones;
  final String current;

  @override
  State<ZonePickerSheet> createState() => _ZonePickerSheetState();
}

class _ZonePickerSheetState extends State<ZonePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase().replaceAll(' ', '_');
    final matches = q.isEmpty ? widget.zones : widget.zones.where((z) => z.toLowerCase().contains(q)).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, Tokens.sm),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Search time zones'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(matches[i]),
                trailing: matches[i] == widget.current ? const AppIcon(AppIcons.confirm) : null,
                onTap: () => Navigator.of(context).pop(matches[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small segmented progress: the current step is a long accent pill, done
/// steps are short accent pills, upcoming ones are faint dots.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.index, required this.label});

  final int index;
  final String label;
  static const count = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final pixel = c.style == StyleFamily.pixel;
    final duration = AppMotion.control(context) * 1.8;
    return Semantics(
      label: 'Step ${index + 1} of $count, $label',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            AnimatedContainer(
              duration: duration,
              curve: const Cubic(0.2, 0.9, 0.1, 1),
              width: i == index ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i <= index ? c.palette.accent.withValues(alpha: i == index ? 1 : .45) : c.ink.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(pixel ? 0 : 4),
              ),
            ),
          ],
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: duration,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0, .4), end: Offset.zero).animate(a), child: child),
            ),
            child: Text(
              label,
              key: ValueKey(label),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.secondaryInk, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
