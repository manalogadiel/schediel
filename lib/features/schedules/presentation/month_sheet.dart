import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/schediel_theme.dart';
import '../../../app/widgets/common.dart';
import '../../../core/time/local_date.dart';
import 'day_strip.dart';

/// Opens the month calendar sheet; returns the chosen date, or null when
/// dismissed.
Future<LocalDate?> showMonthSheet(BuildContext context, {required LocalDate initial}) => showModalBottomSheet<LocalDate>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => MonthSheet(initial: initial),
);

LocalDate _firstOf(int year, int month) => LocalDate.fromDateTime(DateTime.utc(year, month, 1));

/// A month calendar in a bottom sheet: oversized month heading, a raised
/// grid with today ringed, the selection as a glowing orb and dots on days
/// that have schedules. Swipe or use the chevrons to change month.
class MonthSheet extends ConsumerStatefulWidget {
  const MonthSheet({super.key, required this.initial});
  final LocalDate initial;

  @override
  ConsumerState<MonthSheet> createState() => _MonthSheetState();
}

class _MonthSheetState extends ConsumerState<MonthSheet> {
  late LocalDate _month = _firstOf(widget.initial.year, widget.initial.month);
  late LocalDate _selected = widget.initial;
  int _direction = 1;

  void _page(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _direction = delta;
      _month = _firstOf(_month.year, _month.month + delta);
    });
  }

  void _goToday() {
    final today = ref.read(todayProvider);
    setState(() {
      _direction = today.daysUntil(_month) > 0 ? -1 : 1;
      _month = _firstOf(today.year, today.month);
      _selected = today;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final p = c.palette;
    final text = Theme.of(context).textTheme;
    final f = Formats.of(context);
    final today = ref.watch(todayProvider);
    final pixel = c.style == StyleFamily.pixel;
    final dark = p.brightness == Brightness.dark;
    final first = weekStartOf(context, _month);
    final days = [for (var i = 0; i < 42; i++) first.addDays(i)];
    final marked = <LocalDate>{
      for (var w = 0; w < 6; w++)
        for (final d in ref.watch(weekViewProvider(first.addDays(7 * w))).value?.days ?? const [])
          if (!d.isEmpty) d.date,
    };
    final duration = AppMotion.screen(context);

    final grid = Column(
      key: ValueKey(_month),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    f.weekdayShort(days[i].weekday).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .6,
                      color: days[i].weekday >= 6 ? c.accentText : c.secondaryInk,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var w = 0; w < 6; w++)
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _DayDot(
                    date: days[w * 7 + i],
                    inMonth: days[w * 7 + i].month == _month.month,
                    selected: days[w * 7 + i] == _selected,
                    isToday: days[w * 7 + i] == today,
                    marked: marked.contains(days[w * 7 + i]),
                    onTap: () => setState(() => _selected = days[w * 7 + i]),
                  ),
                ),
            ],
          ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(pixel ? 0 : 28)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.paddingOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: c.ink.withValues(alpha: .18), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: f.monthName(_month)),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: '${_month.year}',
                            style: TextStyle(color: c.accentText, fontWeight: c.displayFont == null ? FontWeight.w300 : null),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      style: text.displaySmall,
                    ),
                  ),
                ),
                _RoundButton(key: const ValueKey('month-prev'), icon: AppIcons.previous, tooltip: 'Previous month', onTap: () => _page(-1)),
                const SizedBox(width: 8),
                _RoundButton(key: const ValueKey('month-next'), icon: AppIcons.next, tooltip: 'Next month', onTap: () => _page(1)),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v.abs() > 250) _page(v < 0 ? 1 : -1);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(pixel ? 0 : 22),
                  border: c.outlined ? Border.all(color: p.outline, width: 2) : null,
                  boxShadow: c.outlined
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: dark ? .03 : .8),
                            offset: const Offset(-4, -4),
                            blurRadius: 12,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: dark ? .35 : .08),
                            offset: const Offset(4, 8),
                            blurRadius: 18,
                          ),
                        ],
                ),
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: duration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final incoming = child.key == ValueKey(_month);
                      final dx = (incoming ? .25 : -.25) * _direction;
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                    child: grid,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton(
                  key: const ValueKey('month-today'),
                  onPressed: _goToday,
                  child: const FittedBox(child: Text('Today')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('month-done'),
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: const FittedBox(child: Text('Done')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({super.key, required this.icon, required this.tooltip, required this.onTap});
  final AppIcons icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final shape = c.style == StyleFamily.pixel ? const RoundedRectangleBorder() : const CircleBorder();
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Center(child: AppIcon(icon, size: 20, color: c.ink)),
          ),
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.date,
    required this.inMonth,
    required this.selected,
    required this.isToday,
    required this.marked,
    required this.onTap,
  });
  final LocalDate date;
  final bool inMonth, selected, isToday, marked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final p = c.palette;
    final soft = c.style == StyleFamily.soft;
    final shape = c.style == StyleFamily.pixel ? BoxShape.rectangle : BoxShape.circle;
    final ink = selected ? p.onAccent : (inMonth ? (date.weekday >= 6 ? c.accentText : c.ink) : c.ink.withValues(alpha: .3));
    return Semantics(
      button: true,
      selected: selected,
      label: Formats.of(context).dayTitle(date),
      excludeSemantics: true,
      child: InkResponse(
        key: ValueKey('month-day-${date.toIso()}'),
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          height: 46,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppMotion.control(context),
                curve: Curves.easeOutCubic,
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: shape,
                  color: selected && !soft ? p.accent : (selected ? null : Colors.transparent),
                  gradient: selected && soft
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [p.accent, Color.lerp(p.accent, const Color(0xFFFF7A59), .45)!],
                        )
                      : null,
                  border: isToday && !selected ? Border.all(color: c.accentText, width: 1.5) : null,
                  boxShadow: selected && soft
                      ? [BoxShadow(color: p.accent.withValues(alpha: .4), blurRadius: 10, offset: const Offset(0, 4))]
                      : null,
                ),
                child: FittedBox(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected || isToday ? FontWeight.w800 : FontWeight.w500,
                      color: ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                key: marked ? ValueKey('month-dot-${date.toIso()}') : null,
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: shape,
                  color: marked ? c.accentText.withValues(alpha: inMonth ? 1 : .4) : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
