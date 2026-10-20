# Handoff: finish online sharing, build and install

For the coding agent running **on the owner's Windows PC** (PowerShell). Everything here must run locally: the owner's Supabase/Vercel logins, release keystore and phone are on this machine.

## Read first (in this order)

1. `README.md`: sections **Online sharing setup (Supabase + Vercel)**, **Link sharing**, **Release signing**.
2. `tools/deploy_sharing.ps1`: the deploy script (read it fully before running it).
3. `env/sharing.example.json`: the settings file shape.
4. `backend/README.md`: backend env vars, deployment gates, security rules.
5. `web-preview/README.md`: share page build and hosting.
6. `docs/superpowers/plans/2026-10-21-review-fixes-and-sharing-backend.md`: **Task 8** is this work (Tasks 1–7 are done).
7. `lib/features/sharing/application/sharing_config.dart`: the app's build-time defines.
8. Only if debugging the API: `contracts/openapi.yaml`, `backend/supabase/functions/_shared/runtime.ts`.

## Current state

- Branch: `feat/motion-texture-polish-t0xl4w` (pushed). All UI review fixes are done; Flutter (356), backend (79) and web-preview (136) tests passed in CI-like runs. Not yet done: an Android compile of the latest Kotlin change (`WidgetRenderer.kt` title-bitmap reuse) and `:app:testDebugUnitTest`.
- Supabase project exists: ref `rjxhoxedxptpqcivcszj`, URL `https://rjxhoxedxptpqcivcszj.supabase.co`, region Singapore, Data API off. Nothing is deployed to it yet.
- Vercel project name wanted: `schediel` (share page at `https://schediel.vercel.app`). Not created yet.
- **The owner's local clone may be mid-merge**: a `git pull` opened Vim and the window was closed. Fix that first (step 0).

## Rules

- Never commit, print or paste: the database password, `sb_secret_…`/service keys, `SCHEDIEL_RATE_HASH_SECRET`, keystore passwords, `android/key.properties`, `*.jks`, `env/sharing.json`. Before any commit run `git diff --cached` and check for `sb_secret`, `postgres://`, `password`.
- The owner types the database password and keystore passwords themselves when a prompt asks; do not ask for them in chat.
- Do not expose the `schediel_private` schema in the Data API. Do not remove the in-function auth verifier or set `verify_jwt` to true.
- Do not skip or weaken tests to get green.

## Steps

### 0. Repair the local clone
```powershell
cd <the schediel folder>
git config --global core.editor notepad
git status
```
If it says "All conflicts fixed but you are still merging" or shows a merge in progress: `git commit --no-edit`. If there are conflicts, stop and show them to the owner. Then `git pull origin feat/motion-texture-polish-t0xl4w` and confirm `git log --oneline -5` contains `feat: one-command online sharing setup (Supabase + Vercel)`.

Then build checks the cloud could not run:
```powershell
flutter pub get
flutter analyze
flutter test
cd android; .\gradlew :app:testDebugUnitTest; cd ..
```

### 1. Release key (skip if `android\key.properties` already exists)
Owner runs (chooses the password):
```powershell
keytool -genkey -v -keystore $HOME\schediel-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Create `android\key.properties` (git-ignored):
```
storeFile=C:/Users/<user>/schediel-upload.jks
storePassword=<owner types>
keyAlias=upload
keyPassword=<owner types>
```
Tell the owner to back up the `.jks` and password; losing them means the app can never be updated.

### 2. Settings file
Create `env\sharing.json` (git-ignored):
```json
{
  "SCHEDIEL_SUPABASE_URL": "https://rjxhoxedxptpqcivcszj.supabase.co",
  "SCHEDIEL_SUPABASE_KEY": "sb_publishable_gyk0GoDrmFj2anlApk7CwQ_P_Yisq6T",
  "SCHEDIEL_SHARE_HOST": "schediel.vercel.app",
  "SCHEDIEL_SUPABASE_PROJECT_REF": "rjxhoxedxptpqcivcszj",
  "SCHEDIEL_VERCEL_PROJECT": "schediel"
}
```

### 3. Owner's dashboard clicks (ask the owner to do these)
- Supabase → **Authentication → Sign In / Providers → Allow anonymous sign-ins** → on → Save.
- Supabase → **Database settings → SSL Configuration → Download certificate** (`prod-ca-2021.crt`, usually in Downloads).
- Terminal: `npx supabase login` and `npx vercel login` (each opens the browser; owner clicks Authorize).

### 4. Deploy
```powershell
powershell -ExecutionPolicy Bypass -File tools\deploy_sharing.ps1 -DatabaseCaPath $HOME\Downloads\prod-ca-2021.crt
```
The owner types the database password when `supabase link` asks. Expected at the end: `health: 200`, `share-resolve: 404 for an unknown link`, and both `https://schediel.vercel.app/s/` and `/.well-known/assetlinks.json` return 200.

