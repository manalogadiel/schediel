import 'dart:io';

import '../data/local_image_preparer.dart';
import 'ocr_document.dart';

enum ImagePickKind { gallery, camera }

abstract interface class ImageSourcePicker {
  Future<String?> pick(ImagePickKind kind);
}

abstract interface class ImageFilePreparer {
  Future<PreparedImageFile> prepare(String path, {required int sourceRevision, PixelCrop? crop, int quarterTurns = 0});
}

class PreparedImageFile {
  const PreparedImageFile({required this.path, required this.width, required this.height, required this.sourceRevision, this.ownedDirectory});
  final String path;
  final int width, height, sourceRevision;
  final Directory? ownedDirectory;
  Future<void> remove() async {
    if (ownedDirectory != null && await ownedDirectory!.exists()) await ownedDirectory!.delete(recursive: true);
  }
}

abstract interface class OnDeviceOcr {
  Future<OcrDocument> recognize(PreparedImageFile image);
}
