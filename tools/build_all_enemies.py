"""
Build script for all 2K enemies and portraits in Mirror Page: The Editions.
"""

import os
import sys
from collections import deque
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

BRAIN_DIR = r"C:\Users\sanke\.gemini\antigravity-ide\brain\bcb3d432-669d-4728-9b1c-a1cd5bd1d9fd"
WT_ANTI = r"D:\Infinium\wt-anti"
MAIN_WS = r"D:\Infinium\TGC-Game-Jam"

RAW_FILES = {
    'lancer_sheet': os.path.join(BRAIN_DIR, "lancer_sheet_1791171364648.jpg"),
    'lancer_sprite': os.path.join(BRAIN_DIR, "lancer_sprite_raw_1791171404646.jpg"),
    'bat_sheet': os.path.join(BRAIN_DIR, "bat_sheet_1791171442530.jpg"),
    'bat_sprite': os.path.join(BRAIN_DIR, "bat_sprite_raw_1791171472998.jpg"),
    'brute_sheet': os.path.join(BRAIN_DIR, "brute_sheet_1791171509375.jpg"),
    'brute_sprite': os.path.join(BRAIN_DIR, "brute_sprite_raw_1791171546760.jpg"),
    'baron_sheet': os.path.join(BRAIN_DIR, "baron_sheet_1791171601353.jpg"),
    'baron_sprite': os.path.join(BRAIN_DIR, "baron_sprite_raw_1791171631012.jpg"),
    'baron_portrait': os.path.join(BRAIN_DIR, "baron_portrait_raw_1791171662716.jpg"),
    'static_twins_portrait': os.path.join(BRAIN_DIR, "static_twins_raw_1791171696343.jpg"),
}

def remove_bg_clean(img, tolerance=38):
    """
    Flood-fill from perimeter + interior trapped pocket clearing so there are NO
    trapped white or grey areas between legs, arms, lance, or coat tails.
    """
    im = img.convert('RGB')
    arr = np.array(im, dtype=np.int32)
    h, w, _ = arr.shape
    corner = arr[0:8, 0:8].mean(axis=(0, 1))
    
    dist = np.sqrt(np.sum((arr - corner)**2, axis=2))
    
    is_candidate = (dist < tolerance) | (
        (arr[:, :, 0] > 205) & (arr[:, :, 1] > 200) & (arr[:, :, 2] > 190) &
        (np.abs(arr[:, :, 0] - arr[:, :, 1]) < 22) & (np.abs(arr[:, :, 1] - arr[:, :, 2]) < 25)
    )
    
    # Protect glows and colored features:
    # Fiery furnace / orange-amber glow
    furnace_glow = (arr[:, :, 0] > 210) & (arr[:, :, 1] > 110) & (arr[:, :, 2] < 110)
    # Cyan/teal glowing eyes
    teal_glow = (arr[:, :, 1] > 180) & (arr[:, :, 2] > 180) & (arr[:, :, 0] < 160)
    # Parchment bat paper: has warm brownish tone (R > G > B by significant margin)
    parchment = (arr[:, :, 0] > arr[:, :, 1] + 15) & (arr[:, :, 1] > arr[:, :, 2] + 15) & (arr[:, :, 0] < 240)
    is_candidate[furnace_glow | teal_glow | parchment] = False
    
    # BFS Flood fill from perimeter
    bg_mask = np.zeros((h, w), dtype=bool)
    queue = deque()
    
    for x in range(w):
        if is_candidate[0, x]:
            queue.append((0, x))
            bg_mask[0, x] = True
        if is_candidate[h-1, x]:
            queue.append((h-1, x))
            bg_mask[h-1, x] = True
    for y in range(h):
        if is_candidate[y, 0]:
            queue.append((y, 0))
            bg_mask[y, 0] = True
        if is_candidate[y, w-1]:
            queue.append((y, w-1))
            bg_mask[y, w-1] = True
            
    while queue:
        cy, cx = queue.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w:
                if not bg_mask[ny, nx] and is_candidate[ny, nx]:
                    bg_mask[ny, nx] = True
                    queue.append((ny, nx))
                    
    # Trapped area clearing: candidate pixels matching background color even if enclosed
    trapped_bg = is_candidate & (dist < tolerance * 1.15)
    final_bg = bg_mask | trapped_bg
    
    alpha = np.where(final_bg, 0, 255).astype(np.uint8)
    rgba = np.dstack([arr.astype(np.uint8), alpha])
    return Image.fromarray(rgba, mode='RGBA')

def get_bbox(img, alpha_th=20):
    arr = np.array(img)
    alpha = arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > alpha_th)
    if len(x_idx) == 0 or len(y_idx) == 0:
        return 0, 0, img.width, img.height
    return int(x_idx.min()), int(y_idx.min()), int(x_idx.max()) + 1, int(y_idx.max()) + 1

