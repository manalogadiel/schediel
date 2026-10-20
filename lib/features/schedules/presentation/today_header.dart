import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/themed.dart';
import '../../../core/time/local_date.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';

/// "Good morning" 05:00–11:59, "Good afternoon" 12:00–17:59, otherwise
/// "Good evening", from device-local wall time.
String greetingFor(DateTime local) {
  final h = local.hour;
  if (h >= 5 && h < 12) return 'Good morning';
  if (h >= 12 && h < 18) return 'Good afternoon';
  return 'Good evening';
}

/// Avatar, greeting and share action. The avatar only appears when the user
/// set a name or photo; nothing is invented.
class TodayHeader extends ConsumerWidget {
  const TodayHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value ?? const Profile();
    final now = ref.watch(nowProvider);
    final local = ref.watch(zoneResolverProvider).toLocal(now, ref.watch(deviceZoneProvider));
    final greeting = greetingFor(DateTime(local.date.year, local.date.month, local.date.day, local.time.hour, local.time.minute));
    final c = context.scheduleColors;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        if (!profile.isEmpty) ...[
          ThemedAvatar(profile: profile, size: 42),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: text.bodySmall?.copyWith(color: c.secondaryInk, fontSize: 13)),
                if (profile.name != null)
                  Text(profile.name!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium?.copyWith(fontSize: 16)),
              ],
            ),
          ),
        ),
        ThemedIconButton(icon: AppIcons.share, tooltip: 'Share schedules', onPressed: () => context.push('/share/create')),
      ],
    );
  }
}

/// The oversized date: a weekday overline above "October 20", month heavy
/// and day light. Tap to pick a date; off today, a Today pill returns.
class DateHeading extends ConsumerWidget {
  const DateHeading({super.key, required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(effectiveDateProvider);
    final today = ref.watch(todayProvider);
    final f = Formats.of(context);
    final c = context.scheduleColors;
    final text = Theme.of(context).textTheme;
    final relative = f.relativeDay(date, today);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Selected date ${f.dayTitle(date)}${relative == null ? '' : ', $relative'}. Choose a date',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(Tokens.radiusControl),
              onTap: onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Tokens.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [f.weekdayLong(date.weekday), relative ?? '${date.year}'].join('  ·  '),
                      style: text.labelMedium?.copyWith(color: c.secondaryInk, letterSpacing: .2, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: f.monthName(date)),
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: '${date.day}',
                              style: TextStyle(
                                color: c.accentText,
                                fontWeight: c.displayFont == null ? FontWeight.w300 : null,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        style: text.displayLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (date != today)
          Semantics(
            button: true,
            label: 'Go to today',
            excludeSemantics: true,
            child: InkWell(
              key: const ValueKey('today-pill'),
              customBorder: const StadiumBorder(),
              onTap: () => ref.read(selectedDateProvider.notifier).today(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: ThemedPill(label: 'Today', emphasized: true),
              ),
            ),
          ),
      ],
    );
  }
}

/// Picks a date with the platform date picker.
Future<LocalDate?> pickDate(BuildContext context, LocalDate current) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime(current.year, current.month, current.day),
    firstDate: DateTime(LocalDate.minYear),
    lastDate: DateTime(LocalDate.maxYear, 12, 31),
  );
  return picked == null ? null : LocalDate.fromDateTime(picked);
}
