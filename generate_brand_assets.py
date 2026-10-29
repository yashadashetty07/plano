import os
import math
from PIL import Image, ImageDraw

BRANDING_DIR = os.path.join("assets", "branding")
ICONS_DIR = os.path.join("assets", "icons")
WEB_ICONS_DIR = os.path.join("web", "icons")
WEB_DIR = "web"
MIPMAP_BASE = os.path.join("android", "app", "src", "main", "res")

os.makedirs(BRANDING_DIR, exist_ok=True)
os.makedirs(ICONS_DIR, exist_ok=True)
os.makedirs(WEB_ICONS_DIR, exist_ok=True)

# 1. Generate SVG Assets
SVG_LOGO_DARK = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="100%" height="100%">
  <defs>
    <linearGradient id="planoGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0D9488" />
      <stop offset="50%" stop-color="#14B8A6" />
      <stop offset="100%" stop-color="#6366F1" />
    </linearGradient>
    <linearGradient id="planoAccent" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#38BDF8" />
      <stop offset="100%" stop-color="#818CF8" />
    </linearGradient>
    <filter id="subtleGlow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="12" result="blur" />
      <feComposite in="SourceGraphic" in2="blur" operator="over" />
    </filter>
  </defs>
  <rect width="512" height="512" rx="112" fill="#0F172A" />
  <g transform="translate(64, 64)">
    <!-- Upward trajectory guide line -->
    <path d="M 64 288 L 64 96 C 64 42.98 106.98 0 160 0 C 213.02 0 256 42.98 256 96 C 256 149.02 213.02 192 160 192 L 64 192" 
          fill="none" stroke="url(#planoGrad)" stroke-width="44" stroke-linecap="round" stroke-linejoin="round" />
    <!-- Focal progress dot -->
    <circle cx="160" cy="96" r="28" fill="url(#planoAccent)" />
    <!-- Dynamic forward path indicator -->
    <path d="M 160 256 L 256 256 C 291.34 256 320 284.66 320 320" 
          fill="none" stroke="#14B8A6" stroke-width="24" stroke-linecap="round" stroke-dasharray="1 36" />
  </g>
</svg>"""

SVG_LOGO_LIGHT = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="100%" height="100%">
  <defs>
    <linearGradient id="planoGradLight" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0F766E" />
      <stop offset="50%" stop-color="#0D9488" />
      <stop offset="100%" stop-color="#4F46E5" />
    </linearGradient>
    <linearGradient id="planoAccentLight" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#0284C7" />
      <stop offset="100%" stop-color="#6366F1" />
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="112" fill="#F8FAFC" />
  <g transform="translate(64, 64)">
    <path d="M 64 288 L 64 96 C 64 42.98 106.98 0 160 0 C 213.02 0 256 42.98 256 96 C 256 149.02 213.02 192 160 192 L 64 192" 
          fill="none" stroke="url(#planoGradLight)" stroke-width="44" stroke-linecap="round" stroke-linejoin="round" />
    <circle cx="160" cy="96" r="28" fill="url(#planoAccentLight)" />
    <path d="M 160 256 L 256 256 C 291.34 256 320 284.66 320 320" 
          fill="none" stroke="#0D9488" stroke-width="24" stroke-linecap="round" stroke-dasharray="1 36" />
  </g>
</svg>"""

SVG_LOGO_MONOCHROME = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="100%" height="100%">
  <rect width="512" height="512" rx="112" fill="#000000" />
  <g transform="translate(64, 64)">
    <path d="M 64 288 L 64 96 C 64 42.98 106.98 0 160 0 C 213.02 0 256 42.98 256 96 C 256 149.02 213.02 192 160 192 L 64 192" 
          fill="none" stroke="#FFFFFF" stroke-width="44" stroke-linecap="round" stroke-linejoin="round" />
    <circle cx="160" cy="96" r="28" fill="#FFFFFF" />
    <path d="M 160 256 L 256 256 C 291.34 256 320 284.66 320 320" 
          fill="none" stroke="#FFFFFF" stroke-width="24" stroke-linecap="round" stroke-dasharray="1 36" />
  </g>
