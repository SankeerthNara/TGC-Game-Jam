"""
Hero Animation Pipeline for 'Glitched Out' (2K Painted and 720p Pixel Art)
"""

import os
import sys
from collections import deque
import numpy as np
from PIL import Image, ImageDraw

BRAIN_DIR = r"C:\Users\sanke\.gemini\antigravity-ide\brain\0e3e4b2c-4485-48cb-a8eb-d7adf359721c"
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
# GROUP 1: MOVEMENT TOUCH-UP (hero_run_3 blade continuity)
# =========================================================================
def process_group1_touchup():
    print("\n--- Processing Group 1 Movement Touch-up ---")
    s_dir = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "sprites")
    r2 = Image.open(os.path.join(s_dir, "hero_run_2.png"))
    r3 = Image.open(os.path.join(s_dir, "hero_run_3.png"))
    r4 = Image.open(os.path.join(s_dir, "hero_run_4.png"))
    
    # Composite the glowing light blade onto run_3 to guarantee uninterrupted blade trail
    # In run_2 blade is at y=275..391, x=230..325
    # In run_4 blade is at y=113..343, x=185..333
    # Interpolate blade position for run_3
    arr3 = np.array(r3)
    arr2 = np.array(r2)
    arr4 = np.array(r4)
    
    # Extract blade mask from r2 and r4
    blade_m2 = (arr2[:,:,3] > 80) & (arr2[:,:,0] > 200) & (arr2[:,:,1] > 175) & (arr2[:,:,2] < 150)
    blade_m4 = (arr4[:,:,3] > 80) & (arr4[:,:,0] > 200) & (arr4[:,:,1] > 175) & (arr4[:,:,2] < 150)
    
    # Blend interpolated blade into run_3
    # Draw radiant golden beam angled through the right hand (approx x=240..300, y=190..365)
    r3_mod = r3.copy()
    draw = ImageDraw.Draw(r3_mod)
    # Layered radiant blade beam: outer glow, core, inner white
    draw.line([(248, 220), (295, 360)], fill=(255, 180, 50, 180), width=9)
    draw.line([(248, 220), (295, 360)], fill=(255, 230, 100, 230), width=5)
    draw.line([(248, 220), (295, 360)], fill=(255, 255, 220, 255), width=2)
    
    # Save touched-up hero_run_3
    px_r3 = make_pixel_art_720(r3_mod)
    save_sprite("hero_run_3", r3_mod, px_r3)
    
    # Re-read all 12 run frames and rebuild GIFs
    run_frames_2k = [Image.open(os.path.join(s_dir, f"hero_run_{i}.png")) for i in range(1, 13)]
    run_frames_720 = [Image.open(os.path.join(s_dir, f"px_hero_run_{i}.png")) for i in range(1, 11)]
    
    save_preview_gif("hero_run_2k.gif", run_frames_2k, fps=14)
    save_preview_gif("hero_run_720.gif", run_frames_720, fps=14, scale_factor=3)
    print("Group 1 Movement touch-up complete.")

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

if __name__ == "__main__":
    process_group1_touchup()
    process_group2_idle()
