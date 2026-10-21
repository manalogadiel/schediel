# Schediel website plan

## Problem
Students put timetables on their wallpaper to keep their next class visible. This hides the wallpaper they actually want, makes changes awkward, and still leaves them searching for room and professor details.

## Website purpose
Introduce the free Android app, demonstrate how its customizable schedule and transparent home-screen widget solve that problem, and provide the supplied APK.

## Page flow
1. A concise introduction and real Pixel app and widget captures.
2. The wallpaper problem, stated in the maker's informal voice.
3. A theme studio: Lilac, Clay, Mint, Midnight, Pop, Pixel, Sketch, and Custom. Switch both real app and real home-screen captures together. Preserve the actual Android widget's transparent background.
4. Brief, visual features: offline schedules, offline and link sharing, reminders, and system alarm handoff.
5. APK installation, Android steps, and short FAQs.

## Design
Use the actual Schediel logo and bundled Inter, Caveat, and Silkscreen fonts with their licenses. Use real captures from the user's phone running build 4006, including the texture behind the status bar, arched date selector, large Next card, and floating navigation. Use Lilac for the website, a restrained spacing/radius scale, accessible controls, and motion that respects reduced-motion preferences.

## Implementation and validation
Buildless HTML, CSS, and vanilla JavaScript, with no runtime dependencies. Preserve the existing share-link website in `web-preview/`. A separate `website/` contains this landing page. Package the supplied APK into small static parts and reconstruct the exact original download in the browser, verifying SHA-256. Check mobile/desktop layout, all eight real theme pairs, image loading/error handling, installation, download integrity, keyboard navigation, and reduced motion. Publish an owner-private review version through Sites when supported.

## Scroll redesign

The next design direction is documented in [SCROLL-REDESIGN-PLAN.md](SCROLL-REDESIGN-PLAN.md). The poster redesign and its scroll effects are now implemented; the document records the delivered scope and verification. The current page uses oversized typography, taped theme posters, dark feature cards, real screenshots, factual copy, plain backgrounds without decorative dot patterns, and the iDIELogies copyright.
