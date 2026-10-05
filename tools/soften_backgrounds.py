"""Soft versions of the 2K fight backgrounds (blur, desaturate, darken, haze), so the fighters
stand out like in the reference fights. Writes <name>_soft.jpg / .png next to each picture.
Run: python tools/soften_backgrounds.py   (from the repo root)"""
from PIL import Image, ImageFilter, ImageEnhance
import os

DIR = os.path.join(os.path.dirname(__file__), "..", "new-game-project", "assets", "editions", "2k")
JOBS = [  # name, ext, blur radius, haze colour
    ("hall_far", ".jpg", 4, (29, 43, 51)),
    ("arena_far", ".jpg", 4, (42, 34, 56)),
    ("arena_dark", ".jpg", 4, (42, 34, 56)),
    ("hall_mid", ".png", 2, (29, 43, 51)),
    ("arena_mid", ".png", 2, (42, 34, 56)),
]

for name, ext, radius, haze in JOBS:
    src = os.path.join(DIR, name + ext)
    if not os.path.exists(src):
        continue
    im = Image.open(src).convert("RGBA")
    alpha = im.getchannel("A")
    rgb = im.convert("RGB").filter(ImageFilter.GaussianBlur(radius))
    rgb = ImageEnhance.Color(rgb).enhance(0.55)
    rgb = ImageEnhance.Brightness(rgb).enhance(0.7)
    rgb = Image.blend(rgb, Image.new("RGB", rgb.size, haze), 0.18)
    out = os.path.join(DIR, name + "_soft" + ext)
    if ext == ".png":
        rgb.putalpha(alpha.filter(ImageFilter.GaussianBlur(radius * 0.5)))
        rgb.save(out, optimize=True)
    else:
        rgb.save(out, quality=88)
    print("wrote", out)
