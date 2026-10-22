# Schediel

Offline-first Flutter scheduling app for Android and iOS. Repeating schedules, room/professor/subtitle details, Today and Week, categories, native home-screen widgets, optional reminders/alarms, image review and preview-first share links. Eight themes (Lilac, Clay, Pop, Mint, Midnight, Pixel, Sketch, Custom color) and an optional local profile; home-screen widgets can follow the app theme.

**Development build, not release-certified.** Android debug compilation and local automated tests are recorded in [VALIDATION.md](VALIDATION.md). The optional Android sharing service and HTTPS domains were deployed on October 20, 2026; see [VALIDATION.md](VALIDATION.md) for the checks and remaining platform limits. iOS code has not been built on a Mac; the WidgetKit target still requires the documented Xcode setup. Real-device checks remain mandatory.

## Run locally

The Schediel landing page is in [`website/`](website/README.md). It uses vanilla JavaScript and includes its own Vercel configuration. For Vercel imports, set the project root directory to `website`.

Use the Flutter/Dart toolchain compatible with the committed `pubspec.lock` (Dart SDK constraint `^3.13.3`), Android SDK and Java 17. Android minimum is API 26; iOS minimum is 17, with app-owned AlarmKit alarms limited to iOS 26+ and the corresponding SDK.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

Use an Android/iOS device for the app: the mobile plugins and native widgets are not desktop/web implementations. The browser preview in `web-preview/` is a separate read-only site, not a Flutter web build. Test data lives only under test/contract fixtures, never release storage.

Android JVM tests and lint (from `android/`; Windows uses `cmd.exe /c "gradlew.bat ..."`):

```sh
./gradlew :app:testDebugUnitTest :app:lintDebug
```

The pinned `home_widget` plugin currently emits a Kotlin Gradle Plugin deprecation warning. The debug APK is for testing and uses debug signing; production signing, permissions/store eligibility and dependency updates must be reviewed before release. Do not distribute it as a signed production release.

After each minified Android release build, run `python tools/check_release_scanner.py build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`. This checks the APK's actual DEX code for the three ML Kit registrar constructors loaded through reflection; debug and mocked OCR tests cannot catch their removal by R8. Then verify scanning on a device using that release APK.

## Share schedules

Tap **Share → Categories** to choose School, Personal, or other categories from one grouped list. Location, person and subtitle are included by default; Notes stays off unless checked under Details. Only checked schedules and details are shared.

With online sharing configured, **Send link** creates a short HTTPS link and opens Android's share menu. Your friend reviews the schedules in a tall modal, can edit them, and taps **Add selected schedules** to save an independent local copy. Internet is required to create or retrieve an online link; imported copies work offline. Anyone with a forwarded link can view it until expiry or revocation. Downloaded copies cannot be recalled.

**Send offline link** packs the snapshot into the link itself and needs no server or account. These links do not expire and cannot be revoked. In an offline-only build the primary Send link action uses this self-contained format. If a chat app does not make either link tappable, copy the whole message and use **Open shared link**; Schediel offers the copied link automatically.

**Settings → Shared links** has sending/opening shortcuts and online link management when configured. Online creation establishes an anonymous session only when requested; ordinary local use and public link resolution do not create an identity. Losing that session may lose management rights to old links.

## Online sharing configuration

This PC's share and handoff domains are `schediel-share.vercel.app` and `schediel-open.vercel.app`. Both are public production domains with the installed APK's Android signing association. Some messaging apps may retain links in their own browser; the fallback offers an explicit Open action that requests the installed Android app directly. If an embedded browser blocks that action, open the original link in Chrome and tap Open in Schediel there. Recipients need a compatible installed Schediel APK.

Keep these build-time defines absent for offline-only builds. For online builds, put only public configuration in git-ignored `env/sharing.json` (start from `env/sharing.example.json`):

- `SCHEDIEL_SUPABASE_URL`: actual HTTPS Supabase project origin.
- `SCHEDIEL_SUPABASE_KEY`: public publishable key, never a provider/service secret.
- `SCHEDIEL_SHARE_HOST`: primary hostname without a scheme or path.
- `SCHEDIEL_APP_LINK_HOST` (optional): distinct owned handoff hostname.
- `SCHEDIEL_SUPABASE_PROJECT_REF` and `SCHEDIEL_VERCEL_PROJECT`: deployment identifiers used by the script.

