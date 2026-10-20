import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/profile/domain/profile.dart';
import '../icons.dart';
import '../theme/app_theme.dart';
import '../theme/schediel_theme.dart';
import '../theme/theme_customization.dart';
import '../theme/tokens.dart';
import 'pixel_border.dart';
import 'sketch_border.dart';
import 'theme_texture.dart';

/// Hard shadow offset used by pop and pixel shapes.
double _shadowFor(StyleFamily style, bool emphasized) => switch (style) {
      StyleFamily.pop => emphasized ? 5 : 3,
      StyleFamily.pixel => emphasized ? 4 : 3,
      _ => 0,
    };

/// A surface drawn in the active theme's style: soft (rounded, faint shadow),
/// pop (outline and hard offset shadow), pixel (notched square) or sketch
/// (hand-drawn outline with a slight, seed-stable tilt).
class ThemedCard extends StatelessWidget {
  const ThemedCard({
    super.key,
    this.fill,
    this.emphasized = false,
    this.seed,
    this.padding = const EdgeInsets.all(Tokens.md),
    this.onTap,
    this.onLongPress,
    required this.child,
  });

  /// Defaults to the theme surface.
  final Color? fill;

  /// Marks the card that matters most on screen (e.g. the next schedule).
  final bool emphasized;

  /// Keeps sketch wobble and tilt stable for the same item.
  final Object? seed;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final color = fill ?? c.surface;
    final ink = c.palette.outline;
    final shadow = _shadowFor(c.style, emphasized);
    final tappable = onTap != null || onLongPress != null;
    final radius = BorderRadius.circular(c.radius);

    Widget content = Padding(padding: padding, child: child);
    if (tappable) content = ConstrainedBox(constraints: const BoxConstraints(minHeight: Tokens.minTarget), child: content);
    // Cards repeat the chosen texture, fainter, in their own ink.
    if (c.texture != ThemeTexture.none) {
      content = Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: TextureLayer(c.texture, shade: c.palette.cardInk.withValues(alpha: .045), accent: c.palette.accent),
            ),
          ),
          content,
        ],
      );
    }

    Widget ink0(Widget child, {ShapeBorder? shape, BorderRadius? borderRadius}) => Material(
          type: MaterialType.transparency,
          child: tappable
              ? InkWell(customBorder: shape, borderRadius: borderRadius, onTap: onTap, onLongPress: onLongPress, child: child)
              : child,
        );

    switch (c.style) {
      case StyleFamily.soft:
        final dark = c.palette.brightness == Brightness.dark;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            border: emphasized ? Border.all(color: c.palette.accent, width: 2) : null,
            boxShadow: dark
                ? null
                : [BoxShadow(color: const Color(0xFF000000).withValues(alpha: emphasized ? 0.10 : 0.05), blurRadius: emphasized ? 18 : 10, offset: const Offset(0, 3))],
          ),
          child: ClipRRect(borderRadius: radius, child: ink0(content, borderRadius: radius)),
        );
      case StyleFamily.pop:
        return Padding(
          padding: EdgeInsets.only(right: shadow, bottom: shadow),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: radius,
              border: Border.all(color: ink, width: 2),
              boxShadow: [BoxShadow(color: ink, offset: Offset(shadow, shadow))],
            ),
            child: ClipRRect(borderRadius: radius, child: ink0(content, borderRadius: radius)),
          ),
        );
      case StyleFamily.pixel:
        return CustomPaint(
          painter: PixelBorderPainter(fill: color, ink: ink, shadow: shadow),
          child: Padding(
            padding: EdgeInsets.only(right: shadow, bottom: shadow),
            child: ClipPath(clipper: const PixelClipper(), child: ink0(content)),
          ),
        );
      case StyleFamily.sketch:
        final card = CustomPaint(
          painter: SketchBorderPainter(seed: seed, fill: color, ink: ink, radius: c.radius, strokeWidth: emphasized ? 2.6 : 2),
          child: ink0(content, borderRadius: radius),
        );
        if (MediaQuery.disableAnimationsOf(context)) return card;
        return Transform.rotate(angle: sketchTilt(seed), child: card);
    }
  }
}

/// A seed-stable tilt between 0.25° and 0.8° either way.
double sketchTilt(Object? seed) {
  final h = stableSeed(seed);
  final degrees = 0.25 + (h % 1000) / 1000 * 0.55;
  return (h.isEven ? 1 : -1) * degrees * math.pi / 180;
}

/// Small label or status shape (time badge, "Now", day pill).
class ThemedPill extends StatelessWidget {
  const ThemedPill({super.key, this.label, this.emphasized = false, this.fill, this.width, this.height});

  final String? label;

