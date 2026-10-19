import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/schediel_theme.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// A routed sheet: existing URLs/results work without a second editor stack.
class BottomSheetPage<T> extends Page<T> {
  const BottomSheetPage({required this.child, super.key});
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    final radius = context.scheduleColors.style == StyleFamily.pixel ? 0.0 : Tokens.radiusSheet;
    return ModalBottomSheetRoute<T>(
      settings: this,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: context.scheduleColors.canvas,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius))),
      clipBehavior: Clip.antiAlias,
      sheetAnimationStyle: AnimationStyle(duration: AppMotion.screen(context), reverseDuration: AppMotion.control(context)),
      builder: (_) => FractionallySizedBox(heightFactor: 0.94, child: child),
    );
  }
}
