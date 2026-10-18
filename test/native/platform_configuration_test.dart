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
