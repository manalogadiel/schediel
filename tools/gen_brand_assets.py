"""Generate launcher icons and splash assets from the approved paper-cut source.

Source: assets/branding/source/schediel-paper.png (1254x1254, plain warm background).
Run: python tools/gen_brand_assets.py   (needs Pillow + numpy)
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/branding/source/schediel-paper.png"
RES = ROOT / "android/app/src/main/res"
IOS = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

im = Image.open(SRC).convert("RGB")
a = np.asarray(im).astype(np.int32)
border = np.concatenate([a[:24].reshape(-1, 3), a[-24:].reshape(-1, 3),
                         a[:, :24].reshape(-1, 3), a[:, -24:].reshape(-1, 3)])
BG = tuple(int(v) for v in np.median(border, axis=0))

# Object bounds (includes its soft shadow).
diff = np.abs(a - np.array(BG)).sum(axis=2)
ys, xs = np.where(diff > 30)
x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
cx, cy = float(x0 + x1) / 2, float(y0 + y1) / 2
side = float(max(x1 - x0, y1 - y0)) * 1.08


def logo(px: int, fraction: float) -> Image.Image:
    """Square tile of `px`, object's largest side = fraction*px, on a flat BG.

    Source edges are feathered into the flat colour so no paper-grain seam shows.
    """
    crop_side = side / fraction
    box = (cx - crop_side / 2, cy - crop_side / 2, cx + crop_side / 2, cy + crop_side / 2)
    flat = Image.new("RGB", (int(crop_side), int(crop_side)), BG)
    # Paste the source into the (possibly larger) crop canvas.
    flat.paste(im, (int(-box[0]), int(-box[1])))
    mask = Image.new("L", flat.size, 0)
    r = side * 0.62
    d = ImageDraw.Draw(mask)
    d.ellipse((crop_side / 2 - r, crop_side / 2 - r, crop_side / 2 + r, crop_side / 2 + r), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(side * 0.06))
    out = Image.composite(flat, Image.new("RGB", flat.size, BG), mask)
    return out.resize((px, px), Image.LANCZOS)


def rounded(img: Image.Image, radius_frac: float) -> Image.Image:
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, img.size[0] - 1, img.size[1] - 1),
                                        radius=int(img.size[0] * radius_frac), fill=255)
    out = img.convert("RGBA")
    out.putalpha(m)
    return out


densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
for name, s in densities.items():
    d = RES / f"mipmap-{name}"
    d.mkdir(exist_ok=True)
    # Adaptive foreground: 108dp canvas, object ~50% so circle masks only clip background.
    logo(int(108 * s), 0.50).save(d / "ic_launcher_foreground.png", optimize=True)
    # Legacy (pre-adaptive launchers): 48dp rounded square.
    rounded(logo(int(48 * s), 0.78), 0.22).save(d / "ic_launcher.png", optimize=True)

# Splash logo for API 26-30 window background: 154dp tile, matching the API 31+ system icon as measured.
for name, s in densities.items():
    d = RES / f"drawable-{name}"
    d.mkdir(exist_ok=True)
    logo(int(154 * s), 0.90).save(d / "splash_logo.png", optimize=True)

# In-app intro uses the same tile (rendered at 154 logical px).
logo(640, 0.90).save(ROOT / "assets/branding/splash_logo.png", optimize=True)

# iOS: opaque full-bleed squares (the system applies the mask).
master = logo(1024, 0.80)
for f in IOS.glob("Icon-App-*.png"):
    dims, scale = f.stem.removeprefix("Icon-App-").split("@")
    px = round(float(dims.split("x")[0]) * int(scale.removesuffix("x")))
    master.resize((px, px), Image.LANCZOS).save(f, optimize=True)

print("background", "#%02X%02X%02X" % BG)
