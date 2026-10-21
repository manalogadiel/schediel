# Schediel website

A buildless HTML/CSS/vanilla JavaScript landing page. The existing Flutter app and `web-preview/` share-link viewer remain separate.

Run `npm start` in this folder and open http://localhost:4173. No install or build step is required. `npm run check` verifies JavaScript syntax, referenced assets, and the APK's byte count and SHA-256.

`dist/` is the complete deployable static site. Serve it over HTTPS in production. The APK is delivered as three small static parts, assembled in browser memory, and verified against its SHA-256 before downloading as `Schediel.apk`. To replace the release, run `node scripts/prepare-apk.mjs "C:\absolute\path\Schediel.apk"`. This supports static hosts with per-file size limits. Allow roughly 120 MB of free browser memory for the download. No install capability is claimed in the browser; Android handles installation after the file is opened.

The poster-style theme gallery displays real, unmodified app and home-screen captures taken from the user's Samsung SM-A326B running Schediel 1.0.0, build 4006. Each theme opens a dialog with both screens. Desktop scroll advances the gallery horizontally when the viewport is at least 901px wide and 850px high; narrow/short viewports and reduced motion use a native horizontal scroller with arrow and keyboard controls. These show the app's actual saved per-theme customizations, textured backgrounds, arched day strip, large Next card, floating navigation, and Android widget. The screenshots are illustrative product captures, not an interactive web version of the scheduler. Feature descriptions cover the app’s offline schedules, sharing, reminders, and Android Clock alarm handoff. The website itself does not schedule notifications.

The logo and bundled fonts are Schediel assets. Inter, Caveat, and Silkscreen license files are retained in `dist/assets/`. The home-screen captures were explicitly authorized by the user. The APK supplied for this site is ARM64, minimum Android 8.0; other architectures are not included in this download.

The current download is Schediel 1.0.1 (ARM64 build 4008), saved as `Schediel.apk`. It includes One time / Weekly choices for scanned schedules, School defaults for university tables, populated widget-picker previews and an optional **Save & open Clock** action when enabling an eligible alarm in the schedule editor. Clock alarms are managed separately from Schediel alarms. The APK parts are checked against the release file's SHA-256 before publication.

The initial Sites deployment is owner-private for review. A public APK distribution link requires making the site public or deploying `dist/` to your chosen public host.

## Vercel

Import `manalogadiel/schediel` and set the project's **Root Directory** to `website`. The committed `vercel.json` selects the static `dist` output and runs `npm run check`; no framework build or dependency installation is required. Keep this project separate from the app's existing schedule-sharing and handoff services. Vercel project linking files stay in the ignored `.vercel/` directory.

Preview deployments use the non-production deployment target. With Vercel's Git integration connected, pushes to branches create previews and pushes to the configured production branch publish production.

## Current visual design

The redesign follows the user’s supplied short video: oversized heavy type, sharp borders, offset shadows, taped poster edges, dark feature cards, and hover emphasis. It preserves Schediel’s Lilac/violet/ink palette, bundled Inter and Silkscreen fonts, actual Pixel hero, APK download, and iDIELogies copyright. No decorative dot grids or fabricated schedule interfaces are used.

`dist/redesign.css` contains the active styles. `dist/motion.js` uses one passive scroll listener and a throttled animation frame to update CSS variables. Desktop effects include headline lift/scale/fade, a clipped manifesto fill, a widget reveal, a sticky horizontal theme gallery, and small feature-card movement. Geometry is measured outside scroll frames. Reduced motion and short/mobile screens return to normal flow. Theme dialogs support Escape, outside click, loading/error feedback, and focus restoration.
