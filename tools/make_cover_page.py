"""
Builds a stunning, high-resolution comic book cover for 'GLITCHED OUT'.
Features:
- Vintage comic paper texture with halftone screen
- The towering Masked Villain with dark ink aura
- The central Hero wielding the radiant golden Light Blade
- Companion hero cameos in angled comic panels
- 3D extruded "GLITCHED OUT" logo with chromatic aberration glitch slices
- Vintage trade dress: Issue #1, Comics Code stamp, barcodes, and action bursts
"""

import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance

BASE_DIR = r"D:\Infinium\wt-claude\new-game-project"
OUT_DIR = r"D:\Infinium\TGC-Game-Jam\build"
ITCH_DIR = r"D:\Infinium\TGC-Game-Jam\build\itch"
ART_DIR = os.path.join(BASE_DIR, "assets", "art")

FONT_TITLE_PATH = os.path.join(BASE_DIR, "assets", "fonts", "Bangers-Regular.ttf")
FONT_BODY_PATH = os.path.join(BASE_DIR, "assets", "fonts", "ComicNeue-Bold.ttf")

BG_PATH = os.path.join(BASE_DIR, "assets", "editions", "2k", "arena_far.jpg")
VILLAIN_PATH = os.path.join(BASE_DIR, "assets", "editions", "sprites", "masked_villain.png")
HERO_PATH = os.path.join(BASE_DIR, "assets", "editions", "sprites", "hero_blade_1.png")
HERO_FALLBACK = os.path.join(BASE_DIR, "assets", "editions", "portraits", "hero.png")

INK = (24, 21, 29)
PAPER = (255, 249, 230)
GOLD = (255, 210, 63)
RED = (230, 57, 70)
CYAN = (43, 179, 192)
PURPLE = (140, 40, 180)


