import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/icons.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../app/shell.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/themed.dart';
import '../profile/data/profile_repository.dart';
import '../profile/domain/profile.dart';

/// Settings destination (spec 4.1): appearance, widgets, categories, alert
/// status, privacy and shared links.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    Widget item(AppIcons icon, String title, String location) => ListTile(
      leading: SoftIcon(
        icon,
        key: ValueKey('settings-icon-${icon.name}'),
        colorKey: switch (icon) {
          AppIcons.appearance => 'purple',
          AppIcons.category => 'blue',
          AppIcons.widget => 'green',
          AppIcons.notification => 'orange',
          AppIcons.link => 'red',
          AppIcons.privacy => 'gray',
          _ => null,
        },
      ),
      title: Text(title),
      trailing: AppIcon(AppIcons.next, size: 18, color: context.scheduleColors.secondaryInk),
      onTap: () => context.push(location),
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, AppShell.bottomInset(context)),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Tokens.lg, top: Tokens.md),
              child: Semantics(header: true, child: Text('Settings', style: text.headlineMedium)),
            ),
            const _ProfileCard(),
            SectionGroup(
              children: [
                item(AppIcons.appearance, 'Appearance', '/settings/appearance'),
                item(AppIcons.category, 'Categories', '/settings/categories'),
                item(AppIcons.widget, 'Home screen widgets', '/settings/widgets'),
                item(AppIcons.notification, 'Reminders and alarms', '/settings/alerts'),
              ],
            ),
            SectionGroup(
              children: [
                item(AppIcons.link, 'Shared links', '/settings/shared-links'),
                item(AppIcons.privacy, 'Privacy and data', '/settings/privacy'),
              ],
            ),
            SectionGroup(
              children: [
                ListTile(
                  leading: const SoftIcon(AppIcons.info, key: ValueKey('settings-icon-info'), colorKey: 'gray'),
                  title: const Text('Open source licenses'),
                  onTap: () => showLicensePage(context: context, applicationName: 'Schediel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar and name, or an invitation to add them. Opens the profile screen.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value ?? const Profile();
    final c = context.scheduleColors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.lg),
      child: Semantics(
        button: true,
        label: profile.name == null ? 'Profile, add your name and photo' : 'Profile, ${profile.name}',
        excludeSemantics: true,
        child: ThemedCard(
          seed: 'profile-card',
          onTap: () => context.push('/settings/profile'),
          child: Row(
            children: [
              ThemedAvatar(profile: profile, size: 52),
              const SizedBox(width: Tokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name ?? 'Profile', style: text.titleMedium),
                    Text(
                      profile.isEmpty ? 'Add your name and photo' : 'Name and photo',
                      style: text.bodySmall?.copyWith(color: c.secondaryInk),
                    ),
                  ],
                ),
              ),
              AppIcon(AppIcons.next, size: 18, color: c.secondaryInk),
            ],
          ),
        ),
      ),
    );
  }
}
