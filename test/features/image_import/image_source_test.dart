import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:schediel/features/image_import/data/image_source.dart';
import 'package:schediel/features/image_import/domain/image_services.dart';
import 'package:schediel/features/image_import/domain/image_preparation.dart';
import 'package:schediel/features/image_import/data/local_image_preparer.dart';
import 'package:schediel/features/image_import/data/platform_image_preparer.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();
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
  test('HEIC byte signature dispatches to platform decoder and owns only normalized output', () async {
    final root = await Directory.systemTemp.createTemp('schediel-heic-');
    addTearDown(() => root.delete(recursive: true));
    final bytes = Uint8List.fromList([0, 0, 0, 20, ...'ftypheic'.codeUnits, 0, 0, 0, 0, ...'mif1'.codeUnits]);
    final source = await File('${root.path}/source.wrong-extension').writeAsBytes(bytes);
    var calls = 0;
    final preparer = LocalImageFilePreparer(temporaryDirectory: () async => root, platformNormalizer: (actual, crop, turns) async {
      calls++;
      expect(actual, bytes);
      return normalizeImage(img.encodePng(img.Image(width: 4, height: 3)), crop: crop, quarterTurns: turns);
    });
    final result = await preparer.prepare(source.path, sourceRevision: 2);
    expect(calls, 1);
    expect((result.width, result.height), (4, 3));
    await result.remove();
    expect(await source.readAsBytes(), bytes);
    expect(await File(result.path).exists(), isFalse);
  });

  test('platform decoder failures remain precise and never accept invalid output', () async {
    const channel = MethodChannel('schediel/image_decode');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final bytes = Uint8List.fromList([0, 0, 0, 20, ...'ftypheic'.codeUnits, 0, 0, 0, 0, ...'mif1'.codeUnits]);
    for (final code in ['tooLarge', 'unsupported', 'unreadable']) {
      messenger.setMockMethodCallHandler(channel, (_) async => throw PlatformException(code: code));
      await expectLater(normalizePlatformImage(bytes, null, 0), throwsA(isA<ImageImportFailure>().having((e) => e.code.name, 'code', code)));
    }
    messenger.setMockMethodCallHandler(channel, (_) async => Uint8List(0));
    await expectLater(normalizePlatformImage(bytes, null, 0), throwsA(isA<ImageImportFailure>()));
  });

}
