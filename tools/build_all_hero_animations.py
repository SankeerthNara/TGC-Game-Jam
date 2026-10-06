"""
Hero Animation Pipeline for 'Glitched Out' (2K Painted and 720p Pixel Art)
"""

import os
import sys
from collections import deque
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

BRAIN_DIR = r"C:\Users\sanke\.gemini\antigravity-ide\brain\0e3e4b2c-4485-48cb-a8eb-d7adf359721c"
GRID_RUN_PATH = r"C:\Users\sanke\.gemini\antigravity-ide\brain\bcb3d432-669d-4728-9b1c-a1cd5bd1d9fd\hero_run_grid_1791176956112.jpg"
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

BG_2K_HALL = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "2k", "hall_far.jpg")
BG_2K_ARENA = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "2k", "arena_far.jpg")
BG_720_NEON = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "720", "neon_mid.png")

PARKOUR_BRAIN_DIR = r"C:\Users\sanke\.gemini\antigravity-ide\brain\cbb40665-76c8-44b8-b1b3-35084d6ab57c"
GRID_WALLSLIDE_PATH = os.path.join(PARKOUR_BRAIN_DIR, "hero_wallslide_grid_b_1791205490833.jpg")
GRID_WALLJUMP_PATH = os.path.join(PARKOUR_BRAIN_DIR, "hero_walljump_grid_1791205224314.jpg")
GRID_AIRDASH_PATH = os.path.join(PARKOUR_BRAIN_DIR, "hero_airdash_grid_1791205348586.jpg")
GRID_DIVE_PATH = os.path.join(PARKOUR_BRAIN_DIR, "hero_dive_grid_1791205432945.jpg")
GRID_POGO_PATH = os.path.join(PARKOUR_BRAIN_DIR, "hero_pogo_grid_1791205463734.jpg")

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
    # Protect golden blade glow
    blade_glow = (arr[:, :, 0] > 215) & (arr[:, :, 1] > 170) & (arr[:, :, 2] < arr[:, :, 0] - 15)
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

def save_preview_gif(filename, frames, fps=8, scale_factor=1):
    if scale_factor > 1:
        scaled = [f.resize((f.width * scale_factor, f.height * scale_factor), Image.Resampling.NEAREST) for f in frames]
    else:
        scaled = frames
    duration_ms = int(1000.0 / fps)
    for p_dir in DESTS_PREVIEWS:
        os.makedirs(p_dir, exist_ok=True)
        scaled[0].save(
            os.path.join(p_dir, filename),
            save_all=True,
            append_images=scaled[1:],
            duration=duration_ms,
            loop=0
        )
    print(f"Saved preview GIF: {filename} ({len(frames)} frames @ {fps} FPS)")

def place_on_canvas(char_img, scale=1.0, y_offset=0, x_shift=0):
    nw = max(1, int(round(char_img.width * scale)))
    nh = max(1, int(round(char_img.height * scale)))
    resized = char_img.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    x = (512 - nw) // 2 + x_shift
    y = 512 - nh - y_offset
    canvas.paste(resized, (x, y), resized)
    return canvas

def make_composite(frames_2k, bg_path, out_name, y_ground=880, spacing=260):
    if not os.path.exists(bg_path):
        return
    bg = Image.open(bg_path).convert('RGBA')
    bw, bh = bg.size
    n = len(frames_2k)
    total_w = (n - 1) * spacing
    start_x = (bw - total_w) // 2
    for i, fr in enumerate(frames_2k):
        # Scale 512 frame to ~340px on 1080p background
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
        # 64x64 frame grounded at y_ground
        x = start_x + i * spacing - fr.width // 2
        y = y_ground - fr.height
        bg.paste(fr, (x, y), fr)
    # Upscale 3x for crisp viewing
    up = bg.resize((bw * 3, bh * 3), Image.Resampling.NEAREST)
    for p_dir in DESTS_PREVIEWS:
        os.makedirs(p_dir, exist_ok=True)
        up.save(os.path.join(p_dir, out_name))
    print(f"Saved pixel composite preview: {out_name}")

