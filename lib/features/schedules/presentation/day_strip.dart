import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/schediel_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../core/time/local_date.dart';

/// First day of the locale's week containing [date].
LocalDate weekStartOf(BuildContext context, LocalDate date) {
  final first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  final isoStart = first == 0 ? 7 : first;
  return date.addDays(-((date.weekday - isoStart + 7) % 7));
}

/// Seven days of the selected week. Tap a day to select it; swipe sideways
/// to move a week. Dots mark days that have schedules (real data, current
/// filter).
class DayStrip extends ConsumerWidget {
  const DayStrip({super.key, this.arched = false});

  /// Lays the days along a gentle arc (Today's hero strip).
  final bool arched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(effectiveDateProvider);
    final today = ref.watch(todayProvider);
    final start = weekStartOf(context, selected);
    final week = ref.watch(weekViewProvider(start)).value;
    final withSchedules = {
      if (week != null)
        for (final d in week.days)
          if (!d.isEmpty) d.date,
    };
    final notifier = ref.read(selectedDateProvider.notifier);
    return DayStripView(
      start: start,
      selected: selected,
      today: today,
      daysWithSchedules: withSchedules,
      onSelect: notifier.select,
      arched: arched,
    );
  }
}

class DayStripView extends StatelessWidget {
  const DayStripView({
    super.key,
    required this.start,
    required this.selected,
    required this.today,
    required this.daysWithSchedules,
    required this.onSelect,
    this.arched = false,
  });

  final LocalDate start;
  final LocalDate selected;
  final LocalDate today;
  final Set<LocalDate> daysWithSchedules;
  final ValueChanged<LocalDate> onSelect;
  final bool arched;

  /// How far the outermost days sit below the middle one.
  static const archDepth = 14.0;

  /// Half the band's height around the number row (orb radius + margin).
  static const bandHalf = 23.0;

  /// Fixed weekday-label box, so the number row (and the band behind it)
  /// sits at a predictable height.
  static double labelHeightFor(double textScale) => (12 * 1.3 * textScale).ceilToDouble();

  /// Centre of the number row in an unshifted cell: padding, label, gap,
  /// orb radius.
  static double numberCenter(double labelHeight) => 6 + labelHeight + 6 + 19;

  /// Arc offset at [x] across a strip [width] wide; matches the per-cell
  /// translation at each cell centre.
  static double archAt(double x, double width) {
    final u = ((x / width) * 7 - 3.5) / 3;
    return archDepth * u * u;
  }

  /// Top edge of the glass band at [x].
  static double bandTop(double x, double width, double labelHeight) => numberCenter(labelHeight) - bandHalf + archAt(x, width);

  @override
  Widget build(BuildContext context) {
    final f = Formats.of(context);
    final c = context.scheduleColors;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    // Large text flattens the arc so nothing clips.
    final arch = arched && scale < 1.5;
    final labelHeight = labelHeightFor(scale);
    void week(int delta) => onSelect(selected.addDays(7 * delta));
    final row = Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Transform.translate(
              offset: Offset(0, arch ? archDepth * ((i - 3) / 3) * ((i - 3) / 3) : 0),
              child: _DayCell(
                labelHeight: arch ? labelHeight : null,
                date: start.addDays(i),
                weekday: f.weekdayShort(start.addDays(i).weekday),
                title: f.dayTitle(start.addDays(i)),
                selected: start.addDays(i) == selected,
                isToday: start.addDays(i) == today,
                hasSchedules: daysWithSchedules.contains(start.addDays(i)),
                onTap: () => onSelect(start.addDays(i)),
              ),
            ),
          ),
      ],
    );
    return Semantics(
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Previous week'): () => week(-1),
        const CustomSemanticsAction(label: 'Next week'): () => week(1),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 200) return;
          week(v < 0 ? 1 : -1);
        },
        child: arch
            ? CustomPaint(
                painter: _BandPainter(
                  fill: c.palette.brightness == Brightness.dark ? Colors.white.withValues(alpha: .06) : c.surface.withValues(alpha: .55),
                  highlight: Colors.white.withValues(alpha: c.palette.brightness == Brightness.dark ? .14 : .7),
                  shadow: c.ink.withValues(alpha: .08),
                  labelHeight: labelHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: archDepth),
                  child: row,
                ),
              )
            : row,
      ),
    );
  }
}

