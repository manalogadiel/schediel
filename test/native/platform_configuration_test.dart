import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('Android production manifest declares network access and plugin-owned verified links', () {
    final manifest=File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest,contains('android.permission.INTERNET'));
    expect(manifest,contains('android:name="flutter_deeplinking_enabled" android:value="false"'));
    expect(manifest,contains('android:autoVerify="true"'));
    expect(manifest,contains(r'android:host="${shareHost}"'));
    expect(manifest,contains(r'android:host="${appLinkHost}"'));
    final gradle=File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle,contains('schediel.appLinkHost'));
    expect(gradle,contains('manifestPlaceholders["appLinkHost"]'));
    // Unset, the hand-off host repeats the share host: an unresolvable extra
    // autoVerify host would break verification on Android 11 and lower.
    expect(gradle,contains('?: shareHost'));
    expect(gradle,isNot(contains('app.schediel.invalid')));
    expect(manifest,contains('android:pathPrefix="/s/"'));
    expect(manifest,contains('android:scheme="schediel"'));
  });
  test('iOS widget reader accepts snapshot 1.1 (theme ignored) and still rejects others', () {
    final swift=File('ios/ScheduleWidget/ScheduleWidget.swift').readAsStringSync();
    expect(swift,contains('["1.0", "1.1"].contains(version)'));
    expect(swift,isNot(contains('== "1.0"')));
  });
  test('themed widget layouts and shapes are generated and current', () {
    final result=Process.runSync('python3',['tools/gen_widget_layouts.py','--check']);
    expect(result.exitCode,0,reason:'${result.stdout}${result.stderr}');
    for (final style in ['soft','pop','pixel','sketch']) {
      final xml=File('android/app/src/main/res/layout/widget_schedule_$style.xml').readAsStringSync();
      expect(xml,contains('android:background="@android:color/transparent"'),reason:style);
      for (var i=0;i<4;i++) {
        expect(xml,contains('@+id/holder_${i}_fill'),reason:style);
      }
    }
    expect(File('android/app/src/main/res/layout/widget_schedule_pixel.xml').readAsStringSync(),contains('@font/silkscreen'));
    // Launchers ignore app fonts in RemoteViews: bundled-font titles also have a bitmap view.
    for (final style in ['pixel','sketch']) {
      expect(File('android/app/src/main/res/layout/widget_schedule_$style.xml').readAsStringSync(),contains('holder_3_title_image'),reason:style);
    }
    for (final style in ['soft','pop']) {
      expect(File('android/app/src/main/res/layout/widget_schedule_$style.xml').readAsStringSync(),isNot(contains('title_image')),reason:style);
    }
    expect(File('android/app/src/main/res/layout/widget_schedule_sketch.xml').readAsStringSync(),contains('@font/caveat_variable'));
  });
  test('iOS alarm status source reads native pending alarms rather than cached requests', () {
    final swift=File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(swift,contains('try AlarmManager.shared.alarms'));
    expect(swift,contains('alarm_query_failed'));
    expect(swift,contains('cancelFailed'));
  });
  test('iOS image permission copy and plugin deep-link opt out are present', () {
    final plist=File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist,contains('<key>NSCameraUsageDescription</key>'));
    expect(plist,contains('<key>NSPhotoLibraryUsageDescription</key>'));
    expect(plist,contains('<key>FlutterDeepLinkingEnabled</key>'));
  });
}