# =========================================================================
# GROUP 1: MOVEMENT FIXES (hero_run_3 glowing blade & hero_run_6 1.06x rescale)
# =========================================================================
def process_group1_touchup():
    print("\n--- Processing Group 1 Movement Fixes (run_3 blade & run_6 scale) ---")
    s_dir = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "sprites")
    
    # ---------------------------------------------------------------------
    # 1. FIX hero_run_3.png & px_hero_run_3.png: Glowing White-Gold Light Blade
    # ---------------------------------------------------------------------
    # Load clean unblemished raw cell 3 from master run grid
    grid = Image.open(GRID_RUN_PATH)
    cw = grid.width / 6.0
    rh = grid.height / 2.0
    cell3 = grid.crop((int(2 * cw), 0, int(3 * cw), int(rh)))
    cut3 = clean_floodfill(cell3)
    bx0, by0, bx1, by1 = get_bbox(cut3)
    char3 = cut3.crop((bx0, by0, bx1, by1))
    
    max_char_h = 329.0
    global_scale_2k = 440.0 / max_char_h
    nw3 = int(round(char3.width * global_scale_2k))
    nh3 = int(round(char3.height * global_scale_2k))
    resized3 = char3.resize((nw3, nh3), Image.Resampling.LANCZOS)
    canvas3 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    canvas3.paste(resized3, ((512 - nw3) // 2, 512 - nh3), resized3)
    
    # Extract authentic painted glowing blades from run_2 and run_4
    im2 = Image.open(os.path.join(s_dir, "hero_run_2.png"))
    im4 = Image.open(os.path.join(s_dir, "hero_run_4.png"))
    arr2 = np.array(im2)
    arr4 = np.array(im4)
    
    def extract_blade(arr, p0, p1, radius=32):
        h, w, _ = arr.shape
        yy, xx = np.mgrid[:h, :w]
        dx = p1[0] - p0[0]
        dy = p1[1] - p0[1]
        t = np.clip(((xx - p0[0]) * dx + (yy - p0[1]) * dy) / (dx*dx + dy*dy), 0.0, 1.0)
        dist = np.hypot(xx - (p0[0] + t * dx), yy - (p0[1] + t * dy))
        is_blade = (arr[:,:,3] > 15) & (
            ((arr[:,:,0] > 180) & (arr[:,:,1] > 140)) |
            ((arr[:,:,0] > 220) & (arr[:,:,1] > 200))
        ) & ~(arr[:,:,2] > arr[:,:,0] + 5)
        res = np.zeros_like(arr)
        res[(dist < radius) & is_blade] = arr[(dist < radius) & is_blade]
        return Image.fromarray(res, mode='RGBA')
        
    b2 = extract_blade(arr2, (236, 296), (351, 413), radius=35)
    b4 = extract_blade(arr4, (196, 278), (300, 409), radius=35)
    
    def transform_blade(blade_img, p_hilt, p_tip, target_hilt, target_tip):
        dx = p_tip[0] - p_hilt[0]
        dy = p_tip[1] - p_hilt[1]
        src_len = np.hypot(dx, dy)
        src_ang = np.degrees(np.arctan2(dy, dx))
        tdx = target_tip[0] - target_hilt[0]
        tdy = target_tip[1] - target_hilt[1]
        tgt_len = np.hypot(tdx, tdy)
        tgt_ang = np.degrees(np.arctan2(tdy, tdx))
        rot_deg = tgt_ang - src_ang
        scale_fac = tgt_len / src_len
        
        bx0, by0, bx1, by1 = get_bbox(blade_img)
        m = 25
        bx0, by0 = max(0, bx0 - m), max(0, by0 - m)
        bx1, by1 = min(512, bx1 + m), min(512, by1 + m)
        cropped = blade_img.crop((bx0, by0, bx1, by1))
        
        ch_x = p_hilt[0] - bx0
        ch_y = p_hilt[1] - by0
        snw = int(round(cropped.width * scale_fac))
        snh = int(round(cropped.height * scale_fac))
        scaled = cropped.resize((snw, snh), Image.Resampling.LANCZOS)
        sch_x = ch_x * scale_fac
        sch_y = ch_y * scale_fac
        
        R = int(np.ceil(np.hypot(snw, snh))) * 2
        pad_img = Image.new('RGBA', (R, R), (0, 0, 0, 0))
        pad_cx, pad_cy = R // 2, R // 2
        pad_img.paste(scaled, (int(round(pad_cx - sch_x)), int(round(pad_cy - sch_y))), scaled)
        rotated = pad_img.rotate(-rot_deg, resample=Image.Resampling.BICUBIC)
        
        res = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
        res.paste(rotated, (int(round(target_hilt[0] - pad_cx)), int(round(target_hilt[1] - pad_cy))), rotated)
        return res
        
    t_hilt = (216, 287)
    t_tip = (326, 411)
    b2_trans = transform_blade(b2, (236, 296), (351, 413), t_hilt, t_tip)
    b4_trans = transform_blade(b4, (196, 278), (300, 409), t_hilt, t_tip)
    
    # Blend authentic blades with vibrant golden bloom and pure white interior core
    blended = np.maximum(np.array(b2_trans, dtype=np.float32), np.array(b4_trans, dtype=np.float32))
    
    layer_beam = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    draw_beam = ImageDraw.Draw(layer_beam)
    draw_beam.line([t_hilt, t_tip], fill=(255, 185, 60, 160), width=18)
    layer_beam = layer_beam.filter(ImageFilter.GaussianBlur(radius=4))
    
    draw_beam2 = ImageDraw.Draw(layer_beam)
    draw_beam2.line([t_hilt, t_tip], fill=(255, 245, 190, 240), width=9)
    draw_beam2.line([t_hilt, t_tip], fill=(255, 255, 255, 255), width=4)
    
    final_blade_arr = np.maximum(blended, np.array(layer_beam, dtype=np.float32))
    final_blade = Image.fromarray(final_blade_arr.astype(np.uint8), mode='RGBA')
    
    canvas3_mod = canvas3.copy()
    canvas3_mod.paste(final_blade, (0, 0), final_blade)
    
    # Wrap glove fingers over hilt
    arr_orig = np.array(canvas3)
    arr_out = np.array(canvas3_mod)
    glove = (arr_orig[:,:,3] > 100) & (arr_orig[:,:,0] < 80) & (arr_orig[:,:,1] < 80) & (arr_orig[:,:,2] < 90)
    yy, xx = np.mgrid[:512, :512]
    wrap_region = glove & (xx >= 204) & (xx <= 226) & (yy >= 275) & (yy <= 295)
    arr_out[wrap_region] = arr_orig[wrap_region]
    
    final_r3 = Image.fromarray(arr_out, mode='RGBA')
    px_r3 = make_pixel_art_720(final_r3)
    save_sprite("hero_run_3", final_r3, px_r3)
    
    # ---------------------------------------------------------------------
    # 2. FIX hero_run_6.png & px_hero_run_6.png: Rescale to Match Neighbours
    # ---------------------------------------------------------------------
    im6 = Image.open(os.path.join(s_dir, "hero_run_6.png"))
    bx0, by0, bx1, by1 = get_bbox(im6)
    char6 = im6.crop((bx0, by0, bx1, by1))
    
    # Target height 430px (matching run_5 at 428px and run_7 at 437px)
    scale_fac = 430.0 / char6.height
    nw6 = int(round(char6.width * scale_fac))
    nh6 = int(round(char6.height * scale_fac))
    res6 = char6.resize((nw6, nh6), Image.Resampling.LANCZOS)
    
    can6 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    arr_r = np.array(res6)
    hip_m = (arr_r[int(nh6 * 0.5):int(nh6 * 0.75), :, 3] > 80)
    hip_x = np.where(hip_m)[1].mean() if hip_m.sum() > 0 else nw6 / 2.0
    can6.paste(res6, (int(round(256 - hip_x)), 511 - nh6), res6)
    
    px_r6 = make_pixel_art_720(can6)
    save_sprite("hero_run_6", can6, px_r6)
    
    # ---------------------------------------------------------------------
    # 3. Rebuild 16 FPS GIFs and Composite Previews
    # ---------------------------------------------------------------------
    run_frames_2k = [Image.open(os.path.join(s_dir, f"hero_run_{i}.png")) for i in range(1, 13)]
    run_frames_720 = [Image.open(os.path.join(s_dir, f"px_hero_run_{i}.png")) for i in range(1, 11)]
    
    save_preview_gif("hero_run_2k.gif", run_frames_2k, fps=16)
    save_preview_gif("hero_run_720.gif", run_frames_720, fps=16, scale_factor=3)
    
    # Update movement composites
    comp_2k_frames = [run_frames_2k[0], run_frames_2k[2], run_frames_2k[5], run_frames_2k[6]]
    make_composite(comp_2k_frames, BG_2K_HALL, "preview_movement_2k.png", y_ground=880, spacing=260)
    
    comp_720_frames = [run_frames_720[0], run_frames_720[2], run_frames_720[5], run_frames_720[6]]
    make_pixel_composite(comp_720_frames, BG_720_NEON, "preview_movement_720.png", y_ground=236, spacing=70)
    print("Group 1 Movement fixes complete (run_3 blade & run_6 scale @ 16 FPS).")

# =========================================================================
# GROUP 2: IDLE (6 frames 2K, 4 frames 720p)
# =========================================================================
def process_group2_idle():
    print("\n--- Processing Group 2: Idle (6 frames 2K, 4 frames 720p) ---")
    grid_path = os.path.join(BRAIN_DIR, "hero_idle_grid_1791195429637.jpg")
    grid = Image.open(grid_path)
    gw, gh = grid.size
    cols, rows = 3, 2
    cw = gw / cols
    rh = gh / rows
    
    cells = []
    for r in range(rows):
        for c in range(cols):
            box = (int(c * cw), int(r * rh), int((c+1) * cw), int((r+1) * rh))
            cell = grid.crop(box)
            cut = clean_floodfill(cell)
            cells.append(cut)
            
    # Clean secondary blade artifact from left hand in cells 2..6
    for i in range(1, 6):
        arr = np.array(cells[i])
        h, w, _ = arr.shape
        xc = np.arange(w)[None, :]
        yc = np.arange(h)[:, None]
        stick = (xc > 318) & (yc > 240) & (arr[:,:,0] > 180) & (arr[:,:,1] > 160)
        glow = (xc > 315) & (yc > 240) & (arr[:,:,0] > 170) & (arr[:,:,2] < 200) & (arr[:,:,3] < 240)
        arr[stick, 3] = 0
        arr[glow, 3] = 0
        cells[i] = Image.fromarray(arr, mode='RGBA')
        
    # Scale and center on 512x512 canvas:
    # Character body height in raw cells is ~395px.
    # Desired standing body height is 440px -> scale = 440.0 / 395.0 = 1.114
    scale = 440.0 / 395.0
    frames_2k = []
    for i, char_img in enumerate(cells):
        bx0, by0, bx1, by1 = get_bbox(char_img)
        # Bounding box crop
        char = char_img.crop((bx0, by0, bx1, by1))
        nw = int(round(char.width * scale))
        nh = int(round(char.height * scale))
        resized = char.resize((nw, nh), Image.Resampling.LANCZOS)
        
        canvas = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
        x_pos = (512 - nw) // 2
        # Feet firmly planted at y=511 (bottom edge)
        y_pos = 512 - nh
        canvas.paste(resized, (x_pos, y_pos), resized)
        frames_2k.append(canvas)
        
    # Save 2K Idle frames (hero_idle_1 ... hero_idle_6)
    for i, fr in enumerate(frames_2k):
        save_sprite(f"hero_idle_{i+1}", fr)
    # Also update master fallback hero_idle.png
    save_sprite("hero_idle", frames_2k[0])
    
    # Save 720p Pixel Art Idle frames (px_hero_idle_1 ... px_hero_idle_4)
    # Use evenly spaced frames from breathing cycle: [0, 1, 2, 4]
    idle_720_indices = [0, 1, 2, 4]
    frames_720 = []
    for out_idx, in_idx in enumerate(idle_720_indices):
        px_fr = make_pixel_art_720(frames_2k[in_idx])
        save_sprite(f"hero_idle_{out_idx+1}", frames_2k[in_idx], px_fr)
        frames_720.append(px_fr)
    save_sprite("hero_idle", frames_2k[0], frames_720[0])
    
    # Save preview GIFs
    save_preview_gif("hero_idle_2k.gif", frames_2k, fps=8)
    save_preview_gif("hero_idle_720.gif", frames_720, fps=8, scale_factor=3)
    
    # Save background composites
    make_composite([frames_2k[0], frames_2k[2], frames_2k[4]], BG_2K_HALL, "preview_idle_2k.png", y_ground=880, spacing=350)
    make_pixel_composite([frames_720[0], frames_720[1], frames_720[2]], BG_720_NEON, "preview_idle_720.png", y_ground=236, spacing=80)
    print("Group 2 Idle complete.")

# =========================================================================
# GROUP 3: ATTACKS (10 frames 2K, 17 frames 720p combat)
# =========================================================================
def process_group3_attacks():
    print("\n--- Processing Group 3: Attacks & Combat ---")
    att_path = os.path.join(BRAIN_DIR, "hero_attacks_grid_1791195558475.jpg")
    att_img = Image.open(att_path)
    gw, gh = att_img.size
    cols, rows = 5, 2
    cw = gw / cols
    
    scale_att = 1.30
    names_2k = [
        "hero_attack1_1", "hero_attack1_2", "hero_attack1_3",
        "hero_attack2_1", "hero_attack2_2", "hero_attack2_3",
        "hero_attack3_1", "hero_attack3_2", "hero_attack3_3", "hero_attack3_4"
    ]
    
    frames_2k = []
    for idx in range(10):
        r = idx // 5
        c = idx % 5
        y0 = 0 if r == 0 else 356
        y1 = 356 if r == 0 else gh
        cell = att_img.crop((int(c * cw), y0, int((c + 1) * cw), y1))
        cut = clean_floodfill(cell)
        
        nw = int(round(cut.width * scale_att))
        nh = int(round(cut.height * scale_att))
        resized = cut.resize((nw, nh), Image.Resampling.LANCZOS)
        
        base_y = 354 if r == 0 else 379
        if idx == 8:  # impact flash cell rests on ground
            base_y = 398
            
        canvas = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
        arr_c = np.array(cut)
        hy0, hy1 = (120, 240) if r == 0 else (150, 260)
        torso_mask = (arr_c[hy0:hy1, :, 3] > 80)
        torso_x = np.where(torso_mask)[1]
        hip_x = torso_x.mean() if len(torso_x) > 0 else cut.width / 2.0
        
        scaled_hip_x = hip_x * scale_att
        canvas_x = int(round(256 - scaled_hip_x))
        canvas_y = 511 - int(round(base_y * scale_att))
        
        canvas.paste(resized, (canvas_x, canvas_y), resized)
        frames_2k.append(canvas)
        save_sprite(names_2k[idx], canvas)
        
    # Update master fallback hero_attack.png
    save_sprite("hero_attack", frames_2k[1])
    
    # 720p Brawler Combat frames from px_hero_combat_grid
    cb_path = os.path.join(BRAIN_DIR, "px_hero_combat_grid_1791195669073.jpg")
    cb_img = Image.open(cb_path)
    cb_w, cb_h = cb_img.size
    cb_cols, cb_rows = 4, 4
    cb_cw, cb_rh = cb_w / cb_cols, cb_h / cb_rows
    
    scale_px = 54.0 / 168.0
    names_px_combat = [
        "px_hero_punch1_1", "px_hero_punch1_2", "px_hero_punch1_3",
        "px_hero_punch2_1", "px_hero_punch2_2", "px_hero_punch2_3",
        "px_hero_punch3_1", "px_hero_punch3_2", "px_hero_punch3_3", "px_hero_punch3_4",
        "px_hero_roll_1", "px_hero_roll_2", "px_hero_roll_3", "px_hero_roll_4",
        "px_hero_counter_1", "px_hero_counter_2"
    ]
    
    frames_px = []
    for idx in range(16):
        r = idx // 4
        c = idx % 4
        cell = cb_img.crop((int(c * cb_cw), int(r * cb_rh), int((c + 1) * cb_cw), int((r + 1) * cb_rh)))
        cut = clean_floodfill(cell)
        
        arr_c = np.array(cut)
        torso_mask = (arr_c[70:120, :, 3] > 80)
        torso_x = np.where(torso_mask)[1]
        hip_x = torso_x.mean() if len(torso_x) > 0 else cut.width / 2.0
        
        nw = int(round(cut.width * scale_px))
        nh = int(round(cut.height * scale_px))
        resized = cut.resize((nw, nh), Image.Resampling.BILINEAR)
        
        canvas = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
        canvas_x = int(round(32 - hip_x * scale_px))
        canvas_y = 63 - int(round(191 * scale_px))
        canvas.paste(resized, (canvas_x, canvas_y), resized)
        
        # Hard 1-bit alpha and 24-color quantization
        arr = np.array(canvas)
        hard_alpha = (arr[:, :, 3] > 80).astype(np.uint8) * 255
        rgb_img = Image.fromarray(arr[:, :, :3], mode='RGB')
        mask = Image.fromarray(hard_alpha, mode='L')
        quant = rgb_img.quantize(colors=24, method=Image.Quantize.MEDIANCUT).convert('RGB')
        quant.putalpha(mask)
        
        frames_px.append(quant)
        for s_dir in DESTS_SPRITES:
            quant.save(os.path.join(s_dir, f"{names_px_combat[idx]}.png"))
            
    # px_hero_counter_3: Counter recovery returning to ready stance
    counter_3 = frames_px[14].copy()
    frames_px.append(counter_3)
    for s_dir in DESTS_SPRITES:
        counter_3.save(os.path.join(s_dir, "px_hero_counter_3.png"))
        
    # Update master fallbacks
    for s_dir in DESTS_SPRITES:
        frames_px[1].save(os.path.join(s_dir, "px_hero_punch.png"))
        frames_px[7].save(os.path.join(s_dir, "px_hero_kick.png"))
        frames_px[11].save(os.path.join(s_dir, "px_hero_roll.png"))
        
    # Preview GIFs
    save_preview_gif("hero_attack_combo_2k.gif", frames_2k, fps=10)
    save_preview_gif("hero_attack1_2k.gif", frames_2k[0:3], fps=10)
    save_preview_gif("hero_attack2_2k.gif", frames_2k[3:6], fps=10)
    save_preview_gif("hero_attack3_2k.gif", frames_2k[6:10], fps=9)
    save_preview_gif("hero_combat_720.gif", frames_px, fps=10, scale_factor=3)
    save_preview_gif("px_hero_punch_720.gif", frames_px[0:10], fps=10, scale_factor=3)
    save_preview_gif("px_hero_roll_720.gif", frames_px[10:14], fps=10, scale_factor=3)
    
    # Composites
    make_composite([frames_2k[1], frames_2k[4], frames_2k[7], frames_2k[8]], BG_2K_ARENA, "preview_attacks_2k.png", y_ground=880, spacing=280)
    make_pixel_composite([frames_px[1], frames_px[4], frames_px[7], frames_px[11]], BG_720_NEON, "preview_attacks_720.png", y_ground=236, spacing=75)
    print("Group 3 Attacks complete.")

# =========================================================================
# GROUP 4: SPECIAL MOVES (21 frames 2K, plus 720p editions)
# =========================================================================
def process_group4_specials():
    print("\n--- Processing Group 4: Special Moves ---")
    imga_path = os.path.join(BRAIN_DIR, "hero_specials_grid_a_1791195598432.jpg")
    imga = Image.open(imga_path)
    cwa = imga.width / 7.0
    scale_a = 1.30
    
    names_a = [
        "hero_dash_1", "hero_dash_2", "hero_dash_3",
        "hero_upslash_1", "hero_upslash_2", "hero_upslash_3",
        "hero_downslash_1", "hero_downslash_2", "hero_downslash_3",
        "hero_blade_1", "hero_blade_2", "hero_blade_3", "hero_blade_4"
    ]
    
    frames_2k_specials = {}
    frames_720_specials = {}
    
    for idx in range(13):
        r = idx // 7
        c = idx % 7
        y0 = 0 if r == 0 else 356
        y1 = 356 if r == 0 else imga.height
        cell = imga.crop((int(c * cwa), y0, int((c + 1) * cwa), y1))
        cut = clean_floodfill(cell)
        
        nw = int(round(cut.width * scale_a))
        nh = int(round(cut.height * scale_a))
        resized = cut.resize((nw, nh), Image.Resampling.LANCZOS)
        
        base_y = 354 if r == 0 else (735 - 356)
        
        canvas = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
        arr_c = np.array(cut)
        hy0, hy1 = (100, 240) if r == 0 else (120, 260)
        torso_mask = (arr_c[hy0:hy1, :, 3] > 80)
        torso_x = np.where(torso_mask)[1]
        hip_x = torso_x.mean() if len(torso_x) > 0 else cut.width / 2.0
        
        scaled_hip_x = hip_x * scale_a
        canvas_x = int(round(256 - scaled_hip_x))
        canvas_y = 511 - int(round(base_y * scale_a))
        
        canvas.paste(resized, (canvas_x, canvas_y), resized)
        px_canvas = make_pixel_art_720(canvas)
        
        name = names_a[idx]
        frames_2k_specials[name] = canvas
        frames_720_specials[f"px_{name}"] = px_canvas
        save_sprite(name, canvas, px_canvas)
        
    # Update master fallback hero_dash.png
    save_sprite("hero_dash", frames_2k_specials["hero_dash_2"], frames_720_specials["px_hero_dash_2"])
    
    # Specials Grid B (Heal, Hurt, KO)
    imgb_path = os.path.join(BRAIN_DIR, "hero_specials_grid_b_1791195635827.jpg")
    imgb = Image.open(imgb_path)
    cwb, rhb = imgb.width / 4.0, imgb.height / 2.0
    scale_b = 1.24
    
    names_b = [
        "hero_heal_1", "hero_heal_2", "hero_heal_3", "hero_hurt_1",
        "hero_hurt_2", "hero_ko_1", "hero_ko_2", "hero_ko_3"
    ]
    
    for idx in range(8):
        r = idx // 4
        c = idx % 4
        cell = imgb.crop((int(c * cwb), int(r * rhb), int((c + 1) * cwb), int((r + 1) * rhb)))
        cut = clean_floodfill(cell)
        
        nw = int(round(cut.width * scale_b))
        nh = int(round(cut.height * scale_b))
        resized = cut.resize((nw, nh), Image.Resampling.LANCZOS)
        
        base_y = 384 if r == 0 else 375
        
        canvas = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
        arr_c = np.array(cut)
        hy0, hy1 = (120, 260) if r == 0 else (100, 260)
        torso_mask = (arr_c[hy0:hy1, :, 3] > 80)
        torso_x = np.where(torso_mask)[1]
        hip_x = torso_x.mean() if len(torso_x) > 0 else cut.width / 2.0
        
        scaled_hip_x = hip_x * scale_b
        canvas_x = int(round(256 - scaled_hip_x))
        canvas_y = 511 - int(round(base_y * scale_b))
        
        canvas.paste(resized, (canvas_x, canvas_y), resized)
        px_canvas = make_pixel_art_720(canvas)
        
        name = names_b[idx]
        frames_2k_specials[name] = canvas
        frames_720_specials[f"px_{name}"] = px_canvas
        save_sprite(name, canvas, px_canvas)
        
    # Update master fallbacks hero_hurt.png & px_hero_hurt.png
    save_sprite("hero_hurt", frames_2k_specials["hero_hurt_1"], frames_720_specials["px_hero_hurt_1"])
    
    # Previews for Special Moves
    dash_2k = [frames_2k_specials[f"hero_dash_{i}"] for i in range(1, 4)]
    dash_720 = [frames_720_specials[f"px_hero_dash_{i}"] for i in range(1, 4)]
    save_preview_gif("hero_dash_2k.gif", dash_2k, fps=10)
    save_preview_gif("hero_dash_720.gif", dash_720, fps=10, scale_factor=3)
    
    upslash_2k = [frames_2k_specials[f"hero_upslash_{i}"] for i in range(1, 4)]
    upslash_720 = [frames_720_specials[f"px_hero_upslash_{i}"] for i in range(1, 4)]
    save_preview_gif("hero_upslash_2k.gif", upslash_2k, fps=10)
    save_preview_gif("hero_upslash_720.gif", upslash_720, fps=10, scale_factor=3)
    
    downslash_2k = [frames_2k_specials[f"hero_downslash_{i}"] for i in range(1, 4)]
    downslash_720 = [frames_720_specials[f"px_hero_downslash_{i}"] for i in range(1, 4)]
    save_preview_gif("hero_downslash_2k.gif", downslash_2k, fps=10)
    save_preview_gif("hero_downslash_720.gif", downslash_720, fps=10, scale_factor=3)
    
    blade_2k = [frames_2k_specials[f"hero_blade_{i}"] for i in range(1, 5)]
    blade_720 = [frames_720_specials[f"px_hero_blade_{i}"] for i in range(1, 5)]
    save_preview_gif("hero_blade_2k.gif", blade_2k, fps=8)
    save_preview_gif("hero_blade_720.gif", blade_720, fps=8, scale_factor=3)
    
    heal_2k = [frames_2k_specials[f"hero_heal_{i}"] for i in range(1, 4)]
    heal_720 = [frames_720_specials[f"px_hero_heal_{i}"] for i in range(1, 4)]
    save_preview_gif("hero_heal_2k.gif", heal_2k, fps=8)
    save_preview_gif("hero_heal_720.gif", heal_720, fps=8, scale_factor=3)
    
    hurt_2k = [frames_2k_specials[f"hero_hurt_{i}"] for i in range(1, 3)]
    hurt_720 = [frames_720_specials[f"px_hero_hurt_{i}"] for i in range(1, 3)]
    save_preview_gif("hero_hurt_2k.gif", hurt_2k, fps=8)
    save_preview_gif("hero_hurt_720.gif", hurt_720, fps=8, scale_factor=3)
    
    ko_2k = [frames_2k_specials[f"hero_ko_{i}"] for i in range(1, 4)]
    ko_720 = [frames_720_specials[f"px_hero_ko_{i}"] for i in range(1, 4)]
    save_preview_gif("hero_ko_2k.gif", ko_2k, fps=6)
    save_preview_gif("hero_ko_720.gif", ko_720, fps=6, scale_factor=3)
    
    # Composites
    make_composite([
        frames_2k_specials["hero_dash_2"], frames_2k_specials["hero_upslash_2"],
        frames_2k_specials["hero_blade_3"], frames_2k_specials["hero_heal_2"]
    ], BG_2K_ARENA, "preview_specials_2k.png", y_ground=880, spacing=280)
    
    make_pixel_composite([
        frames_720_specials["px_hero_dash_2"], frames_720_specials["px_hero_upslash_2"],
        frames_720_specials["px_hero_blade_3"], frames_720_specials["px_hero_heal_2"]
    ], BG_720_NEON, "preview_specials_720.png", y_ground=236, spacing=75)
    print("Group 4 Special Moves complete.")

# =========================================================================
# GROUP 5: PARKOUR ACTIONS (Wallslide, Walljump, Airdash, Dive, Pogo)
# =========================================================================
def process_group5_parkour():
    print("\n--- Processing Group 5: Parkour Actions ---")
    SCALE_GLOBAL = 0.692
    WALL_X = 445
    
    frames_2k_dict = {}
    frames_720_dict = {}
    
    # 1. Wallslide
    arr_ws = np.array(Image.open(GRID_WALLSLIDE_PATH).convert('RGB'))
    cuts_ws = [
        clean_floodfill(Image.fromarray(arr_ws[:, :460])),
        clean_floodfill(Image.fromarray(arr_ws[:, 460:920])),
        clean_floodfill(Image.fromarray(arr_ws[:, 920:])),
    ]
    wallslide_2k, wallslide_720 = [], []
    for i, cut in enumerate(cuts_ws):
        b = get_bbox(cut)
        char = cut.crop(b)
        nw = int(round(char.width * SCALE_GLOBAL))
        nh = int(round(char.height * SCALE_GLOBAL))
        res = char.resize((nw, nh), Image.Resampling.LANCZOS)
        can = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
        x_pos = WALL_X - nw
        y_pos = int(round(256 - nh / 2.0))
        can.paste(res, (x_pos, y_pos), res)
        
        arr_can = np.array(can)
        arr_can[:10, :] = 0; arr_can[-10:, :] = 0; arr_can[:, :10] = 0; arr_can[:, -10:] = 0
        clean_can = Image.fromarray(arr_can, mode='RGBA')
        px_can = make_pixel_art_720(clean_can)
        name = f"hero_wallslide_{i+1}"
        save_sprite(name, clean_can, px_can)
        frames_2k_dict[name] = clean_can
        frames_720_dict[f"px_{name}"] = px_can
        wallslide_2k.append(clean_can)
        wallslide_720.append(px_can)
        
    save_sprite("hero_wallslide", wallslide_2k[1], wallslide_720[1])
    save_preview_gif("hero_wallslide_2k.gif", wallslide_2k, fps=14)
    save_preview_gif("hero_wallslide_720.gif", wallslide_720, fps=14, scale_factor=3)
    
    # 2. Walljump
    arr_wj = np.array(Image.open(GRID_WALLJUMP_PATH).convert('RGB'))
    arr_wj[:, 386:394] = 255; arr_wj[:, 899:906] = 255
    scale_wj = 0.710
    
    cut_wj1 = clean_floodfill(Image.fromarray(arr_wj[:, :386]))
    b1 = get_bbox(cut_wj1); c1 = cut_wj1.crop(b1)
    nw1, nh1 = int(round(c1.width * scale_wj)), int(round(c1.height * scale_wj))
    res1 = c1.resize((nw1, nh1), Image.Resampling.LANCZOS)
    can_wj1 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_wj1.paste(res1, (WALL_X - nw1, int(round(440 - nh1))), res1)
    
    cut_wj2 = clean_floodfill(Image.fromarray(arr_wj[:, 394:899]))
    b2 = get_bbox(cut_wj2); c2 = cut_wj2.crop(b2)
    nw2, nh2 = int(round(c2.width * scale_wj)), int(round(c2.height * scale_wj))
    res2 = c2.resize((nw2, nh2), Image.Resampling.LANCZOS)
    can_wj2 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_wj2.paste(res2, (WALL_X - nw2, int(round(440 - nh2))), res2)
    
    cut_wj3 = clean_floodfill(Image.fromarray(arr_wj[:, 906:]))
    b3 = get_bbox(cut_wj3); c3 = cut_wj3.crop(b3)
    nw3, nh3 = int(round(c3.width * scale_wj)), int(round(c3.height * scale_wj))
    res3 = c3.resize((nw3, nh3), Image.Resampling.LANCZOS)
    can_wj3 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_wj3.paste(res3, ((512 - nw3) // 2, 70), res3)
    
    walljump_2k, walljump_720 = [], []
    for i, can in enumerate([can_wj1, can_wj2, can_wj3]):
        arr_can = np.array(can)
        arr_can[:10, :] = 0; arr_can[-10:, :] = 0; arr_can[:, :10] = 0; arr_can[:, -10:] = 0
        clean_can = Image.fromarray(arr_can, mode='RGBA')
        px_can = make_pixel_art_720(clean_can)
        name = f"hero_walljump_{i+1}"
        save_sprite(name, clean_can, px_can)
        frames_2k_dict[name] = clean_can
        frames_720_dict[f"px_{name}"] = px_can
        walljump_2k.append(clean_can)
        walljump_720.append(px_can)
        
    save_sprite("hero_walljump", walljump_2k[1], walljump_720[1])
    save_preview_gif("hero_walljump_2k.gif", walljump_2k, fps=14)
    save_preview_gif("hero_walljump_720.gif", walljump_720, fps=14, scale_factor=3)
    
    # 3. Airdash
    arr_ad = np.array(Image.open(GRID_AIRDASH_PATH).convert('RGB'))
    scale_ad = 0.692
    
    c1_img = Image.fromarray(arr_ad[:, :360])
    cut_ad1 = clean_floodfill(c1_img); b1 = get_bbox(cut_ad1); c1 = cut_ad1.crop(b1)
    nw1, nh1 = int(round(c1.width * scale_ad)), int(round(c1.height * scale_ad))
    res1 = c1.resize((nw1, nh1), Image.Resampling.LANCZOS)
    can_ad1 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_ad1.paste(res1, (160, 150), res1)
    
    c2_arr = arr_ad[:, 360:956].copy(); c2_arr[:250, 950-360:] = 255
    cut_ad2 = clean_floodfill(Image.fromarray(c2_arr)); b2 = get_bbox(cut_ad2); c2 = cut_ad2.crop(b2)
    nw2, nh2 = int(round(c2.width * scale_ad)), int(round(c2.height * scale_ad))
    res2 = c2.resize((nw2, nh2), Image.Resampling.LANCZOS)
    can_ad2 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_ad2.paste(res2, ((512 - nw2) // 2, 175), res2)
    
    c3_arr = arr_ad[:, 940:].copy(); c3_arr[330:, :960-940] = 255
    cut_ad3 = clean_floodfill(Image.fromarray(c3_arr)); b3 = get_bbox(cut_ad3); c3 = cut_ad3.crop(b3)
    nw3, nh3 = int(round(c3.width * scale_ad)), int(round(c3.height * scale_ad))
    res3 = c3.resize((nw3, nh3), Image.Resampling.LANCZOS)
    can_ad3 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_ad3.paste(res3, ((512 - nw3) // 2, 85), res3)
    
    airdash_2k, airdash_720 = [], []
    for i, can in enumerate([can_ad1, can_ad2, can_ad3]):
        arr_can = np.array(can)
        arr_can[:10, :] = 0; arr_can[-10:, :] = 0; arr_can[:, :10] = 0; arr_can[:, -10:] = 0
        clean_can = Image.fromarray(arr_can, mode='RGBA')
        px_can = make_pixel_art_720(clean_can)
        name = f"hero_airdash_{i+1}"
        save_sprite(name, clean_can, px_can)
        frames_2k_dict[name] = clean_can
        frames_720_dict[f"px_{name}"] = px_can
        airdash_2k.append(clean_can)
        airdash_720.append(px_can)
        
    save_sprite("hero_airdash", airdash_2k[1], airdash_720[1])
    save_preview_gif("hero_airdash_2k.gif", airdash_2k, fps=14)
    save_preview_gif("hero_airdash_720.gif", airdash_720, fps=14, scale_factor=3)
    
    # 4. Dive Strike
    arr_dv = np.array(Image.open(GRID_DIVE_PATH).convert('RGB'))
    arr_dv[725:, :] = 255
    scale_dv = 0.700
    
    cut_dv1 = clean_floodfill(Image.fromarray(arr_dv[:, :400]))
    b1 = get_bbox(cut_dv1); c1 = cut_dv1.crop(b1)
    nw1, nh1 = int(round(c1.width * scale_dv)), int(round(c1.height * scale_dv))
    res1 = c1.resize((nw1, nh1), Image.Resampling.LANCZOS)
    can_dv1 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_dv1.paste(res1, ((512 - nw1) // 2, 20), res1)
    
    c2_arr = arr_dv[:, 400:956].copy(); c2_arr[:550, 945-400:] = 255
    cut_dv2 = clean_floodfill(Image.fromarray(c2_arr)); b2 = get_bbox(cut_dv2); c2 = cut_dv2.crop(b2)
    nw2, nh2 = int(round(c2.width * scale_dv)), int(round(c2.height * scale_dv))
    res2 = c2.resize((nw2, nh2), Image.Resampling.LANCZOS)
    can_dv2 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_dv2.paste(res2, (70, 500 - nh2), res2)
    
    c3_arr = arr_dv[:, 940:].copy(); c3_arr[550:, :955-940] = 255
    cut_dv3 = clean_floodfill(Image.fromarray(c3_arr)); b3 = get_bbox(cut_dv3); c3 = cut_dv3.crop(b3)
    nw3, nh3 = int(round(c3.width * scale_dv)), int(round(c3.height * scale_dv))
    res3 = c3.resize((nw3, nh3), Image.Resampling.LANCZOS)
    can_dv3 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_dv3.paste(res3, ((512 - nw3) // 2, 511 - nh3), res3)
    
    dive_2k, dive_720 = [], []
    for i, can in enumerate([can_dv1, can_dv2, can_dv3]):
        arr_can = np.array(can)
        arr_can[:10, :] = 0; arr_can[-10:, :] = 0; arr_can[:, :10] = 0; arr_can[:, -10:] = 0
        clean_can = Image.fromarray(arr_can, mode='RGBA')
        px_can = make_pixel_art_720(clean_can)
        name = f"hero_dive_{i+1}"
        save_sprite(name, clean_can, px_can)
        frames_2k_dict[name] = clean_can
        frames_720_dict[f"px_{name}"] = px_can
        dive_2k.append(clean_can)
        dive_720.append(px_can)
        
    save_sprite("hero_dive", dive_2k[1], dive_720[1])
    save_preview_gif("hero_dive_2k.gif", dive_2k, fps=14)
    save_preview_gif("hero_dive_720.gif", dive_720, fps=14, scale_factor=3)
    
    # 5. Pogo Bounce
    arr_pg = np.array(Image.open(GRID_POGO_PATH).convert('RGB'))
    scale_pg = 0.692
    
    cut_pg1 = clean_floodfill(Image.fromarray(arr_pg[:, :600]))
    b1 = get_bbox(cut_pg1); c1 = cut_pg1.crop(b1)
    nw1, nh1 = int(round(c1.width * scale_pg)), int(round(c1.height * scale_pg))
    res1 = c1.resize((nw1, nh1), Image.Resampling.LANCZOS)
    can_pg1 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_pg1.paste(res1, ((512 - nw1) // 2, 511 - nh1), res1)
    
    cut_pg2 = clean_floodfill(Image.fromarray(arr_pg[:, 600:]))
    b2 = get_bbox(cut_pg2); c2 = cut_pg2.crop(b2)
    nw2, nh2 = int(round(c2.width * scale_pg)), int(round(c2.height * scale_pg))
    res2 = c2.resize((nw2, nh2), Image.Resampling.LANCZOS)
    can_pg2 = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    can_pg2.paste(res2, ((512 - nw2) // 2, 25), res2)
    
    pogo_2k, pogo_720 = [], []
    for i, can in enumerate([can_pg1, can_pg2]):
        arr_can = np.array(can)
        arr_can[:10, :] = 0; arr_can[-10:, :] = 0; arr_can[:, :10] = 0; arr_can[:, -10:] = 0
        clean_can = Image.fromarray(arr_can, mode='RGBA')
        px_can = make_pixel_art_720(clean_can)
        name = f"hero_pogo_{i+1}"
        save_sprite(name, clean_can, px_can)
        frames_2k_dict[name] = clean_can
        frames_720_dict[f"px_{name}"] = px_can
        pogo_2k.append(clean_can)
        pogo_720.append(px_can)
        
    save_sprite("hero_pogo", pogo_2k[0], pogo_720[0])
    save_preview_gif("hero_pogo_2k.gif", pogo_2k, fps=14)
    save_preview_gif("hero_pogo_720.gif", pogo_720, fps=14, scale_factor=3)
    
    # 6. Combo Flow & Composites
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
    print("Group 5 Parkour Actions complete.")

if __name__ == "__main__":
    process_group1_touchup()
    process_group2_idle()
    process_group3_attacks()
    process_group4_specials()
    process_group5_parkour()
