// Local diagnostic only. Temporarily bundle an image as
// assets/illustrations/scan_probe_input.png (never commit that image), build
// this entry point in profile mode with a version >= the installed version,
// and capture only SCAN_PROBE records from adb logcat to an ignored local file.
// Restore the normal release APK with adb install -r afterward; never uninstall.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:schediel/features/image_import/data/image_source.dart';
import 'package:schediel/features/image_import/data/mlkit_ocr.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Checking the timetable scanner…')))));
  final directory = await Directory('${(await getTemporaryDirectory()).path}/scan-probe').create();
  final source = File('${directory.path}/source.png');
  final bytes = await rootBundle.load('assets/illustrations/scan_probe_input.png');
  var input = bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
  const scale = int.fromEnvironment('SCHEDIEL_OCR_PROBE_SCALE', defaultValue: 1);
  if (scale == 2) {
    input = await Isolate.run(() {
      final decoded = img.decodeImage(input)!;
      return img.encodePng(img.copyResize(decoded, width: decoded.width * 2,
        height: decoded.height * 2, interpolation: img.Interpolation.cubic));
    });
  }
  await source.writeAsBytes(input);
  final prepared = await LocalImageFilePreparer().prepare(source.path, sourceRevision: 1);
  try {
    final document = await MlKitOnDeviceOcr().recognize(prepared);
    final data = jsonEncode({'width': document.width, 'height': document.height,
      'text': document.text, 'lines': [for (final line in document.lines) {
        'text': line.text, 'start': line.start, 'blockId': line.blockId,
        if (line.region case final region?) 'region': {
          'left': region.left, 'top': region.top, 'right': region.right, 'bottom': region.bottom},
        'glyphs': [for (final glyph in line.glyphs) {'text': glyph.text, 'left': glyph.region.left,
          'top': glyph.region.top, 'right': glyph.region.right, 'bottom': glyph.region.bottom}],
      }]});
    final encoded = base64Encode(utf8.encode(data));
    for (var i = 0; i < encoded.length; i += 800) {
      // Local diagnostic contains the chosen image's OCR; never upload it.
      // ignore: avoid_print
      print('SCAN_PROBE ${encoded.substring(i, (i + 800).clamp(0, encoded.length))}');
    }
    // ignore: avoid_print
    print('SCAN_PROBE_DONE');
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Scanner check complete')))));
  } finally {
    await prepared.remove();
    await directory.delete(recursive: true);
  }
}
