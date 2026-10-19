import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/schediel_theme.dart';
import '../../../app/theme/tokens.dart';

/// Add is an action, not a destination (spec 4.1).
Future<void> showAddMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) {
      void go(String location) {
        Navigator.of(sheetContext).pop();
        context.push(location);
      }

      final c = sheetContext.scheduleColors;
      Widget option(AppIcons icon, String title, CategoryColorKey tint, String location) {
        final pixel = c.style == StyleFamily.pixel;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: Tokens.lg, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.palette.categoryFills[tint],
              borderRadius: BorderRadius.circular(pixel ? 0 : 14),
              border: c.outlined ? Border.all(color: c.palette.outline, width: 2) : null,
            ),
            child: AppIcon(icon, size: 22, color: c.palette.cardInk),
          ),
          title: Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
          onTap: () => go(location),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: Tokens.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option(AppIcons.add, 'Create schedule', CategoryColorKey.blue, '/schedule/new'),
              option(AppIcons.image, 'Import image', CategoryColorKey.green, '/import/image'),
              option(AppIcons.link, 'Open shared link', CategoryColorKey.purple, '/share/open'),
            ],
          ),
        ),
      );
    },
  );
}
