import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/profile/data/profile_repository.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late ProfileRepository repo;
  var tick = 0;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dir = await Directory.systemTemp.createTemp('schediel-profile-test-');
    repo = ProfileRepository(db, directory: () async => dir, clock: () => DateTime.utc(2026, 11, 2, 0, 0, tick++));
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Uint8List photo() {
    final image = img.Image(width: 900, height: 600);
    img.fill(image, color: img.ColorRgb8(120, 90, 200));
    return Uint8List.fromList(img.encodeJpg(image));
  }

  test('a new profile is empty', () async {
    final p = await repo.load();
    expect(p.name, isNull);
    expect(p.photoPath, isNull);
  });

  test('name is trimmed, limited to 40 characters, and blank clears it', () async {
    await repo.setName('  Diel  ');
    expect((await repo.load()).name, 'Diel');
    expect(() => repo.setName('x' * 41), throwsArgumentError);
    expect((await repo.load()).name, 'Diel');
    await repo.setName('   ');
    expect((await repo.load()).name, isNull);
  });

  test('photo is cropped square, resized to 512 and stored without metadata', () async {
    await repo.setPhoto(photo());
    final path = (await repo.load()).photoPath!;
    final bytes = File(path).readAsBytesSync();
    final decoded = img.decodeJpg(bytes)!;
    expect(decoded.width, 512);
    expect(decoded.height, 512);
    expect(decoded.exif.isEmpty, isTrue);
    expect(path.startsWith(dir.path), isTrue);
  });

  test('an explicit square crop picks that region', () async {
    // Left half red, right half blue.
    final image = img.Image(width: 400, height: 200);
    img.fillRect(image, x1: 0, y1: 0, x2: 199, y2: 199, color: img.ColorRgb8(220, 0, 0));
    img.fillRect(image, x1: 200, y1: 0, x2: 399, y2: 199, color: img.ColorRgb8(0, 0, 220));
    await repo.setPhoto(Uint8List.fromList(img.encodePng(image)), crop: const SquareCrop(200, 0, 200));
    final saved = img.decodeJpg(File((await repo.load()).photoPath!).readAsBytesSync())!;
    final center = saved.getPixel(256, 256);
    expect(center.b, greaterThan(150));
    expect(center.r, lessThan(60));
  });

  test('replacing the photo deletes the previous file', () async {
    await repo.setPhoto(photo());
    final first = (await repo.load()).photoPath!;
    await repo.setPhoto(photo());
    final second = (await repo.load()).photoPath!;
    expect(second, isNot(first));
    expect(File(first).existsSync(), isFalse);
    expect(File(second).existsSync(), isTrue);
  });

  test('removing the photo deletes the file and keeps the name', () async {
    await repo.setName('Diel');
    await repo.setPhoto(photo());
    final path = (await repo.load()).photoPath!;
    await repo.removePhoto();
    expect(File(path).existsSync(), isFalse);
    final p = await repo.load();
    expect(p.photoPath, isNull);
    expect(p.name, 'Diel');
  });

  test('clear removes name and photo', () async {
    await repo.setName('Diel');
    await repo.setPhoto(photo());
    final path = (await repo.load()).photoPath!;
    await repo.clear();
    expect(File(path).existsSync(), isFalse);
    final p = await repo.load();
    expect(p.name, isNull);
    expect(p.photoPath, isNull);
  });

  test('images that are not JPEG or PNG are rejected and nothing is stored', () async {
    await expectLater(repo.setPhoto(Uint8List.fromList(List.filled(64, 7))), throwsA(isA<ProfilePhotoRejected>()));
    expect((await repo.load()).photoPath, isNull);
    expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
  });
}
