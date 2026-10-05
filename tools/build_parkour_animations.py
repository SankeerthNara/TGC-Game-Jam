"""
Build Parkour Animation Frames for 'Glitched Out' (2K Painted and 720p Pixel Art)
Actions:
  - hero_wallslide (1..3)
  - hero_walljump (1..3)
  - hero_airdash (1..3)
  - hero_dive (1..3)
  - hero_pogo (1..2)
"""

import os
import sys
from collections import deque
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

CURR_BRAIN_DIR = r"C:\Users\sanke\.gemini\antigravity-ide\brain\cbb40665-76c8-44b8-b1b3-35084d6ab57c"
WT_ANTI = r"D:\Infinium\wt-anti"
MAIN_WS = r"D:\Infinium\TGC-Game-Jam"

DESTS_SPRITES = [
    os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "sprites"),
    os.path.join(MAIN_WS, "new-game-project", "assets", "editions", "sprites"),
]

DESTS_PREVIEWS = [
    os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "reference", "anim_previews"),
    os.path.join(MAIN_WS, "new-game-project", "assets", "editions", "reference", "anim_previews"),
]

BG_2K_ARENA = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "2k", "arena_far.jpg")
BG_720_NEON = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "720", "neon_mid.png")

GRID_WALLSLIDE_PATH = os.path.join(CURR_BRAIN_DIR, "hero_wallslide_grid_b_1791205490833.jpg")
GRID_WALLJUMP_PATH = os.path.join(CURR_BRAIN_DIR, "hero_walljump_grid_1791205224314.jpg")
GRID_AIRDASH_PATH = os.path.join(CURR_BRAIN_DIR, "hero_airdash_grid_1791205348586.jpg")
GRID_DIVE_PATH = os.path.join(CURR_BRAIN_DIR, "hero_dive_grid_1791205432945.jpg")
GRID_POGO_PATH = os.path.join(CURR_BRAIN_DIR, "hero_pogo_grid_1791205463734.jpg")

def clean_floodfill(img, tolerance=36):
    """Clean floodfill cutout from borders protecting warm golden light blade glow."""
    arr = np.array(img.convert('RGB'), dtype=np.int32)
    h, w, _ = arr.shape
    corner = arr[0:6, 0:6].mean(axis=(0, 1))
    dist = np.sqrt(np.sum((arr - corner)**2, axis=2))
    
    is_candidate = (dist < tolerance) | (
        (arr[:, :, 0] > 205) & (arr[:, :, 1] > 200) & (arr[:, :, 2] > 190) &
        (np.abs(arr[:, :, 0] - arr[:, :, 1]) < 24) & (np.abs(arr[:, :, 1] - arr[:, :, 2]) < 24)
    )
    # Protect golden blade glow and energetic spark core
    blade_glow = (arr[:, :, 0] > 200) & (arr[:, :, 1] > 160) & (arr[:, :, 2] < arr[:, :, 0] - 10)
    is_candidate[blade_glow] = False
    
    bg_mask = np.zeros((h, w), dtype=bool)
    queue = deque()
    for x in range(w):
        if is_candidate[0, x]: queue.append((0, x)); bg_mask[0, x] = True
        if is_candidate[h-1, x]: queue.append((h-1, x)); bg_mask[h-1, x] = True
    for y in range(h):
        if is_candidate[y, 0]: queue.append((y, 0)); bg_mask[y, 0] = True
        if is_candidate[y, w-1]: queue.append((y, w-1)); bg_mask[y, w-1] = True
        
    while queue:
        cy, cx = queue.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w:
                if not bg_mask[ny, nx] and is_candidate[ny, nx]:
                    bg_mask[ny, nx] = True
                    queue.append((ny, nx))
                    
    trapped = is_candidate & (dist < tolerance * 1.15)
    final_bg = bg_mask | trapped
    alpha = np.where(final_bg, 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([arr.astype(np.uint8), alpha]), mode='RGBA')

def get_bbox(img, alpha_th=20):
    arr = np.array(img)
    alpha = arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > alpha_th)
    if len(x_idx) == 0 or len(y_idx) == 0:
        return 0, 0, img.width, img.height
    return int(x_idx.min()), int(y_idx.min()), int(x_idx.max()) + 1, int(y_idx.max()) + 1

