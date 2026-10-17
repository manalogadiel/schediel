import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../core/time/local_date.dart';
import '../../categories/domain/category.dart';
import '../application/widget_snapshot_reader.dart';
import '../application/widget_snapshot_service.dart';
import '../domain/widget_config.dart';
import '../domain/widget_style.dart';

bool get _isIOS => !kIsWeb && Platform.isIOS;

/// Home screen widget settings (spec 4.7). Each placed Android widget has its
/// own settings; "Default" covers the rest.
class WidgetSettingsScreen extends ConsumerWidget {
  const WidgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installed = ref.watch(installedWidgetKeysProvider).value ?? const <String>[];
    final text = Theme.of(context).textTheme;
    final secondary = context.scheduleColors.secondaryInk;
    return Scaffold(
      appBar: AppBar(title: const Text('Home screen widgets')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Tokens.xs, 0, Tokens.xs, Tokens.md),
            child: Text(
              'Add Schediel from your home screen’s widget list. Your wallpaper stays as it is; '
              'the widget shows your next and upcoming schedules on top of it.',
              style: text.bodyMedium?.copyWith(color: secondary),
            ),
          ),
          SectionGroup(children: [
            ListTile(
              leading: const AppIcon(AppIcons.widget),
              title: const Text('Default widget settings'),
              subtitle: Text(_isIOS ? 'Used by all widgets on this iPhone' : 'Used by widgets without their own settings'),
              trailing: AppIcon(AppIcons.next, size: 18, color: secondary),
              onTap: () => context.push('/settings/widgets/${WidgetConfig.defaultKey}'),
            ),
          ]),
          if (installed.isNotEmpty)
            SectionGroup(header: 'Placed widgets', children: [
              for (var i = 0; i < installed.length; i++)
                ListTile(
                  title: Text('Widget ${i + 1}'),
                  trailing: AppIcon(AppIcons.next, size: 18, color: secondary),
                  onTap: () => context.push('/settings/widgets/${installed[i]}'),
                ),
            ]),
          if (_isIOS)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Tokens.xs),
              child: Text(
                'On iPhone, the system can replace the widget background and tint its content in some home screen styles.',
                style: text.bodySmall?.copyWith(color: secondary),
              ),
            ),
        ],
      ),
    );
  }
}

class WidgetConfigScreen extends ConsumerStatefulWidget {
  const WidgetConfigScreen({super.key, required this.widgetKey});

  final String widgetKey;

