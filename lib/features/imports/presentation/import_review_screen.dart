import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';

import '../../../core/schedule/models.dart';
import '../../schedules/presentation/schedule_editor_screen.dart';
import '../data/import_repository.dart';
import '../domain/import_entry.dart';

/// A single confirmation boundary shared by link and image imports. Edits are
/// inactive until the selected entries commit together in the local database.
class ImportReviewScreen extends ConsumerStatefulWidget {
  const ImportReviewScreen({super.key, required this.entries, this.title = 'Review schedules',
    this.sourceText, this.sourceImagePath, this.sourceCategoryLabels = const {}});

  final List<ImportEntry> entries;
  final String title;
  final String? sourceText;
  final String? sourceImagePath;
  final Map<String, String?> sourceCategoryLabels;

  @override
  ConsumerState<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends ConsumerState<ImportReviewScreen> {
  late final List<ImportEntry> _entries = [...widget.entries];
  final Set<String> _selected = {};
  Map<String, ImportDuplicate>? _duplicates;
  String? _error;
  bool _saving = false;
  bool _dirty = false;
  bool _closing = false;
  bool _discardPromptOpen = false;
  late final String _commandId = ref.read(idGeneratorProvider)();

  @override
  void initState() {
    super.initState();
    _inspect();
  }

  Future<void> _inspect() async {
    try {
      final checks = await ref.read(importRepositoryProvider).inspect(_entries);
      if (!mounted) return;
      setState(() {
        _duplicates = checks;
        _error = null;
        _selected.addAll(_entries.where((e) => !(checks[e.candidateId]?.exact ?? false)).map((e) => e.candidateId));
      });
    } on Object {
      if (mounted) setState(() => _error = 'Could not check existing schedules. Try again.');
    }
  }

  Future<void> _edit(int index) async {
    final e = _entries[index];
    final result = await Navigator.of(context).push<ReviewEdit>(MaterialPageRoute(
      builder: (_) => ScheduleEditorScreen(scope: EditorScope.review, initialDraft: e.draft,
        initialAlerts: e.alerts, initialExceptions: e.exceptions),
    ));
    if (result == null || !mounted) return;
    setState(() {
      _dirty = true;
      _entries[index] = e.copyWith(draft: result.draft, alerts: result.alerts);
    });
  }

  Future<void> _close() async {
    if (_saving || _discardPromptOpen) return;
    if (_dirty) {
      _discardPromptOpen = true;
      final discard = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
        title: const Text('Discard review changes?'),
        content: const Text('Your unconfirmed edits will be lost. No schedules have been added.'),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep reviewing')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard review'))]));
      _discardPromptOpen = false;
      if (discard != true || !mounted) return;
    }
    setState(() => _closing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.of(context).pop(); });
  }

  Future<void> _add() async {
    if (_saving || _duplicates == null || _selected.isEmpty) return;
    setState(() { _saving = true; _error = null; });
    try {
      final ids = await ref.read(importRepositoryProvider).commit(_commandId,
        [for (final e in _entries) if (_selected.contains(e.candidateId)) e]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        ids.isEmpty ? 'No new schedules added' : 'Added ${ids.length} ${ids.length == 1 ? 'schedule' : 'schedules'}')));
      setState(() { _closing = true; _dirty = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.of(context).pop(ids); });
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not add the selection. Your edits are still here. Check the schedules or try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = Formats.of(context);
    return PopScope(canPop: _closing || (!_saving && !_dirty),
      onPopInvokedWithResult: (didPop, _) { if (!didPop && !_saving) _close(); }, child: Scaffold(
      appBar: AppBar(title: Text(widget.title), leading: IconButton(tooltip: 'Close',
        onPressed: _saving ? null : _close, icon: const AppIcon(AppIcons.close))),
      body: _duplicates == null && _error == null
        ? const Center(child: CircularProgressIndicator.adaptive())
        : ListView.builder(
            padding: const EdgeInsets.all(Tokens.md),
            itemCount: _entries.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Independent copies. Categories and alerts are your choice. Nothing is added until you confirm.'),
                if (widget.sourceText != null || widget.sourceImagePath != null)
                  ExpansionTile(title: const Text('Source evidence'), children: [
                    if (widget.sourceImagePath != null) Image.file(File(widget.sourceImagePath!), height: 240,
                      fit: BoxFit.contain, semanticLabel: 'Selected image region',
                      errorBuilder: (_, _, _) => const Text('Source image is no longer available')),
                    if (widget.sourceText != null) Padding(padding: const EdgeInsets.all(Tokens.md), child: SelectableText(widget.sourceText!)),
                  ]),
                const SizedBox(height: Tokens.md),
                ]);
              }
              return _row(index - 1, f);
            }),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(Tokens.md),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_error != null) Semantics(liveRegion: true, child: Padding(padding: const EdgeInsets.only(bottom: Tokens.sm), child: Text(_error!))),
          if (_duplicates == null && _error != null) TextButton(onPressed: _inspect, child: const Text('Try again')),
          Semantics(liveRegion: true, child: Text('${_selected.length} selected')),
          const SizedBox(height: Tokens.sm),
          FilledButton(onPressed: !_saving && _duplicates != null && _selected.isNotEmpty ? _add : null,
            child: Text(_saving ? 'Adding…' : 'Add selected schedules')),
        ]))),
    ));
  }

  Widget _row(int index, Formats f) {
    final e = _entries[index];
    final duplicate = _duplicates?[e.candidateId] ?? const ImportDuplicate();
    final d = e.draft;
    final sourceLabel = widget.sourceCategoryLabels[e.candidateId];
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final timeLabel = scheduleTimeLabel(d.time, f);
    final warnings = [if (duplicate.exact) 'Already imported', if (duplicate.similar && !duplicate.exact) 'Similar schedule already saved'];
    return Card(margin: const EdgeInsets.only(bottom: Tokens.md), child: Padding(padding: const EdgeInsets.symmetric(vertical: Tokens.sm), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CheckboxListTile(controlAffinity: ListTileControlAffinity.leading, value: _selected.contains(e.candidateId),
          title: Text(d.title), subtitle: Text([timeLabel, if (d.recurrence != null) f.repeatSummary(d.recurrence)].join('\n')),
          onChanged: _saving ? null : (on) => setState(() {
            _dirty = true;
            if (on == true) {
              _selected.add(e.candidateId);
              if (duplicate.exact) _entries[index] = e.copyWith(keepCopy: true);
            } else { _selected.remove(e.candidateId); }
          })),
        for (final warning in warnings) Padding(padding: const EdgeInsets.symmetric(horizontal: Tokens.md), child: Text(warning)),
        if (duplicate.exact) Align(alignment: Alignment.centerLeft, child: TextButton(
          onPressed: _saving ? null : () => setState(() {
            _dirty = true;
            _entries[index] = e.copyWith(keepCopy: true); _selected.add(e.candidateId);
          }), child: const Text('Keep a copy'))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: Tokens.md), child: Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            key: ValueKey('${e.candidateId}:${d.categoryId}'),
            initialValue: categories.any((c) => c.id == d.categoryId) ? d.categoryId : '',
            decoration: const InputDecoration(labelText: 'Category'), isExpanded: true,
            items: [const DropdownMenuItem(value: '', child: Text('Uncategorized')),
              for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
            onChanged: _saving ? null : (value) => setState(() {
              _dirty = true;
              _entries[index] = e.copyWith(draft: d.copyWith(categoryId: () => value == '' ? null : value));
            }),
          )),
          const SizedBox(width: Tokens.md),
          TextButton(onPressed: _saving ? null : () => _edit(index), child: const Text('Edit')),
        ])),
        if (sourceLabel != null) Padding(padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, 0), child: Text('Shared category: $sourceLabel')),
        Padding(padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, 0), child: Text(
          e.alerts.where((a) => a.enabled).isEmpty ? 'Alerts off' : '${e.alerts.where((a) => a.enabled).length} alert preferences chosen')),
        if (!d.details.isEmpty || e.exceptions.isNotEmpty) ExpansionTile(title: const Text('Included details'), children: [
          for (final value in [d.details.location, d.details.professor, d.details.subtitle, d.details.notes])
            if (value != null) ListTile(title: Text(value)),
          for (final x in e.exceptions) ListTile(
            title: Text('${f.fullDate(x.originalKey)} · ${x.action == ExceptionAction.cancel ? 'Cancelled' : 'Changed'}'),
            subtitle: x.replacement == null ? null : Text('${x.replacement!.title}\n${scheduleTimeLabel(x.replacement!.time, f)}'),
          ),
        ]),
      ])));
  }
}

/// The source wall-clock time and zone, never an invented duration.
String scheduleTimeLabel(TimeSpec time, Formats f) => switch (time) {
  TimedSpec() => '${f.fullDate(time.startDate)} · ${f.clock(time.startTime)}'
      '${time.endTime == null ? '' : ' – ${f.clock(time.endTime!)}${time.endDayOffset == 1 ? ' next day' : ''}'} · ${time.timeZone}',
  DateOnlySpec() => '${f.range(time.startDate, time.lastDate)} · All day',
};
