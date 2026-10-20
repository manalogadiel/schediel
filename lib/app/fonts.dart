import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the bundled display fonts' SIL OFL texts to the licenses page.
/// Safe to call more than once per process only at startup; tests call it
/// directly.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in const [('Inter', 'LICENSE-Inter.txt'), ('Silkscreen', 'LICENSE-Silkscreen.txt'), ('Caveat', 'LICENSE-Caveat.txt')]) {
      yield LicenseEntryWithLineBreaks([family], await rootBundle.loadString('assets/fonts/$file'));
    }
  });
}