  /// Uses the theme's tested badge colors (e.g. "Now").
  final bool emphasized;

  /// Overrides the fill; text then uses whichever of ink or surface reads best.
  final Color? fill;
  final double? width;
  final double? height;

  Color resolveFill(BuildContext context) {
    final c = context.scheduleColors;
    return fill ?? (emphasized ? c.palette.nowBadge : c.surface);
  }

  Color _textColor(BuildContext context, Color background) {
    final c = context.scheduleColors;
    if (fill == null) return emphasized ? c.palette.onNowBadge : c.ink;
    final options = [c.palette.cardInk, c.ink, c.surface, c.palette.onNowBadge];
    options.sort((a, b) => contrastRatio(b, background).compareTo(contrastRatio(a, background)));
    return options.first;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final background = resolveFill(context);
    final pixel = c.style == StyleFamily.pixel;
    final text = label == null
        ? null
        : Text(label!,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2, color: _textColor(context, background)));
    final body = Container(
      width: width,
      height: height,
      // Center only inside a fixed size; otherwise hug the label (an aligned
      // Container would expand to the full available width).
      alignment: width != null || height != null ? Alignment.center : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: text,
    );
    if (pixel) {
      return CustomPaint(painter: PixelBorderPainter(fill: background, ink: c.palette.outline, width: 2, step: 2), child: body);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Tokens.radiusPill),
        border: c.outlined ? Border.all(color: c.palette.outline, width: 1.5) : null,
      ),
      child: body,
    );
  }
}

/// A selectable chip in the theme style (category filters).
class ThemedChip extends StatelessWidget {
  const ThemedChip({super.key, required this.label, required this.selected, required this.onSelected, this.swatch});

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  /// Category fill shown as a dot before the label.
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final pixel = c.style == StyleFamily.pixel;
    final background = selected ? c.palette.navBackground : c.surface;
    final foreground = selected ? _bestOn(background, [c.palette.navInk, c.surface, c.ink]) : c.ink;
    final shape = pixel
        ? RoundedRectangleBorder(side: BorderSide(color: c.palette.outline, width: 2))
        : StadiumBorder(side: c.outlined || !selected ? BorderSide(color: c.outlined ? c.palette.outline : c.divider, width: c.outlined ? 2 : 1) : BorderSide.none);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelected(!selected),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: Tokens.minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (swatch != null) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: pixel ? BoxShape.rectangle : BoxShape.circle,
                      border: Border.all(color: foreground.withValues(alpha: 0.6)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: foreground)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

Color _bestOn(Color background, List<Color> options) =>
    options.reduce((a, b) => contrastRatio(a, background) >= contrastRatio(b, background) ? a : b);

/// Round (square for pixel) icon button in the theme style.
class ThemedIconButton extends StatelessWidget {
  const ThemedIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.filled = false, this.size = 44});

  final AppIcons icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Accent fill (primary action, e.g. add).
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final pixel = c.style == StyleFamily.pixel;
    final background = filled ? c.palette.accent : c.surface;
    final foreground = filled ? c.palette.onAccent : c.ink;
    final side = c.outlined ? BorderSide(color: c.palette.outline, width: 2) : BorderSide.none;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: math.max(size, Tokens.minTarget),
          child: Center(
            child: Material(
              color: background,
              elevation: !c.outlined && filled ? 2 : 0,
              shape: pixel ? RoundedRectangleBorder(side: side) : CircleBorder(side: side),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: SizedBox.square(dimension: size, child: Center(child: AppIcon(icon, size: size * 0.5, color: foreground))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The local profile picture: photo, otherwise initials, otherwise an icon.
class ThemedAvatar extends StatelessWidget {
  const ThemedAvatar({super.key, required this.profile, this.size = 44});

  final Profile? profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final pixel = c.style == StyleFamily.pixel;
    final path = profile?.photoPath;
    final initials = profile?.initials;
    final Widget inner;
    if (path != null) {
      inner = Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => _placeholder(c, initials),
      );
    } else {
      inner = _placeholder(c, initials);
    }
    final border = c.outlined ? Border.all(color: c.palette.outline, width: 2) : null;
    return Semantics(
      image: true,
      label: profile?.name ?? 'Profile',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: pixel ? BoxShape.rectangle : BoxShape.circle, border: border),
        child: pixel ? ClipRect(child: inner) : ClipOval(child: inner),
      ),
    );
  }

  Widget _placeholder(ScheduleColors c, String? initials) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: initials == null ? c.palette.neutralFill : c.palette.accent,
        child: initials == null
            ? AppIcon(AppIcons.person, size: size * 0.5, color: c.palette.cardInk)
            : Text(initials, style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w700, color: c.palette.onAccent)),
      );
}
