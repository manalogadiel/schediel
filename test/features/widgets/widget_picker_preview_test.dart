import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  test('widget picker has populated scalable content and a legacy image fallback', () {
    const root = 'android/app/src/main/res';
    final info = XmlDocument.parse(File('$root/xml/schedule_widget_info.xml').readAsStringSync()).rootElement;
    final preview = info.getAttribute('android:previewLayout')!;
    expect(preview, isNot(info.getAttribute('android:initialLayout')));
    final layout = XmlDocument.parse(File('$root/layout/${preview.split('/').last}.xml').readAsStringSync());
    final text = layout.findAllElements('TextView').map((e) => e.getAttribute('android:text')).whereType<String>();
    expect(text.length, greaterThanOrEqualTo(6));
    final image = info.getAttribute('android:previewImage');
    expect(image, isNotNull);
    expect(File('$root/drawable-nodpi/${image!.split('/').last}.png').lengthSync(), greaterThan(1000));
  });
}