</svg>"""

SVG_ICON_ONLY = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 384 384" width="100%" height="100%">
  <defs>
    <linearGradient id="pGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0D9488" />
      <stop offset="60%" stop-color="#14B8A6" />
      <stop offset="100%" stop-color="#6366F1" />
    </linearGradient>
  </defs>
  <path d="M 64 320 L 64 96 C 64 42.98 106.98 0 160 0 C 213.02 0 256 42.98 256 96 C 256 149.02 213.02 192 160 192 L 64 192" 
        fill="none" stroke="url(#pGrad)" stroke-width="48" stroke-linecap="round" stroke-linejoin="round" />
  <circle cx="160" cy="96" r="28" fill="#38BDF8" />
  <path d="M 160 264 L 264 264 C 299.34 264 328 292.66 328 328" 
        fill="none" stroke="#14B8A6" stroke-width="28" stroke-linecap="round" stroke-dasharray="1 40" />
</svg>"""

with open(os.path.join(BRANDING_DIR, "plano_logo.svg"), "w") as f:
    f.write(SVG_LOGO_DARK)
with open(os.path.join(BRANDING_DIR, "plano_logo_dark.svg"), "w") as f:
    f.write(SVG_LOGO_DARK)
with open(os.path.join(BRANDING_DIR, "plano_logo_light.svg"), "w") as f:
    f.write(SVG_LOGO_LIGHT)
with open(os.path.join(BRANDING_DIR, "plano_logo_monochrome.svg"), "w") as f:
    f.write(SVG_LOGO_MONOCHROME)
with open(os.path.join(BRANDING_DIR, "plano_icon.svg"), "w") as f:
    f.write(SVG_ICON_ONLY)

# 2. Render High Quality Raster Assets using PIL
def draw_plano_icon(size, is_maskable=False, background_color=(15, 23, 42)):
    scale = size / 512.0
    # Create 4x supersampled image for ultra crisp antialiasing
    ss = 4
    canvas_size = size * ss
    img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background
    if background_color:
        if is_maskable:
            # Full bleed square
            draw.rectangle([0, 0, canvas_size, canvas_size], fill=background_color)
        else:
            # Rounded squircle
            radius = int(112 * scale * ss)
            draw.rounded_rectangle([0, 0, canvas_size, canvas_size], radius=radius, fill=background_color)
            
    # Center emblem
    # Inner coordinate space is 512x512
    margin = (64 if not is_maskable else 96) * scale * ss
    target_dim = 384 * scale * ss if not is_maskable else 320 * scale * ss
    s_factor = target_dim / 384.0
    
    # Stem line: (64, 96) to (64, 288) -> offset by margin
    ox = margin
    oy = margin
    
    sw = int(44 * s_factor)
    
    # Colors
    c_teal = (13, 148, 136, 255)
    c_cyan = (20, 184, 166, 255)
    c_indigo = (99, 102, 241, 255)
    c_sky = (56, 189, 248, 255)
    
    # Draw vertical stem
    x_stem = ox + 64 * s_factor
    y_top = oy + 96 * s_factor
    y_bot = oy + 288 * s_factor
    draw.line([(x_stem, y_top), (x_stem, y_bot)], fill=c_teal, width=sw)
    # Cap
    r_cap = sw // 2
    draw.ellipse([x_stem - r_cap, y_bot - r_cap, x_stem + r_cap, y_bot + r_cap], fill=c_teal)
    
    # Draw P loop arc
    # Bounding box for circle centered at (160, 96) with radius 96
    cx = ox + 160 * s_factor
    cy = oy + 96 * s_factor
    r_outer = 96 * s_factor
    draw.arc([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer], start=270, end=90, fill=c_indigo, width=sw)
    
    # Horizontal connectors: top and mid
    draw.line([(x_stem, cy - r_outer), (cx, cy - r_outer)], fill=c_teal, width=sw)
    draw.line([(x_stem, cy + r_outer), (cx, cy + r_outer)], fill=c_indigo, width=sw)
    
    # Draw focus dot at (cx, cy)
    r_dot = int(28 * s_factor)
    draw.ellipse([cx - r_dot, cy - r_dot, cx + r_dot, cy + r_dot], fill=c_sky)
    
    # Small forward path dots
    path_y = oy + 256 * s_factor
    p_x1 = cx
    p_x2 = cx + 80 * s_factor
    draw.line([(p_x1, path_y), (p_x2, path_y)], fill=c_cyan, width=int(18 * s_factor))
    
    # Resize down with high quality Lanczos filter
    final_img = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_img

