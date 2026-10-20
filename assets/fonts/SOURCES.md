# Bundled fonts

Inter is the UI font; Silkscreen and Caveat are display fonts for the Pixel and Sketch themes. All are licensed under the SIL Open Font License 1.1 (license texts beside the files, also shown on the app's licenses page). They are bundled so the app works offline; nothing is downloaded at runtime.

| File | Family | Source (google/fonts, `main` branch, fetched 2026-10-19) | SHA-256 |
|---|---|---|---|
| `Silkscreen-Regular.ttf` | Silkscreen 400 | `https://raw.githubusercontent.com/google/fonts/main/ofl/silkscreen/Silkscreen-Regular.ttf` | `c845473330b94c2079ce9af01c51ac8ba2d99c24f4d14c039843bbb8e642ebd8` |
| `Silkscreen-Bold.ttf` | Silkscreen 700 | `https://raw.githubusercontent.com/google/fonts/main/ofl/silkscreen/Silkscreen-Bold.ttf` | `768476aa712d4f5c3e18d3bce80f980a8bd3f72b7094d22ec5e768df3acfed61` |
| `Caveat-Variable.ttf` | Caveat, variable weight 400–700 | `https://raw.githubusercontent.com/google/fonts/main/ofl/caveat/Caveat%5Bwght%5D.ttf` | `0bdb6b660482d31531b3945849fba5916b3ef8695da7024a9e6b9ee3c4157988` |
| `Inter-Variable.ttf` | Inter, variable opsz + weight | `https://github.com/google/fonts/raw/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf` (fetched 2026-10-20) | `29160a80ff49ddcab2c97711247e08b1fab27a484a329ce8b813d820dc559031` |
| `LICENSE-Inter.txt` | OFL text | `.../ofl/inter/OFL.txt` | |
| `LICENSE-Silkscreen.txt` | OFL text | `.../ofl/silkscreen/OFL.txt` (line endings normalized to LF) | |
| `LICENSE-Caveat.txt` | OFL text | `.../ofl/caveat/OFL.txt` (line endings normalized to LF) | |

The Android home-screen widget uses copies under `android/app/src/main/res/font/`.
