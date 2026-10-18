import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/image_source.dart';
import '../data/mlkit_ocr.dart';
import '../domain/image_services.dart';
import 'image_import_controller.dart';

final imageSourcePickerProvider = Provider<ImageSourcePicker>((ref) => SystemImageSourcePicker());
final imagePreparerProvider = Provider<ImageFilePreparer>((ref) => LocalImageFilePreparer());
final onDeviceOcrProvider = Provider<OnDeviceOcr>((ref) => MlKitOnDeviceOcr());
final imageImportControllerProvider = Provider.autoDispose<ImageImportController>((ref) {
  final controller = ImageImportController(picker: ref.watch(imageSourcePickerProvider),
    preparer: ref.watch(imagePreparerProvider), ocr: ref.watch(onDeviceOcrProvider), newId: ref.watch(idGeneratorProvider));
  ref.onDispose(controller.dispose);
  return controller;
});