Known uncertainties (untested against the live project) and fixes:
- **`share-resolve: 503`** → either TLS to the database or the client-IP header. Check `npx supabase functions logs share-resolve --project-ref rjxhoxedxptpqcivcszj` if available, or test: rerun with `-SkipDatabase -SkipFunctions -SkipWeb -IpHeader x-forwarded-for`. If Supabase sends a comma-separated `x-forwarded-for`, the backend deliberately rejects lists; report to the owner rather than loosening it silently.
- **`supabase functions deploy` rejects several names or `--use-api`** (CLI version) → deploy each function separately: `npx supabase functions deploy <name> --project-ref rjxhoxedxptpqcivcszj --use-api`, or without `--use-api` if Docker Desktop is running.
- **Vercel gives a different domain** (name taken) → put that domain in `SCHEDIEL_SHARE_HOST`, rerun with `-SkipDatabase -SkipFunctions`. The app must be rebuilt afterwards (host is compiled in).
- **`vercel link --project` fails because the project does not exist** → `npx vercel project add schediel` then retry.
- `vercel.json` in `web-preview/dist` is generated; do not hand-edit it, change `web-preview/scripts/configure.mjs` (and its test) instead.

### 5. Build and install
Phone connected by USB with USB debugging on (`adb devices` lists it):
```powershell
flutter build apk --release --split-per-abi --dart-define-from-file=env/sharing.json
adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```
If install fails with a signature mismatch (old build used the debug key): have the owner open the old app and use **Send link** to send their schedules to themselves, then `adb uninstall com.manalogadiel.schediel`, install again, and reopen the link to re-import. Do not uninstall without that warning.

The build should print no `WARNING: android/key.properties not found`.

### 6. Verify on the phone (with the owner)
1. Create a share link in the app → open it on the phone → it opens **Schediel** (not the browser) → review screen → confirm adds the schedules. Opening must never add schedules without confirmation.
2. Revoke the link → reopen → "Shared link revoked".
3. Airplane mode → **Create link** shows an honest error; **Send link** (offline) still works.
4. Open the link on a PC browser → read-only preview page loads.
5. Home-screen widget still fills its height; Week view, month sheet and Today screen look right.

### 7. Finish
- If code changed: run the Step 0 checks again, commit (`feat: wire online sharing to Supabase` or a `fix:` message), confirm `git diff --cached` has no secrets, `git push origin feat/motion-texture-polish-t0xl4w`.
- Tell the owner to delete any access tokens created for this (Supabase → Account → Access Tokens; Vercel → Tokens).

## Known minor follow-ups (not blocking)
- Share-link domain is `*.vercel.app`; a custom domain can be added later (rerun the script with the new `SCHEDIEL_SHARE_HOST`, rebuild the app).
- No second app-link host is configured, so the browser preview shows no "Open in Schediel" button; tapping the original link still opens the app via App Links.
- Before a public release: abuse/CAPTCHA policy for anonymous sign-ins, load testing, and the production gates listed in `backend/README.md`.