/// A curved glass band behind the number row: soft shadow beneath, a
/// translucent fill and a bright top edge. Labels stay above it.
class _BandPainter extends CustomPainter {
  const _BandPainter({required this.fill, required this.highlight, required this.shadow, required this.labelHeight});
  final Color fill, highlight, shadow;
  final double labelHeight;

  @override
  void paint(Canvas canvas, Size size) {
    const steps = 28;
    final top = <Offset>[];
    final bottom = <Offset>[];
    for (var k = 0; k <= steps; k++) {
      final x = size.width * k / steps;
      final y = DayStripView.bandTop(x, size.width, labelHeight);
      top.add(Offset(x, y));
      bottom.add(Offset(x, y + 2 * DayStripView.bandHalf));
    }
    final band = Path()..addPolygon([...top, ...bottom.reversed], true);
    canvas
      ..drawPath(
        band.shift(const Offset(0, 6)),
        Paint()
          ..color = shadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      )
      ..drawPath(band, Paint()..color = fill)
      ..drawPath(
        Path()..addPolygon(top, false),
        Paint()
          ..color = highlight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.fill != fill || old.highlight != highlight || old.shadow != shadow || old.labelHeight != labelHeight;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.labelHeight,
    required this.date,
    required this.weekday,
    required this.title,
    required this.selected,
    required this.isToday,
    required this.hasSchedules,
    required this.onTap,
  });

  /// Fixed label box when the strip draws its band; null lets it size itself.
  final double? labelHeight;
  final LocalDate date;
  final String weekday;
  final String title;
  final bool selected;
  final bool isToday;
  final bool hasSchedules;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final p = c.palette;
    final pixel = c.style == StyleFamily.pixel;
    final soft = c.style == StyleFamily.soft;
    // Low-contrast accents (customized or outlined themes) get a boundary.
    final needsEdge = selected && (c.outlined || contrastRatio(p.accent, c.canvas) < 3 || contrastRatio(p.accent, c.surface) < 3);
    // The column is never outlined; the orb carries any boundary.
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(pixel ? 0 : Tokens.radiusControl));
    final label = [title, if (isToday) 'today', if (hasSchedules) 'has schedules'].join(', ');
    final duration = AppMotion.control(context) * 1.5;
    final numberStyle = TextStyle(
      fontFamily: c.displayFont,
      fontSize: c.displayFont == 'Caveat' ? 22 : (c.displayFont == 'Silkscreen' ? 13 : 17),
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      color: selected ? p.onAccent : c.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Material(
          key: ValueKey('day-${date.toIso()}'),
          color: Colors.transparent,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: labelHeight,
                      child: Text(
                        weekday,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? c.accentText : c.secondaryInk,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      key: ValueKey('day-orb-${date.toIso()}'),
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: pixel ? BoxShape.rectangle : BoxShape.circle,
                        color: selected && !soft ? p.accent : (selected ? null : Colors.transparent),
                        gradient: selected && soft
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [p.accent, Color.lerp(p.accent, const Color(0xFFFF7A59), .45)!],
                              )
                            : null,
                        border: needsEdge
                            ? Border.all(color: p.outline, width: 2)
                            : isToday && !selected
                            ? Border.all(color: c.accentText, width: 1.5)
                            : null,
                        boxShadow: selected && soft
                            ? [BoxShadow(color: p.accent.withValues(alpha: .4), blurRadius: 12, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Text('${date.day}', maxLines: 1, style: numberStyle),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: duration,
                      width: hasSchedules && selected ? 14 : 5,
                      height: 4,
                      decoration: BoxDecoration(
                        color: hasSchedules ? c.accentText.withValues(alpha: selected ? 1 : .55) : Colors.transparent,
                        borderRadius: BorderRadius.circular(pixel ? 0 : 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
