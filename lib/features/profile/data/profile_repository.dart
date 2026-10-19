import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../data/local/database.dart';
import '../domain/profile.dart';

/// A square region of the upright (orientation-applied) image, in pixels.
class SquareCrop {
  const SquareCrop(this.left, this.top, this.side);
  final int left;
  final int top;
  final int side;

  @override
  bool operator ==(Object other) => other is SquareCrop && other.left == left && other.top == top && other.side == side;

  @override
  int get hashCode => Object.hash(left, top, side);

  @override
  String toString() => 'SquareCrop($left, $top, $side)';
}

/// The chosen image could not be read as a JPEG or PNG photo.
class ProfilePhotoRejected implements Exception {
  const ProfilePhotoRejected();
  @override
  String toString() => 'ProfilePhotoRejected';
}

/// Stores the optional profile in the app database and its photo in the
/// app-private support directory. Nothing here touches the network.
class ProfileRepository {
  ProfileRepository(this._db, {required this._directory, required this._clock});

  final AppDatabase _db;
  final Future<Directory> Function() _directory;
  final DateTime Function() _clock;

  static const photoSize = 512;

  Future<ProfileRow?> _row() => (_db.select(_db.profilePreferences)..where((t) => t.id.equals(1))).getSingleOrNull();

  Profile _toProfile(ProfileRow? row) => Profile(name: row?.displayName, photoPath: row?.photoPath);

  Future<Profile> load() async => _toProfile(await _row());

  Stream<Profile> watch() =>
      (_db.select(_db.profilePreferences)..where((t) => t.id.equals(1))).watchSingleOrNull().map(_toProfile);

  Future<void> _write({required String? name, required String? photoPath}) =>
      _db.into(_db.profilePreferences).insertOnConflictUpdate(ProfilePreferencesCompanion.insert(
            id: const Value(1),
            displayName: Value(name),
            photoPath: Value(photoPath),
            updatedAt: _clock().toUtc(),
          ));

  /// Trims [name]; blank clears it. Longer than [Profile.maxNameLength]
  /// characters is rejected.
  Future<void> setName(String? name) async {
    final trimmed = name?.trim() ?? '';
    if (trimmed.runes.length > Profile.maxNameLength) throw ArgumentError.value(name, 'name', 'too long');
    final current = await load();
    await _write(name: trimmed.isEmpty ? null : trimmed, photoPath: current.photoPath);
  }

  /// Crops to [crop] (default: centered square), resizes to [photoSize] and
  /// re-encodes as JPEG, which drops all metadata (EXIF location included).
  /// Replaces any earlier photo file.
  Future<void> setPhoto(Uint8List bytes, {SquareCrop? crop}) async {
    final decoded = _decode(bytes);
    if (decoded == null) throw const ProfilePhotoRejected();
    final oriented = img.bakeOrientation(decoded);
    final maxSide = oriented.width < oriented.height ? oriented.width : oriented.height;
    final side = (crop?.side ?? maxSide).clamp(1, maxSide);
    final left = (crop?.left ?? (oriented.width - side) ~/ 2).clamp(0, oriented.width - side);
    final top = (crop?.top ?? (oriented.height - side) ~/ 2).clamp(0, oriented.height - side);
    final square = img.copyCrop(oriented, x: left, y: top, width: side, height: side);
    final resized = img.copyResize(square, width: photoSize, height: photoSize, interpolation: img.Interpolation.average);
    resized.exif = img.ExifData();
    final jpeg = img.encodeJpg(resized, quality: 88);

    final dir = Directory('${(await _directory()).path}${Platform.pathSeparator}profile');
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}photo-${_clock().toUtc().microsecondsSinceEpoch}.jpg');
    await file.writeAsBytes(jpeg, flush: true);
    final previous = await load();
    await _write(name: previous.name, photoPath: file.path);
    await _deleteFile(previous.photoPath, except: file.path);
  }

  Future<void> removePhoto() async {
    final current = await load();
    await _write(name: current.name, photoPath: null);
    await _deleteFile(current.photoPath);
  }

  /// Removes the name and the photo.
  Future<void> clear() async {
    final current = await load();
    await (_db.delete(_db.profilePreferences)..where((t) => t.id.equals(1))).go();
    await _deleteFile(current.photoPath);
  }

  img.Image? _decode(Uint8List bytes) {
    try {
      if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return img.decodeJpg(bytes);
      if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return img.decodePng(bytes);
      }
    } on Object {
      return null;
    }
    return null;
  }

  Future<void> _deleteFile(String? path, {String? except}) async {
    if (path == null || path == except) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository(
      ref.watch(databaseProvider),
      directory: getApplicationSupportDirectory,
      clock: ref.watch(clockProvider),
    ));

final profileProvider = StreamProvider<Profile>((ref) => ref.watch(profileRepositoryProvider).watch());
