import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/shell.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/time/local_date.dart';
import '../../categories/domain/category.dart';
import '../application/day_view.dart';
import 'day_strip.dart';
import 'next_card.dart';
import 'timeline_row.dart';
import 'today_header.dart';

/// Today: the Monitor surface (spec 4.3; revamp §4). The next thing
/// dominates; everything shown comes from the user's data.
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
    final view = ref.watch(dayViewProvider(date));
    const pad = EdgeInsets.symmetric(horizontal: Tokens.md);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.sm, 0),
              sliver: SliverToBoxAdapter(child: TodayHeader()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, 0),
              sliver: SliverToBoxAdapter(child: DateHeading(onPick: () => _pickDate(context, date))),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.sm),
              sliver: SliverToBoxAdapter(child: DayStrip()),
            ),
            ...view.when(
              loading: () => [
                const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator.adaptive())),
              ],
              error: (_, _) => [
                SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'Unable to load schedules',
                    action: OutlinedButton(onPressed: () => ref.invalidate(allSeriesProvider), child: const Text('Try again')),
                  ),
                ),
              ],
              data: (v) => [
                SliverPadding(
                  padding: pad,
                  sliver: SliverList.list(children: _content(context, v)),
                ),
              ],
            ),
            SliverToBoxAdapter(child: SizedBox(height: AppShell.bottomInset(context))),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, DayView v) {
    if (!v.hasAnySchedules) {
      return [
        EmptyState(
          title: 'No schedules yet',
          illustration: const ScheduleEmptyArt(),
          action: FilledButton(onPressed: () => context.push('/schedule/new'), child: const Text('Create schedule')),
        ),
      ];
    }
    final a = v.agenda;
    final showNext = v.isToday && a.next != null;
    final children = <Widget>[
      if (showNext)
        Padding(
          padding: const EdgeInsets.only(top: Tokens.xs, bottom: Tokens.md),
          child: NextCard(next: a.next!),
        ),
      _SectionHeader(title: v.isToday ? 'Today' : 'Schedule', trailing: const FilterPill()),
    ];

    if (v.isEmpty) {
      children.add(
        v.filterActive
            ? EmptyState(
                title: 'No schedules in this filter',
                action: TextButton(
                  onPressed: () => ref.read(appFilterProvider.notifier).set(const CategoryFilter.all()),
                  child: const Text('Show all'),
                ),
              )
            : const EmptyState(title: 'No schedules on this day', illustration: ScheduleEmptyArt()),
      );
      return children;
    }

    Widget row(Occurrence o, RowEmphasis e) =>
        TimelineRow(key: ValueKey('${o.id}-${e.name}'), occurrence: o, emphasis: e, overlaps: v.overlapIds.contains(o.id));

    if (a.dateOnly.isNotEmpty) {
      children
        ..add(const _SectionHeader(title: 'All day', small: true))
        ..addAll([for (final o in a.dateOnly) row(o, RowEmphasis.normal)]);
    }
    if (a.needsReview.isNotEmpty) {
      children
        ..add(const _SectionHeader(title: 'Needs time review', small: true))
        ..addAll([for (final o in a.needsReview) row(o, RowEmphasis.normal)]);
    }
    if (v.isToday) {
      // The next item is the Next card; the timeline lists the rest.
      final active = [for (final o in a.ongoing) row(o, RowEmphasis.now), for (final o in a.upcoming) row(o, RowEmphasis.normal)];
      children.addAll(active);
      if (active.isEmpty && !showNext && a.past.isNotEmpty) {
        children.add(const EmptyState(title: 'Nothing else today', illustration: ScheduleEmptyArt()));
      }
      if (a.past.isNotEmpty) {
        children.add(
          _SectionHeader(
            title: 'Earlier today',
            small: true,
            trailing: TextButton(
              onPressed: () => setState(() => _pastCollapsed = !_pastCollapsed),
              child: Text(_pastCollapsed ? 'Show ${a.past.length}' : 'Hide'),
            ),
          ),
        );
        if (!_pastCollapsed) children.addAll([for (final o in a.past) row(o, RowEmphasis.past)]);
      }
    } else {
      children.addAll([for (final o in a.timed) row(o, RowEmphasis.normal)]);
    }
    if (v.truncated) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: Tokens.sm),
          child: Text(
            'Some entries are not shown. Open the week view or narrow the filter.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return children;
  }

  Future<void> _pickDate(BuildContext context, LocalDate current) async {
    final picked = await pickDate(context, current);
    if (picked != null) ref.read(selectedDateProvider.notifier).select(picked);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing, this.small = false});

  final String title;
  final Widget? trailing;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.scheduleColors;
    return Padding(
      padding: EdgeInsets.only(top: small ? Tokens.sm : 0, bottom: Tokens.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: small ? text.labelMedium?.copyWith(color: c.secondaryInk) : text.titleLarge),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
