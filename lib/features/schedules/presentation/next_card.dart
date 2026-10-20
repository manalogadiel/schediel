import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/schediel_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/art.dart';
import '../../../app/widgets/themed.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/time/local_date.dart';
import 'occurrence_sheet.dart';

/// "in 40 min", "in 1 h 30 min"; whole minutes, rounded down.
String untilLabel(Duration d) {
  final minutes = d.inMinutes;
  if (minutes < 1) return 'in less than a minute';
  if (minutes < 60) return 'in $minutes min';
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? 'in $h h' : 'in $h h $m min';
}

/// Today's hero: what is happening now or comes next (today or the first
/// entry in the coming days), with big start/end times and a countdown.
class NextCard extends ConsumerWidget {
  const NextCard({super.key, required this.next, this.date, this.ongoing = false});

  final Occurrence next;

  /// The day [next] happens on; null means today.
  final LocalDate? date;
  final bool ongoing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.scheduleColors;
    final p = c.palette;
    final text = Theme.of(context).textTheme;
    final f = Formats.of(context);
    final now = ref.watch(nowProvider);
    final today = ref.watch(todayProvider);
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(deviceZoneProvider);
    final timing = next.timing;
    final times = timing is TimedTiming ? OccurrenceTimeText.of(timing, zones, zone, f) : null;
    final day = date ?? today;
    final isToday = day == today;
    final until = timing is TimedTiming && !ongoing && isToday ? untilLabel(timing.startUtc.difference(now.toUtc())) : null;
    final when = isToday ? until : (f.relativeDay(day, today) ?? f.shortDate(day));
    final details = next.details;
    final ink = p.onAccent;
    final soft = c.style == StyleFamily.soft;

    double? elapsed;
    if (ongoing && timing is TimedTiming && timing.endUtc != null) {
      final total = timing.endUtc!.difference(timing.startUtc).inSeconds;
      final done = now.toUtc().difference(timing.startUtc).inSeconds;
      if (total > 0) elapsed = (done / total).clamp(0.0, 1.0);
    }

    final big = TextStyle(
      fontFamily: c.displayFont,
      fontSize: c.displayFont == 'Silkscreen' ? 22 : 30,
      fontWeight: c.displayFont == null ? FontWeight.w800 : FontWeight.w700,
      height: 1.05,
      letterSpacing: c.displayFont == null ? -1.0 : 0,
      color: ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget meta(AppIcons icon, String value) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 15, color: ink.withValues(alpha: .85)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: ink.withValues(alpha: .9), fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );

    final semantics = [
      ongoing ? 'Now' : 'Next',
      ?when,
      next.title,
      ?times?.range,
      if (details.location != null) 'Room ${details.location}',
      if (details.professor != null) 'With ${details.professor}',
    ].join(', ');

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ThemedPill(label: ongoing ? 'Now' : 'Next', fill: ink),
            const SizedBox(width: 8),
            if (when != null)
              Expanded(
                child: Text(
                  when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(color: ink, fontWeight: FontWeight.w600),
                ),
              )
            else
              const Spacer(),
            AppIcon(AppIcons.next, size: 18, color: ink.withValues(alpha: .8)),
          ],
        ),
        const SizedBox(height: 14),
        if (times != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(times.start, style: big),
                if (times.end != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(width: 22, height: 2.5, color: ink.withValues(alpha: .6)),
                  ),
                  Text(times.endsNextDay ? '${times.end} +1' : times.end!, style: big.copyWith(color: ink.withValues(alpha: .78))),
                ],
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          next.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        if (details.location != null || details.professor != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              if (details.location != null) meta(AppIcons.location, details.location!),
              if (details.professor != null) meta(AppIcons.person, details.professor!),
            ],
          ),
        ],
        if (elapsed != null) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(c.style == StyleFamily.pixel ? 0 : 3),
            child: LinearProgressIndicator(
              key: const ValueKey('elapsed-bar'),
              value: elapsed,
              minHeight: 5,
              color: ink,
              backgroundColor: ink.withValues(alpha: 0.2),
            ),
          ),
        ],
      ],
    );

    final card = soft
        ? _GlowCard(accent: p.accent, onTap: () => showOccurrenceSheet(context, next), child: body)
        : ThemedCard(
            fill: p.accent,
            emphasized: true,
            seed: 'next-${next.id}',
            padding: const EdgeInsets.fromLTRB(Tokens.md + 2, Tokens.md, Tokens.md + 2, Tokens.md + 2),
            onTap: () => showOccurrenceSheet(context, next),
            child: body,
          );
    return Semantics(button: true, label: semantics, excludeSemantics: true, child: card);
  }
}

/// Soft style hero surface: a two-tone accent gradient with a colored shadow
/// and a faint highlight bloom.
class _GlowCard extends StatelessWidget {
  const _GlowCard({required this.accent, required this.onTap, required this.child});
  final Color accent;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final partner = accentPartner(accent);
    final radius = BorderRadius.circular(26);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent, partner]),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: .35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.white.withValues(alpha: .22), Colors.white.withValues(alpha: 0)]),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                child: Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 20), child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
