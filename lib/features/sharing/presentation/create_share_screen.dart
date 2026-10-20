import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/format.dart';
import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../core/schedule/models.dart';
import '../../../core/time/local_date.dart';
import '../../categories/domain/category.dart';
import '../../imports/presentation/import_review_screen.dart';
import '../application/share_sender.dart';
import '../application/sharing_config.dart';
import '../data/share_api.dart';
import '../../reminders/application/capabilities.dart';
import '../domain/direct_share.dart';
import '../domain/share_payload.dart';
import 'share_open_screen.dart';

class CreateShareScreen extends ConsumerStatefulWidget {
  const CreateShareScreen({super.key});
  @override ConsumerState<CreateShareScreen> createState() => _CreateShareScreenState();
}
class _CreateShareScreenState extends ConsumerState<CreateShareScreen> {
  List<ScheduleSeries>? _all;
  final _selected = <String>{};
  CategoryFilter _shareFilter = const CategoryFilter.all();
  bool _location = false, _professor = false, _subtitle = false, _notes = false;
  Duration _validity = const Duration(days: 7);
  bool _creating = false;
  bool _uncertain = false;
  String? _error;
  CreatedShare? _created;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final saved = await ref.read(scheduleRepositoryProvider).loadAll();
      final pending = ref.read(sharingConfigProvider).isConfigured
          ? await ref.read(shareSenderProvider).pending() : const [];
      if (!mounted) return;
      setState(() { _all = saved; _uncertain = pending.isNotEmpty;
        _shareFilter = ref.read(effectiveFilterProvider); _selectScope(); });
    } on Object {
      if (mounted) setState(() => _error = 'Could not load saved schedules. Try again.');
    }
  }
  void _selectScope() {
    _selected..clear()..addAll((_all ?? []).where((s) => _shareFilter.matches(s.categoryId)).map((s) => s.id));
  }
  void _category(String? id, bool on) => setState(() {
    final previous = _shareFilter;
    final ids = _shareFilter.isAll ? <String>{} : {..._shareFilter.categoryIds};
    if (id != null) { on ? ids.add(id) : ids.remove(id); }
    _shareFilter = CategoryFilter.only(ids,
      includeUncategorized: id == null ? on : !_shareFilter.isAll && _shareFilter.includeUncategorized);
    // Adding a category must not restore individually excluded schedules.
    _selected.retainAll({for (final s in _all ?? <ScheduleSeries>[]) if (_shareFilter.matches(s.categoryId)) s.id});
    _selected.addAll([for (final s in _all ?? <ScheduleSeries>[])
      if (_shareFilter.matches(s.categoryId) && !previous.matches(s.categoryId)) s.id]);
  });
  SharedFieldPolicy get _policy => SharedFieldPolicy(location: _location, professor: _professor, subtitle: _subtitle, notes: _notes);

  Future<void> _create(SharePayload payload) async {
    if (_creating || _uncertain) return;
    setState(() { _creating = true; _error = null; });
    try {
      final created = await ref.read(shareSenderProvider).create(payload, validity: _validity);
      if (mounted) setState(() { _created = created; _creating = false; });
    } on ShareApiException catch (e) {
      // Any attempt the sender kept (uncertain, expired, or rejected for
      // auth/rate limits) must be retried or discarded before a new link.
      final kept = await ref.read(shareSenderProvider).pending().then((p) => p.isNotEmpty, onError: (_) => true);
      if (mounted) setState(() { _creating = false; _uncertain = kept; _error = '${shareErrorLabel(e.code)}${kept ? ' Check Shared links for the saved attempt; retry it there rather than creating a second link.' : ''}'; });
    } on Object {
      if (mounted) setState(() { _creating = false; _uncertain = true; _error = 'Creation could not be confirmed. Check Shared links for the saved attempt before trying again.'; });
    }
  }
  @override Widget build(BuildContext context) {
    final enabled = ref.watch(sharingConfigProvider).isConfigured;
    final created = _created;
    final all = _all;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    ShareBuild? build;
    if (all != null) {
      build = ref.read(shareSenderProvider).build([for (final s in all) if (_selected.contains(s.id)) s],
        {for (final c in categories) c.id: c.name}, _policy);
    }
    final payload = build?.payload;
    return PopScope(canPop: !_creating, child: Scaffold(
      appBar: AppBar(title: const Text('Share schedules')),
      body: created != null ? ListView(padding: const EdgeInsets.all(Tokens.md), children: [
          const Text('Link created', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: Tokens.md),
          SelectableText(created.link.toString()),
          const SizedBox(height: Tokens.md),
          Text('Expires ${Formats.of(context).fullDate(LocalDate.fromDateTime(created.share.expiresAt.toLocal()))}'),
          FilledButton(onPressed: () async {
            await Clipboard.setData(ClipboardData(text: created.link.toString()));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
          }, child: const Text('Copy link')),
          const Text('Anyone with this link can view these schedules. Revocation cannot remove copies already added.'),
        ])
        : all == null ? (_error == null ? const Center(child: CircularProgressIndicator.adaptive())
          : EmptyState(title: _error!, action: TextButton(onPressed: _load, child: const Text('Try again'))))
        : ListView(padding: const EdgeInsets.all(Tokens.md), children: [
          const Text('Categories to share', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: Tokens.sm),
          Wrap(spacing: Tokens.sm, runSpacing: Tokens.xs, children: [
            FilterChip(label: const Text('All'), selected: _shareFilter.isAll,
              onSelected: _creating ? null : (_) => setState(() { _shareFilter = const CategoryFilter.all(); _selectScope(); })),
            for (final category in categories)
              FilterChip(key: ValueKey('share-category-${category.id}'), label: Text(category.name),
                selected: !_shareFilter.isAll && _shareFilter.categoryIds.contains(category.id),
                onSelected: _creating ? null : (on) => _category(category.id, on)),
            FilterChip(key: const ValueKey('share-category-uncategorized'), label: const Text('Uncategorized'),
              selected: !_shareFilter.isAll && _shareFilter.includeUncategorized,
              onSelected: _creating ? null : (on) => _category(null, on)),
          ]),
          const Text('Choose categories, then deselect any schedules you do not want to send.'),
          const SizedBox(height: Tokens.md),
          const Text('Past and ended entries are included unless you deselect them. Recurring schedules share their rules and exceptions, not an infinite list of dates.'),
          const SizedBox(height: Tokens.md),
          ExpansionTile(title: const Text('Optional details to share'), children: [
            _toggle('Room or location', _location, (v) => _location = v),
            _toggle('Professor or person', _professor, (v) => _professor = v),
            _toggle('Subtitle', _subtitle, (v) => _subtitle = v),
            _toggle('Notes', _notes, (v) => _notes = v),
          ]),
          const Text('Included schedules', style: TextStyle(fontWeight: FontWeight.w600)),
          for (final s in all.where((s) => _shareFilter.matches(s.categoryId))) CheckboxListTile(value: _selected.contains(s.id), title: Text(s.title),
            subtitle: Text('${categories.where((c) => c.id == s.categoryId).firstOrNull?.name ?? 'Uncategorized'} · ${scheduleTimeLabel(s.time, Formats.of(context))}'), controlAffinity: ListTileControlAffinity.leading,
            onChanged: _creating ? null : (on) => setState(() { on == true ? _selected.add(s.id) : _selected.remove(s.id); })),
          if (payload != null) ExpansionTile(title: const Text('Review exact included data'), children: [
            for (final item in payload.items) _payloadRow(item),
          ]),
          if (enabled) DropdownButtonFormField<Duration>(initialValue: _validity, decoration: const InputDecoration(labelText: 'Link validity'),
            items: const [DropdownMenuItem(value: Duration(days: 1), child: Text('1 day')),
              DropdownMenuItem(value: Duration(days: 7), child: Text('7 days'))],
            onChanged: _creating ? null : (v) => setState(() => _validity = v!)),
          const SizedBox(height: Tokens.md),
          Text(enabled
              ? 'Send link works offline: the schedules travel inside the link. Online links can expire and be revoked; revoking does not erase copies already added.'
              : 'Send link works offline: the schedules travel inside the link. Anyone who has it can add these schedules.'),
          const SizedBox(height: Tokens.sm),
          if (build?.problem != null && build!.problem != ShareBuildProblem.nothingSelected)
            Text(switch (build.problem!) {
              ShareBuildProblem.tooMany => 'Select at most 250 schedules and split larger selections into separate links.',
              ShareBuildProblem.tooLarge => 'This selection is too large. Reduce optional details or split it into separate links.',
              _ => 'Check the selected schedules before sharing.',
            }),
          if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
        ]),
      bottomNavigationBar: created != null || all == null ? null : SafeArea(child: Padding(
        padding: const EdgeInsets.all(Tokens.md), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Semantics(liveRegion: true, child: Text('${_selected.length} selected')),
          if (_uncertain) TextButton(onPressed: _creating ? null : () async {
            await context.push('/settings/shared-links');
            if (!mounted) return;
            final pending = await ref.read(shareSenderProvider).pending();
            if (mounted) setState(() => _uncertain = pending.isNotEmpty);
          }, child: const Text('Check saved attempts')),
          Row(children: [
            if (enabled) ...[
              Expanded(child: FilledButton(onPressed: !_creating && !_uncertain && payload != null ? () => _create(payload) : null,
                child: Text(_creating ? 'Creating…' : 'Create link'))),
              const SizedBox(width: Tokens.sm),
            ],
            Expanded(child: enabled
                ? FilledButton.tonal(key: const ValueKey('send-direct'), onPressed: !_creating && payload != null ? () => _sendDirect(payload) : null,
                    child: const Text('Send link'))
                : FilledButton(key: const ValueKey('send-direct'), onPressed: payload != null ? () => _sendDirect(payload) : null,
                    child: const Text('Send link'))),
          ]),
        ]))),
    ));
  }
  /// Offline link through the system share sheet; copied when nothing can
  /// receive it.
  Future<void> _sendDirect(SharePayload payload) async {
    final link = DirectShare.encode(payload).toString();
    final titles = payload.items.map((i) => i.title).take(3).join(', ');
    final more = payload.items.length > 3 ? ' +${payload.items.length - 3} more' : '';
    final text = 'Schedules from Schediel: $titles$more\n\n'
        'To add them, copy this message, open Schediel, tap + and choose Open shared link.\n\n$link';
    final sent = await ref.read(nativeBridgeProvider).shareText(text, subject: 'Schediel schedules');
    if (!sent) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
    }
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> change) => SwitchListTile(title: Text(label), value: value,
    onChanged: _creating ? null : (v) => setState(() => change(v)));
  Widget _payloadRow(ShareItem item) {
    final f = Formats.of(context);
    return ExpansionTile(title: Text(item.title), subtitle: Text('${scheduleTimeLabel(item.time, f)}\n${f.repeatSummary(item.recurrence)}'), children: [
      if (item.categoryLabel != null) ListTile(title: Text(item.categoryLabel!)),
      for (final v in [item.details.location, item.details.professor, item.details.subtitle, item.details.notes])
        if (v != null) ListTile(title: Text(v)),
      for (final e in item.exceptions) ListTile(title: Text('${f.fullDate(e.originalKey)} · ${e.action.name}'),
        subtitle: e.replacement == null ? null : Text([e.replacement!.title, scheduleTimeLabel(e.replacement!.time,f),
          ...[e.replacement!.details.location,e.replacement!.details.professor,e.replacement!.details.subtitle,e.replacement!.details.notes].whereType<String>()].join('\n'))),
    ]);
  }
}
