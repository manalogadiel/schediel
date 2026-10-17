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
import '../../categories/domain/category.dart';
import '../application/day_view.dart';
import 'add_menu.dart';
import 'timeline_row.dart';

/// Today: the Monitor surface (spec 4.3).
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _pastCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(effectiveDateProvider);
    final today = ref.watch(todayProvider);
    final view = ref.watch(dayViewProvider(date));
    final f = Formats.of(context);
    final text = Theme.of(context).textTheme;
    final colors = context.scheduleColors;
    final relative = f.relativeDay(date, today);
    final dateNotifier = ref.read(selectedDateProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.sm, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Selected date ${f.dayTitle(date)}${relative == null ? '' : ', $relative'}. Choose a date',
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(Tokens.radiusControl),
                          onTap: () => _pickDate(context, date),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: Tokens.xs),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(relative ?? '${date.year}', style: text.labelMedium?.copyWith(color: colors.secondaryInk)),
                                Text(f.dayTitle(date), style: text.headlineMedium),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Share schedules',
                      onPressed: () => context.push('/share/create'),
                      icon: const AppIcon(AppIcons.share),
                    ),
                    IconButton(
                      tooltip: 'Add',
                      onPressed: () => showAddMenu(context),
                      icon: const AppIcon(AppIcons.add),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Tokens.sm, Tokens.xs, Tokens.md, Tokens.md),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous day',
                      onPressed: () => dateNotifier.select(date.addDays(-1)),
                      icon: const AppIcon(AppIcons.previous),
                    ),
                    IconButton(
                      tooltip: 'Next day',
                      onPressed: () => dateNotifier.select(date.addDays(1)),
                      icon: const AppIcon(AppIcons.next),
                    ),
                    if (date != today) TextButton(onPressed: dateNotifier.today, child: const Text('Today')),
                    const Spacer(),
                    const FilterPill(),
                  ],
                ),
              ),
            ),
            ...view.when(
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
              ],
              error: (_, _) => [
                SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'Unable to load schedules',
                    action: OutlinedButton(
                      onPressed: () => ref.invalidate(allSeriesProvider),
                      child: const Text('Try again'),
                    ),
                  ),
                ),
              ],
              data: (v) => _content(context, v),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: Tokens.xxl)),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, DayView v) {
    if (!v.hasAnySchedules) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            title: 'No schedules yet',
            action: FilledButton(onPressed: () => context.push('/schedule/new'), child: const Text('Create schedule')),
          ),
        ),
      ];
    }
    if (v.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: v.filterActive
              ? EmptyState(
                  title: 'No schedules in this filter',
                  action: TextButton(
                    onPressed: () => ref.read(appFilterProvider.notifier).set(const CategoryFilter.all()),
                    child: const Text('Show all'),
                  ),
                )
              : const EmptyState(title: 'No schedules on this day'),
        ),
      ];
    }

    final a = v.agenda;
    final sections = <Widget>[];
    Widget row(Occurrence o, RowEmphasis e) =>
        TimelineRow(key: ValueKey('${o.id}-${e.name}'), occurrence: o, emphasis: e, overlaps: v.overlapIds.contains(o.id));

    if (a.dateOnly.isNotEmpty) {
      sections.add(SectionGroup(header: 'All day', children: [for (final o in a.dateOnly) row(o, RowEmphasis.normal)]));
    }
    if (a.needsReview.isNotEmpty) {
      sections.add(SectionGroup(header: 'Needs time review', children: [for (final o in a.needsReview) row(o, RowEmphasis.normal)]));
    }
    if (v.isToday) {
      final active = [
        for (final o in a.ongoing) row(o, RowEmphasis.now),
        if (a.next != null) row(a.next!, RowEmphasis.next),
        for (final o in a.upcoming) row(o, RowEmphasis.normal),
      ];
      if (active.isNotEmpty) {
        sections.add(SectionGroup(children: active));
      } else if (a.past.isNotEmpty) {
        sections.add(const Padding(
          padding: EdgeInsets.only(bottom: Tokens.lg),
          child: EmptyState(title: 'Nothing else today'),
        ));
      }
      if (a.past.isNotEmpty) {
        sections.add(SectionGroup(
          header: 'Earlier today',
          trailing: TextButton(
            onPressed: () => setState(() => _pastCollapsed = !_pastCollapsed),
            child: Text(_pastCollapsed ? 'Show ${a.past.length}' : 'Hide'),
          ),
          children: _pastCollapsed ? const [] : [for (final o in a.past) row(o, RowEmphasis.past)],
        ));
      }
    } else if (a.timed.isNotEmpty) {
      sections.add(SectionGroup(children: [for (final o in a.timed) row(o, RowEmphasis.normal)]));
    }
    if (v.truncated) {
      sections.add(Text('Some entries are not shown. Open the week view or narrow the filter.',
          style: Theme.of(context).textTheme.bodySmall));
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.md),
        sliver: SliverList.list(children: sections),
      ),
    ];
  }

  Future<void> _pickDate(BuildContext context, LocalDate current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(LocalDate.minYear),
      lastDate: DateTime(LocalDate.maxYear, 12, 31),
    );
    if (picked != null) ref.read(selectedDateProvider.notifier).select(LocalDate.fromDateTime(picked));
  }
}
