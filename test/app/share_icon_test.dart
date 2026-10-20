import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/icons.dart';

void main() {
  test('share uses the original arrow-out-of-tray SVG, not connected nodes', () {
    expect(AppIcons.share.asset, 'assets/icons/share-out.svg');
    final svg = File(AppIcons.share.asset).readAsStringSync();
    expect(svg, contains('viewBox="0 0 24 24"'));
    expect(svg, contains('<path'));
    expect(svg, isNot(contains('<circle')));
  });
}
