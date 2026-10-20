import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../../app/icons.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/schediel_theme.dart';
import '../../app/theme/theme_catalog.dart';
import '../../app/theme/theme_customization.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/theme_texture.dart';
import 'appearance.dart';

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});
  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  ThemeId? _draftTheme;
  ThemeCustomization? _draft;

  Future<void> _save(ThemeId id, ThemeCustomization value) =>
      ref.read(appearanceProvider.notifier).update((s) => s.copyWith(customizations: {...s.customizations, id: value}));

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final c = context.scheduleColors;
    final brightness = Theme.of(context).brightness;
    final choice = _draftTheme == s.theme ? _draft! : s.customizations[s.theme] ?? const ThemeCustomization();
    final base = themeFor(s.theme, customHue: s.customHue);
    final theme = themeFor(s.theme, customHue: s.customHue, customization: choice);
    final accent = Hct.fromInt(base.palette(brightness).accent.toARGB32());
    final canvas = Hct.fromInt(base.palette(brightness).canvas.toARGB32());
    void change(ThemeCustomization value) => setState(() {
      _draftTheme = s.theme;
      _draft = value;
    });
    Widget slider(String key, String label, double value, double max, ThemeCustomization Function(double) update) => _ColorSlider(
      key: ValueKey(key),
      label: label,
      value: value,
      max: max,
      onChanged: (v) => change(update(v)),
      onChangeEnd: (v) => _save(s.theme, update(v)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.xxl),
        children: [
          SectionGroup(
            header: 'Theme',
            children: [
              Padding(
                padding: const EdgeInsets.all(Tokens.md),
                child: _LivePreview(
                  key: const ValueKey('theme-preview'),
                  theme: theme,
                  brightness: brightness,
                  texture: choice.texture,
                  density: s.density,
                  categoryColors: s.showCategoryColors,
                ),
              ),
              SingleChildScrollView(
                key: const ValueKey('theme-selector'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(Tokens.sm, 0, Tokens.sm, Tokens.sm),
                child: Row(
                  children: [
                    for (final id in ThemeId.values)
                      Padding(
                        padding: const EdgeInsets.only(right: Tokens.sm),
                        child: _FamilyChoice(
                          theme: themeFor(id, customHue: s.customHue, customization: s.customizations[id]),
                          selected: id == s.theme,
                          onTap: () {
                            setState(() {
                              _draftTheme = null;
                              _draft = null;
                            });
                            notifier.update((a) => a.copyWith(theme: id));
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SectionGroup(
            header: 'Mode',
            children: [
              Padding(
                padding: const EdgeInsets.all(Tokens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                        ButtonSegment(value: ThemeMode.system, label: Text('System')),
                      ],
                      selected: {s.themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: theme.darkOnly ? null : (v) => notifier.update((a) => a.copyWith(themeMode: v.first)),
                    ),
                    if (theme.darkOnly) ...[
                      const SizedBox(height: Tokens.sm),
                      Text('${s.theme.label} is always dark.', style: TextStyle(color: c.secondaryInk)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SectionGroup(
            header: 'Colors',
            children: [
              Padding(
                padding: const EdgeInsets.all(Tokens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    slider(
                      'main-hue',
                      'Main hue',
                      ThemeCustomization.number(choice.mainHue, 359) ?? accent.hue,
                      359,
                      (v) => choice.copyWith(mainHue: v),
                    ),
                    slider(
                      'main-tone',
                      'Main lightness',
                      ThemeCustomization.number(choice.mainTone, 100) ?? accent.tone,
                      100,
                      (v) => choice.copyWith(mainTone: v),
                    ),
                    slider(
                      'background-hue',
                      'Background hue',
                      ThemeCustomization.number(choice.backgroundHue, 359) ?? canvas.hue,
                      359,
                      (v) => choice.copyWith(backgroundHue: v),
                    ),
                    slider(
                      'background-tone',
                      'Background lightness',
                      ThemeCustomization.number(choice.backgroundTone, 100) ?? canvas.tone,
                      100,
                      (v) => choice.copyWith(backgroundTone: v),
                    ),
                    Text('Text and control colors adjust for readability.', style: TextStyle(color: c.secondaryInk)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Tokens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Texture'),
                    DropdownButton<ThemeTexture>(
                      key: const ValueKey('texture-selector'),
                      isExpanded: true,
                      value: choice.texture,
                      underline: const SizedBox.shrink(),
                      items: [for (final t in ThemeTexture.values) DropdownMenuItem(value: t, child: Text(t.label))],
                      onChanged: (v) {
                        if (v != null) {
                          final next = choice.copyWith(texture: v);
                          change(next);
                          _save(s.theme, next);
                        }
                      },
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _draftTheme = null;
                    _draft = null;
                  });
                  notifier.update((a) => a.copyWith(customizations: {...a.customizations}..remove(a.theme)));
                },
                child: const Text('Reset theme'),
              ),
            ],
          ),
          SectionGroup(
            header: 'Density',
            children: [
              Padding(
                padding: const EdgeInsets.all(Tokens.md),
                child: SegmentedButton<Density>(
                  segments: const [
                    ButtonSegment(value: Density.comfortable, label: Text('Comfortable')),
                    ButtonSegment(value: Density.compact, label: Text('Compact')),
                  ],
                  selected: {s.density},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => notifier.update((a) => a.copyWith(density: v.first)),
                ),
              ),
            ],
          ),
          SectionGroup(
            children: [
              SwitchListTile(
                title: const Text('Category colors'),
                subtitle: Text('Category names are always shown', style: TextStyle(color: c.secondaryInk)),
                value: s.showCategoryColors,
                onChanged: (v) => notifier.update((a) => a.copyWith(showCategoryColors: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });
  final String label;
  final double value, max;
  final ValueChanged<double> onChanged, onChangeEnd;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          Text('${value.round()}'),
        ],
      ),
      Semantics(
        label: label,
        child: Slider(
          value: value.clamp(0, max),
          max: max,
          label: '${value.round()}',
          semanticFormatterCallback: (v) => '${v.round()} ${max == 359 ? 'degrees' : 'percent'}',
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ),
    ],
  );
}

class _FamilyChoice extends StatelessWidget {
  const _FamilyChoice({required this.theme, required this.selected, required this.onTap});
  final SchedielTheme theme;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final p = theme.palette(Theme.of(context).brightness);
    final radius = c.style == StyleFamily.pixel ? 0.0 : Tokens.radiusControl;
    return Semantics(
      key: ValueKey('theme-${theme.id.name}'),
      label: '${theme.id.label} theme',
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.palette.accent : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: selected ? c.ink : c.divider, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.md, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: p.accent,
                    borderRadius: BorderRadius.circular(theme.style == StyleFamily.pixel ? 0 : 6),
                  ),
                ),
                const SizedBox(width: Tokens.sm),
                Text(
                  theme.id.label,
                  style: TextStyle(
                    color: selected ? c.palette.onAccent : c.ink,
                    fontFamily: theme.displayFont,
                    fontSize: theme.displayFont == 'Caveat'
                        ? 20
                        : theme.displayFont == 'Silkscreen'
                        ? 12
                        : 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({
    super.key,
    required this.theme,
    required this.brightness,
    required this.texture,
    required this.density,
    required this.categoryColors,
  });
  final SchedielTheme theme;
  final Brightness brightness;
  final ThemeTexture texture;
  final Density density;
  final bool categoryColors;
  @override
  Widget build(BuildContext context) {
    final data = buildTheme(
      theme: theme,
      brightness: brightness,
      density: density,
      showCategoryColors: categoryColors,
      texture: texture,
    );
    final p = theme.palette(brightness);
    final outlined = theme.style != StyleFamily.soft;
    final radius = theme.style == StyleFamily.pixel ? 0.0 : Tokens.radiusControl;
    return Theme(
      data: data,
      child: SizedBox(
        height:
            104 +
            MediaQuery.textScalerOf(context).scale(data.textTheme.titleLarge!.fontSize!) *
                (data.textTheme.titleLarge!.height ?? 1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: ThemeTextureSurface(
            texture: texture,
            child: Padding(
              padding: const EdgeInsets.all(Tokens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          theme.id.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: data.textTheme.titleLarge,
                        ),
                      ),
                      AppIcon(AppIcons.calendar, color: data.extension<ScheduleColors>()!.accentText),
                    ],
                  ),
                  const SizedBox(height: Tokens.sm),
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        for (final key in [CategoryColorKey.blue, CategoryColorKey.orange])
                          Expanded(
                            child: Container(
                              height: 44,
                              margin: const EdgeInsets.only(right: Tokens.sm),
                              decoration: BoxDecoration(
                                color: categoryColors ? p.categoryFills[key] : p.neutralFill,
                                borderRadius: BorderRadius.circular(radius),
                                border: outlined ? Border.all(color: p.cardInk, width: 1.5) : null,
                                boxShadow: theme.style == StyleFamily.pop
                                    ? [BoxShadow(color: p.cardInk, offset: const Offset(2, 2))]
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
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
