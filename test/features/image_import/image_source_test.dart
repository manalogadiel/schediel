import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:schediel/features/image_import/data/image_source.dart';
import 'package:schediel/features/image_import/domain/image_services.dart';
import 'package:schediel/features/image_import/domain/image_preparation.dart';

class PickerProbe extends ImagePicker {
  int calls = 0;
  ImageSource? source;
  bool? fullMetadata;
  @override
  Future<XFile?> pickImage({required ImageSource source, double? maxWidth, double? maxHeight, int? imageQuality, CameraDevice preferredCameraDevice = CameraDevice.rear, bool requestFullMetadata = true}) async {
    calls++;
    this.source = source;
    fullMetadata = requestFullMetadata;
    return null;
  }
}

void main() {
  test('system picker is invoked only by action, handles cancel and avoids full metadata request', () async {
    final probe = PickerProbe();
    final picker = SystemImageSourcePicker(picker: probe);
    expect(probe.calls, 0);
    expect(await picker.pick(ImagePickKind.gallery), isNull);
    expect(probe.source, ImageSource.gallery);
    expect(probe.fullMetadata, isFalse);
    expect(await picker.pick(ImagePickKind.camera), isNull);
    expect(probe.source, ImageSource.camera);
    expect(probe.calls, 2);
  });

  test('file preparation owns only normalized temporary output and bounds file reads', () async {
    final root = await Directory.systemTemp.createTemp('schediel-prepare-');
    addTearDown(() => root.delete(recursive: true));
    final original = await File('${root.path}/user-photo.not-a-png-extension').writeAsBytes(img.encodePng(img.Image(width: 4, height: 3)));
    final preparer = LocalImageFilePreparer(temporaryDirectory: () async => root);
    final result = await preparer.prepare(original.path, sourceRevision: 12);
    expect((result.width, result.height, result.sourceRevision), (4, 3, 12));
    expect(File(result.path).existsSync(), isTrue);
    expect(result.path, isNot(original.path));
    await result.remove();
    expect(File(result.path).existsSync(), isFalse);
    expect(await original.exists(), isTrue);
    final handle = await File('${root.path}/oversize.png').open(mode: FileMode.write);
    await handle.truncate(10 * 1024 * 1024 + 1);
    await handle.close();
    await expectLater(preparer.prepare('${root.path}/oversize.png', sourceRevision: 13),
      throwsA(isA<ImageImportFailure>().having((e) => e.code, 'code', ImageFailureCode.tooLarge)));
  });
}
