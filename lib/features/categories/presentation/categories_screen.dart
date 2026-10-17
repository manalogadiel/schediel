import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Add category',
            icon: const AppIcon(AppIcons.add),
            onPressed: () => _editName(context, ref, null),
          ),
        ],
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
                  return Material(
                    key: ValueKey(c.id),
                    color: context.scheduleColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusControl)),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: ListTile(
                        leading: CategoryDot(colorKey: c.colorKey, size: 12),
                        title: Text(c.name),
                        onTap: () => _actions(context, ref, c, list),
                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: Tokens.md, vertical: Tokens.sm),
              child: Wrap(
                spacing: Tokens.sm,
                runSpacing: Tokens.sm,
                children: [
                  ChoiceChip(
                    label: const Text('No color'),
                    selected: c.colorKey == null,
                    onSelected: (_) {
                      repo.setColor(c.id, null);
                      Navigator.of(sheet).pop();
                    },
                  ),
                  for (final color in CategoryColor.values)
                    ChoiceChip(
                      avatar: CircleAvatar(backgroundColor: color.resolve(Theme.of(context).brightness), radius: 6),
                      label: Text(color.label),
                      selected: c.colorKey == color.name,
                      onSelected: (_) {
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
      choices: [
        for (final o in others) (o.id, 'Move to ${o.name}', false),
        ('', 'Make uncategorized', false),
      ],
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
                    setState(() => error = switch (e.problem) {
                          CategoryNameProblem.empty => 'Enter a name',
                          CategoryNameProblem.tooLong => 'Use at most ${ScheduleLimits.categoryNameMax} characters',
                          CategoryNameProblem.duplicate => 'A category with this name exists',
                        });
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