  @override
  ConsumerState<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends ConsumerState<WidgetConfigScreen> {
  WidgetConfig? _config;
  bool _darkBackdrop = true;

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(widgetConfigsProvider).value;
    if (_config == null && saved != null) {
      _config = saved.where((c) => c.widgetKey == widget.widgetKey).firstOrNull ??
          (saved.where((c) => c.widgetKey == WidgetConfig.defaultKey).firstOrNull ?? WidgetConfig.defaults)
              .copyWith(widgetKey: widget.widgetKey, revision: 0);
    }
    final config = _config;
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.widgetKey == WidgetConfig.defaultKey ? 'Default widget' : 'Widget settings'),
      ),
      body: config == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.xxl),
              children: [
                _Preview(config: config, darkBackdrop: _darkBackdrop),
                Padding(
                  padding: const EdgeInsets.only(bottom: Tokens.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Preview on', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: Tokens.sm),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Dark')),
                          ButtonSegment(value: false, label: Text('Light')),
                        ],
                        selected: {_darkBackdrop},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => setState(() => _darkBackdrop = s.first),
                      ),
                    ],
                  ),
                ),
                SectionGroup(header: 'Show', children: [
                  Padding(
                    padding: const EdgeInsets.all(Tokens.md),
                    child: Wrap(spacing: Tokens.sm, runSpacing: Tokens.sm, children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: config.filter.isAll,
                        onSelected: (_) => _update(config.copyWith(filter: const CategoryFilter.all())),
                      ),
                      for (final c in categories)
                        FilterChip(
                          label: Text(c.name),
                          selected: !config.filter.isAll && config.filter.categoryIds.contains(c.id),
                          onSelected: (on) => _update(config.copyWith(filter: _toggle(config.filter, c.id, on))),
                        ),
                      FilterChip(
                        label: const Text('Uncategorized'),
                        selected: !config.filter.isAll && config.filter.includeUncategorized,
                        onSelected: (on) => _update(config.copyWith(filter: _toggle(config.filter, null, on))),
                      ),
                    ]),
                  ),
                ]),
                SectionGroup(header: 'Layout', children: [
                  Padding(
                    padding: const EdgeInsets.all(Tokens.md),
                    child: SegmentedButton<WidgetLayout>(
                      segments: const [
                        ButtonSegment(value: WidgetLayout.compact, label: Text('Compact')),
                        ButtonSegment(value: WidgetLayout.expanded, label: Text('Expanded')),
                      ],
                      selected: {config.layout},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => _update(config.copyWith(layout: s.first)),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Emphasize next schedule'),
                    value: config.nextEmphasis,
                    onChanged: (v) => _update(config.copyWith(nextEmphasis: v)),
                  ),
                ]),
                SectionGroup(header: 'Surface', children: [
                  RadioGroup<WidgetSurface>(
                    groupValue: config.surface,
                    onChanged: (v) => _update(config.copyWith(surface: v)),
                    child: const Column(children: [
                      RadioListTile(
                        value: WidgetSurface.clear,
                        title: Text('Clear'),
                        subtitle: Text('No background. Your wallpaper shows through, with subtle holders.'),
                      ),
                      RadioListTile(
                        value: WidgetSurface.softTint,
                        title: Text('Soft tint'),
                        subtitle: Text('Stronger translucent holders'),
                      ),
                      RadioListTile(
                        value: WidgetSurface.solid,
                        title: Text('Solid'),
                        subtitle: Text('Opaque holders for the most readable text'),
                      ),
                    ]),
                  ),
                ]),
                SectionGroup(header: 'Text', children: [
                  SwitchListTile(
                    title: const Text('Match app appearance'),
                    subtitle: const Text('Light or dark text follows the app'),
                    value: config.matchApp,
                    onChanged: (v) => _update(config.copyWith(matchApp: v)),
                  ),
                  if (!config.matchApp)
                    Padding(
                      padding: const EdgeInsets.all(Tokens.md),
                      child: SegmentedButton<WidgetTextTone>(
                        segments: const [
                          ButtonSegment(value: WidgetTextTone.light, label: Text('Light text')),
                          ButtonSegment(value: WidgetTextTone.dark, label: Text('Dark text')),
                        ],
                        selected: {config.textTone},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => _update(config.copyWith(textTone: s.first)),
                      ),
                    ),
                ]),
                SectionGroup(header: 'Details', children: [
                  SwitchListTile(
                    title: const Text('Room or location'),
                    value: config.showLocation,
                    onChanged: (v) => _update(config.copyWith(showLocation: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Professor or person'),
                    value: config.showProfessor,
                    onChanged: (v) => _update(config.copyWith(showProfessor: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Subtitle'),
                    value: config.showSubtitle,
                    onChanged: (v) => _update(config.copyWith(showSubtitle: v)),
                  ),
                ]),
              ],
            ),
    );
  }

  CategoryFilter _toggle(CategoryFilter filter, String? id, bool on) {
    final ids = filter.isAll ? <String>{} : {...filter.categoryIds};
    var uncategorized = !filter.isAll && filter.includeUncategorized;
    if (id == null) {
      uncategorized = on;
    } else if (on) {
      ids.add(id);
    } else {
      ids.remove(id);
    }
    if (ids.isEmpty && !uncategorized) return const CategoryFilter.all();
    return CategoryFilter.only(ids, includeUncategorized: uncategorized);
  }

  Future<void> _update(WidgetConfig next) async {
    setState(() => _config = next);
    final saved = await ref.read(widgetConfigRepositoryProvider).save(next);
    if (mounted) setState(() => _config = saved);
    await ref.read(widgetSnapshotServiceProvider).refresh();
  }
}

/// Renders the widget with the same reader rules as the native widgets, over
/// a plain backdrop. It never uses or copies the device wallpaper.
class _Preview extends ConsumerWidget {
  const _Preview({required this.config, required this.darkBackdrop});

