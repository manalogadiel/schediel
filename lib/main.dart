import 'dart:convert';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/fonts.dart';
import 'app/app.dart';
import 'app/lifecycle.dart';
import 'app/providers.dart';
import 'core/time/zone_resolver.dart';
import 'data/local/database.dart';
import 'features/appearance/appearance.dart';
import 'features/categories/domain/category.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/icons/LICENSE-lucide.txt');
    yield LicenseEntryWithLineBreaks(const ['Lucide icons'], text);
  });
  registerFontLicenses();

  final zones = ZoneResolver.initialized();
  final db = AppDatabase(driftDatabase(name: 'schediel'));
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );

  final zone = await container.read(deviceZoneSourceProvider)();
  final appearance = await AppearanceRepository(db, clock: DateTime.now).load();
  final savedFilter = await db.readValue(AppFilterNotifier.storageKey);
  container.dispose();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        zoneResolverProvider.overrideWithValue(zones),
        initialDeviceZoneProvider.overrideWithValue(
          zone != null && zones.isValidZone(zone) ? zone : 'UTC',
        ),
        initialAppearanceProvider.overrideWithValue(appearance),
        appearanceRepositoryProvider.overrideWithValue(
          AppearanceRepository(db, clock: DateTime.now),
        ),
        initialAppFilterProvider.overrideWithValue(
          CategoryFilter.fromJson(
            savedFilter == null ? null : jsonDecode(savedFilter),
          ),
        ),
      ],
      child: const SchedielApp(showIntro: true),
    ),
  );
}
