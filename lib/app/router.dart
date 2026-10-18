import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/time/local_date.dart';
import '../features/appearance/appearance_screen.dart';
import '../features/image_import/presentation/image_import_screen.dart';
import '../features/privacy/presentation/privacy_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/reminders/presentation/alerts_settings_screen.dart';
import '../features/reminders/presentation/reminder_page.dart';
import '../features/schedules/presentation/occurrence_sheet.dart';
import '../features/schedules/presentation/schedule_editor_screen.dart';
import '../features/schedules/presentation/today_screen.dart';
import '../features/schedules/presentation/week_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/sharing/presentation/sharing_screens.dart';
import '../features/sharing/domain/share_link.dart';
import '../features/sharing/presentation/shared_links_screen.dart';
import '../features/widgets/presentation/widget_settings_screen.dart';
import 'shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({String initialLocation = '/today', List<RouteBase> extraRoutes = const []}) => GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/today', builder: (_, _) => const TodayScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/week', builder: (_, _) => const WeekScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())]),
          ],
        ),
        GoRoute(
          path: '/schedule/new',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, state) => ScheduleEditorScreen(
            scope: EditorScope.create,
            initialDate: LocalDate.tryParse(state.uri.queryParameters['date'] ?? ''),
          ),
        ),
        GoRoute(
          path: '/schedule/:id/edit',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, state) {
            final key = LocalDate.tryParse(state.uri.queryParameters['key'] ?? '');
            final occurrence = state.uri.queryParameters['scope'] == 'occurrence' && key != null;
            return ScheduleEditorScreen(
              scope: occurrence ? EditorScope.occurrence : EditorScope.series,
              seriesId: state.pathParameters['id'],
              occurrenceKey: occurrence ? key : null,
            );
          },
        ),
        GoRoute(
          path: '/occurrence/:id/:key',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, state) => OccurrenceDetailsPage(
            seriesId: state.pathParameters['id']!,
            originalKey: LocalDate.tryParse(state.pathParameters['key']!),
          ),
        ),
        GoRoute(
          path: '/settings/appearance',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => const AppearanceScreen(),
        ),
        GoRoute(
          path: '/settings/categories',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/settings/widgets',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => const WidgetSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/widgets/:key',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, state) => WidgetConfigScreen(widgetKey: state.pathParameters['key']!),
        ),
        GoRoute(
          path: '/settings/alerts',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => const AlertsSettingsScreen(),
        ),
        GoRoute(
          path: '/reminder/:id/:key',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (_, state) => MaterialPage(
            fullscreenDialog: true,
            child: ReminderPage(
              seriesId: state.pathParameters['id']!,
              originalKey: LocalDate.tryParse(state.pathParameters['key']!),
              isAlarm: state.uri.queryParameters['kind'] == 'alarm',
              requestKey: state.uri.queryParameters['request'] ?? '',
            ),
          ),
        ),
        GoRoute(path: '/share/open', parentNavigatorKey: rootNavigatorKey,
          builder: (_, state) => ShareOpenScreen(initialLink: state.extra is ShareLink ? state.extra as ShareLink : null)),
        GoRoute(path: '/share/create', parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => const CreateShareScreen()),
        GoRoute(path: '/settings/shared-links', parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => const SharedLinksScreen()),
        GoRoute(path: '/settings/privacy', parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => const PrivacyScreen()),
        GoRoute(path: '/import/image', parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => const ImageImportScreen()),
        ...extraRoutes,
      ],
    );
