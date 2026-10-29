# Plano Brand Assets & Visual Identity

## 1. Visual Identity Concept
Plano's visual identity embodies **clarity, direction, focus, and balanced progress**.
- **Emblem**: Monogram "P" composed of an upright pillar anchored on purpose, an outer trajectory loop indicating continuous forward progress, and a central circular focus aperture representing clarity and prioritized attention.
- **Color Palette**:
  - **Teal / Emerald (`#0D9488` / `#14B8A6`)**: Vitality, steady habit building, health synchronization.
  - **Indigo / Violet (`#6366F1`)**: Focus, deep work, project mastery.
  - **Night Slate (`#0F172A`)**: High-contrast, clean dark-mode foundation.
  - **Morning Slate (`#F8FAFC`)**: Crisp, minimal light-mode canvas.

## 2. Asset Catalog & Locations
- **Master Vector SVGs**:
  - `assets/branding/plano_logo.svg`: Master brandmark with dark background
  - `assets/branding/plano_logo_dark.svg`: Dark mode vector mark
  - `assets/branding/plano_logo_light.svg`: Light mode vector mark
  - `assets/branding/plano_logo_monochrome.svg`: High-contrast monochrome black & white
  - `assets/branding/plano_icon.svg`: Standalone emblem without frame
- **Raster Icons**:
  - `assets/branding/plano_logo_512.png`: 512x512 high-res brandmark
  - `assets/branding/plano_logo_192.png`: 192x192 medium brandmark
  - `assets/branding/plano_icon_512.png`: 512x512 icon emblem
  - `assets/branding/plano_icon_192.png`: 192x192 icon emblem
  - `assets/icons/favicon.png`: 48x48 web favicon
- **Web Platform Assets**:
  - `web/favicon.png`: 48x48 favicon
  - `web/icons/Icon-192.png`: PWA standard 192x192 icon
  - `web/icons/Icon-512.png`: PWA standard 512x512 icon
  - `web/icons/Icon-maskable-192.png`: PWA maskable safe-zone icon
  - `web/icons/Icon-maskable-512.png`: PWA maskable safe-zone icon
- **Android Platform Assets**:
  - `android/app/src/main/res/drawable/ic_launcher_background.xml`: Vector adaptive background
  - `android/app/src/main/res/drawable/ic_launcher_foreground.xml`: Vector adaptive foreground
  - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`: 48x48
  - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`: 72x72
  - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`: 96x96
  - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`: 144x144
  - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`: 192x192

## 3. How Assets Are Generated
All vector assets and raster sizes are reproducibly rendered via `generate_brand_assets.py` using Python 3 and Pillow:
```bash
python generate_brand_assets.py
```
This script ensures 4x supersampling, precision vector geometry, and Lanczos downsampling for small-size legibility.