def process_enemy_sprite(raw_img, target_size=(512, 512), target_height_ratio=0.88, is_bat=False, is_portrait=False):
    cut = remove_bg_clean(raw_img)
    bx0, by0, bx1, by1 = get_bbox(cut)
    char = cut.crop((bx0, by0, bx1, by1))
    cw, ch = char.size
    tw, th = target_size
    canvas = Image.new('RGBA', target_size, (0, 0, 0, 0))
    
    if is_portrait:
        scale = min((tw * 0.90) / max(cw, 1), (th * 0.90) / max(ch, 1))
        nw, nh = max(1, int(round(cw * scale))), max(1, int(round(ch * scale)))
        resized = char.resize((nw, nh), Image.Resampling.LANCZOS)
        canvas.paste(resized, ((tw - nw) // 2, (th - nh) // 2), resized)
        return canvas
        
    if is_bat:
        # Flying enemy: keep generous bounds inside canvas
        scale = min((tw * 0.92) / max(cw, 1), (th * 0.82) / max(ch, 1))
        nw, nh = max(1, int(round(cw * scale))), max(1, int(round(ch * scale)))
        resized = char.resize((nw, nh), Image.Resampling.LANCZOS)
        canvas.paste(resized, ((tw - nw) // 2, (th - nh) // 2), resized)
        return canvas
        
    desired_h = int(th * target_height_ratio)
    scale = desired_h / max(ch, 1)
    nw = max(1, int(round(cw * scale)))
    nh = desired_h
    
    if nw > tw * 0.96:
        scale = (tw * 0.96) / max(cw, 1)
        nw = int(round(cw * scale))
        nh = int(round(ch * scale))
        
    resized = char.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (tw - nw) // 2
    y = th - nh # FEET TOUCH BOTTOM EDGE
    canvas.paste(resized, (x, y), resized)
    return canvas

def build_enemies():
    print("=== Processing Master Sheets ===")
    lancer_sheet = Image.open(RAW_FILES['lancer_sheet'])
    bat_sheet = Image.open(RAW_FILES['bat_sheet'])
    brute_sheet = Image.open(RAW_FILES['brute_sheet'])
    baron_sheet = Image.open(RAW_FILES['baron_sheet'])
    
    print("=== Processing 2K Enemy Sprites ===")
    enemies = {}
    # enemy_lancer: 512x512
    enemies['enemy_lancer.png'] = process_enemy_sprite(Image.open(RAW_FILES['lancer_sprite']), (512, 512), target_height_ratio=0.88)
    # enemy_bat: 512x512
    enemies['enemy_bat.png'] = process_enemy_sprite(Image.open(RAW_FILES['bat_sprite']), (512, 512), is_bat=True)
    # enemy_brute: 768x768
    enemies['enemy_brute.png'] = process_enemy_sprite(Image.open(RAW_FILES['brute_sprite']), (768, 768), target_height_ratio=0.90)
    # enemy_baron: 768x768
    enemies['enemy_baron.png'] = process_enemy_sprite(Image.open(RAW_FILES['baron_sprite']), (768, 768), target_height_ratio=0.92)

    print("=== Processing Comms Portraits ===")
    portraits = {}
    portraits['ink_baron.png'] = process_enemy_sprite(Image.open(RAW_FILES['baron_portrait']), (512, 512), is_portrait=True)
    portraits['static_twins.png'] = process_enemy_sprite(Image.open(RAW_FILES['static_twins_portrait']), (512, 512), is_portrait=True)

    print("=== Saving to Target Directories ===")
    for base in [WT_ANTI, MAIN_WS]:
        sprites_dir = os.path.join(base, "new-game-project", "assets", "editions", "sprites")
        portraits_dir = os.path.join(base, "new-game-project", "assets", "editions", "portraits")
        ref_dir = os.path.join(base, "new-game-project", "assets", "editions", "reference")
        os.makedirs(sprites_dir, exist_ok=True)
        os.makedirs(portraits_dir, exist_ok=True)
        os.makedirs(ref_dir, exist_ok=True)
        
        # Save master sheets
        lancer_sheet.save(os.path.join(ref_dir, "lancer_master_sheet.jpg"), quality=95)
        bat_sheet.save(os.path.join(ref_dir, "bat_master_sheet.jpg"), quality=95)
        brute_sheet.save(os.path.join(ref_dir, "brute_master_sheet.jpg"), quality=95)
        baron_sheet.save(os.path.join(ref_dir, "baron_master_sheet.jpg"), quality=95)
        
        # Save enemy sprites
        for name, img in enemies.items():
            img.save(os.path.join(sprites_dir, name))
            
        # Save portraits
        for name, img in portraits.items():
            img.save(os.path.join(portraits_dir, name))
            
        print(f"Saved to {base}")

    print("=== Generating preview_enemies.png ===")
    from process_enemies_pipeline import generate_preview_enemies
    bg_dir = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "2k")
    for base in [WT_ANTI, MAIN_WS]:
        sprites_dir = os.path.join(base, "new-game-project", "assets", "editions", "sprites")
        portraits_dir = os.path.join(base, "new-game-project", "assets", "editions", "portraits")
        ref_dir = os.path.join(base, "new-game-project", "assets", "editions", "reference")
        out_preview = os.path.join(ref_dir, "preview_enemies.png")
        generate_preview_enemies(sprites_dir, portraits_dir, bg_dir, out_preview)
        
    print("All enemy tasks complete!")

if __name__ == '__main__':
    build_enemies()
