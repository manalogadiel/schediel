import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/icons.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/schediel_theme.dart';
import '../../app/theme/theme_catalog.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/common.dart';
import 'appearance.dart';

/// App appearance: theme, light/dark mode, density and category colors.
class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  /// Hue while the slider is dragged; saved when the drag ends.
  double? _draggingHue;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final colors = context.scheduleColors;
    final brightness = Theme.of(context).brightness;
    final hue = _draggingHue?.round() ?? settings.customHue;
    final darkOnly = settings.schedielTheme.darkOnly;
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.xxl),
        children: [
          SectionGroup(header: 'Theme', children: [
            Padding(
              padding: const EdgeInsets.all(Tokens.md),
              child: LayoutBuilder(builder: (context, box) {
                final columns = box.maxWidth >= 520 ? 4 : 2;
                final width = (box.maxWidth - Tokens.md * (columns - 1)) / columns;
                return Wrap(
                  spacing: Tokens.md,
                  runSpacing: Tokens.md,
                  children: [
                    for (final id in ThemeId.values)
                      SizedBox(
                        width: width,
                        child: _ThemeTile(
                          theme: themeFor(id, customHue: hue),
                          brightness: brightness,
                          selected: settings.theme == id,
                          onTap: () => notifier.update((a) => a.copyWith(theme: id)),
                        ),
                      ),
                  ],
                );
              }),
            ),
            if (settings.theme == ThemeId.custom)
              Padding(
                padding: const EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, Tokens.md),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Color', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: Tokens.xs),
                  _HueTrack(hue: hue),
                  Slider(
                    value: hue.toDouble(),
                    min: 0,
                    max: 359,
                    label: '$hue',
                    semanticFormatterCallback: (v) => 'Hue ${v.round()} degrees',
                    onChanged: (v) => setState(() => _draggingHue = v),
                    onChangeEnd: (v) async {
                      await notifier.update((a) => a.copyWith(customHue: v.round()));
                      if (mounted) setState(() => _draggingHue = null);
                    },
                  ),
                ]),
              ),
          ]),
          SectionGroup(header: 'Mode', children: [
            Padding(
              padding: const EdgeInsets.all(Tokens.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {settings.themeMode},
                  showSelectedIcon: false,
                  onSelectionChanged: darkOnly ? null : (s) => notifier.update((a) => a.copyWith(themeMode: s.first)),
                ),
                if (darkOnly) ...[
                  const SizedBox(height: Tokens.sm),
                  Text('${settings.theme.label} is always dark.', style: TextStyle(color: colors.secondaryInk)),
                ],
              ]),
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
              subtitle: Text('Category names are always shown', style: TextStyle(color: colors.secondaryInk)),
              value: settings.showCategoryColors,
              onChanged: (v) => notifier.update((a) => a.copyWith(showCategoryColors: v)),
            ),
          ]),
        ],
      ),
    );
  }
}

/// A small live preview of one theme: its canvas, two category cards and the
/// accent, drawn in that theme's shape style.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.theme, required this.brightness, required this.selected, required this.onTap});

  final SchedielTheme theme;
  final Brightness brightness;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = theme.palette(brightness);
    final current = context.scheduleColors;
    final outlined = theme.style != StyleFamily.soft;
    final radius = theme.style == StyleFamily.pixel ? 0.0 : 14.0;
    BoxDecoration card(Color fill) => BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius / 2),
          border: outlined ? Border.all(color: p.outline, width: 1.5) : null,
          boxShadow: theme.style == StyleFamily.pop ? [BoxShadow(color: p.outline, offset: const Offset(2, 2))] : null,
        );
    return Semantics(
      button: true,
      selected: selected,
      label: '${theme.id.label} theme',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Tokens.controlMotion,
            height: 92,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.canvas,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected ? current.ink : current.divider,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Stack(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(height: 26, decoration: card(p.categoryFills[CategoryColorKey.blue]!)),
                const SizedBox(height: 6),
                Container(height: 26, decoration: card(p.categoryFills[CategoryColorKey.orange]!)),
              ]),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: p.accent,
                    shape: theme.style == StyleFamily.pixel ? BoxShape.rectangle : BoxShape.circle,
                    border: outlined ? Border.all(color: p.outline, width: 1.5) : null,
                  ),
                  child: selected ? AppIcon(AppIcons.confirm, size: 14, color: p.onAccent) : null,
                ),
              ),
            ]),
          ),
          const SizedBox(height: Tokens.xs),
          Text(
            theme.id.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontFamily: theme.displayFont,
                  fontSize: theme.displayFont == 'Caveat' ? 18 : (theme.displayFont == 'Silkscreen' ? 12 : null),
                ),
          ),
        ]),
      ),
    );
  }
}

/// The hue range as a strip so the slider position reads as a color.
class _HueTrack extends StatelessWidget {
  const _HueTrack({required this.hue});

  final int hue;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ExcludeSemantics(
      child: Container(
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(colors: [
            for (var h = 0; h < 360; h += 30) themeFor(ThemeId.custom, customHue: h).palette(brightness).accent,
          ]),
        ),
      ),
    );
  }
}