def make_pixel_art_720(frame_2k, max_colors=24):
    small = frame_2k.resize((64, 64), Image.Resampling.BILINEAR)
    arr = np.array(small)
    alpha = arr[:, :, 3]
    hard_alpha = (alpha > 80).astype(np.uint8) * 255
    rgb_img = Image.fromarray(arr[:, :, :3], mode='RGB')
    mask = Image.fromarray(hard_alpha, mode='L')
    quantized = rgb_img.quantize(colors=max_colors, method=Image.Quantize.MEDIANCUT).convert('RGB')
    quantized.putalpha(mask)
    return quantized

def save_sprite(name, img_2k, img_720=None):
    for s_dir in DESTS_SPRITES:
        os.makedirs(s_dir, exist_ok=True)
        img_2k.save(os.path.join(s_dir, f"{name}.png"))
        if img_720 is not None:
            px_name = f"px_{name}"
            img_720.save(os.path.join(s_dir, f"{px_name}.png"))

def save_preview_gif(filename, frames, fps=14, scale_factor=1):
    if scale_factor > 1:
        scaled = [f.resize((f.width * scale_factor, f.height * scale_factor), Image.Resampling.NEAREST) for f in frames]
    else:
        scaled = frames
    duration_ms = int(round(1000.0 / fps))
    for p_dir in DESTS_PREVIEWS:
        os.makedirs(p_dir, exist_ok=True)
        scaled[0].save(
            os.path.join(p_dir, filename),
            save_all=True,
            append_images=scaled[1:],
            duration=duration_ms,
            loop=0
        )
    print(f"Saved preview GIF: {filename} ({len(frames)} frames @ {fps} FPS, {duration_ms}ms)")

def make_composite(frames_2k, bg_path, out_name, y_ground=880, spacing=260):
    if not os.path.exists(bg_path):
        return
    bg = Image.open(bg_path).convert('RGBA')
    bw, bh = bg.size
    n = len(frames_2k)
    total_w = (n - 1) * spacing
    start_x = (bw - total_w) // 2
    for i, fr in enumerate(frames_2k):
        sc = 340.0 / 512.0
        nw, nh = int(fr.width * sc), int(fr.height * sc)
        rf = fr.resize((nw, nh), Image.Resampling.LANCZOS)
        x = start_x + i * spacing - nw // 2
        y = y_ground - nh
        bg.paste(rf, (x, y), rf)
    for p_dir in DESTS_PREVIEWS:
        os.makedirs(p_dir, exist_ok=True)
        bg.save(os.path.join(p_dir, out_name))
    print(f"Saved composite preview: {out_name}")

def make_pixel_composite(frames_720, bg_path, out_name, y_ground=236, spacing=70):
    if not os.path.exists(bg_path):
        return
    bg = Image.open(bg_path).convert('RGBA')
    bw, bh = bg.size
    n = len(frames_720)
    total_w = (n - 1) * spacing
    start_x = (bw - total_w) // 2
    for i, fr in enumerate(frames_720):
        x = start_x + i * spacing - fr.width // 2
        y = y_ground - fr.height
        bg.paste(fr, (x, y), fr)
    up = bg.resize((bw * 3, bh * 3), Image.Resampling.NEAREST)
    for p_dir in DESTS_PREVIEWS:
        os.makedirs(p_dir, exist_ok=True)
        up.save(os.path.join(p_dir, out_name))
    print(f"Saved pixel composite preview: {out_name}")

