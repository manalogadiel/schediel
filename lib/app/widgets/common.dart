import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/categories/domain/category.dart';
import '../icons.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Motion durations that collapse to zero when the OS requests reduced motion.
abstract final class AppMotion {
  static Duration control(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : Tokens.controlMotion;

  static Duration screen(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : Tokens.screenMotion;
}

/// An optional header above a rounded surface group whose rows are separated
/// by hairlines. Used only for meaningful grouping.
class SectionGroup extends StatelessWidget {
  const SectionGroup({super.key, this.header, this.trailing, required this.children, this.headerSemantics});

  final String? header;
  final Widget? trailing;
  final String? headerSemantics;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.scheduleColors;
    final text = Theme.of(context).textTheme;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Padding(padding: const EdgeInsets.only(left: Tokens.md), child: Divider(color: colors.divider)));
      rows.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.xs, 0, Tokens.xs, Tokens.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      label: headerSemantics,
                      child: Text(header!, style: text.labelMedium?.copyWith(color: colors.secondaryInk)),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          if (rows.isNotEmpty)
            DecoratedBox(
              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(Tokens.radiusCard)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Tokens.radiusCard),
                child: Material(type: MaterialType.transparency, child: Column(children: rows)),
              ),
            ),
        ],
      ),
    );
  }
}

/// A genuine empty or problem state: one line of copy and an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.message, this.action});

  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.lg, vertical: Tokens.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: Tokens.sm),
            Text(message!, style: text.bodySmall, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: Tokens.md), action!],
        ],
      ),
    );
  }
}

class DetailLine extends StatelessWidget {
  const DetailLine({super.key, required this.icon, required this.text, this.style, this.semanticPrefix});

  final AppIcons icon;
  final String text;
  final TextStyle? style;

  /// Spoken before the value, e.g. "Room".
  final String? semanticPrefix;

  @override
  Widget build(BuildContext context) {
    final colors = context.scheduleColors;
    final resolved = style ?? Theme.of(context).textTheme.bodySmall;
    return Semantics(
      label: semanticPrefix == null ? text : '$semanticPrefix: $text',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 6),
              child: AppIcon(icon, size: 15, color: resolved?.color ?? colors.secondaryInk),
            ),
            Expanded(child: Text(text, style: resolved)),
          ],
        ),
      ),
    );
  }
}

/// "Now" / "Next" / other short status, never color-only.
class StatusLabel extends StatelessWidget {
  const StatusLabel(this.label, {super.key, this.strong = true});

  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: strong ? scheme.primary : Colors.transparent,
        border: strong ? null : Border.all(color: context.scheduleColors.inputBoundary),
        borderRadius: BorderRadius.circular(Tokens.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: strong ? scheme.onPrimary : context.scheduleColors.ink,
        ),
      ),
    );
  }
}

class CategoryDot extends StatelessWidget {
  const CategoryDot({super.key, required this.colorKey, this.size = 8});

  final String? colorKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = CategoryColor.fromKey(colorKey);
    if (color == null || !context.scheduleColors.showCategoryColors) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.resolve(Theme.of(context).brightness), shape: BoxShape.circle),
      ),
    );
  }
}

/// Shows the current filter and opens the category filter sheet.
class FilterPill extends ConsumerWidget {
  const FilterPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(effectiveFilterProvider);
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final label = filterLabel(filter, categories);
    final colors = context.scheduleColors;
    return Semantics(
      button: true,
      label: 'Category filter: $label',
      excludeSemantics: true,
      child: Material(
        color: filter.isAll ? colors.surface : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        shape: StadiumBorder(side: BorderSide(color: colors.inputBoundary.withValues(alpha: 0.6))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showCategoryFilterSheet(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: Tokens.minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(AppIcons.filter, size: 16, color: colors.ink),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, color: colors.ink)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String filterLabel(CategoryFilter filter, List<Category> categories) {
  if (filter.isAll) return 'All';
  final names = [
    for (final c in categories)
      if (filter.categoryIds.contains(c.id)) c.name,
    if (filter.includeUncategorized) 'Uncategorized',
  ];
  if (names.isEmpty) return 'All';
  return names.length == 1 ? names.single : '${names.first} +${names.length - 1}';
}

Future<void> showCategoryFilterSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _CategoryFilterSheet(),
  );
}

class _CategoryFilterSheet extends ConsumerWidget {
  const _CategoryFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(effectiveFilterProvider);
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final notifier = ref.read(appFilterProvider.notifier);

    void toggle(String? id) {
      final selected = filter.isAll ? <String>{} : {...filter.categoryIds};
      var uncategorized = !filter.isAll && filter.includeUncategorized;
      if (id == null) {
        uncategorized = !uncategorized;
      } else if (!selected.remove(id)) {
        selected.add(id);
      }
      notifier.set(selected.isEmpty && !uncategorized
          ? const CategoryFilter.all()
          : CategoryFilter.only(selected, includeUncategorized: uncategorized));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, Tokens.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Tokens.sm),
              child: Text('Show categories', style: Theme.of(context).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  CheckboxListTile(
                    value: filter.isAll,
                    title: const Text('All'),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (_) => notifier.set(const CategoryFilter.all()),
                  ),
                  for (final c in categories)
                    CheckboxListTile(
                      value: !filter.isAll && filter.categoryIds.contains(c.id),
                      title: Row(children: [CategoryDot(colorKey: c.colorKey), Flexible(child: Text(c.name))]),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (_) => toggle(c.id),
                    ),
                  CheckboxListTile(
                    value: !filter.isAll && filter.includeUncategorized,
                    title: const Text('Uncategorized'),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (_) => toggle(null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Tokens.sm),
            Text(
              'Filters change what you see. Reminders and alarms stay as they are.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// A two-or-more-choice decision dialog. Returns the chosen value or null.
Future<T?> showChoiceDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  required List<(T, String, bool)> choices,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowButtonSpacing: Tokens.xs,
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        for (final (value, label, destructive) in choices)
          TextButton(
            style: destructive ? TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error) : null,
            onPressed: () => Navigator.of(context).pop(value),
            child: Text(label),
          ),
      ],
    ),
  );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
