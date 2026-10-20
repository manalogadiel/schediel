import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:schediel/features/image_import/data/local_image_preparer.dart';
import 'package:schediel/features/image_import/data/mlkit_ocr.dart';
import 'package:schediel/features/image_import/domain/conservative_parser.dart';
import 'package:schediel/features/image_import/domain/image_services.dart';
import 'package:schediel/features/image_import/domain/image_preparation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('google_mlkit_text_recognizer');
  late Directory dir;
  late PreparedImageFile source;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('schediel-ocr-');
    final image = await normalizeImage(img.encodePng(img.Image(width: 200, height: 100)));
    final file = await File('${dir.path}/normalized.png').writeAsBytes(image.bytes);
    source = PreparedImageFile(path: file.path, width: image.width, height: image.height, sourceRevision: 4, ownedDirectory: dir);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await source.remove();
  });
  test('real normalization + native adapter mock + parser retain validated evidence and close', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'vision#closeTextRecognizer') return null;
      expect(((call.arguments as Map)['imageData'] as Map)['path'], source.path);
      return {'text': 'Exam | 2027-03-05 | 1 PM', 'blocks': [
        {'text': 'Exam | 2027-03-05 | 1 PM', 'rect': {'left': 10.0, 'top': 20.0, 'right': 190.0, 'bottom': 50.0}, 'recognizedLanguages': <String>[], 'points': <Object>[], 'lines': [
          {'text': 'Exam | 2027-03-05 | 1 PM', 'rect': {'left': 10.0, 'top': 20.0, 'right': 190.0, 'bottom': 50.0}, 'recognizedLanguages': <String>[], 'points': <Object>[], 'elements': <Object>[]}
        ]}
      ]};
    });
    final document = await MlKitOnDeviceOcr(isSupported: () => true).recognize(source);
    final candidate = ConservativeCandidateParser().parse(document).candidates.single;
    expect(candidate.date.region!.left, 0.05);
    expect(candidate.date.region!.top, 0.2);
    expect(candidate.date.region!.sourceRevision, 4);
    expect(document.text.substring(candidate.date.span!.start, candidate.date.span!.end), '2027-03-05');
    expect(calls, ['vision#startTextRecognizer', 'vision#closeTextRecognizer']);
  });
  test('missing optional native rectangles do not discard recognized text', () async {
    var closed = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'vision#closeTextRecognizer') { closed = true; return null; }
      Map<String, Object?> node(String text, Object? rect) => {
        'text': text, 'rect': rect, 'points': <Object>[], 'recognizedLanguages': <String>[],
      };
      return {'text': 'Exam | 2027-03-05 | 1 PM', 'blocks': [
        {...node('Exam | 2027-03-05 | 1 PM', null), 'lines': [
          {...node('Exam | 2027-03-05 | 1 PM', {'left': 10, 'top': 20, 'right': 190, 'bottom': 50}), 'elements': [
            {...node('Exam', null), 'symbols': [node('E', null)]}
          ]},
          {...node('optional unlocated text', null), 'elements': <Object>[]}
        ]}
      ]};
    });
    final document = await MlKitOnDeviceOcr(isSupported: () => true).recognize(source);
    final candidate = ConservativeCandidateParser().parse(document).candidates.single;
    expect(candidate.title.value, 'Exam');
    expect(candidate.title.region, isNotNull);
    expect(document.lines.last.region, isNull);
    expect(document.lines.first.glyphs, isEmpty);
    expect(closed, isTrue);
  });

  test('recognizer closes after a native failure and a retry can succeed', () async {
    var closes = 0, attempts = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'vision#closeTextRecognizer') { closes++; return null; }
      if (++attempts == 1) throw PlatformException(code: 'TextRecognizerError');
      return {'text': 'Exam | 2027-03-05 | 1 PM', 'blocks': <Object>[]};
    });
    final adapter = MlKitOnDeviceOcr(isSupported: () => true);
    await expectLater(adapter.recognize(source), throwsA(isA<ImageImportFailure>()));
    expect(closes, 1);
    expect((await adapter.recognize(source)).text, contains('Exam'));
    expect(closes, 2);
  });

}
