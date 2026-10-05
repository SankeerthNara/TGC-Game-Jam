"""
Complete asset build pipeline for Glitched Out.
Processes and validates:
1. 2K Hero frames (512x512)
2. 2K Narrator & Masked Villain frames (768x768)
3. 2K Dialogue portraits (512x512)
4. 720p Hero pixel art frames (64x64, ~58px tall, 24 colors, hard alpha)
5. 720p Narrator pixel art portraits (96x96, 24 colors, hard alpha)
6. Check previews: preview_2k.png and preview_720.png
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
    'hero_sheet': os.path.join(BRAIN_DIR, "pulp_hero_sheet_1791153330308.jpg"),
    'narrator_sheet': os.path.join(BRAIN_DIR, "narrator_master_sheet_1791153348934.jpg"),
    'villain_sheet': os.path.join(BRAIN_DIR, "villain_master_sheet_1791153369093.jpg"),
    'hero_idle': os.path.join(BRAIN_DIR, "hero_idle_raw_1791153393893.jpg"),
    'hero_run1': os.path.join(BRAIN_DIR, "hero_run_one_1791153415011.jpg"),
    'hero_run2': os.path.join(BRAIN_DIR, "hero_run_two_1791153431901.jpg"),
    'hero_jump': os.path.join(BRAIN_DIR, "hero_jump_raw_1791153449256.jpg"),
    'hero_attack': os.path.join(BRAIN_DIR, "hero_attack_raw_1791153468239.jpg"),
    'hero_dash': os.path.join(BRAIN_DIR, "hero_dash_raw_1791153487101.jpg"),
    'hero_hurt': os.path.join(BRAIN_DIR, "hero_hurt_raw_1791153505782.jpg"),
    'narrator_boss': os.path.join(BRAIN_DIR, "narrator_boss_raw_1791153532188.jpg"),
    'masked_villain': os.path.join(BRAIN_DIR, "masked_villain_raw_1791153551473.jpg"),
    'hero_portrait': os.path.join(BRAIN_DIR, "hero_portrait_raw_1791153568729.jpg"),
}

def remove_bg(img, tolerance=38):
    """Clean flood-fill cutout of pure or off-white background from image borders."""
    im = img.convert('RGB')
    arr = np.array(im, dtype=np.int32)
    h, w, _ = arr.shape
    corner = arr[0:8, 0:8].mean(axis=(0, 1))
    
    # Distance to corner background color
    dist = np.sqrt(np.sum((arr - corner)**2, axis=2))
    
    # Candidate background pixels: close to corner color or near-white neutral
    is_candidate = (dist < tolerance) | (
        (arr[:, :, 0] > 200) & (arr[:, :, 1] > 195) & (arr[:, :, 2] > 185) &
        (np.abs(arr[:, :, 0] - arr[:, :, 1]) < 22) & (np.abs(arr[:, :, 1] - arr[:, :, 2]) < 25)
    )
    
    # Protect light blade glow: warm yellow/gold tint
    blade_glow = (arr[:, :, 0] > 220) & (arr[:, :, 1] > 180) & (arr[:, :, 2] < arr[:, :, 0] - 18)
    is_candidate[blade_glow] = False
    
    # BFS Flood fill from image outer perimeter
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
                    
    alpha = np.where(bg_mask, 0, 255).astype(np.uint8)
    rgba = np.dstack([arr.astype(np.uint8), alpha])
    return Image.fromarray(rgba, mode='RGBA')

def get_bbox(img, alpha_th=20):
    arr = np.array(img)
    alpha = arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > alpha_th)
    if len(x_idx) == 0 or len(y_idx) == 0:
        return 0, 0, img.width, img.height
    return int(x_idx.min()), int(y_idx.min()), int(x_idx.max()) + 1, int(y_idx.max()) + 1

def process_sprite_2k(img, target_size=(512, 512), target_height_ratio=0.88, is_portrait=False):
    """
    Cutout, horizontally centered, feet touch bottom edge.
    For consistent scale: hero height is controlled by target_height_ratio.
    """
    cut = remove_bg(img)
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

def make_pixel_art(rgba_img, target_size=(64, 64), target_char_height=58, max_colors=24):
    """
    Convert 2K sprite to true pixel art:
    - Downscaled to 64x64
    - Character ~58px tall, feet on bottom row
    - Hard 1-bit alpha (no soft blur/halos)
    - Quantized to at most 24 colors
    """
    bx0, by0, bx1, by1 = get_bbox(rgba_img)
    char = rgba_img.crop((bx0, by0, bx1, by1))
    cw, ch = char.size
    tw, th = target_size
    
    scale = target_char_height / max(ch, 1)
    nw = max(1, int(round(cw * scale)))
    nh = target_char_height
    if nw > tw:
        nw = tw
        
    small_char = char.resize((nw, nh), Image.Resampling.BILINEAR)
    
    canvas = Image.new('RGBA', target_size, (0, 0, 0, 0))
    x = (tw - nw) // 2
    y = th - nh # Feet on bottom row
    canvas.paste(small_char, (x, y), small_char)
    
    # Clean hard 1-bit alpha
    arr = np.array(canvas)
    alpha = arr[:, :, 3]
    hard_alpha = (alpha > 85).astype(np.uint8) * 255
    arr[:, :, 3] = hard_alpha
    
    rgb_img = Image.fromarray(arr[:, :, :3], mode='RGB')
    mask = Image.fromarray(hard_alpha, mode='L')
    
    # 24 color quantization
    quantized = rgb_img.quantize(colors=max_colors, method=Image.Quantize.MEDIANCUT).convert('RGB')
    quantized.putalpha(mask)
    return quantized

def make_pixel_portrait(rgba_img, target_size=(96, 96), max_colors=24):
    """True pixel art portrait 96x96 with hard alpha and limited palette."""
    bx0, by0, bx1, by1 = get_bbox(rgba_img)
    char = rgba_img.crop((bx0, by0, bx1, by1))
    cw, ch = char.size
    tw, th = target_size
    
    scale = min((tw * 0.92) / max(cw, 1), (th * 0.92) / max(ch, 1))
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    
    small = char.resize((nw, nh), Image.Resampling.BILINEAR)
    canvas = Image.new('RGBA', target_size, (0, 0, 0, 0))
    canvas.paste(small, ((tw - nw) // 2, (th - nh) // 2), small)
    
    arr = np.array(canvas)
    alpha = arr[:, :, 3]
    hard_alpha = (alpha > 80).astype(np.uint8) * 255
    arr[:, :, 3] = hard_alpha
    
    rgb_img = Image.fromarray(arr[:, :, :3], mode='RGB')
    mask = Image.fromarray(hard_alpha, mode='L')
    quantized = rgb_img.quantize(colors=max_colors, method=Image.Quantize.MEDIANCUT).convert('RGB')
    quantized.putalpha(mask)
    return quantized

def build_all():
    print("=== Step 1: Processing Master Reference Sheets ===")
    hero_sheet = Image.open(RAW_FILES['hero_sheet'])
    nar_sheet = Image.open(RAW_FILES['narrator_sheet'])
    vil_sheet = Image.open(RAW_FILES['villain_sheet'])
    
    print("=== Step 2: Processing 2K Hero Sprites (512x512) ===")
    # 7 hero frames: idle, run1, run2, jump, attack, dash, hurt
    hero_2k = {}
    hero_2k['hero_idle.png'] = process_sprite_2k(Image.open(RAW_FILES['hero_idle']), (512, 512), target_height_ratio=0.88)
    hero_2k['hero_run1.png'] = process_sprite_2k(Image.open(RAW_FILES['hero_run1']), (512, 512), target_height_ratio=0.88)
    hero_2k['hero_run2.png'] = process_sprite_2k(Image.open(RAW_FILES['hero_run2']), (512, 512), target_height_ratio=0.88)
    hero_2k['hero_jump.png'] = process_sprite_2k(Image.open(RAW_FILES['hero_jump']), (512, 512), target_height_ratio=0.86)
    hero_2k['hero_attack.png'] = process_sprite_2k(Image.open(RAW_FILES['hero_attack']), (512, 512), target_height_ratio=0.88)
    hero_2k['hero_dash.png'] = process_sprite_2k(Image.open(RAW_FILES['hero_dash']), (512, 512), target_height_ratio=0.82)
    hero_2k['hero_hurt.png'] = process_sprite_2k(Image.open(RAW_FILES['hero_hurt']), (512, 512), target_height_ratio=0.88)

    print("=== Step 3: Processing 2K Narrator Sprites (768x768) ===")
    narrator_2k = {}
    narrator_2k['narrator_boss.png'] = process_sprite_2k(Image.open(RAW_FILES['narrator_boss']), (768, 768), target_height_ratio=0.92)
    narrator_2k['masked_villain.png'] = process_sprite_2k(Image.open(RAW_FILES['masked_villain']), (768, 768), target_height_ratio=0.92)

    print("=== Step 4: Processing 2K Portraits (512x512) ===")
    portraits_2k = {}
    portraits_2k['hero.png'] = process_sprite_2k(Image.open(RAW_FILES['hero_portrait']), (512, 512), is_portrait=True)
    
    # Narrator friendly portrait from sheet (head + top hat + cravat)
    # 3/4 view head on narrator sheet: x=645..875, y=70..365
    nar_head_crop = nar_sheet.crop((645, 70, 875, 365))
    portraits_2k['narrator_friendly.png'] = process_sprite_2k(nar_head_crop, (512, 512), is_portrait=True)
    
    # Narrator evil portrait from villain sheet (head + cracked monocle + grin)
    vil_head_crop = vil_sheet.crop((640, 110, 855, 370))
    portraits_2k['narrator_evil.png'] = process_sprite_2k(vil_head_crop, (512, 512), is_portrait=True)

    print("=== Step 5: Processing 720p Pixel Art Sprites (64x64, ~58px tall) ===")
    hero_720 = {}
    hero_720['px_hero.png'] = make_pixel_art(hero_2k['hero_idle.png'], (64, 64), target_char_height=58)
    hero_720['px_hero_run1.png'] = make_pixel_art(hero_2k['hero_run1.png'], (64, 64), target_char_height=58)
    hero_720['px_hero_run2.png'] = make_pixel_art(hero_2k['hero_run2.png'], (64, 64), target_char_height=58)
    hero_720['px_hero_punch.png'] = make_pixel_art(hero_2k['hero_attack.png'], (64, 64), target_char_height=58)
    hero_720['px_hero_kick.png'] = make_pixel_art(hero_2k['hero_jump.png'], (64, 64), target_char_height=58)
    hero_720['px_hero_roll.png'] = make_pixel_art(hero_2k['hero_dash.png'], (64, 64), target_char_height=54)
    hero_720['px_hero_hurt.png'] = make_pixel_art(hero_2k['hero_hurt.png'], (64, 64), target_char_height=58)

    print("=== Step 6: Processing 720p Pixel Portraits (96x96) ===")
    portraits_720 = {}
    portraits_720['px_narrator_friendly.png'] = make_pixel_portrait(portraits_2k['narrator_friendly.png'], (96, 96))
    portraits_720['px_narrator_evil.png'] = make_pixel_portrait(portraits_2k['narrator_evil.png'], (96, 96))

    print("=== Step 7: Saving to Target Directories ===")
    for base in [WT_ANTI, MAIN_WS]:
        sprites_dir = os.path.join(base, "new-game-project", "assets", "editions", "sprites")
        portraits_dir = os.path.join(base, "new-game-project", "assets", "editions", "portraits")
        ref_dir = os.path.join(base, "new-game-project", "assets", "editions", "reference")
        os.makedirs(sprites_dir, exist_ok=True)
        os.makedirs(portraits_dir, exist_ok=True)
        os.makedirs(ref_dir, exist_ok=True)
        
        # Save reference turnaround sheets
        hero_sheet.save(os.path.join(ref_dir, "pulp_hero_sheet.jpg"), quality=95)
        nar_sheet.save(os.path.join(ref_dir, "narrator_friendly_sheet.jpg"), quality=95)
        vil_sheet.save(os.path.join(ref_dir, "narrator_villain_sheet.jpg"), quality=95)
        
        # Save 2K sprites
        for name, img in hero_2k.items():
            img.save(os.path.join(sprites_dir, name))
        for name, img in narrator_2k.items():
            img.save(os.path.join(sprites_dir, name))
            
        # Save 2K portraits
        for name, img in portraits_2k.items():
            img.save(os.path.join(portraits_dir, name))
            
        # Save 720p pixel sprites
        for name, img in hero_720.items():
            img.save(os.path.join(sprites_dir, name))
            
        # Save 720p pixel portraits
        for name, img in portraits_720.items():
            img.save(os.path.join(portraits_dir, name))
            
        print(f"Saved all sprites and portraits to {base}")

    print("=== Step 8: Generating Quality Previews (preview_2k.png & preview_720.png) ===")
    from process_editions_sprites import generate_preview_2k, generate_preview_720
    
    bg_dir_2k = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "2k")
    bg_dir_720 = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "720")
    
    for base in [WT_ANTI, MAIN_WS]:
        sprites_dir = os.path.join(base, "new-game-project", "assets", "editions", "sprites")
        portraits_dir = os.path.join(base, "new-game-project", "assets", "editions", "portraits")
        ref_dir = os.path.join(base, "new-game-project", "assets", "editions", "reference")
        
        out_2k = os.path.join(ref_dir, "preview_2k.png")
        generate_preview_2k(sprites_dir, portraits_dir, bg_dir_2k, out_2k)
        
        out_720 = os.path.join(ref_dir, "preview_720.png")
        generate_preview_720(sprites_dir, portraits_dir, bg_dir_720, out_720)

    print("All tasks finished successfully!")

if __name__ == '__main__':
    build_all()
