import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/schediel_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../core/schedule/limits.dart';
import '../data/category_repository.dart';
import '../domain/category.dart';

/// Category management (spec 9.1): add, rename, color, reorder, delete with
/// an explicit destination for its schedules.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final repo = ref.read(categoryRepositoryProvider);
    final counts = <String, int>{};
    for (final series in ref.watch(allSeriesProvider).value ?? const []) {
      final id = series.categoryId;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [IconButton(tooltip: 'Add category', icon: const AppIcon(AppIcons.add), onPressed: () => _editName(context, ref, null))],
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (_, _) => const EmptyState(title: 'Unable to load categories'),
        data: (list) => list.isEmpty
            ? EmptyState(
                title: 'No categories',
                message: 'Schedules without a category are shown as Uncategorized.',
                action: OutlinedButton(onPressed: () => _editName(context, ref, null), child: const Text('Add category')),
              )
            : ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.xxl),
                itemCount: list.length,
                onReorderItem: (from, to) {
                  final ids = [for (final c in list) c.id];
                  final moved = ids.removeAt(from);
                  ids.insert(to, moved);
                  repo.reorder(ids);
                },
                itemBuilder: (context, i) {
                  final c = list[i];
                  return Padding(
                    key: ValueKey('category-row-${c.id}'),
                    padding: const EdgeInsets.only(bottom: Tokens.md),
                    child: _FolderCard(
                      key: ValueKey(c.id),
                      category: c,
                      count: counts[c.id] ?? 0,
                      onTap: () => _actions(context, ref, c, list),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _actions(BuildContext context, WidgetRef ref, Category c, List<Category> all) async {
    final repo = ref.read(categoryRepositoryProvider);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.lg, 0, Tokens.lg, Tokens.sm),
              child: Text(c.name, style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: const AppIcon(AppIcons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.of(sheet).pop();
                _editName(context, ref, c);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Tokens.lg, vertical: Tokens.sm),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ColorDot(
                    label: 'No color',
                    color: null,
                    selected: c.colorKey == null,
                    onTap: () {
                      repo.setColor(c.id, null);
                      Navigator.of(sheet).pop();
                    },
                  ),
                  for (final color in CategoryColor.values)
                    _ColorDot(
                      label: color.label,
                      color: context.scheduleColors.palette.fillFor(color.name),
                      dotKey: ValueKey('color-dot-${color.name}'),
                      selected: c.colorKey == color.name,
                      onTap: () {
                        repo.setColor(c.id, color.name);
                        Navigator.of(sheet).pop();
                      },
                    ),
                ],
              ),
            ),
            ListTile(
              leading: AppIcon(AppIcons.remove, color: Theme.of(context).colorScheme.error),
              title: Text('Delete category', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                Navigator.of(sheet).pop();
                await _delete(context, ref, c, all);
              },
            ),
            const SizedBox(height: Tokens.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Category c, List<Category> all) async {
    final others = all.where((o) => o.id != c.id).toList();
    final destination = await showChoiceDialog<String>(
      context,
      title: 'Delete “${c.name}”?',
      message: 'Schedules are kept. Choose where schedules in this category go.',
      choices: [for (final o in others) (o.id, 'Move to ${o.name}', false), ('', 'Make uncategorized', false)],
    );
    if (destination == null) return;
    await ref.read(categoryRepositoryProvider).delete(c.id, reassignTo: destination.isEmpty ? null : destination);
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, Category? existing) async {
    final repo = ref.read(categoryRepositoryProvider);
    final controller = TextEditingController(text: existing?.name ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(existing == null ? 'New category' : 'Rename category'),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Name', errorText: error),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  try {
                    if (existing == null) {
                      await repo.create(controller.text);
                    } else {
                      await repo.rename(existing.id, controller.text);
                    }
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  } on CategoryNameException catch (e) {
                    setState(
                      () => error = switch (e.problem) {
                        CategoryNameProblem.empty => 'Enter a name',
                        CategoryNameProblem.tooLong => 'Use at most ${ScheduleLimits.categoryNameMax} characters',
                        CategoryNameProblem.duplicate => 'A category with this name exists',
                      },
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A category as a folder: a tab in the category's strong color on the top
/// left and a body in its soft fill, with the name and how many schedules it
/// holds.
class _FolderCard extends StatelessWidget {
  const _FolderCard({super.key, required this.category, required this.count, required this.onTap});
  final Category category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.scheduleColors;
    final p = colors.palette;
    final text = Theme.of(context).textTheme;
    final pixel = colors.style == StyleFamily.pixel;
    final strong = CategoryColor.fromKey(category.colorKey)?.resolve(p.brightness);
    final body = colors.categoryFill(category.colorKey);
    final tab = strong ?? colors.secondaryInk.withValues(alpha: .35);
    final shape = _FolderShape(
      radius: pixel ? 0 : 20,
      tabRadius: pixel ? 0 : 10,
      outline: colors.outlined ? BorderSide(color: p.outline, width: 2) : BorderSide.none,
    );
    final label = count == 1 ? '1 schedule' : '$count schedules';
    return Semantics(
      button: true,
      label: '${category.name}, $label',
      excludeSemantics: true,
      child: CustomPaint(
        painter: _FolderPainter(
          shape: shape,
          tab: tab,
          body: body,
          shadow: colors.style == StyleFamily.soft && p.brightness == Brightness.light,
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, _FolderShape.tab + 16, 14, 16),
              child: Row(
                children: [
                  Container(
                    key: ValueKey('category-icon-${category.id}'),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: p.brightness == Brightness.dark ? .10 : .55),
                      borderRadius: BorderRadius.circular(pixel ? 0 : 12),
                    ),
                    child: Center(child: AppIcon(AppIcons.folder, color: strong ?? p.cardInk)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(color: p.cardInk, fontWeight: FontWeight.w700),
                        ),
                        Text(label, style: text.bodySmall?.copyWith(color: p.cardInk.withValues(alpha: .7))),
                      ],
                    ),
                  ),
                  AppIcon(AppIcons.next, size: 18, color: p.cardInk.withValues(alpha: .6)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fills the folder: the tab strip in the strong color, the body in the soft
/// fill, with an optional soft shadow.
class _FolderPainter extends CustomPainter {
  const _FolderPainter({required this.shape, required this.tab, required this.body, required this.shadow});
  final _FolderShape shape;
  final Color tab, body;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);
    if (shadow) {
      canvas.drawPath(
        path.shift(const Offset(0, 5)),
        Paint()
          ..color = Colors.black.withValues(alpha: .07)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }
    canvas
      ..save()
      ..clipPath(path)
      ..drawRect(rect, Paint()..color = tab)
      ..drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(0, _FolderShape.tab + 6, size.width, size.height),
          topLeft: Radius.circular(shape.radius),
          topRight: Radius.circular(shape.radius),
        ),
        Paint()..color = body,
      )
      ..restore();
    shape.paint(canvas, rect);
  }

  @override
  bool shouldRepaint(_FolderPainter old) => old.tab != tab || old.body != body || old.shadow != shadow || old.shape != shape;
}

/// Folder silhouette: a rounded body with a tab rising from its top left.
class _FolderShape extends OutlinedBorder {
  const _FolderShape({this.radius = 20, this.tabRadius = 10, this.outline = BorderSide.none}) : super(side: outline);
  final double radius, tabRadius;
  final BorderSide outline;

  static const tab = 14.0;

  Path _path(Rect r) {
    final tabW = math.min(r.width * .42, 150.0);
    final rr = math.min(radius, (r.height - tab) / 2);
    return Path()
      ..moveTo(r.left, r.top + tabRadius)
      ..quadraticBezierTo(r.left, r.top, r.left + tabRadius, r.top)
      ..lineTo(r.left + tabW - tabRadius, r.top)
      ..cubicTo(r.left + tabW + 2, r.top, r.left + tabW + 6, r.top + tab, r.left + tabW + 20, r.top + tab)
      ..lineTo(r.right - rr, r.top + tab)
      ..quadraticBezierTo(r.right, r.top + tab, r.right, r.top + tab + rr)
      ..lineTo(r.right, r.bottom - rr)
      ..quadraticBezierTo(r.right, r.bottom, r.right - rr, r.bottom)
      ..lineTo(r.left + rr, r.bottom)
      ..quadraticBezierTo(r.left, r.bottom, r.left, r.bottom - rr)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(outline.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (outline.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect.deflate(outline.width / 2)), outline.toPaint());
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(outline.width);

  @override
  ShapeBorder scale(double t) => _FolderShape(radius: radius * t, tabRadius: tabRadius * t, outline: outline.scale(t));

  @override
  _FolderShape copyWith({BorderSide? side}) => _FolderShape(radius: radius, tabRadius: tabRadius, outline: side ?? outline);

  @override
  bool operator ==(Object other) =>
      other is _FolderShape && other.radius == radius && other.tabRadius == tabRadius && other.outline == outline;

  @override
  int get hashCode => Object.hash(radius, tabRadius, outline);
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.label, required this.color, required this.selected, required this.onTap, this.dotKey});
  final String label;
  final Color? color;
  final Key? dotKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final shape = c.style == StyleFamily.pixel ? BoxShape.rectangle : BoxShape.circle;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: shape,
                border: Border.all(color: selected ? c.ink : Colors.transparent, width: 2),
              ),
              child: Container(
                key: dotKey,
                decoration: BoxDecoration(
                  shape: shape,
                  color: color ?? c.surface,
                  border: Border.all(color: c.ink.withValues(alpha: color == null ? .35 : .12)),
                ),
                child: color == null ? Center(child: Container(width: 22, height: 2, color: c.ink.withValues(alpha: .4))) : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: c.secondaryInk),
            ),
          ],
        ),
      ),
    );
  }
}
