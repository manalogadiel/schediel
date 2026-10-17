import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/icons.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/common.dart';

/// Settings destination (spec 4.1): appearance, widgets, categories, alert
/// status, privacy and shared links.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    Widget item(AppIcons icon, String title, String location) => ListTile(
          leading: AppIcon(icon),
          title: Text(title),
          trailing: AppIcon(AppIcons.next, size: 18, color: context.scheduleColors.secondaryInk),
          onTap: () => context.push(location),
        );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Tokens.lg, top: Tokens.md),
              child: Semantics(header: true, child: Text('Settings', style: text.headlineMedium)),
            ),
            SectionGroup(children: [
              item(AppIcons.appearance, 'Appearance', '/settings/appearance'),
              item(AppIcons.category, 'Categories', '/settings/categories'),
              item(AppIcons.widget, 'Home screen widgets', '/settings/widgets'),
              item(AppIcons.notification, 'Reminders and alarms', '/settings/alerts'),
            ]),
            SectionGroup(children: [
              item(AppIcons.link, 'Shared links', '/settings/shared-links'),
              item(AppIcons.privacy, 'Privacy and data', '/settings/privacy'),
            ]),
            SectionGroup(children: [
              ListTile(
                leading: const AppIcon(AppIcons.info),
                title: const Text('Open source licenses'),
                onTap: () => showLicensePage(context: context, applicationName: 'Schediel'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
