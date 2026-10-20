import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

enum _ColorTarget { main, background }

/// One-tap starting points (HCT hue, tone); the sliders fine-tune from there.
const _mainPresets = [(300.0, 45.0), (270.0, 45.0), (195.0, 45.0), (145.0, 45.0), (85.0, 70.0), (50.0, 60.0), (15.0, 50.0), (350.0, 55.0)];
const _backgroundPresets = [(80.0, 96.0), (260.0, 99.0), (20.0, 95.0), (240.0, 95.0), (140.0, 95.0), (300.0, 95.0), (260.0, 18.0), (280.0, 8.0)];

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});
  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  ThemeId? _draftTheme;
  ThemeCustomization? _draft;
  _ColorTarget _target = _ColorTarget.main;

  Future<void> _save(ThemeId id, ThemeCustomization value) =>
      ref.read(appearanceProvider.notifier).update((s) => s.copyWith(customizations: {...s.customizations, id: value}));

  void _clearDraft() => setState(() {
    _draftTheme = null;
    _draft = null;
  });

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final c = context.scheduleColors;
    final brightness = Theme.of(context).brightness;
    final choice = _draftTheme == s.theme ? _draft! : s.customizations[s.theme] ?? const ThemeCustomization();
    final base = themeFor(s.theme, customHue: s.customHue).palette(brightness);
    final theme = themeFor(s.theme, customHue: s.customHue, customization: choice);
    final live = theme.palette(brightness);
    void change(ThemeCustomization value) => setState(() {
      _draftTheme = s.theme;
      _draft = value;
    });

    // The sliders paint exactly the colors themeFor produces (see
    // _customizedPalette: accent keeps chroma >= 30, canvas >= 12).
    final main = _target == _ColorTarget.main;
    final baseHct = Hct.fromInt((main ? base.accent : base.canvas).toARGB32());
    final chroma = math.max(baseHct.chroma, main ? 30.0 : 12.0);
    final hue = ThemeCustomization.number(main ? choice.mainHue : choice.backgroundHue, 359) ?? baseHct.hue;
    final tone = ThemeCustomization.number(main ? choice.mainTone : choice.backgroundTone, 100) ?? baseHct.tone;
    Color hct(double h, double t) => Color(Hct.from(h, chroma, t).toInt());
    ThemeCustomization withColor(double h, double t) =>
        main ? choice.copyWith(mainHue: h, mainTone: t) : choice.copyWith(backgroundHue: h, backgroundTone: t);
    final presets = main ? _mainPresets : _backgroundPresets;

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.xxl),
        children: [
          SectionGroup(
            header: 'Theme',
            children: [
              _ThemeCarousel(
                selected: s.theme,
                themes: {for (final id in ThemeId.values) id: themeFor(id, customHue: s.customHue, customization: s.customizations[id])},
                live: theme,
                texture: choice.texture,
                density: s.density,
                categoryColors: s.showCategoryColors,
                onSelect: (id) {
                  _clearDraft();
                  HapticFeedback.selectionClick();
                  notifier.update((a) => a.copyWith(theme: id));
                },
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
                    ModeToggle(
                      key: const ValueKey('mode-toggle'),
                      value: theme.darkOnly ? ThemeMode.dark : s.themeMode,
                      onChanged: theme.darkOnly ? null : (v) => notifier.update((a) => a.copyWith(themeMode: v)),
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
            trailing: choice.hasColors
                ? TextButton(
                    key: const ValueKey('reset-colors'),
                    onPressed: () {
                      _clearDraft();
                      final next = ThemeCustomization(texture: choice.texture);
                      notifier.update((a) => a.copyWith(customizations: {...a.customizations, a.theme: next}));
                    },
                    child: const Text('Reset'),
                  )
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.all(Tokens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TargetToggle(
                      value: _target,
                      main: live.accent,
                      background: live.canvas,
                      onChanged: (t) => setState(() => _target = t),
                    ),
                    const SizedBox(height: Tokens.md),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        key: ValueKey('presets-${_target.name}'),
                        scrollDirection: Axis.horizontal,
                        itemCount: presets.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final (h, t) = presets[i];
                          return _Swatch(
                            color: hct(h, t),
                            selected: (hue - h).abs() < 1 && (tone - t).abs() < 1,
                            label: 'Preset ${i + 1}',
                            onTap: () {
                              final next = withColor(h, t);
                              change(next);
                              _save(s.theme, next);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: Tokens.md),
                    _ColorSlider(
                      key: ValueKey('${_target.name}-hue'),
                      label: 'Hue',
                      value: hue,
                      max: 359,
                      track: [for (var h = 0.0; h <= 360; h += 30) hct(h % 360, tone)],
                      thumb: hct(hue, tone),
                      onChanged: (v) => change(withColor(v, tone)),
                      onChangeEnd: (v) => _save(s.theme, withColor(v, tone)),
                    ),
                    _ColorSlider(
                      key: ValueKey('${_target.name}-tone'),
                      label: 'Lightness',
                      value: tone,
                      max: 100,
                      track: [for (var t = 5.0; t <= 98; t += 9.3) hct(hue, t)],
                      thumb: hct(hue, tone),
                      onChanged: (v) => change(withColor(hue, v)),
                      onChangeEnd: (v) => _save(s.theme, withColor(hue, v)),
                    ),
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
            ],
          ),
          SectionGroup(
            header: 'Density',
            children: [
              Padding(
                padding: const EdgeInsets.all(Tokens.md),
                child: Row(
                  children: [
                    for (final (i, d) in Density.values.indexed) ...[
                      if (i > 0) const SizedBox(width: Tokens.sm + 4),
                      Expanded(
                        child: _DensityCard(
                          density: d,
                          selected: s.density == d,
                          onTap: () => notifier.update((a) => a.copyWith(density: d)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SectionGroup(
            children: [
              SwitchListTile(
                title: const Text('Category colors'),
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

// ---------------------------------------------------------------------------
// Theme carousel

/// Mini phone previews; the selected one shows the live draft and texture.
class _ThemeCarousel extends StatefulWidget {
  const _ThemeCarousel({
    required this.selected,
    required this.themes,
    required this.live,
    required this.texture,
    required this.density,
    required this.categoryColors,
    required this.onSelect,
  });
  final ThemeId selected;
  final Map<ThemeId, SchedielTheme> themes;
  final SchedielTheme live;
  final ThemeTexture texture;
  final Density density;
  final bool categoryColors;
  final ValueChanged<ThemeId> onSelect;

  @override
  State<_ThemeCarousel> createState() => _ThemeCarouselState();
}

class _ThemeCarouselState extends State<_ThemeCarousel> {
  final _keys = {for (final id in ThemeId.values) id: GlobalKey()};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(animate: false));
  }

  @override
  void didUpdateWidget(_ThemeCarousel old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _reveal(animate: true);
  }

  void _reveal({required bool animate}) {
    final target = _keys[widget.selected]?.currentContext;
    if (target == null || !mounted) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.5,
      duration: animate && !MediaQuery.disableAnimationsOf(context) ? const Duration(milliseconds: 320) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SingleChildScrollView(
      key: const ValueKey('theme-selector'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(Tokens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final id in ThemeId.values)
            Padding(
              key: _keys[id],
              padding: const EdgeInsets.only(right: Tokens.sm + 4),
              child: _ThemeCard(
                theme: id == widget.selected ? widget.live : widget.themes[id]!,
                brightness: brightness,
                selected: id == widget.selected,
                texture: id == widget.selected ? widget.texture : null,
                density: widget.density,
                categoryColors: widget.categoryColors,
                onTap: () => widget.onSelect(id),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.brightness,
    required this.selected,
    required this.texture,
    required this.density,
    required this.categoryColors,
    required this.onTap,
  });
  final SchedielTheme theme;
  final Brightness brightness;
  final bool selected;
  final ThemeTexture? texture;
  final Density density;
  final bool categoryColors;
  final VoidCallback onTap;

  static const width = 92.0, height = 148.0;

  static Widget _bar(Color color, double width, double height, bool pixel) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(pixel ? 0 : height / 2)),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final p = theme.palette(brightness);
    final pixel = theme.style == StyleFamily.pixel;
    final r = pixel ? 0.0 : 18.0;
    final outlined = theme.style != StyleFamily.soft;
    final duration = AppMotion.control(context) * 1.5;

    Widget phone = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(9, 12, 9, 9),
      decoration: BoxDecoration(
        color: texture == null ? p.canvas : null,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: outlined ? p.outline : p.ink.withValues(alpha: .08), width: outlined ? 1.5 : 1),
      ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(p.ink.withValues(alpha: .55), 34, 6, pixel),
            const SizedBox(height: 4),
            _bar(p.ink.withValues(alpha: .25), 52, 4, pixel),
            const SizedBox(height: 10),
            for (final key in [CategoryColorKey.blue, CategoryColorKey.orange]) ...[
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: categoryColors ? p.categoryFills[key] : p.neutralFill,
                  borderRadius: BorderRadius.circular(pixel ? 0 : 7),
                  border: outlined ? Border.all(color: p.cardInk, width: 1.2) : null,
                  boxShadow: theme.style == StyleFamily.pop ? [BoxShadow(color: p.cardInk, offset: const Offset(1.5, 1.5))] : null,
                ),
              ),
              const SizedBox(height: 6),
            ],
            const Spacer(),
            Center(
              child: Container(
                width: 52,
                height: 14,
                padding: const EdgeInsets.all(3),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(color: p.navBackground, borderRadius: BorderRadius.circular(pixel ? 0 : 7)),
                child: Container(
                  width: 20,
                  decoration: BoxDecoration(color: p.navSelected, borderRadius: BorderRadius.circular(pixel ? 0 : 4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (texture != null) {
      // The live card renders inside its own theme so the texture matches.
      phone = Theme(
        key: const ValueKey('theme-preview'),
        data: buildTheme(theme: theme, brightness: brightness, density: density, showCategoryColors: categoryColors, texture: texture!),
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: ThemeTextureSurface(texture: texture!, child: phone),
          ),
        ),
      );
    }

    return Semantics(
      key: ValueKey('theme-${theme.id.name}'),
      label: '${theme.id.label} theme',
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1 : 0.92,
              duration: duration,
              curve: Curves.easeOutBack,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(pixel ? 0 : r + 3),
                      border: Border.all(color: selected ? c.palette.accent : Colors.transparent, width: 2.5),
                    ),
                    child: phone,
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: duration,
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: c.palette.accent,
                          shape: pixel ? BoxShape.rectangle : BoxShape.circle,
                          border: Border.all(color: c.surface, width: 2),
                        ),
                        child: Center(child: AppIcon(AppIcons.confirm, size: 13, color: c.palette.onAccent)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Tokens.sm),
            SizedBox(
              width: width + 8,
              child: Text(
                theme.id.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? c.ink : c.secondaryInk,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: theme.displayFont,
                  fontSize: theme.displayFont == 'Caveat'
                      ? 19
                      : theme.displayFont == 'Silkscreen'
                      ? 11
                      : 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode toggle

/// Light / Dark / Auto with a sliding thumb; the chosen icon plays a short
/// gesture (sun turns, moon swings, auto flips). Null [onChanged] disables it.
class ModeToggle extends StatelessWidget {
  const ModeToggle({super.key, required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode>? onChanged;

  static const _modes = [
    (ThemeMode.light, AppIcons.sun, 'Light'),
    (ThemeMode.dark, AppIcons.moon, 'Dark'),
    (ThemeMode.system, AppIcons.auto, 'Auto'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final pixel = c.style == StyleFamily.pixel;
    final radius = BorderRadius.circular(pixel ? 0 : Tokens.radiusPill);
    final index = _modes.indexWhere((m) => m.$1 == value);
    final duration = AppMotion.control(context) * 1.8;
    return Opacity(
      opacity: onChanged == null ? 0.5 : 1,
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.ink.withValues(alpha: .06),
          borderRadius: radius,
          border: c.outlined ? Border.all(color: c.palette.outline, width: 1.5) : null,
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: Alignment(-1 + index.toDouble(), 0),
              duration: duration,
              curve: const Cubic(0.2, 0.9, 0.1, 1),
              child: FractionallySizedBox(
                widthFactor: 1 / _modes.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.palette.accent,
                    borderRadius: radius,
                    boxShadow: c.style == StyleFamily.soft
                        ? [BoxShadow(color: c.palette.accent.withValues(alpha: .35), blurRadius: 10, offset: const Offset(0, 3))]
                        : null,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final (mode, icon, label) in _modes)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: mode == value,
                      label: '$label mode',
                      excludeSemantics: true,
                      child: InkWell(
                        key: ValueKey('mode-${mode.name}'),
                        borderRadius: radius,
                        onTap: onChanged == null || mode == value
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                onChanged!(mode);
                              },
                        child: _ModeLabel(icon: icon, label: label, selected: mode == value, duration: duration),
                      ),
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

class _ModeLabel extends StatelessWidget {
  const _ModeLabel({required this.icon, required this.label, required this.selected, required this.duration});
  final AppIcons icon;
  final String label;
  final bool selected;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final color = selected ? c.palette.onAccent : c.secondaryInk;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Keyed on selection so the gesture replays each time it is chosen.
        TweenAnimationBuilder<double>(
          key: ValueKey(selected),
          tween: Tween(begin: selected ? 0 : 1, end: 1),
          duration: selected ? duration * 1.6 : Duration.zero,
          curve: Curves.easeOutBack,
          builder: (context, t, child) {
            final turn = switch (icon) {
              AppIcons.sun => (1 - t) * math.pi / 2,
              AppIcons.moon => (1 - t) * -0.6,
              _ => (1 - t) * math.pi,
            };
            return Transform.rotate(angle: turn, child: Transform.scale(scale: 0.7 + 0.3 * t, child: child));
          },
          child: AppIcon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: AnimatedDefaultTextStyle(
            duration: duration,
            style: DefaultTextStyle.of(context).style.copyWith(color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 14),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Colors

/// Chooses whether the sliders edit the main or the background color; each
/// side shows its current color.
class _TargetToggle extends StatelessWidget {
  const _TargetToggle({required this.value, required this.main, required this.background, required this.onChanged});
  final _ColorTarget value;
  final Color main, background;
  final ValueChanged<_ColorTarget> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final pixel = c.style == StyleFamily.pixel;
    final duration = AppMotion.control(context) * 1.5;
    final targets = [(_ColorTarget.main, main, 'Main'), (_ColorTarget.background, background, 'Background')];
    return Row(
      children: [
        for (final (i, (target, color, label)) in targets.indexed) ...[
          if (i > 0) const SizedBox(width: Tokens.sm),
          Expanded(
            child: Semantics(
              button: true,
              selected: value == target,
              label: '$label color',
              excludeSemantics: true,
              child: GestureDetector(
                key: ValueKey('target-${target.name}'),
                onTap: () => onChanged(target),
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: value == target ? c.palette.accent.withValues(alpha: .10) : Colors.transparent,
                    borderRadius: BorderRadius.circular(pixel ? 0 : 14),
                    border: Border.all(color: value == target ? c.palette.accent : c.divider, width: value == target ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: duration,
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: pixel ? BoxShape.rectangle : BoxShape.circle,
                          border: Border.all(color: c.ink.withValues(alpha: .15)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: value == target ? FontWeight.w700 : FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.label, required this.onTap});
  final Color color;
  final bool selected;
  final String label;
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.control(context),
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: shape,
            border: Border.all(color: selected ? c.ink : Colors.transparent, width: 2),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: shape,
              border: Border.all(color: c.ink.withValues(alpha: .12)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A slider whose track is painted with the colors it can produce and whose
/// thumb is filled with the current one.
class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.track,
    required this.thumb,
    required this.onChanged,
    required this.onChangeEnd,
  });
  final String label;
  final double value, max;
  final List<Color> track;
  final Color thumb;
  final ValueChanged<double> onChanged, onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final unit = max == 359 ? '°' : '';
    // Lightroom-style row: label, a thin track painted in the real colors,
    // and the value.
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.secondaryInk, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              trackShape: _GradientTrackShape(track, c.ink.withValues(alpha: .10)),
              thumbShape: _RingThumbShape(thumb),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              overlayColor: thumb.withValues(alpha: .16),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Semantics(
              label: label,
              child: Slider(
                value: value.clamp(0, max),
                max: max,
                semanticFormatterCallback: (v) => '${v.round()} ${max == 359 ? 'degrees' : 'percent'}',
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 42,
          child: ExcludeSemantics(
            child: Text(
              '${value.round()}$unit',
              textAlign: TextAlign.right,
              style: TextStyle(color: c.ink, fontSize: 13, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const _GradientTrackShape(this.colors, this.edge);
  final List<Color> colors;
  final Color edge;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(parentBox: parentBox, offset: offset, sliderTheme: sliderTheme, isEnabled: isEnabled, isDiscrete: isDiscrete);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));
    context.canvas
      ..drawRRect(rrect, Paint()..shader = LinearGradient(colors: colors).createShader(rect))
      ..drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = edge,
      );
  }
}

class _RingThumbShape extends SliderComponentShape {
  const _RingThumbShape(this.color);
  final Color color;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size.square(22);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final grow = 1 + 0.12 * activationAnimation.value;
    context.canvas
      ..drawCircle(
        center.translate(0, 1.5),
        10 * grow,
        Paint()
          ..color = const Color(0x33000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawCircle(center, 10 * grow, Paint()..color = Colors.white)
      ..drawCircle(center, 7 * grow, Paint()..color = color);
  }
}

// ---------------------------------------------------------------------------
// Density

class _DensityCard extends StatelessWidget {
  const _DensityCard({required this.density, required this.selected, required this.onTap});
  final Density density;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final pixel = c.style == StyleFamily.pixel;
    final compact = density == Density.compact;
    final rows = compact ? 5 : 3;
    final gap = compact ? 3.0 : 7.0;
    final bar = compact ? 6.0 : 10.0;
    final label = compact ? 'Compact' : 'Comfortable';
    final duration = AppMotion.control(context) * 1.5;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label density',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('density-${density.name}'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? c.palette.accent.withValues(alpha: .10) : Colors.transparent,
            borderRadius: BorderRadius.circular(pixel ? 0 : 16),
            border: Border.all(color: selected ? c.palette.accent : c.divider, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < rows; i++) ...[
                      if (i > 0) SizedBox(height: gap),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: bar,
                            decoration: BoxDecoration(
                              color: selected ? c.palette.accent : c.secondaryInk.withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(pixel ? 0 : 3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              height: bar,
                              decoration: BoxDecoration(
                                color: c.ink.withValues(alpha: selected ? .22 : .12),
                                borderRadius: BorderRadius.circular(pixel ? 0 : 3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
