import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The profile must never reach share payloads, widget snapshots or network
/// code (revamp §6). Enforced structurally: those layers cannot import it.
void main() {
  test('sharing, widget, backend and native code never reference the profile', () {
    final offenders = <String>[];
    for (final root in ['lib/features/sharing', 'lib/features/widgets', 'lib/features/imports', 'lib/integrations']) {
      for (final f in Directory(root).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final src = f.readAsStringSync();
        if (src.contains('profile/') || src.contains('profileProvider') || src.contains('ProfileRepository')) offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('Android native code never reads the profile table or photo', () {
    final offenders = <String>[];
    for (final f in Directory('android/app/src/main').listSync(recursive: true).whereType<File>()
        .where((f) => f.path.endsWith('.kt') || f.path.endsWith('.java'))) {
      final src = f.readAsStringSync();
      if (src.contains('profile_preferences') || src.contains('photo-')) offenders.add(f.path);
    }
    expect(offenders, isEmpty);
  });
}
