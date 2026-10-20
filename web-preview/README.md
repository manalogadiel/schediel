# Schediel browser share preview

Static, read-only fallback for an owned compact `https://{host}/s/#{secret}` link; legacy `/s/{shareId}#token={secret}` links remain readable. Opening it previews only the selected snapshot; adding schedules happens in the app after editable review and explicit confirmation. The Schediel share site was deployed on October 20, 2026; see `../VALIDATION.md`. There are no fake store links, trackers or third-party resources.

## Test

```sh
npm ci
npm test
```

Tests use Node's test runner and jsdom, loading the real HTML/modules with injected fetch responses and shared contract fixtures. They cover canonical links, fragment scrubbing, no-store body-only resolution, error states, payload validation, inert untrusted text, formatting and build configuration. They do not prove actual App Links/Universal Links or mobile browser rendering.

## Configure a static build

Required environment values:

- `SCHEDIEL_API_BASE`: actual HTTPS Supabase edge base ending `/functions/v1`.
- `SCHEDIEL_SHARE_HOST`: actual owned HTTPS origin, including `https://`, with no path, query, credentials or fragment.
- `SCHEDIEL_PUBLISHABLE_KEY`: optional public `sb_publishable_...` key. Never a secret/service key.
- `SCHEDIEL_APP_LINK_ORIGIN`: optional second owned HTTPS origin (for example a different subdomain) used only by the **Open in Schediel** button. It must differ from the share origin: browsers treat a link to the page's own host as ordinary navigation and stay in the browser, so a same-host hand-off can never open the app. Without it, the preview shows no app button and tells the person to reopen the original link on a device with Schediel installed. Configure the same host in the app (`SCHEDIEL_APP_LINK_HOST` / Gradle `schediel.appLinkHost`) and serve the association files on it too.

Then run:

```sh
npm run configure
# Or: node scripts/configure.mjs --out YOUR_OUTPUT_DIRECTORY
```

The generator writes `dist/s/index.html`, same-origin assets, public config, restrictive CSP and privacy response headers, and a `/s/*` rewrite. Missing required configuration fails without generating output. The source tree intentionally has no usable deployment config.

Optional domain associations are generated only with real signing inputs:

- `ANDROID_CERT_SHA256`: one actual colon-separated certificate fingerprint; `ANDROID_PACKAGE_NAME` defaults to `com.manalogadiel.schediel`.
- `APPLE_TEAM_ID`: actual ten-character Apple team identifier; `APPLE_BUNDLE_ID` defaults to `com.manalogadiel.schediel`.

No fingerprint/team ID is fabricated. Omitted inputs produce an explicit note and no association file; reconfiguration removes stale generated associations.

## Host and verify

Deploy the generated directory to a static HTTPS host supporting the emitted `_redirects` and `_headers`, or translate those rules exactly for the chosen host. Do not blindly serve it without the SPA `/s/*` rewrite. Serve association files as JSON without authentication or redirects. Configure backend CORS to allow the exact share origin. Keep the response CSP, `no-store, private`, `no-referrer` and `nosniff` headers; do not add analytics, external scripts or error-reporting URLs containing incoming links.

The fragment is removed immediately from browser history before any resolution attempt, retained only in memory for explicit retry/open-app, and sent only in the resolver POST body. Reloading after fragment removal requires reopening the original link. This is intentional privacy behavior, not deferred-install context restoration. Only a valid matching capability may see revoked/expired states; wrong/unknown links get an unavailable state.

On a real Android/iOS device, prove that opening the original HTTPS link preserves its fragment on cold and warm starts and opens **preview**, not automatic import. App association/signing and store distribution are separate release gates. Link expiry/revocation cannot recall already downloaded previews or imported copies.

Both share and handoff hosts must be public production domains. A Vercel alias alone can remain behind preview authentication, preventing Android from reading its association file; attach the alias to the project as a production domain. The preview accepts either configured origin and hands off to the other only after the Open action.
