import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/router.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';
import 'package:schediel/features/sharing/application/share_sender.dart';
import 'package:schediel/features/sharing/domain/direct_share.dart';
import 'package:schediel/features/sharing/domain/share_payload.dart';
import 'package:schediel/features/sharing/presentation/create_share_screen.dart';
import 'package:schediel/integrations/native/native_bridge.dart';

import '../../support/harness.dart';

class _ShareSheet extends NativeBridge {
  String? message;
  @override
  Future<bool> shareText(String text, {String? subject}) async {
    message = text;
    return true;
  }
}

Future<void> _seed(TestHarness h) => h.run(() async {
  final repo = h.read(scheduleRepositoryProvider);
  for (final (title, category) in [
    ('School class', 'school'),
    ('Personal visit', 'personal'),
    ('Unfiled', null),
  ]) {
    await repo.create(
      ScheduleDraft(
        title: title,
        categoryId: category,
        details: const ScheduleDetails(location: '105', professor: 'Midterms', subtitle: 'CS 312', notes: 'Private fixture notes'),
        time: DateOnlySpec(
          startDate: LocalDate(2026, 11, 3),
          endDateExclusive: LocalDate(2026, 11, 4),
        ),
      ),
    );
  }
});

Future<void> _openShare(TestHarness h) async {
  rootNavigatorKey.currentState!.push(
    MaterialPageRoute<void>(builder: (_) => const CreateShareScreen()),
  );
  await h.settle();
}

Future<void> _chooseCategories(TestHarness h, List<String> ids) async {
  await h.tester.tap(find.byKey(const ValueKey('share-category-selector')));
  await h.settle();
  for (final id in ids) {
    await h.tester.tap(find.byKey(ValueKey('share-category-$id')));
    await h.settle();
  }
  await h.tapText('Apply');
}

