import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme/tokens.dart';

/// Curated Lucide icons plus original Schediel marks (upstream ISC license in
/// assets/icons/LICENSE-lucide.txt).
enum AppIcons {
  calendar('calendar'),
  today('today'),
  todayFill('today-fill'),
  week('week'),
  weekFill('week-fill'),
  settings('settings'),
  settingsFill('settings-fill'),
  add('plus'),
  image('image'),
  share('share-out'),
  filter('list-filter'),
  location('map-pin'),
  person('user'),
  repeat('repeat'),
  notification('bell'),
  alarm('alarm-clock'),
  appearance('palette'),
  edit('pencil'),
  remove('trash-2'),
  confirm('check'),
  close('x'),
  previous('chevron-left'),
  next('chevron-right'),
  expand('chevron-down'),
  link('link'),
  warning('triangle-alert'),
  category('tag'),
  folder('folder-soft'),
  grid('layout-grid'),
  agenda('list'),
  restore('rotate-ccw'),
  rotate('rotate-cw'),
  privacy('shield'),
  time('clock'),
  text('text'),
  camera('camera'),
  copy('copy'),
  info('info'),
  crop('crop'),
  widget('smartphone'),
  scan('scan-text');

  const AppIcons(this.file);
  final String file;

  String get asset => 'assets/icons/$file.svg';
}

/// Renders a curated SVG. Without [semanticLabel] the icon is decorative and
/// hidden from accessibility; actionable icons get labels from their button.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = Tokens.iconSize, this.color, this.semanticLabel});

  final AppIcons icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
