import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/image_import/application/image_import_providers.dart';
import 'package:schediel/features/image_import/domain/image_services.dart';
import 'package:schediel/features/profile/data/profile_repository.dart';
import 'package:schediel/features/profile/presentation/avatar_crop_screen.dart';
import 'package:schediel/features/profile/presentation/profile_screen.dart';

import '../../support/harness.dart';

class _FakePicker implements ImageSourcePicker {
  _FakePicker(this.path);
  final String? Function() path;
  @override
  Future<String?> pick(ImagePickKind kind) async => path();
}

Uint8List _png() {
  final image = img.Image(width: 64, height: 32);
  img.fill(image, color: img.ColorRgb8(30, 120, 200));
  return Uint8List.fromList(img.encodePng(image));
}

late String _pickPath;

void main() {
  late Directory dir;
  late File photo;
  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('schediel-profile-ui-');
    photo = File('${dir.path}/pick.png')..writeAsBytesSync(_png());
    _pickPath = photo.path;
  });
  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows may still hold the image file open; the OS temp cleaner removes it.
    }
  });

  Future<void> openProfile(TestHarness h) async {
    await h.tapText('Settings');
    await h.tapText('Add your name and photo');
  }

  appTest('name is limited to 40 characters and appears on Today once saved', (h) async {
    await openProfile(h);
    await h.tester.enterText(textField('Name'), 'x' * 41);
    await h.tester.pump();
    expect(find.text('Use 40 characters or fewer'), findsOneWidget);
    expect(h.tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save name')).onPressed, isNull);
    await h.tester.enterText(textField('Name'), '  Diel  ');
    await h.tester.pump();
    await h.tapText('Save name');
    expect((await h.run(() => ProfileRepository(h.db, directory: () async => dir, clock: DateTime.now).load())).name, 'Diel');
    await h.tester.pageBack();
    await h.settle();
    await h.tapText('Today');
    expect(find.text('Diel'), findsOneWidget);
  });

  appTest('cancelling the crop leaves the profile unchanged', (h) async {
    await openProfile(h);
    await h.tester.tap(find.text('Choose photo'));
    // The real file read completes outside the fake-async zone; the busy bar
    // animates meanwhile, so pump frames instead of settling.
    for (var i = 0; i < 20 && find.byType(AvatarCropScreen).evaluate().isEmpty; i++) {
      await h.tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await h.tester.pump(const Duration(milliseconds: 50));
    }
    await h.tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AvatarCropScreen), findsOneWidget);
    await h.tester.tap(find.text('Cancel').last);
    for (var i = 0; i < 10; i++) {
      await h.tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.byType(AvatarCropScreen), findsNothing);
    expect(await h.run(() => h.db.select(h.db.profilePreferences).get()), isEmpty);
  }, overrides: [
    imageSourcePickerProvider.overrideWithValue(_FakePicker(() => _pickPath)),
    imageSizeReaderProvider.overrideWithValue((_) async => const Size(64, 32)),
  ]);

  appTest('removing the photo asks first', (h) async {
    await h.run(() => h.db.into(h.db.profilePreferences).insert(ProfilePreferencesCompanion.insert(
          id: const Value(1),
          displayName: const Value('Diel'),
          photoPath: Value(photo.path),
          updatedAt: DateTime.utc(2026, 11, 2),
        )));
    await h.settle();
    await h.tapText('Settings');
    await h.tapText('Diel');
    await h.tapText('Remove photo');
    expect(find.text('Remove photo?'), findsOneWidget);
    await h.tapText('Cancel');
    expect((await h.run(() => h.db.select(h.db.profilePreferences).getSingle())).photoPath, photo.path);
  });

  appTest('an unmoved crop saves the centered square of the photo', (h) async {
    final nav = Navigator.of(h.tester.element(find.text('Create schedule').first));
    final pending = nav.push<SquareCrop>(MaterialPageRoute(
      builder: (_) => AvatarCropScreen(image: MemoryImage(_png()), imageSize: const Size(640, 320)),
    ));
    await h.settle();
    await h.tapText('Save');
    expect(await pending, const SquareCrop(160, 0, 320));
  });
}