def create_cover(width=1200, height=1600):
    img = Image.new("RGBA", (width, height), (251, 243, 219, 255))
    draw = ImageDraw.Draw(img)

    # 1. Background scene (Opera Arena with moody tint)
    if os.path.exists(BG_PATH):
        bg = Image.open(BG_PATH).convert("RGBA")
        bg_ratio = max(width / bg.width, (height * 0.75) / bg.height)
        new_w = int(bg.width * bg_ratio)
        new_h = int(bg.height * bg_ratio)
        bg = bg.resize((new_w, new_h), Image.Resampling.LANCZOS)
        # Crop to upper 75%
        crop_box = ((new_w - width) // 2, 0, (new_w - width) // 2 + width, int(height * 0.75))
        bg_cropped = bg.crop(crop_box)
        # Darken and add purple tint
        tint = Image.new("RGBA", bg_cropped.size, (30, 10, 45, 140))
        bg_composite = Image.alpha_composite(bg_cropped, tint)
        img.paste(bg_composite, (0, int(height * 0.08)), bg_composite)

    # Halftone dot overlay simulation
    dot_overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d_draw = ImageDraw.Draw(dot_overlay)
    step = 16
    for y in range(0, height, step):
        for x in range(0, width, step):
            if (x // step + y // step) % 2 == 0:
                d_draw.ellipse((x - 1, y - 1, x + 2, y + 2), fill=(24, 21, 29, 18))
    img = Image.alpha_composite(img, dot_overlay)
    draw = ImageDraw.Draw(img)

    # 2. Top Trade Dress Banner
    # Dark masthead bar
    draw.rectangle([(20, 20), (width - 20, 80)], fill=INK)
    f_masthead = ImageFont.truetype(FONT_TITLE_PATH, 28)
    draw.text((40, 36), "INFINIUM COMICS GROUP", fill=GOLD, font=f_masthead)
    draw.text((width // 2 - 140, 36), "SPECIAL COLLECTOR'S EDITION", fill=PAPER, font=f_masthead)
    draw.text((width - 150, 36), "PRICE: 25¢", fill=GOLD, font=f_masthead)

    # Comics Code Authority Stamp (Top Right)
    stamp_x = width - 180
    stamp_y = 100
    stamp_w = 140
    stamp_h = 170
    draw.rectangle([(stamp_x, stamp_y), (stamp_x + stamp_w, stamp_y + stamp_h)], fill=PAPER, outline=INK, width=6)
    draw.rectangle([(stamp_x + 6, stamp_y + 6), (stamp_x + stamp_w - 6, stamp_y + stamp_h - 6)], outline=INK, width=2)
    f_stamp1 = ImageFont.truetype(FONT_TITLE_PATH, 22)
    f_stamp2 = ImageFont.truetype(FONT_BODY_PATH, 16)
    f_stamp3 = ImageFont.truetype(FONT_TITLE_PATH, 20)
    draw.text((stamp_x + 22, stamp_y + 16), "APPROVED", fill=INK, font=f_stamp1)
    draw.text((stamp_x + 36, stamp_y + 48), "BY THE", fill=INK, font=f_stamp2)
    draw.text((stamp_x + 10, stamp_y + 74), "COMICS CODE", fill=RED, font=f_stamp3)
    draw.text((stamp_x + 18, stamp_y + 104), "AUTHORITY", fill=INK, font=f_stamp1)
    # Small star
    draw.text((stamp_x + 58, stamp_y + 134), "★", fill=GOLD, font=f_stamp1)

    # Issue badge (Top Left)
    issue_x = 40
    issue_y = 100
    draw.rectangle([(issue_x, issue_y), (issue_x + 120, issue_y + 140)], fill=RED, outline=INK, width=6)
    f_issue1 = ImageFont.truetype(FONT_TITLE_PATH, 42)
    f_issue2 = ImageFont.truetype(FONT_TITLE_PATH, 24)
    draw.text((issue_x + 35, issue_y + 15), "#1", fill=PAPER, font=f_issue1)
    draw.text((issue_x + 22, issue_y + 80), "ISSUE", fill=GOLD, font=f_issue2)

    # 3. Looming Masked Villain (Center Upper)
    if os.path.exists(VILLAIN_PATH):
        villain = Image.open(VILLAIN_PATH).convert("RGBA")
        v_scale = 1.6
        vw, vh = int(villain.width * v_scale), int(villain.height * v_scale)
        villain_resized = villain.resize((vw, vh), Image.Resampling.LANCZOS)

        # Violet aura glow behind villain
        aura = Image.new("RGBA", (vw + 200, vh + 200), (0, 0, 0, 0))
        a_draw = ImageDraw.Draw(aura)
        a_draw.ellipse([(50, 50), (vw + 150, vh + 150)], fill=(120, 20, 160, 140))
        aura = aura.filter(ImageFilter.GaussianBlur(50))
        vx = (width - vw) // 2
        vy = int(height * 0.18)
        img.paste(aura, (vx - 100, vy - 100), aura)
        img.paste(villain_resized, (vx, vy), villain_resized)

    # 4. Giant 3D Extruded "GLITCHED OUT" Title Logo
    f_logo = ImageFont.truetype(FONT_TITLE_PATH, 168)
    logo_text = "GLITCHED OUT"
    logo_x = width // 2 - 470
    logo_y = int(height * 0.38)

    # Draw deep 3D ink extrusion shadow
    for offset in range(24, 0, -2):
        draw.text((logo_x + offset, logo_y + offset), logo_text, fill=INK, font=f_logo)

    # Red chromatic aberration shift
    draw.text((logo_x - 6, logo_y + 2), logo_text, fill=RED, font=f_logo)
    # Cyan chromatic aberration shift
    draw.text((logo_x + 6, logo_y - 2), logo_text, fill=CYAN, font=f_logo)
    # Main golden face
    draw.text((logo_x, logo_y), logo_text, fill=GOLD, font=f_logo)
    # Highlight shimmer
    f_logo_inner = ImageFont.truetype(FONT_TITLE_PATH, 166)
    draw.text((logo_x, logo_y - 2), logo_text, fill=(255, 245, 180), font=f_logo_inner)

    # Subtitle Ribbon underneath Logo
    ribbon_y = logo_y + 175
    ribbon_pts = [
        (60, ribbon_y),
        (width - 60, ribbon_y),
        (width - 90, ribbon_y + 60),
        (30, ribbon_y + 60),
    ]
    draw.polygon(ribbon_pts, fill=RED, outline=INK)
    draw.line(ribbon_pts + [ribbon_pts[0]], fill=INK, width=6)
    f_ribbon = ImageFont.truetype(FONT_TITLE_PATH, 34)
    draw.text((width // 2 - 340, ribbon_y + 12), "✦ THE REALITY-BENDING COMIC BOOK ADVENTURE ✦", fill=PAPER, font=f_ribbon)

    # 5. Foreground Hero brandishing Light Blade (Lower Center)
    hero_img_path = HERO_PATH if os.path.exists(HERO_PATH) else HERO_FALLBACK
    if os.path.exists(hero_img_path):
        hero = Image.open(hero_img_path).convert("RGBA")
        h_scale = 1.35
        hw, hh = int(hero.width * h_scale), int(hero.height * h_scale)
        hero_resized = hero.resize((hw, hh), Image.Resampling.LANCZOS)

        # Radiant blade light rays burst behind hero
        blade_burst = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        b_draw = ImageDraw.Draw(blade_burst)
        center_blade = (width // 2 + 80, int(height * 0.72))
        for a_deg in range(0, 360, 15):
            rad = math.radians(a_deg)
            length = 420
            p1 = (center_blade[0] + int(math.cos(rad) * length), center_blade[1] + int(math.sin(rad) * length))
            p2 = (center_blade[0] + int(math.cos(rad + 0.1) * length), center_blade[1] + int(math.sin(rad + 0.1) * length))
            b_draw.polygon([center_blade, p1, p2], fill=(255, 210, 63, 60))
        blade_burst = blade_burst.filter(ImageFilter.GaussianBlur(12))
        img = Image.alpha_composite(img, blade_burst)

        # Place Hero
        hx = (width - hw) // 2 + 40
        hy = int(height * 0.58)
        img.paste(hero_resized, (hx, hy), hero_resized)

    # 6. Companion Hero Cameo Comic Panels (Bottom Left)
    panel_y = int(height * 0.78)
    panel_w = 480
    panel_h = 280
    draw.rectangle([(40, panel_y), (40 + panel_w, panel_y + panel_h)], fill=(255, 252, 240, 255), outline=INK, width=6)
    # Header tag on panel
    draw.rectangle([(40, panel_y - 24), (320, panel_y + 12)], fill=INK)
    f_panel_tag = ImageFont.truetype(FONT_TITLE_PATH, 20)
    draw.text((55, panel_y - 18), "FEATURING THE FOUR GUARDIANS", fill=GOLD, font=f_panel_tag)

    # 4 circular hero portraits inside panel
    heroes_info = [("PULP", GOLD), ("NOIR", (180, 190, 205)), ("NINJA", (247, 127, 0)), ("SPACE", (255, 112, 166))]
    cx_start = 95
    f_pname = ImageFont.truetype(FONT_TITLE_PATH, 16)
    for i, (name, col) in enumerate(heroes_info):
        cx = cx_start + i * 110
        cy = panel_y + 90
        cr = 42
        draw.ellipse([(cx - cr, cy - cr), (cx + cr, cy + cr)], fill=col, outline=INK, width=4)
        # Inner mask silhouette
        draw.ellipse([(cx - cr + 6, cy - cr + 6), (cx + cr - 6, cy + cr - 6)], outline=INK, width=2)
        # Name pill below
        draw.rectangle([(cx - 40, cy + cr + 10), (cx + 40, cy + cr + 32)], fill=INK)
        draw.text((cx - 24, cy + cr + 12), name, fill=PAPER, font=f_pname)

    # Edition badge banner in panel
    f_ed = ImageFont.truetype(FONT_TITLE_PATH, 24)
    draw.text((70, panel_y + 215), "3 EDITIONS: 240P  ➔  720P  ➔  2K", fill=RED, font=f_ed)

    # 7. Action Starburst Callouts (Bottom Right)
    burst_cx = width - 240
    burst_cy = int(height * 0.72)
    # Starburst polygon
    pts = []
    num_points = 18
    for k in range(num_points):
        ang = k / num_points * math.tau
        r = 130 if k % 2 == 0 else 95
        pts.append((burst_cx + int(math.cos(ang) * r), burst_cy + int(math.sin(ang) * r)))
    pts.append(pts[0])
    draw.polygon(pts, fill=GOLD, outline=INK)
    draw.line(pts, fill=INK, width=6)
    f_burst1 = ImageFont.truetype(FONT_TITLE_PATH, 32)
    f_burst2 = ImageFont.truetype(FONT_TITLE_PATH, 26)
    draw.text((burst_cx - 95, burst_cy - 48), "FULL SPOKEN", fill=INK, font=f_burst1)
    draw.text((burst_cx - 105, burst_cy - 12), "VOICE ACTING!", fill=RED, font=f_burst1)
    draw.text((burst_cx - 75, burst_cy + 26), "BY NARRATOR", fill=INK, font=f_burst2)

    # Barcode & Publisher Mark (Bottom Right Corner)
    bc_x = width - 260
    bc_y = height - 140
    draw.rectangle([(bc_x, bc_y), (width - 40, height - 30)], fill=PAPER, outline=INK, width=4)
    # Draw barcode stripes
    curr_x = bc_x + 12
    pattern = [2, 4, 1, 3, 5, 2, 1, 4, 3, 2, 5, 1, 3, 4, 2, 3, 1, 4, 2, 5, 2]
    for w_bar in pattern:
        draw.rectangle([(curr_x, bc_y + 8), (curr_x + w_bar, bc_y + 70)], fill=INK)
        curr_x += w_bar + 4
        if curr_x >= width - 60:
            break
    f_bc = ImageFont.truetype(FONT_BODY_PATH, 12)
    draw.text((bc_x + 16, bc_y + 78), "0  71486 01926  4", fill=INK, font=f_bc)

    # 8. Thick Comic Book Outer Frame Border
    border_w = 16
    draw.rectangle([(border_w // 2, border_w // 2), (width - border_w // 2, height - border_w // 2)], outline=INK, width=border_w)
    draw.rectangle([(border_w + 4, border_w + 4), (width - border_w - 4, height - border_w - 4)], outline=INK, width=3)

    return img


if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(ITCH_DIR, exist_ok=True)
    os.makedirs(ART_DIR, exist_ok=True)

    print("Building high-resolution 1200x1600 comic book cover...")
    cover = create_cover(1200, 1600)

    # 1. High-res cover page
    path_cover = os.path.join(OUT_DIR, "GlitchedOut_Cover_Page.png")
    cover.save(path_cover, "PNG", quality=95)
    print(f"Saved: {path_cover}")

    # 2. Itch.io cover (standard portrait ratio)
    path_itch = os.path.join(ITCH_DIR, "cover.png")
    cover.save(path_itch, "PNG", quality=95)
    print(f"Saved: {path_itch}")

    # 3. In-game asset cover
    path_game_asset = os.path.join(ART_DIR, "cover_page.png")
    cover.save(path_game_asset, "PNG", quality=95)
    print(f"Saved: {path_game_asset}")

    # Also sync to wt-claude
    wt_art_path = r"D:\Infinium\wt-claude\new-game-project\assets\art\cover_page.png"
    cover.save(wt_art_path, "PNG", quality=95)
    print(f"Saved: {wt_art_path}")

    # 4. Landscape 16:9 banner for itch header & wallpaper
    print("Building 1280x720 landscape banner...")
    banner_w, banner_h = 1280, 720
    # Crop / compose landscape version
    cover_scaled = cover.resize((int(1280 * 1.05), int(1600 * (1280 / 1200) * 1.05)), Image.Resampling.LANCZOS)
    landscape = cover_scaled.crop((0, int(cover_scaled.height * 0.15), 1280, int(cover_scaled.height * 0.15) + 720))
    path_banner = os.path.join(OUT_DIR, "GlitchedOut_Banner_16x9.png")
    landscape.save(path_banner, "PNG", quality=95)
    print(f"Saved: {path_banner}")
