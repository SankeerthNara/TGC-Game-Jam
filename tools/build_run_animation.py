"""
Process the 12-frame running cycle animation grid from gemini-3.1-flash-image:
- Slices 2x6 grid from hero_run_grid
- Removes white background with trapped pocket cleaning
- Standardizes scale, centers horizontally on hips, aligns feet to bottom edge
- Outputs 2K frames: hero_run_1.png ... hero_run_12.png (512x512 RGBA)
- Outputs 720p pixel art frames: px_hero_run_1.png ... px_hero_run_10.png (64x64 RGBA, 24 colors, hard alpha)
- Generates 14 FPS preview GIFs in assets/editions/reference/anim_previews/
"""

import os
import sys
from collections import deque
import numpy as np
from PIL import Image

BRAIN_DIR = r"C:\Users\sanke\.gemini\antigravity-ide\brain\bcb3d432-669d-4728-9b1c-a1cd5bd1d9fd"
GRID_PATH = os.path.join(BRAIN_DIR, "hero_run_grid_1791176956112.jpg")
WT_ANTI = r"D:\Infinium\wt-anti"
MAIN_WS = r"D:\Infinium\TGC-Game-Jam"

def remove_bg(img, tolerance=35):
    arr = np.array(img.convert('RGB'), dtype=np.int32)
    h, w, _ = arr.shape
    corner = arr[0:6, 0:6].mean(axis=(0, 1))
    dist = np.sqrt(np.sum((arr - corner)**2, axis=2))
    
    is_candidate = (dist < tolerance) | (
        (arr[:, :, 0] > 210) & (arr[:, :, 1] > 205) & (arr[:, :, 2] > 195) &
        (np.abs(arr[:, :, 0] - arr[:, :, 1]) < 22) & (np.abs(arr[:, :, 1] - arr[:, :, 2]) < 22)
    )
    
    # Protect warm light blade glow
    blade_glow = (arr[:, :, 0] > 220) & (arr[:, :, 1] > 175) & (arr[:, :, 2] < arr[:, :, 0] - 15)
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
                    
    trapped = is_candidate & (dist < tolerance * 1.12)
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

def build_run_animation():
    grid = Image.open(GRID_PATH)
    gw, gh = grid.size
    cols, rows = 6, 2
    cw = gw / cols
    rh = gh / rows
    
    # 1. Slicing and background cutout
    cells_cut = []
    max_char_h = 0
    for r in range(rows):
        for c in range(cols):
            x0, y0 = int(c * cw), int(r * rh)
            x1, y1 = int((c + 1) * cw), int((r + 1) * rh)
            cell = grid.crop((x0, y0, x1, y1))
            cut = remove_bg(cell)
            bx0, by0, bx1, by1 = get_bbox(cut)
            char = cut.crop((bx0, by0, bx1, by1))
            cells_cut.append(char)
            if char.height > max_char_h:
                max_char_h = char.height

    # 2. Consistent scale for 2K (512x512):
    # Desired standing body height is 440px (~86% of 512).
    # To prevent size popping, calculate one global scale factor across the grid:
    global_scale_2k = 440.0 / max_char_h
    
    frames_2k = []
    for i, char in enumerate(cells_cut):
        nw = int(round(char.width * global_scale_2k))
        nh = int(round(char.height * global_scale_2k))
        resized = char.resize((nw, nh), Image.Resampling.LANCZOS)
        
        frame = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
        # Center horizontally on hips, FEET ON BOTTOM EDGE (y = 512 - nh)
        frame.paste(resized, ((512 - nw) // 2, 512 - nh), resized)
        frames_2k.append(frame)

    # 3. 720p Pixel Art frames (64x64):
    # Character ~58px tall, feet on bottom row, <= 24 colors, 1-bit hard alpha
    global_scale_720 = 58.0 / max_char_h
    frames_720 = []
    for i, char in enumerate(cells_cut[:10]): # 10 frames for 720p run
        nw = max(1, int(round(char.width * global_scale_720)))
        nh = int(round(char.height * global_scale_720))
        if nw > 64: nw = 64
        
        small = char.resize((nw, nh), Image.Resampling.BILINEAR)
        canvas = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
        canvas.paste(small, ((64 - nw) // 2, 64 - nh), small)
        
        arr = np.array(canvas)
        hard_alpha = (arr[:, :, 3] > 85).astype(np.uint8) * 255
        rgb_img = Image.fromarray(arr[:, :, :3], mode='RGB')
        mask = Image.fromarray(hard_alpha, mode='L')
        quantized = rgb_img.quantize(colors=24, method=Image.Quantize.MEDIANCUT).convert('RGB')
        quantized.putalpha(mask)
        frames_720.append(quantized)

    # 4. Save frames to both wt-anti and main workspace
    for base in [WT_ANTI, MAIN_WS]:
        sprites_dir = os.path.join(base, "new-game-project", "assets", "editions", "sprites")
        anim_dir = os.path.join(base, "new-game-project", "assets", "editions", "reference", "anim_previews")
        os.makedirs(sprites_dir, exist_ok=True)
        os.makedirs(anim_dir, exist_ok=True)
        
        # Save 2K frames: hero_run_1.png ... hero_run_12.png
        for idx, f in enumerate(frames_2k):
            f.save(os.path.join(sprites_dir, f"hero_run_{idx + 1}.png"))
            
        # Also overwrite hero_run1.png and hero_run2.png for backwards compatibility
        frames_2k[0].save(os.path.join(sprites_dir, "hero_run1.png"))
        frames_2k[6].save(os.path.join(sprites_dir, "hero_run2.png"))
        
        # Save 720p frames: px_hero_run_1.png ... px_hero_run_10.png
        for idx, f in enumerate(frames_720):
            f.save(os.path.join(sprites_dir, f"px_hero_run_{idx + 1}.png"))
        frames_720[0].save(os.path.join(sprites_dir, "px_hero_run1.png"))
        frames_720[5].save(os.path.join(sprites_dir, "px_hero_run2.png"))

        # Save animated preview GIFs at 14 FPS (71ms per frame)
        gif_2k = os.path.join(anim_dir, "hero_run_2k.gif")
        frames_2k[0].save(gif_2k, save_all=True, append_images=frames_2k[1:], duration=71, loop=0, disposal=2)
        
        gif_720 = os.path.join(anim_dir, "hero_run_720.gif")
        # Upscale 720p GIF x3 with nearest-neighbor for crisp preview
        frames_720_x3 = [f.resize((192, 192), Image.Resampling.NEAREST) for f in frames_720]
        frames_720_x3[0].save(gif_720, save_all=True, append_images=frames_720_x3[1:], duration=71, loop=0, disposal=2)
        
        print(f"Saved run animation frames and GIFs to {base}")

    print("Run cycle processing complete!")

if __name__ == '__main__':
    build_run_animation()
