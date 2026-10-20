import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/image_preparation.dart';
import '../domain/image_services.dart';
import 'local_image_preparer.dart';
import 'platform_image_preparer.dart';

class SystemImageSourcePicker implements ImageSourcePicker {
  SystemImageSourcePicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  @override
  Future<String?> pick(ImagePickKind kind) async {
    try {
      final file = await _picker.pickImage(source: kind == ImagePickKind.camera ? ImageSource.camera : ImageSource.gallery,
        requestFullMetadata: false);
      return file?.path;
    } on PlatformException catch (e) {
      if (const ['camera_access_denied', 'photo_access_denied', 'camera_access_restricted', 'photo_access_restricted'].contains(e.code)) {
        throw const ImageImportFailure(ImageFailureCode.permissionDenied);
      }
      throw const ImageImportFailure(ImageFailureCode.unreadable);
    }
  }
}

class LocalImageFilePreparer implements ImageFilePreparer {
  LocalImageFilePreparer({Future<Directory> Function()? temporaryDirectory,
    Future<PreparedImage> Function(Uint8List, PixelCrop?, int)? platformNormalizer})
      : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
        _platformNormalizer = platformNormalizer ?? normalizePlatformImage;
  final Future<Directory> Function() _temporaryDirectory;
  final Future<PreparedImage> Function(Uint8List, PixelCrop?, int) _platformNormalizer;
  @override
  Future<PreparedImageFile> prepare(String path, {required int sourceRevision, PixelCrop? crop, int quarterTurns = 0}) async {
    Directory? owned;
    try {
      final file = File(path);
      if (await file.length() > ImageImportLimits.sourceBytes) throw const ImageImportFailure(ImageFailureCode.tooLarge);
      final builder = BytesBuilder(copy: false);
      // A bounded stream handles a source that changes after stat, too.
      await for (final chunk in file.openRead(0, ImageImportLimits.sourceBytes + 1)) {
        if (builder.length + chunk.length > ImageImportLimits.sourceBytes) throw const ImageImportFailure(ImageFailureCode.tooLarge);
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      final normalized = ImageAdmission.needsPlatformDecoder(bytes)
          ? await _platformNormalizer(bytes, crop, quarterTurns)
          : await normalizeImage(bytes, crop: crop, quarterTurns: quarterTurns);
      owned = await (await _temporaryDirectory()).createTemp('schediel-image-');
      final output = await File('${owned.path}/normalized.png').writeAsBytes(normalized.bytes, flush: true);
      return PreparedImageFile(path: output.path, width: normalized.width, height: normalized.height,
        sourceRevision: sourceRevision, ownedDirectory: owned);
    } on ImageImportFailure {
      if (owned != null && await owned.exists()) await owned.delete(recursive: true);
      rethrow;
    } catch (_) {
      if (owned != null && await owned.exists()) await owned.delete(recursive: true);
      throw const ImageImportFailure(ImageFailureCode.unreadable);
    }
  }
}