For a new environment, sign the Supabase and Vercel CLIs into the intended accounts, enable **Authentication → Sign In / Providers → Allow anonymous sign-ins**, and download the public database certificate from **Database → Settings → SSL configuration**. Keep private credentials in platform secret storage, never app configuration, Git or chat.

Keep this PC's existing debug signing key for in-place updates. Use `apksigner verify --print-certs` on the APK and set `$apkCertificateSha256` to its actual colon-separated SHA-256 certificate fingerprint; this fingerprint is public and requires no new key or keystore password.

```powershell
powershell -ExecutionPolicy Bypass -File tools\deploy_sharing.ps1 -DatabaseCaPath $HOME\Downloads\prod-ca-2021.crt -AndroidCertSha256 $apkCertificateSha256
flutter build apk --release --split-per-abi --dart-define-from-file=env/sharing.json
adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

The script applies migrations, configures server secrets without showing values, deploys functions, probes unknown-link rejection, and publishes the browser fallback and association files. The current CLI can use a temporary database login role. A second host is attached as a public production domain; preview deployment protection stays enabled. Both association URLs must return JSON without authentication or redirects.

A resolver 503 stops deployment. Verify the database certificate and ingress policy before changing the trusted address header. On this project, `cf-connecting-ip` was verified: forged values are rejected and spoofed alternative headers do not change the rate-limit identity. Re-runs can use `-SkipDatabase`, `-SkipSecrets`, `-SkipFunctions` or `-SkipWeb` for completed stages.

Compact links use `/s/#` followed by the full 256-bit random capability. Legacy `/s/{shareId}#token=...` links remain readable. The backend stores selected snapshots and secret digests, never the raw token or all local schedules. Deletion retains only a minimal capability reservation so an old link cannot point to a replacement. Expiry choices are one or seven days. Cloud image scanning remains disabled.

- [Backend setup and live verification](backend/README.md)
- [Browser fallback and hosting](web-preview/README.md)
- [API transport](contracts/openapi.yaml)

## Themes, profile and widgets

Settings → Appearance switches the theme at once; Custom color has one hue slider and is contrast-checked. Settings → Profile holds an optional name and photo, stored only on the device. Pixel and Sketch use two bundled display fonts (Silkscreen, Caveat; SIL Open Font License, see `assets/fonts/`) for headings only.

To place the widget on Android: open the app once, long-press the home screen → Widgets → Schediel → Schedules. Per-widget settings, including **Use app theme**, are under Settings → Home screen widgets. The widget sits on your wallpaper; it never replaces it.

Expanded widgets fit up to four schedule cards to the space available; Compact shows up to two. All four styles offer title/time-only cards before omitting schedules, then restore all-day captions and optional details when there is room. Very small widgets show **Open Schediel** instead of clipping a card. Large text keeps its size and hides optional details first.

**Settings → Open source licenses** starts with short credits. Tap a font or icon name for its complete notice, or **All library licenses** for the full dependency list.

The themed widget layouts and shapes are generated; after editing `tools/gen_widget_layouts.py` run:

```sh
python3 tools/gen_widget_layouts.py            # writes android/app/src/main/res/{layout,drawable,font}
python3 tools/gen_widget_layouts.py --check    # also run by flutter test
python tools/check_widget_contracts.py         # needs the jsonschema package
UPDATE_FIXTURES=1 flutter test test/contracts/widget_snapshot_v1_1_fixture_test.dart   # after changing palettes
```

## Image import

Gallery/camera selection is explicit. Still JPEG, PNG, WebP, GIF, BMP and single-page TIFF images are accepted by their actual bytes. HEIC/HEIF and AVIF use local codecs on supported Android devices (Android 9+; codec availability varies). Animated/multi-page files, SVGs and PDFs are rejected explicitly. Metadata removal, a white background for transparent images, crop/rotation and bounded normalization precede on-device OCR. Extracted fields remain inactive drafts; unknown year, date order, AM/PM, time zone, semester bounds and row associations must be resolved, not guessed. Selected entries remain editable before one explicit local import transaction. Notifications and alarms start off.