void main() {
  appTest('categories use one grouped picker and cancel keeps the current selection', (h) async {
    await _seed(h);
    await _openShare(h);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.byKey(const ValueKey('share-category-selector')), findsOneWidget);
    expect(find.byKey(const ValueKey('share-category-school')), findsNothing);
    await h.tester.tap(find.byKey(const ValueKey('share-category-selector')));
    await h.settle();
    expect(find.byKey(const ValueKey('share-category-school')), findsOneWidget);
    await h.tester.tap(find.byKey(const ValueKey('share-category-personal')));
    await h.tapText('Cancel');
    expect(find.text('All categories'), findsOneWidget);
    expect(find.text('3 selected'), findsOneWidget);
    expect(find.text('School class'), findsOneWidget);
    expect(find.text('Personal visit'), findsOneWidget);
  });

  appTest('grouped category selection fits a narrow screen with enlarged text', (h) async {
    h.tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(h.tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _seed(h);
    await _openShare(h);
    await _chooseCategories(h, ['school']);
    expect(find.text('1 selected'), findsOneWidget);
    expect(h.tester.takeException(), isNull);
  }, size: const Size(360, 740));

  final detailSheet = _ShareSheet();
  appTest('details start checked except Notes and changes reach the sent link', (h) async {
    await _seed(h);
    await _openShare(h);
    await _chooseCategories(h, ['school']);
    await h.tapText('Details');
    for (final label in ['Location', 'Person', 'Subtitle', 'Notes']) {
      final row = find.widgetWithText(CheckboxListTile, label);
      expect(h.tester.widget<CheckboxListTile>(row).value, label != 'Notes');
    }
    await h.tapText('Location');
    await h.tapText('Notes');
    await h.tapText('Send link');
    final payload = DirectShare.decode(DirectShare.findInText(detailSheet.message!)!, h.read(sharePayloadValidatorProvider))!;
    expect(payload.items.single.details, const ScheduleDetails(professor: 'Midterms', subtitle: 'CS 312', notes: 'Private fixture notes'));
    expect(payload.sharedFieldPolicy.location, isFalse);
    expect(payload.sharedFieldPolicy.notes, isTrue);
  }, bridge: detailSheet);

  appTest('adding a share category keeps individual schedules deselected', (
    h,
  ) async {
    await _seed(h);
    await _openShare(h);
    await _chooseCategories(h, ['school']);
    await h.settle();
    await h.tester.tap(find.widgetWithText(CheckboxListTile, 'School class'));
    await h.settle();
    expect(find.text('0 selected'), findsOneWidget);
    await _chooseCategories(h, ['personal']);
    await h.settle();
    expect(find.text('1 selected'), findsOneWidget);
    expect(
      h.tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'School class'),
          )
          .value,
      isFalse,
    );
    expect(
      h.tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'Personal visit'),
          )
          .value,
      isTrue,
    );
  });
  final sheet = _ShareSheet();
  appTest(
    'School category sends only school schedules and leaves Today filters alone',
    (h) async {
      await _seed(h);
      await _openShare(h);
      expect(find.text('3 selected'), findsOneWidget);
      await _chooseCategories(h, ['school']);
      await h.settle();
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Personal visit'), findsNothing);
      expect(find.text('Unfiled'), findsNothing);
      expect(h.read(effectiveFilterProvider).isAll, isTrue);
      expect(find.text('Create link'), findsNothing);
      await h.tapText('Send link');
      final link = DirectShare.findInText(sheet.message!);
      final payload = DirectShare.decode(
        link!,
        h.read(sharePayloadValidatorProvider),
      )!;
      expect(payload.items.map((s) => s.title), ['School class']);
      expect(payload.items.single.categoryLabel, 'School');
      expect(payload.sharedFieldPolicy.location, isTrue);
      expect(payload.sharedFieldPolicy.professor, isTrue);
      expect(payload.sharedFieldPolicy.subtitle, isTrue);
      expect(payload.sharedFieldPolicy.notes, isFalse);
      expect(payload.items.single.details, const ScheduleDetails(location: '105', professor: 'Midterms', subtitle: 'CS 312'));
    },
    bridge: sheet,
  );

  appTest(
    'share categories combine, allow empty selection and isolate Uncategorized',
    (h) async {
      await _seed(h);
      await _openShare(h);
      await _chooseCategories(h, ['school']);
      await h.settle();
      await _chooseCategories(h, ['personal']);
      await h.settle();
      expect(find.text('2 selected'), findsOneWidget);
      await _chooseCategories(h, ['school', 'personal']);
      await h.settle();
      expect(find.text('0 selected'), findsOneWidget);
      expect(
        h.tester
            .widget<FilledButton>(find.byKey(const ValueKey('send-direct')))
            .onPressed,
        isNull,
      );
      await _chooseCategories(h, ['uncategorized']);
      await h.settle();
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Unfiled'), findsOneWidget);
      expect(find.text('School class'), findsNothing);
      expect(find.text('Personal visit'), findsNothing);
    },
  );

  appTest(
    'Shared links offers offline sending and copied-link review without online setup',
    (h) async {
      await h.tapText('Settings');
      await h.tapText('Shared links');
      expect(find.text('Share schedules'), findsOneWidget);
      expect(find.text('Open shared link'), findsOneWidget);
      expect(find.textContaining('online'), findsNothing);
      expect(find.textContaining('not set up'), findsNothing);
      await h.tapText('Open shared link');
      expect(
        find.textContaining('Paste a link or the whole message'),
        findsOneWidget,
      );
      expect(find.textContaining('Online'), findsNothing);
      expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
    },
  );

  appTest('privacy describes offline links without backend setup controls', (
    h,
  ) async {
    await h.tapText('Settings');
    await h.tapText('Privacy and data');
    await h.tester.scrollUntilVisible(
      find.text('Schedules inside links'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await h.tapText('Schedules inside links');
    expect(
      find.textContaining('Schediel does not upload them'),
      findsOneWidget,
    );
    expect(find.text('Online sharing'), findsNothing);
    expect(find.text('Delete my backend data'), findsNothing);
    expect(find.textContaining('not configured'), findsNothing);
  });

  appTest(
    'a copied message opens the offline review without adding schedules',
    (h) async {
      await _seed(h);
      final saved = await h.run(h.read(scheduleRepositoryProvider).loadAll);
      final payload = h.read(shareSenderProvider).build(
        saved.where((s) => s.categoryId == 'school').toList(),
        {'school': 'School'},
        const SharedFieldPolicy(
          location: false,
          professor: false,
          subtitle: false,
          notes: false,
        ),
      ).payload!;
      final message =
          'Schedules from Schediel\n\n${DirectShare.encode(payload)}';
      h.tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async =>
            call.method == 'Clipboard.getData' ? {'text': message} : null,
      );
      addTearDown(
        () => h.tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await h.tapText('Settings');
      await h.tapText('Shared links');
      await h.tapText('Open shared link');
      await h.tapText('Open copied link');
      expect(find.text('Shared schedules'), findsOneWidget);
      expect(find.text('School class'), findsOneWidget);
      expect(find.text('Add selected schedules'), findsOneWidget);
      expect(
        await h.run(h.read(scheduleRepositoryProvider).loadAll),
        hasLength(3),
      );
    },
  );
}
