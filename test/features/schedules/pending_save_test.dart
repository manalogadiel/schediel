import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/features/reminders/domain/alert_rule.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';
import '../../support/harness.dart';
class PausedRepository extends ScheduleRepository {
  PausedRepository(Ref ref):release=Completer<void>(),super(ref.read(databaseProvider),validator:ref.read(seriesValidatorProvider),
    engine:ref.read(occurrenceEngineProvider),clock:ref.read(clockProvider),newId:ref.read(idGeneratorProvider));
  final Completer<void> release;
  final finished = Completer<String>();
  @override Future<String> create(ScheduleDraft draft,{List<AlertPreference> alerts=const[]}) async {
    await release.future;
    final id = await super.create(draft,alerts:alerts);
    finished.complete(id);
    return id;
  }
}
void main() {
  appTest('a pending save cannot be dismissed or mistaken for an unsaved discard', (h) async {
    await h.tester.tap(find.byTooltip('Add')); await h.settle(); await h.tapText('Create schedule');
    await h.tester.enterText(find.widgetWithText(TextField,'Title'),'Pending fixture');
    await h.tapText('Save');
    final closeButton=find.ancestor(of:find.byTooltip('Close'),matching:find.byType(IconButton));
    expect(h.tester.widget<IconButton>(closeButton).onPressed,isNull);
    expect(find.text('Discard changes?'),findsNothing);
    (h.read(scheduleRepositoryProvider) as PausedRepository).release.complete();
    await h.run(() => (h.read(scheduleRepositoryProvider) as PausedRepository).finished.future);
    await h.settle();
    expect((await h.run(h.read(scheduleRepositoryProvider).loadAll)).single.title,'Pending fixture');
  },overrides:[scheduleRepositoryProvider.overrideWith(PausedRepository.new)]);
}
