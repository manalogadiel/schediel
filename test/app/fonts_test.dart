import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled display fonts load from assets', () async {
    for (final path in ['assets/fonts/Silkscreen-Regular.ttf', 'assets/fonts/Silkscreen-Bold.ttf', 'assets/fonts/Caveat-Variable.ttf']) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(10000), reason: path);
    }
  });

  test('font licenses are registered for the licenses page', () async {
    registerFontLicenses();
    final packages = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
      final text = entry.paragraphs.map((p) => p.text).join('\n');
      if (entry.packages.contains('Silkscreen') || entry.packages.contains('Caveat')) {
        expect(text, contains('SIL OPEN FONT LICENSE'));
      }
    }
    expect(packages, containsAll(['Silkscreen', 'Caveat']));
  });
}