# Generate all required PNG sizes
sizes_and_paths = [
    (512, os.path.join(BRANDING_DIR, "plano_logo_512.png"), False),
    (192, os.path.join(BRANDING_DIR, "plano_logo_192.png"), False),
    (512, os.path.join(BRANDING_DIR, "plano_icon_512.png"), False),
    (192, os.path.join(BRANDING_DIR, "plano_icon_192.png"), False),
    (48, os.path.join(ICONS_DIR, "favicon.png"), False),
    (48, os.path.join(WEB_DIR, "favicon.png"), False),
    (192, os.path.join(WEB_ICONS_DIR, "Icon-192.png"), False),
    (512, os.path.join(WEB_ICONS_DIR, "Icon-512.png"), False),
    (192, os.path.join(WEB_ICONS_DIR, "Icon-maskable-192.png"), True),
    (512, os.path.join(WEB_ICONS_DIR, "Icon-maskable-512.png"), True),
    # Android mipmaps
    (48, os.path.join(MIPMAP_BASE, "mipmap-mdpi", "ic_launcher.png"), False),
    (72, os.path.join(MIPMAP_BASE, "mipmap-hdpi", "ic_launcher.png"), False),
    (96, os.path.join(MIPMAP_BASE, "mipmap-xhdpi", "ic_launcher.png"), False),
    (144, os.path.join(MIPMAP_BASE, "mipmap-xxhdpi", "ic_launcher.png"), False),
    (192, os.path.join(MIPMAP_BASE, "mipmap-xxxhdpi", "ic_launcher.png"), False),
]

for sz, path, maskable in sizes_and_paths:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img = draw_plano_icon(sz, is_maskable=maskable)
    img.save(path, format="PNG")
    print(f"Generated {path} ({sz}x{sz})")

# 3. Android adaptive icon vector drawables
DRAWABLE_DIR = os.path.join(MIPMAP_BASE, "drawable")
os.makedirs(DRAWABLE_DIR, exist_ok=True)

ADAPTIVE_BG_XML = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#0F172A"
        android:pathData="M0,0h108v108h-108z"/>
</vector>
"""

ADAPTIVE_FG_XML = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <!-- Stylized Plano P Emblem -->
    <path
        android:pathData="M 36,72 L 36,36 C 36,25.5 44.5,17 55,17 C 65.5,17 74,25.5 74,36 C 74,46.5 65.5,55 55,55 L 36,55"
        android:strokeWidth="8"
        android:strokeColor="#14B8A6"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"/>
    <!-- Focus Aperture -->
    <path
        android:pathData="M 55,36 m -5,0 a 5,5 0 1,0 10,0 a 5,5 0 1,0 -10,0"
        android:fillColor="#38BDF8"/>
    <!-- Trajectory Dot -->
    <path
        android:pathData="M 55,67 L 70,67"
        android:strokeWidth="5"
        android:strokeColor="#6366F1"
        android:strokeLineCap="round"/>
</vector>
"""

with open(os.path.join(DRAWABLE_DIR, "ic_launcher_background.xml"), "w") as f:
    f.write(ADAPTIVE_BG_XML)
with open(os.path.join(DRAWABLE_DIR, "ic_launcher_foreground.xml"), "w") as f:
    f.write(ADAPTIVE_FG_XML)

print("Android adaptive icon XMLs generated successfully.")