This conservative parser does not claim to understand every timetable or every script. Dense/unsupported content must be cropped or entered manually. Camera/gallery/OCR behavior, memory and accuracy need mobile-device testing. **Cloud AI scanning is disabled**; there is no upload fallback or provider key in the app.

University tables with **Code, Description, Units, Section, Instructor, Schedules** headers have a dedicated local parser. Description becomes Title, Instructor becomes Professor and Code becomes Subtitle; Notes stays blank. Different day/time/room combinations become separate weekly schedules. Choose **One time** or **Weekly**. One time adds each meeting once on its next matching weekday from your starting date; Weekly uses your term start/end dates. Tap a date field to select it from a calendar; tap the month/year heading to choose another year, then press **Done**. Date labels stay above the controls and no date-format typing is required. Cancel keeps existing values, and an end date cannot be chosen before the selected start. You can change dates or repeats for an individual class in Resolve fields. Confirm the school time zone and check the class details, then tap the always-visible **Continue to review** button. It applies the chosen class dates without requiring a separate Apply tap; date choices survive scrolling through long scans. Missing values show beside Continue with a **Fix first entry** action when an individual schedule needs attention. In review, **Category for selected schedules** assigns School, Personal, another existing category, or Uncategorized to all checked entries at once; university classes start in School. Unchecked entries keep their category, and individual category edits remain available. Only **Add selected schedules** saves anything. Missing headers or ambiguous row structure fall back to unresolved review rather than borrowing another course's fields.

Scanned start and end times in **Resolve fields** use clock-wheel selectors with Done and Cancel, rather than typed HH:mm fields. They follow the device's 12/24-hour setting. Missing times stay blank until confirmed; cancelling or accepting the same time preserves the draft. No end time and explicit next-day endings remain available.

## Release signing

Personal updates on this PC keep the existing debug key. Release builds read git-ignored `android/key.properties` when present; without it they use that debug key. No release key is needed for this sharing setup or its verified Android links.

A new signing key cannot update the currently installed app. Preserve the existing key and never uninstall as part of this setup, because uninstalling removes local schedules. A future store-distribution signing migration requires its own reviewed plan.

## Native limits and privacy

- Widgets read committed snapshots; no wallpaper replacement, wallpaper access or screenshot transparency tricks. Clear rendering/readability and refresh opportunities differ by OS/launcher. Solid/stronger alternatives exist, but arbitrary wallpaper contrast is not certified.
- Reminders, app-owned alarms and Android Clock hand-off are distinct. Native acceptance is not a delivery guarantee. Permission denial, capacity/horizon, reboot, force-stop and locked-screen behavior need device verification.
- [iOS WidgetKit/AlarmKit setup](ios/ScheduleWidget/README.md) requires Mac/Xcode, App Groups, signing and an actual widget extension target. iOS is source-only here, not a verified build.
- SQLite schedule data is local but **not encrypted by Schediel** and not backed by a recovery account. Platform/device backup behavior is not a tested recovery policy. Share secrets/session storage use the protected storage adapter; reinstall/session loss remains a limitation.
- Delete local schedules, remove an image source, revoke a link and delete backend snapshots are separate actions with different scopes. Backend deletion reads an actual job state and preserves local schedules.

## Specifications

- [SCHEDULER_SPEC.md](SCHEDULER_SPEC.md): scope, behavior, traceability and release gates.
- [DESIGN.md](DESIGN.md): minimal Apple-inspired tokens, themes, accessibility and motion requirements.
- [CONTRACTS.md](CONTRACTS.md): domain and integration contracts; machine artifacts in `contracts/` are authoritative.
- [SOURCES.md](SOURCES.md): primary-source register and limits of its claims.
- [VALIDATION.md](VALIDATION.md): executed checks and unverified behavior.
- [FULL_SPEC.md](FULL_SPEC.md): generated readable edition of those documents.

```sh
python3 tools/spec_bundle.py
python3 tools/spec_bundle.py --check
npx -y -p @google/design.md@0.4.0 designmd lint DESIGN.md
```

Documentation hashes in `CHECKSUMS.sha256` use LF-canonical UTF-8 bytes. The script verifies the 24 requirement IDs, 48 acceptance IDs, 35-source registry, links and main anchors, then rebuilds the readable edition and hashes. These structural checks do not certify native behavior or AI interpretation.
