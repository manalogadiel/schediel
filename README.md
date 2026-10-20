# Schediel

Offline-first Flutter scheduling app for Android and iOS. Repeating schedules, room/professor/subtitle details, Today and Week, categories, native home-screen widgets, optional reminders/alarms, image review and preview-first share links. Eight themes (Lilac, Clay, Pop, Mint, Midnight, Pixel, Sketch, Custom color) and an optional local profile; home-screen widgets can follow the app theme.

**Development build, not release-certified.** Android debug compilation and local automated tests are recorded in [VALIDATION.md](VALIDATION.md). No backend or share domain is deployed. iOS code has not been built on a Mac; the WidgetKit target still requires the documented Xcode setup. Real-device checks remain mandatory.

## Run locally

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

## Send link — offline sharing

Tap **Share**, choose **School**, **Personal**, or any other categories, then tap **Send link**. Only the checked schedules and optional details you select go into the link. Android's share menu lets you send it through your messaging app; no server or account is needed.

The recipient opens the link in Schediel and reviews it before confirming the import. If a chat app does not make the link tappable, copy the whole message and use **Open shared link**; Schediel offers the copied link automatically. **Settings → Shared links** has shortcuts for sending and opening these links. Sent links contain independent copies, do not expire, and cannot be revoked.

## Link sharing — optional deployment

Keep these build-time defines absent for offline sharing; **Send link** and copied-message review work without them. When the approved Supabase backend and owned domain are ready:

- `SCHEDIEL_SUPABASE_URL`: actual HTTPS Supabase project origin.
- `SCHEDIEL_SUPABASE_KEY`: public project publishable key, never a service/provider secret.
- `SCHEDIEL_SHARE_HOST`: hostname only, without `https://` or a path.
- `SCHEDIEL_APP_LINK_HOST` (optional): a second owned hostname, different from the share host, that the browser preview's **Open in Schediel** button hands off to. Set the Gradle property `schediel.appLinkHost` to the same value.

Put them in `env/sharing.json` (git-ignored; copy `env/sharing.example.json`) and build with `--dart-define-from-file=env/sharing.json`. Android reads the App Link host from the same file; the Gradle properties `schediel.shareHost` / `schediel.appLinkHost` override it, and without either the host is deliberately `schediel.invalid`. Configure real signing associations and iOS Associated Domains on the owned host before claiming verified links.

### Online sharing setup (Supabase + Vercel)

Account steps (only you can do these):

1. Create the release key first (see [Release signing](#release-signing)); App Links are verified against it.
2. Create a free project at [supabase.com](https://supabase.com) (region: Southeast Asia (Singapore)). Save the database password in a password manager.
3. In the project: **Authentication → Sign In / Providers → Allow anonymous sign-ins** → on → Save.
4. **Project Settings → API Keys**: copy the **publishable** key (`sb_publishable_…`). Never copy the secret key anywhere.
5. **Database → Settings → SSL Configuration → Download certificate** (saves `prod-ca-2021.crt`).
6. Create a free account at [vercel.com](https://vercel.com) and pick a project name (lowercase, e.g. `schediel-share`). The page will live at `https://<name>.vercel.app`.
7. In this repo's terminal (Node 22+): `npx supabase login` and `npx vercel login`; each opens the browser once.

Then:

```powershell
copy env\sharing.example.json env\sharing.json   # fill in the five values
powershell -ExecutionPolicy Bypass -File tools\deploy_sharing.ps1 -DatabaseCaPath $HOME\Downloads\prod-ca-2021.crt
flutter build apk --release --split-per-abi --dart-define-from-file=env/sharing.json
adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

The script links the project and asks for the database password, pushes the migration, sets the function secrets (it generates the rate-limit key and never prints it), deploys the five functions, checks that an unknown link gives 404, then builds the share page with `assetlinks.json` from your release key and deploys it to Vercel. Re-run any part with `-SkipDatabase`, `-SkipSecrets`, `-SkipFunctions` or `-SkipWeb`. If the resolve check reports 503, follow its hint (certificate or `-IpHeader x-forwarded-for`). If Vercel gives the project a different domain than `<name>.vercel.app`, put that domain in `SCHEDIEL_SHARE_HOST` and run again with `-SkipDatabase -SkipFunctions`.

On the phone: create a link → open it (it should open Schediel, not the browser) → review → confirm adds; revoke it → reopening says the link was revoked; in airplane mode **Create link** reports an error and **Send link** still works.

The backend stores only the selected snapshot and the secret's digest; it is not a sync database for all local schedules. The device retains the random bearer secret in platform-protected storage. An anonymous online identity is created only for explicit share creation; ordinary local use and public link resolution do not create an identity. Anyone with a link can view it until expiry/revocation. Recipient imports are independent copies; revocation cannot recall downloaded copies. Losing the online identity/session can lose management of old links.

- [Backend setup, tests and deployment gates](backend/README.md)
- [Static browser-preview setup and hosting](web-preview/README.md)
- [Frozen API transport](contracts/openapi.yaml)

No real project, domain, certificate fingerprint, Apple team ID, region, credentials or recovery promise is fabricated in this repository. A local test pass is not production security approval.

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

Gallery/camera selection is explicit. JPEG/PNG admission, metadata removal, crop/rotation and bounded normalization precede on-device OCR. Extracted fields remain inactive drafts; unknown year, date order, AM/PM, time zone, semester bounds and row associations must be resolved, not guessed. Selected entries remain editable before one explicit local import transaction. Notifications and alarms start off.

This conservative parser does not claim to understand every timetable or every script. Dense/unsupported content must be cropped or entered manually. Camera/gallery/OCR behavior, memory and accuracy need mobile-device testing. **Cloud AI scanning is disabled**; there is no upload fallback or provider key in the app.

## Release signing

Release builds read `android/key.properties` (git-ignored) when present. Without it they fall back to the debug key and Gradle prints a `WARNING` saying so; if `key.properties` names a keystore that does not exist, the build stops. A relative `storeFile` is read from `android/`.

1. Create an upload key once and keep the passwords private:
   `keytool -genkey -v -keystore %USERPROFILE%\schediel-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Create `android/key.properties`:
   ```
   storeFile=C:/Users/<you>/schediel-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```
3. `flutter build apk --release --split-per-abi` (phones: `app-arm64-v8a-release.apk`).

A build signed with a new key cannot update one signed with the debug key: send your schedules to yourself with **Send link**, uninstall, install the release build, then open the link to re-import.

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
