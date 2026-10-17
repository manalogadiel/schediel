import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/icons.dart';
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

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: Tokens.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const AppIcon(AppIcons.add),
                title: const Text('Create schedule'),
                onTap: () => go('/schedule/new'),
              ),
              ListTile(
                leading: const AppIcon(AppIcons.image),
                title: const Text('Import image'),
                onTap: () => go('/import/image'),
              ),
              ListTile(
                leading: const AppIcon(AppIcons.link),
                title: const Text('Open shared link'),
                onTap: () => go('/share/open'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
