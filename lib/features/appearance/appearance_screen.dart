import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/icons.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/common.dart';
import 'appearance.dart';

/// App appearance (spec 4.7): theme, tested accents, density, category colors.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final brightness = Theme.of(context).brightness;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.xxl),
        children: [
          SectionGroup(header: 'Theme', children: [
            Padding(
              padding: const EdgeInsets.all(Tokens.md),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {settings.themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => notifier.update((a) => a.copyWith(themeMode: s.first)),
              ),
            ),
          ]),
          SectionGroup(header: 'Accent', children: [
            Padding(
              padding: const EdgeInsets.all(Tokens.md),
              child: Wrap(
                spacing: Tokens.md,
                runSpacing: Tokens.md,
                children: [
                  for (final preset in AccentPreset.values)
                    Semantics(
                      button: true,
                      selected: settings.accent == preset,
                      label: '${preset.label} accent',
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Tokens.radiusControl),
                        onTap: () => notifier.update((a) => a.copyWith(accent: preset)),
                        child: Padding(
                          padding: const EdgeInsets.all(Tokens.xs),
                          child: Column(children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (brightness == Brightness.dark ? preset.dark : preset.light).accent,
                              ),
                              child: settings.accent == preset
                                  ? AppIcon(
                                      AppIcons.confirm,
                                      size: 20,
                                      color: (brightness == Brightness.dark ? preset.dark : preset.light).onAccent,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: Tokens.xs),
                            Text(preset.label, style: text.labelSmall),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ]),
          SectionGroup(header: 'Density', children: [
            Padding(
              padding: const EdgeInsets.all(Tokens.md),
              child: SegmentedButton<Density>(
                segments: const [
                  ButtonSegment(value: Density.comfortable, label: Text('Comfortable')),
                  ButtonSegment(value: Density.compact, label: Text('Compact')),
                ],
                selected: {settings.density},
                showSelectedIcon: false,
                onSelectionChanged: (s) => notifier.update((a) => a.copyWith(density: s.first)),
              ),
            ),
          ]),
          SectionGroup(children: [
            SwitchListTile(
              title: const Text('Category colors'),
              subtitle: Text('Category names are always shown', style: TextStyle(color: context.scheduleColors.secondaryInk)),
              value: settings.showCategoryColors,
              onChanged: (v) => notifier.update((a) => a.copyWith(showCategoryColors: v)),
            ),
          ]),
        ],
      ),
    );
  }
}
