# Schediel poster redesign

## Implemented direction

The user’s reference is a 4.83-second recording of a graphic poster/portfolio site, featuring large condensed display type, dark square project cards, tape details, sharp outlines, and hover reveals. The implementation adopts that composition using Schediel’s own Lilac (#F4F2FC), ink (#1E1B2E), violet (#6A5AE0), bundled Inter and Silkscreen fonts, logo, and real app/home-screen screenshots.

## Page flow

1. A heavy two-line poster hero, the real Pixel app and widget, and the Install Schediel action.
2. The wallpaper problem: a large manifesto with scroll-linked ink fill and a clipped reveal of the real widget.
3. Eight taped theme posters in a horizontal gallery. Desktop vertical scroll advances the rail; arrow buttons, keyboard controls, and a native mobile scroller remain usable. Each poster opens the full app/widget pair.
4. Four dark, sharp feature posters covering offline schedules, file/link sharing, reminders, and Android Clock alarm handoff. Hover adds violet emphasis and an offset shadow.
5. A large install poster, Android compatibility, practical FAQs, and © 2026 iDIELogies.

## Motion and fallback

Vanilla JavaScript only. A single passive scroll listener schedules one requestAnimationFrame that writes CSS custom properties. Section geometry is cached on resize, font readiness, and load. Sticky sections are enabled only above 900px width and at least 850px viewport height. Reduced motion, mobile, and short screens use normal document flow and native horizontal scrolling. Headline words retain accessible heading labels. Essential copy and installation controls remain available without completing an animation.

The earlier proposal for five fully pinned chapters and approximately 200 animated elements was adapted to the supplied video and the app: two useful pinned desktop stages, a limited number of readable headline spans, and no arbitrary element quota. No lot numbers, fake test results, invented notifications, or manufacturing content is included.

## Validation

Checked responsive layouts at 320, 375, 390, 768, 901, 1024, and 1440px, two-line hero wrapping after font load, desktop/reduced-motion/short-screen behavior, scroll progress endpoints, gallery arrows, all eight theme dialogs and actual images, keyboard opening/Escape/focus restoration, and the install dialog. Static checks verify all local references, JavaScript syntax, and the APK’s unchanged byte count and SHA-256.