  final WidgetConfig config;
  final bool darkBackdrop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(allSeriesProvider).value ?? const [];
    final now = ref.watch(nowProvider);
    final zone = ref.watch(deviceZoneProvider);
    final zones = ref.watch(zoneResolverProvider);
    final appDark = Theme.of(context).brightness == Brightness.dark;
    final json = ref.watch(widgetSnapshotBuilderProvider).build(
          series: series,
          configs: [config.copyWith(widgetKey: 'preview')],
          now: now,
          zone: zone,
          dataRevision: 0,
          use24h: MediaQuery.alwaysUse24HourFormatOf(context),
          appIsDark: appDark,
        );
    final result = readWidgetSnapshot(jsonEncode(json), widgetKey: 'preview', now: now, deviceZone: zone, zones: zones);
    final tone = WidgetTextTone.values.byName(result.configuration['textTone'] as String? ?? config.textTone.name);
    final style = WidgetStyle.of(config.surface, tone);
    final f = Formats.of(context);
    final today = zones.localDateOf(now, zone);

    Widget holder(WidgetSnapshotEntry e, {required bool next, String? status}) {
      final start = e.startEpochMs;
      final reviewDate = LocalDate.tryParse(e.startDate);
      final timeText = start == null
          ? '${reviewDate == null || reviewDate == today ? '' : '${f.shortDate(reviewDate)} · '}Time needs review'
          : () {
              final s = zones.toLocal(DateTime.fromMillisecondsSinceEpoch(start, isUtc: true), zone);
              final endMs = e.endEpochMs;
              final range = endMs == null
                  ? f.clock(s.time)
                  : '${f.clock(s.time)} – ${f.clock(zones.toLocal(DateTime.fromMillisecondsSinceEpoch(endMs, isUtc: true), zone).time)}';
              final datePrefix = s.date == today ? '' : '${f.shortDate(s.date)} · ';
              return '$datePrefix$range${e.zoneLabel == null ? '' : ' (${e.zoneLabel})'}';
            }();
      final details = [e.location, e.professor, e.subtitle].whereType<String>().toList();
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: next && config.nextEmphasis ? style.nextHolder : style.upcomingHolder,
          borderRadius: BorderRadius.circular(WidgetStyle.holderRadius),
          border: next && config.nextEmphasis ? Border.all(color: style.nextOutline) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${status == null ? '' : '$status · '}$timeText',
              style: TextStyle(fontSize: 12, color: style.secondaryText, fontWeight: FontWeight.w500),
            ),
            Text(
              e.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: style.primaryText,
                fontWeight: next && config.nextEmphasis ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            if (config.layout == WidgetLayout.expanded && details.isNotEmpty)
              Text(details.join(' · '),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: style.secondaryText)),
          ],
        ),
      );
    }

    final children = <Widget>[];
    if (result.state != WidgetReadState.entries) {
      children.add(Padding(
        padding: const EdgeInsets.all(Tokens.md),
        child: Text(result.message ?? '', style: TextStyle(color: style.primaryText, fontSize: 15)),
      ));
    } else {
      // Same choices as the native widgets (android/.../widget/WidgetPlanner.kt).
      final limit = config.layout == WidgetLayout.compact ? 2 : 4;
      final ordered = <(WidgetSnapshotEntry, bool, String?)>[
        for (final id in result.ongoing) (result.entries[id]!, false, 'Now'),
        if (result.next != null) (result.entries[result.next]!, true, 'Next'),
        for (final id in result.upcoming) (result.entries[id]!, false, null),
        for (final id in result.needsReview.take(1)) (result.entries[id]!, false, null),
      ];
      for (final id in result.allDay.take(2)) {
        final e = result.entries[id]!;
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text('All day · ${e.title}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: style.secondaryText)),
        ));
      }
      for (final entry in ordered.take(limit)) {
        children.add(holder(entry.$1, next: entry.$2, status: entry.$3));
      }
    }

    return Semantics(
      label: 'Widget preview',
      child: Container(
        height: config.layout == WidgetLayout.compact ? 170 : 300,
        margin: const EdgeInsets.only(bottom: Tokens.sm),
        padding: const EdgeInsets.all(Tokens.md),
        decoration: BoxDecoration(
          color: darkBackdrop ? const Color(0xFF2C2C30) : const Color(0xFFD8D8DE),
          borderRadius: BorderRadius.circular(Tokens.radiusCard),
        ),
        child: ClipRect(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}
