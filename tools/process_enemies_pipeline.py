"""
Enemy processing and preview validation pipeline for Glitched Out.
Handles:
- Smart cutout and trapped pocket removal (no trapped white/grey areas inside silhouette)
- Horizontal centering and bottom-edge grounding (feet touching bottom row)
- Canvas sizing:
    - enemy_lancer.png: 512x512
    - enemy_bat.png: 512x512
    - enemy_brute.png: 768x768
    - enemy_baron.png: 768x768
    - ink_baron.png: 512x512 (portrait)
    - static_twins.png: 512x512 (portrait)
- Generates validation composite: preview_enemies.png
"""

import os
import sys
from collections import deque
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

WT_ANTI = r"D:\Infinium\wt-anti"
MAIN_WS = r"D:\Infinium\TGC-Game-Jam"

def remove_bg_clean(img, tolerance=38):
    """
    Removes exterior background AND trapped white/grey areas inside silhouette
    (between legs, arms, lance, coat tails).
    """
    im = img.convert('RGB')
    arr = np.array(im, dtype=np.int32)
    h, w, _ = arr.shape
    corner = arr[0:8, 0:8].mean(axis=(0, 1))
    
    # Distance to corner background color
    dist = np.sqrt(np.sum((arr - corner)**2, axis=2))
    
    # Candidate background pixels: close to corner or neutral near-white
    is_candidate = (dist < tolerance) | (
        (arr[:, :, 0] > 200) & (arr[:, :, 1] > 195) & (arr[:, :, 2] > 185) &
        (np.abs(arr[:, :, 0] - arr[:, :, 1]) < 22) & (np.abs(arr[:, :, 1] - arr[:, :, 2]) < 25)
    )
    
    # Protect special glowing areas (furnace chest, glowing eyes, etc.)
    # Amber/orange glow
    amber_glow = (arr[:, :, 0] > 205) & (arr[:, :, 1] > 100) & (arr[:, :, 2] < 120)
    # Teal/cyan glow
    teal_glow = (arr[:, :, 1] > 180) & (arr[:, :, 2] > 180) & (arr[:, :, 0] < 150)
    # Bright paper/white eyes: only protect if surrounded by non-candidate pixels
    is_candidate[amber_glow | teal_glow] = False
    
    # Exterior flood fill
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
                    
    # Also remove enclosed/trapped background pockets (e.g. between legs, arms, lance):
    # Any candidate pixel that matches corner color within tight tolerance (dist < tolerance)
    trapped_bg = is_candidate & (dist < tolerance * 1.1)
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
        # Bat is flying, center horizontally and vertically
        scale = min((tw * 0.92) / max(cw, 1), (th * 0.75) / max(ch, 1))
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
    y = th - nh # FEET ON BOTTOM EDGE
    canvas.paste(resized, (x, y), resized)
    return canvas

def generate_preview_enemies(sprites_dir, portraits_dir, bg_dir, out_path):
    """
    Creates assets/editions/reference/preview_enemies.png placing each sprite
    next to the new painted hero on hall_far.jpg and arena_far.jpg.
    """
    hall_bg = Image.open(os.path.join(bg_dir, 'hall_far.jpg')).convert('RGBA')
    arena_bg = Image.open(os.path.join(bg_dir, 'arena_far.jpg')).convert('RGBA')
    
    preview = Image.new('RGBA', (1920, 1080), (15, 12, 20, 255))
    
    # Left Half: Gothic Library Hall with Hero, Lancer, Bat
    hall_w, hall_h = 945, 700
    hall_thumb = hall_bg.resize((hall_w, hall_h), Image.Resampling.LANCZOS)
    
    # Hero idle
    hero_p = os.path.join(sprites_dir, 'hero_idle.png')
    if os.path.exists(hero_p):
        h_spr = Image.open(hero_p).convert('RGBA').resize((270, 270), Image.Resampling.LANCZOS)
        hall_thumb.paste(h_spr, (120, hall_h - 270 - 25), h_spr)
        
    # Enemy lancer
    lancer_p = os.path.join(sprites_dir, 'enemy_lancer.png')
    if os.path.exists(lancer_p):
        l_spr = Image.open(lancer_p).convert('RGBA').resize((270, 270), Image.Resampling.LANCZOS)
        hall_thumb.paste(l_spr, (450, hall_h - 270 - 25), l_spr)
        
    # Enemy bat in the air
    bat_p = os.path.join(sprites_dir, 'enemy_bat.png')
    if os.path.exists(bat_p):
        b_spr = Image.open(bat_p).convert('RGBA').resize((220, 220), Image.Resampling.LANCZOS)
        hall_thumb.paste(b_spr, (680, 120), b_spr)
        
    preview.paste(hall_thumb, (12, 20), hall_thumb)
    
    # Right Half: Opera Arena with Hero Attack, Brass Brute, Ink Baron
    arena_thumb = arena_bg.resize((hall_w, hall_h), Image.Resampling.LANCZOS)
    
    # Hero attack
    hero_att_p = os.path.join(sprites_dir, 'hero_attack.png')
    if os.path.exists(hero_att_p):
        h_att = Image.open(hero_att_p).convert('RGBA').resize((280, 280), Image.Resampling.LANCZOS)
        arena_thumb.paste(h_att, (80, hall_h - 280 - 25), h_att)
        
    # Enemy brute (brass golem)
    brute_p = os.path.join(sprites_dir, 'enemy_brute.png')
    if os.path.exists(brute_p):
        br_spr = Image.open(brute_p).convert('RGBA').resize((330, 330), Image.Resampling.LANCZOS)
        arena_thumb.paste(br_spr, (360, hall_h - 330 - 25), br_spr)
        
    # Enemy baron (Ink Baron)
    baron_p = os.path.join(sprites_dir, 'enemy_baron.png')
    if os.path.exists(baron_p):
        bar_spr = Image.open(baron_p).convert('RGBA').resize((330, 330), Image.Resampling.LANCZOS)
        arena_thumb.paste(bar_spr, (620, hall_h - 330 - 25), bar_spr)
        
    preview.paste(arena_thumb, (963, 20), arena_thumb)
    
    # Bottom Strip: Comms dialogue portraits (Ink Baron & Static Twins)
    draw = ImageDraw.Draw(preview)
    draw.rectangle([(0, 740), (1920, 1080)], fill=(12, 10, 16, 255))
    
    portraits = ['ink_baron.png', 'static_twins.png']
    labels = ['Ink Baron (Comms Portrait)', 'Static Twins (Comms Portrait)']
    start_x = 560
    for i, name in enumerate(portraits):
        p = os.path.join(portraits_dir, name)
        if os.path.exists(p):
            port = Image.open(p).convert('RGBA').resize((220, 220), Image.Resampling.LANCZOS)
            px = start_x + i * 440
            preview.paste(port, (px, 760), port)
            
    preview.save(out_path)
    print("Saved enemy preview to", out_path)

if __name__ == '__main__':
    print("Enemy processing pipeline compiled successfully.")