def build_all_parkour():
    print("=== Building All Parkour Animation Frames for 'Glitched Out' ===")
    
    # Target global scale: matching hero_idle (83px head height, 430px body scale)
    SCALE_GLOBAL = 0.692
    
    frames_2k_dict = {}
    frames_720_dict = {}
    
    # -------------------------------------------------------------------------
    # 1. HERO WALLSLIDE (hero_wallslide_1 ... hero_wallslide_3)
    # Clinging to wall on right side, sliding down: one hand and one boot against wall,
    # blade held out, cape fluttering upward (loop). Put right hand/boot at right edge.
    # -------------------------------------------------------------------------
    print("\n--- 1. Processing Wallslide (3 frames) ---")
    arr_ws = np.array(Image.open(GRID_WALLSLIDE_PATH).convert('RGB'))
    cuts_ws = [
        clean_floodfill(Image.fromarray(arr_ws[:, :460])),
        clean_floodfill(Image.fromarray(arr_ws[:, 460:920])),
        clean_floodfill(Image.fromarray(arr_ws[:, 920:])),
    ]
    
    wallslide_2k = []
    wallslide_720 = []
    # Anchor right edge (hand and boot touching wall) at x=445
    WALL_X = 445
    
    for i, cut in enumerate(cuts_ws):
        b = get_bbox(cut)
        char = cut.crop(b)
        nw = int(round(char.width * SCALE_GLOBAL))
        nh = int(round(char.height * SCALE_GLOBAL))
        res = char.resize((nw, nh), Image.Resampling.LANCZOS)
        
        can = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
        x_pos = WALL_X - nw
        # Sliding down in mid-air: maintain continuous vertical slide level
        # In frame 1 boot at y=437, in frame 2 cape billows higher to y=42 while boot flexes to y=471, frame 3 returns to y=440
        y_pos = int(round(256 - nh / 2.0))
        can.paste(res, (x_pos, y_pos), res)
        
        # Ensure zero rogue edge pixels
        arr_can = np.array(can)
        arr_can[:10, :] = 0
        arr_can[-10:, :] = 0
        arr_can[:, :10] = 0
        arr_can[:, -10:] = 0
        clean_can = Image.fromarray(arr_can, mode='RGBA')
        
        px_can = make_pixel_art_720(clean_can)
        name = f"hero_wallslide_{i+1}"
        save_sprite(name, clean_can, px_can)
        frames_2k_dict[name] = clean_can
        frames_720_dict[f"px_{name}"] = px_can
        wallslide_2k.append(clean_can)
        wallslide_720.append(px_can)
        print(f"Delivered {name} (bbox: {get_bbox(clean_can)})")
        
    save_sprite("hero_wallslide", wallslide_2k[1], wallslide_720[1])
    save_preview_gif("hero_wallslide_2k.gif", wallslide_2k, fps=14)
    save_preview_gif("hero_wallslide_720.gif", wallslide_720, fps=14, scale_factor=3)
    
    # -------------------------------------------------------------------------
    # 2. HERO WALLJUMP (hero_walljump_1 ... hero_walljump_3)
    # Kicking off that wall: crouched against it, explosive push away (turning left,
    # cape whipping), launched in the air.
    # -------------------------------------------------------------------------
    print("\n--- 2. Processing Walljump (3 frames) ---")
    arr_wj = np.array(Image.open(GRID_WALLJUMP_PATH).convert('RGB'))
    # Clean thin vertical divider lines between cells
    arr_wj[:, 386:394] = 255
    arr_wj[:, 899:906] = 255
    
    scale_wj = 0.710
    
    # Frame 1: crouched against wall (boots touching right wall plane at x=WALL_X)
    cut_wj1 = clean_floodfill(Image.fromarray(arr_wj[:, :386]))
    b1 = get_bbox(cut_wj1)
    c1 = cut_wj1.crop(b1)
    nw1, nh1 = int(round(c1.width * scale_wj)), int(round(c1.height * scale_wj))
    res1 = c1.resize((nw1, nh1), Image.Resampling.LANCZOS)
    can_wj1 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_wj1.paste(res1, (WALL_X - nw1, int(round(440 - nh1))), res1)
    
    # Frame 2: kicking off wall (feet pushing off at x=WALL_X, body rotating left, blade overhead)
    cut_wj2 = clean_floodfill(Image.fromarray(arr_wj[:, 394:899]))
    b2 = get_bbox(cut_wj2)
    c2 = cut_wj2.crop(b2)
    nw2, nh2 = int(round(c2.width * scale_wj)), int(round(c2.height * scale_wj))
    res2 = c2.resize((nw2, nh2), Image.Resampling.LANCZOS)
    can_wj2 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_wj2.paste(res2, (WALL_X - nw2, int(round(440 - nh2))), res2)
    
    # Frame 3: airborne, soaring in the air with knees tucked
    cut_wj3 = clean_floodfill(Image.fromarray(arr_wj[:, 906:]))
    b3 = get_bbox(cut_wj3)
    c3 = cut_wj3.crop(b3)
    nw3, nh3 = int(round(c3.width * scale_wj)), int(round(c3.height * scale_wj))
    res3 = c3.resize((nw3, nh3), Image.Resampling.LANCZOS)
    can_wj3 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_wj3.paste(res3, ((512 - nw3) // 2, 70), res3)
    
    walljump_2k = []
    walljump_720 = []
    for i, can in enumerate([can_wj1, can_wj2, can_wj3]):
        arr_can = np.array(can)
        arr_can[:10, :] = 0
        arr_can[-10:, :] = 0
        arr_can[:, :10] = 0
        arr_can[:, -10:] = 0
        clean_can = Image.fromarray(arr_can, mode='RGBA')
        px_can = make_pixel_art_720(clean_can)
        name = f"hero_walljump_{i+1}"
        save_sprite(name, clean_can, px_can)
        frames_2k_dict[name] = clean_can
        frames_720_dict[f"px_{name}"] = px_can
        walljump_2k.append(clean_can)
        walljump_720.append(px_can)
        print(f"Delivered {name} (bbox: {get_bbox(clean_can)})")
        
    save_sprite("hero_walljump", walljump_2k[1], walljump_720[1])
    save_preview_gif("hero_walljump_2k.gif", walljump_2k, fps=14)
    save_preview_gif("hero_walljump_720.gif", walljump_720, fps=14, scale_factor=3)
    
    # -------------------------------------------------------------------------
    # 3. HERO AIRDASH (hero_airdash_1 ... hero_airdash_3)
    # A horizontal dash in mid-air: tucked, body horizontal, blade forward, cape
    # streaming straight back, then recovering.
    # -------------------------------------------------------------------------
    print("\n--- 3. Processing Airdash (3 frames) ---")
    arr_ad = np.array(Image.open(GRID_AIRDASH_PATH).convert('RGB'))
    scale_ad = 0.692
    
    # Frame 1: mid-air tuck
    c1_img = Image.fromarray(arr_ad[:, :360])
    cut_ad1 = clean_floodfill(c1_img)
    b1 = get_bbox(cut_ad1)
    c1 = cut_ad1.crop(b1)
    nw1, nh1 = int(round(c1.width * scale_ad)), int(round(c1.height * scale_ad))
    res1 = c1.resize((nw1, nh1), Image.Resampling.LANCZOS)
    can_ad1 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_ad1.paste(res1, (160, 150), res1)
    
    # Frame 2: full horizontal supersonic dash, blade thrust forward, cape trailing back
    c2_arr = arr_ad[:, 360:956].copy()
    c2_arr[:250, 950-360:] = 255
    cut_ad2 = clean_floodfill(Image.fromarray(c2_arr))
    b2 = get_bbox(cut_ad2)
    c2 = cut_ad2.crop(b2)
    nw2, nh2 = int(round(c2.width * scale_ad)), int(round(c2.height * scale_ad))
    res2 = c2.resize((nw2, nh2), Image.Resampling.LANCZOS)
    can_ad2 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_ad2.paste(res2, ((512 - nw2) // 2, 175), res2)
    
    # Frame 3: air dash recovery in mid-air
    c3_arr = arr_ad[:, 940:].copy()
    c3_arr[330:, :960-940] = 255
    cut_ad3 = clean_floodfill(Image.fromarray(c3_arr))
    b3 = get_bbox(cut_ad3)
    c3 = cut_ad3.crop(b3)
    nw3, nh3 = int(round(c3.width * scale_ad)), int(round(c3.height * scale_ad))
    res3 = c3.resize((nw3, nh3), Image.Resampling.LANCZOS)
    can_ad3 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_ad3.paste(res3, ((512 - nw3) // 2, 85), res3)
    
    airdash_2k = []
    airdash_720 = []
    for i, can in enumerate([can_ad1, can_ad2, can_ad3]):
        arr_can = np.array(can)
        arr_can[:10, :] = 0
        arr_can[-10:, :] = 0
        arr_can[:, :10] = 0
        arr_can[:, -10:] = 0
        clean_can = Image.fromarray(arr_can, mode='RGBA')
        px_can = make_pixel_art_720(clean_can)
        name = f"hero_airdash_{i+1}"
        save_sprite(name, clean_can, px_can)
        frames_2k_dict[name] = clean_can
        frames_720_dict[f"px_{name}"] = px_can
        airdash_2k.append(clean_can)
        airdash_720.append(px_can)
        print(f"Delivered {name} (bbox: {get_bbox(clean_can)})")
        
    save_sprite("hero_airdash", airdash_2k[1], airdash_720[1])
    save_preview_gif("hero_airdash_2k.gif", airdash_2k, fps=14)
    save_preview_gif("hero_airdash_720.gif", airdash_720, fps=14, scale_factor=3)
    
    # -------------------------------------------------------------------------
    # 4. HERO DIVE (hero_dive_1 ... hero_dive_3)
    # Diagonal dive-strike down and forward: wind-up in the air, the dive with the
    # blade pointed down-forward and a strong light trail, bounce off the target.
    # -------------------------------------------------------------------------
    print("\n--- 4. Processing Dive Strike (3 frames) ---")
    arr_dv = np.array(Image.open(GRID_DIVE_PATH).convert('RGB'))
    # Clean bottom caption text
    arr_dv[725:, :] = 255
    scale_dv = 0.700
    
    # Frame 1: dive windup high in air
    cut_dv1 = clean_floodfill(Image.fromarray(arr_dv[:, :400]))
    b1 = get_bbox(cut_dv1)
    c1 = cut_dv1.crop(b1)
    nw1, nh1 = int(round(c1.width * scale_dv)), int(round(c1.height * scale_dv))
    res1 = c1.resize((nw1, nh1), Image.Resampling.LANCZOS)
    can_dv1 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_dv1.paste(res1, ((512 - nw1) // 2, 20), res1)
    
    # Frame 2: dive plunge down-forward with vibrant light trail cone
    c2_arr = arr_dv[:, 400:956].copy()
    c2_arr[:550, 945-400:] = 255
    cut_dv2 = clean_floodfill(Image.fromarray(c2_arr))
    b2 = get_bbox(cut_dv2)
    c2 = cut_dv2.crop(b2)
    nw2, nh2 = int(round(c2.width * scale_dv)), int(round(c2.height * scale_dv))
    res2 = c2.resize((nw2, nh2), Image.Resampling.LANCZOS)
    can_dv2 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_dv2.paste(res2, (70, 500 - nh2), res2)
    
    # Frame 3: bounce/recoil off target
    c3_arr = arr_dv[:, 940:].copy()
    c3_arr[550:, :955-940] = 255
    cut_dv3 = clean_floodfill(Image.fromarray(c3_arr))
    b3 = get_bbox(cut_dv3)
    c3 = cut_dv3.crop(b3)
    nw3, nh3 = int(round(c3.width * scale_dv)), int(round(c3.height * scale_dv))
    res3 = c3.resize((nw3, nh3), Image.Resampling.LANCZOS)
    can_dv2_recoil = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_dv2_recoil.paste(res3, ((512 - nw3) // 2, 511 - nh3), res3)
    
    dive_2k = []
    dive_720 = []
    for i, can in enumerate([can_dv1, can_dv2, can_dv2_recoil]):
        arr_can = np.array(can)
        arr_can[:10, :] = 0
        arr_can[-10:, :] = 0
        arr_can[:, :10] = 0
        arr_can[:, -10:] = 0
        clean_can = Image.fromarray(arr_can, mode='RGBA')
        px_can = make_pixel_art_720(clean_can)
        name = f"hero_dive_{i+1}"
        save_sprite(name, clean_can, px_can)
        frames_2k_dict[name] = clean_can
        frames_720_dict[f"px_{name}"] = px_can
        dive_2k.append(clean_can)
        dive_720.append(px_can)
        print(f"Delivered {name} (bbox: {get_bbox(clean_can)})")
        
    save_sprite("hero_dive", dive_2k[1], dive_720[1])
    save_preview_gif("hero_dive_2k.gif", dive_2k, fps=14)
    save_preview_gif("hero_dive_720.gif", dive_720, fps=14, scale_factor=3)
    
    # -------------------------------------------------------------------------
    # 5. HERO POGO (hero_pogo_1 ... hero_pogo_2)
    # The bounce after a downward slash hits: knees up, blade below him, springing upward.
    # -------------------------------------------------------------------------
    print("\n--- 5. Processing Pogo Bounce (2 frames) ---")
    arr_pg = np.array(Image.open(GRID_POGO_PATH).convert('RGB'))
    scale_pg = 0.692
    
    # Frame 1: pogo impact compression, spark burst at bottom contact point
    cut_pg1 = clean_floodfill(Image.fromarray(arr_pg[:, :600]))
    b1 = get_bbox(cut_pg1)
    c1 = cut_pg1.crop(b1)
    nw1, nh1 = int(round(c1.width * scale_pg)), int(round(c1.height * scale_pg))
    res1 = c1.resize((nw1, nh1), Image.Resampling.LANCZOS)
    can_pg1 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_pg1.paste(res1, ((512 - nw1) // 2, 511 - nh1), res1)
    
    # Frame 2: springing upward into the sky
    cut_pg2 = clean_floodfill(Image.fromarray(arr_pg[:, 600:]))
    b2 = get_bbox(cut_pg2)
    c2 = cut_pg2.crop(b2)
    nw2, nh2 = int(round(c2.width * scale_pg)), int(round(c2.height * scale_pg))
    res2 = c2.resize((nw2, nh2), Image.Resampling.LANCZOS)
    can_pg2 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_pg2.paste(res2, ((512 - nw2) // 2, 25), res2)
    
    pogo_2k = []
    pogo_720 = []
    for i, can in enumerate([can_pg1, can_pg2]):
        arr_can = np.array(can)
        arr_can[:10, :] = 0
        arr_can[-10:, :] = 0
        arr_can[:, :10] = 0
        arr_can[:, -10:] = 0
        clean_can = Image.fromarray(arr_can, mode='RGBA')
        px_can = make_pixel_art_720(clean_can)
        name = f"hero_pogo_{i+1}"
        save_sprite(name, clean_can, px_can)
        frames_2k_dict[name] = clean_can
        frames_720_dict[f"px_{name}"] = px_can
        pogo_2k.append(clean_can)
        pogo_720.append(px_can)
        print(f"Delivered {name} (bbox: {get_bbox(clean_can)})")
        
    save_sprite("hero_pogo", pogo_2k[0], pogo_720[0])
    save_preview_gif("hero_pogo_2k.gif", pogo_2k, fps=14)
    save_preview_gif("hero_pogo_720.gif", pogo_720, fps=14, scale_factor=3)
    
    # -------------------------------------------------------------------------
    # 6. PARKOUR COMBO FLOW & COMPOSITES
    # -------------------------------------------------------------------------
    print("\n--- 6. Generating Parkour Combo Flows & Composites ---")
    parkour_flow_2k = [
        wallslide_2k[0], wallslide_2k[1], wallslide_2k[2],
        walljump_2k[0], walljump_2k[1], walljump_2k[2],
        airdash_2k[0], airdash_2k[1], airdash_2k[2],
        dive_2k[0], dive_2k[1], dive_2k[2],
        pogo_2k[0], pogo_2k[1]
    ]
    parkour_flow_720 = [
        wallslide_720[0], wallslide_720[1], wallslide_720[2],
        walljump_720[0], walljump_720[1], walljump_720[2],
        airdash_720[0], airdash_720[1], airdash_720[2],
        dive_720[0], dive_720[1], dive_720[2],
        pogo_720[0], pogo_720[1]
    ]
    
    save_preview_gif("hero_parkour_combo_2k.gif", parkour_flow_2k, fps=14)
    save_preview_gif("hero_parkour_combo_720.gif", parkour_flow_720, fps=14, scale_factor=3)
    
    comp_2k_parkour = [wallslide_2k[1], walljump_2k[1], airdash_2k[1], dive_2k[1], pogo_2k[0]]
    comp_720_parkour = [wallslide_720[1], walljump_720[1], airdash_720[1], dive_720[1], pogo_720[0]]
    
    make_composite(comp_2k_parkour, BG_2K_ARENA, "preview_parkour_2k.png", y_ground=880, spacing=260)
    make_pixel_composite(comp_720_parkour, BG_720_NEON, "preview_parkour_720.png", y_ground=236, spacing=70)
    
    print("\nAll 14 Parkour frames and preview GIFs successfully built and verified!")

if __name__ == "__main__":
    build_all_parkour()
