"""Export platform icons and launch images from the supplied NEC artwork.

Run from any directory with: python3 tool/generate_brand_assets.py
Requires Pillow. The original logo files are never modified.
"""

import json
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
LOGOS = ROOT / 'assets/logos'
SMALL = Image.open(LOGOS / 'NEC app icon — Rounded — 512 × 512.png').convert('RGBA')
LARGE = Image.open(LOGOS / 'NEC app icon — Rounded — 1024 × 1024.png').convert('RGBA')
BRAND = LARGE.getpixel((LARGE.width // 2, 10))[:3]
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
RES = ROOT / 'android/app/src/main/res'


def export(path, size, source=LARGE, opaque=False):
    image = source.resize((size, size), Image.Resampling.LANCZOS)
    if opaque:
        background = Image.new('RGBA', image.size, (*BRAND, 255))
        background.alpha_composite(image)
        image = background.convert('RGB')
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def padded(source, canvas_size, artwork_size, opaque=False):
    background = (*BRAND, 255) if opaque else (0, 0, 0, 0)
    canvas = Image.new('RGBA', (canvas_size, canvas_size), background)
    artwork = source.resize((artwork_size, artwork_size), Image.Resampling.LANCZOS)
    margin = (canvas_size - artwork_size) // 2
    canvas.alpha_composite(artwork, (margin, margin))
    return canvas


# Keep the previous asset name pointing to the final logo as well.
export(LOGOS / 'nec-app-logo.png', 512, SMALL)

# Existing Xcode catalogs define every required device and marketing size.
for platform in ('ios', 'macos'):
    catalog = ROOT / platform / 'Runner/Assets.xcassets/AppIcon.appiconset'
    entries = json.loads((catalog / 'Contents.json').read_text())['images']
    for entry in entries:
        points = float(entry['size'].split('x')[0])
        scale = float(entry['scale'].removesuffix('x'))
        export(catalog / entry['filename'], round(points * scale), opaque=platform == 'ios')

launch = ROOT / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
for scale, filename in ((1, 'LaunchImage.png'), (2, 'LaunchImage@2x.png'), (3, 'LaunchImage@3x.png')):
    export(launch / filename, 140 * scale)

# Android legacy launchers, launch-screen images, and monochrome notifications.
# The small notification glyph uses the white lettering from the supplied logo.
red, green, _, alpha = LARGE.split()
glyph = ImageChops.lighter(
    red.point(lambda value: max(0, min(255, (value - BRAND[0]) * 2))),
    green.point(lambda value: max(0, min(255, (value - BRAND[1]) * 2))),
)
glyph = ImageChops.multiply(glyph, alpha)
notification = Image.new('RGBA', LARGE.size, (255, 255, 255, 0))
notification.putalpha(glyph)

for density, scale in DENSITIES.items():
    export(RES / f'mipmap-{density}/ic_launcher.png', round(48 * scale), SMALL)
    export(RES / f'drawable-{density}/splash_logo.png', round(140 * scale))
    export(
        RES / f'drawable-{density}/splash_logo_android12.png',
        round(288 * scale),
        padded(LARGE, round(288 * scale), round(140 * scale)),
    )
    export(RES / f'drawable-{density}/ic_notification.png', round(24 * scale), notification)

export(RES / 'drawable/splash_logo.png', 140)
export(RES / 'drawable-nodpi/ic_launcher_foreground.png', 432, padded(LARGE, 432, 324))
export(RES / 'drawable-nodpi/ic_launcher_monochrome.png', 432, padded(notification, 432, 324))
brand_hex = '#{:02X}{:02X}{:02X}'.format(*BRAND)
(RES / 'values/icon_colors.xml').write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<resources>\n'
    f'    <color name="ic_launcher_background">{brand_hex}</color>\n'
    '</resources>\n'
)

# Browser icons and maskable PWA artwork with a safe inset.
export(ROOT / 'web/favicon.png', 32, SMALL)
export(ROOT / 'web/icons/apple-touch-icon.png', 180, SMALL, opaque=True)
for size in (192, 512):
    export(ROOT / f'web/icons/Icon-{size}.png', size, SMALL)
    export(
        ROOT / f'web/icons/Icon-maskable-{size}.png',
        size,
        padded(LARGE, size, round(size * 0.8), opaque=True),
        opaque=True,
    )

windows_icon = ROOT / 'windows/runner/resources/app_icon.ico'
SMALL.resize((256, 256), Image.Resampling.LANCZOS).save(
    windows_icon,
    format='ICO',
    sizes=[(size, size) for size in (16, 24, 32, 48, 64, 128, 256)],
)

print('Exported NEC app icons and native launch artwork for Android, iOS, macOS, Windows, and web.')
