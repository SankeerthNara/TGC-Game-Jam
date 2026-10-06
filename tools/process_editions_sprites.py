"""
Sprite processing and quality validation pipeline for Glitched Out.
Handles:
- Smart cutout and background removal
- Horizontal centering and bottom-edge grounding (feet touching bottom row)
- Proportional scaling and canvas framing (2K: 512x512 hero, 768x768 narrator, 512x512 portrait)
- Pixel art downscaling (64x64 hero ~58px, 96x96 portraits, nearest-neighbor, <=24 colors, hard alpha)
- Verification composite generation: preview_2k.png and preview_720.png
"""

import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def remove_background(img_path, bg_color_hint='auto', tolerance=35):
    """
    Removes solid/smooth background from generated character image,
    returning an RGBA Image with clean transparency.
    """
    img = Image.open(img_path).convert('RGBA')
    arr = np.array(img, dtype=np.float32)
    rgb = arr[:, :, :3]
    h, w, _ = rgb.shape

    # Sample corners to determine background color
    corners = np.vstack([
        rgb[0:15, 0:15].reshape(-1, 3),
        rgb[0:15, w-15:w].reshape(-1, 3),
        rgb[h-15:h, 0:15].reshape(-1, 3),
        rgb[h-15:h, w-15:w].reshape(-1, 3)
    ])
    bg_rgb = np.median(corners, axis=0)

    # Calculate color distance to background
    diff = np.linalg.norm(rgb - bg_rgb, axis=2)

    # Create alpha mask with soft transition for 2K
    alpha = np.clip((diff - tolerance) / max(10, tolerance * 0.5) * 255.0, 0, 255).astype(np.uint8)

    # Clean floodfill from outer edges to avoid removing matching colors inside the character
    from scipy.ndimage import binary_fill_holes
    # If scipy isn't present, fallback to basic mask
    try:
        from scipy.ndimage import label
        is_bg = diff < tolerance
        # flood fill connected component from outer border
        labeled, num_features = label(is_bg)
        border_mask = np.zeros_like(is_bg, dtype=bool)
        border_mask[0, :] = True
        border_mask[-1, :] = True
        border_mask[:, 0] = True
        border_mask[:, -1] = True
        border_labels = set(labeled[border_mask].flatten())
        if 0 in border_labels:
            border_labels.remove(0)
        
        true_bg = np.isin(labeled, list(border_labels))
        alpha[true_bg] = 0
        alpha[~true_bg] = 255
    except ImportError:
        pass

    arr[:, :, 3] = alpha
    result = Image.fromarray(arr.astype(np.uint8), mode='RGBA')
    return result

def get_character_bbox(rgba_img, alpha_threshold=30):
    """Returns the tight bounding box (min_x, min_y, max_x, max_y) of opaque pixels."""
    alpha = np.array(rgba_img)[:, :, 3]
    y_indices, x_indices = np.where(alpha > alpha_threshold)
    if len(x_indices) == 0 or len(y_indices) == 0:
        return 0, 0, rgba_img.width, rgba_img.height
    return int(x_indices.min()), int(y_indices.min()), int(x_indices.max()) + 1, int(y_indices.max()) + 1

def frame_sprite_2k(img, target_size=(512, 512), target_height_ratio=0.88, is_portrait=False):
    """
    Crop character, scale appropriately, center horizontally, and align feet to bottom.
    For portraits: centers head and shoulders nicely within frame.
    """
    bbox = get_character_bbox(img)
    char = img.crop(bbox)
    char_w, char_h = char.size
    
    tw, th = target_size
    canvas = Image.new('RGBA', target_size, (0, 0, 0, 0))

    if is_portrait:
        # Scale to fill ~85% of portrait box
        scale = (th * 0.88) / max(char_h, 1)
        new_w = max(1, int(char_w * scale))
        new_h = max(1, int(char_h * scale))
        if new_w > tw * 0.95:
            scale = (tw * 0.95) / char_w
            new_w = max(1, int(char_w * scale))
            new_h = max(1, int(char_h * scale))
        char_resized = char.resize((new_w, new_h), Image.Resampling.LANCZOS)
        x = (tw - new_w) // 2
        y = (th - new_h) // 2
        canvas.paste(char_resized, (x, y), char_resized)
        return canvas

    # For full body game sprite:
    # Target height ratio determines character standing height (e.g. 88% of canvas height)
    desired_h = int(th * target_height_ratio)
    scale = desired_h / max(char_h, 1)
    new_w = max(1, int(char_w * scale))
    new_h = max(1, int(char_h * scale))
    
    # Ensure it doesn't exceed target width
    if new_w > tw:
        scale = tw / char_w
        new_w = max(1, int(char_w * scale))
        new_h = max(1, int(char_h * scale))

    char_resized = char.resize((new_w, new_h), Image.Resampling.LANCZOS)

    # Horizontal center
    x = (tw - new_w) // 2
    # FEET TOUCH BOTTOM EDGE
    y = th - new_h

    canvas.paste(char_resized, (x, y), char_resized)
    return canvas

def make_pixel_sprite_720(img, target_size=(64, 64), target_char_height=58, max_colors=24):
    """
    Downscales to 64x64, ensures feet on bottom row, 1-px hard pixel styling, <=24 colors, hard alpha.
    """
    bbox = get_character_bbox(img)
    char = img.crop(bbox)
    char_w, char_h = char.size

    tw, th = target_size
    scale = target_char_height / max(char_h, 1)
    new_w = max(1, int(round(char_w * scale)))
    new_h = target_char_height
    
    if new_w > tw:
        new_w = tw

    char_small = char.resize((new_w, new_h), Image.Resampling.BILINEAR)

    # Create canvas
    canvas = Image.new('RGBA', target_size, (0, 0, 0, 0))
    x = (tw - new_w) // 2
    y = th - new_h # feet on bottom row

    canvas.paste(char_small, (x, y), char_small)

    # Clean transparency to hard binary alpha (no semi-transparent blur)
    arr = np.array(canvas)
    alpha = arr[:, :, 3]
    hard_alpha = (alpha > 90).astype(np.uint8) * 255
    arr[:, :, 3] = hard_alpha

    rgb_img = Image.fromarray(arr[:, :, :3], mode='RGB')
    mask = Image.fromarray(hard_alpha, mode='L')

    # Quantize RGB to max_colors
    quantized = rgb_img.quantize(colors=max_colors, method=Image.Quantize.MEDIANCUT).convert('RGB')
    quantized.putalpha(mask)

    return quantized

def make_pixel_portrait_720(img, target_size=(96, 96), max_colors=24):
    """Downscales comms portrait to 96x96 with hard alpha and limited palette."""
    bbox = get_character_bbox(img)
    char = img.crop(bbox)
    char_w, char_h = char.size

    tw, th = target_size
    scale = (th * 0.92) / max(char_h, 1)
    new_w = max(1, int(round(char_w * scale)))
    new_h = max(1, int(round(char_h * scale)))

    if new_w > tw:
        scale = tw / max(char_w, 1)
        new_w = tw
        new_h = max(1, int(round(char_h * scale)))

    char_small = char.resize((new_w, new_h), Image.Resampling.BILINEAR)
    canvas = Image.new('RGBA', target_size, (0, 0, 0, 0))
    x = (tw - new_w) // 2
    y = (th - new_h) // 2
    canvas.paste(char_small, (x, y), char_small)

    arr = np.array(canvas)
    alpha = arr[:, :, 3]
    hard_alpha = (alpha > 80).astype(np.uint8) * 255
    arr[:, :, 3] = hard_alpha

    rgb_img = Image.fromarray(arr[:, :, :3], mode='RGB')
    mask = Image.fromarray(hard_alpha, mode='L')
    quantized = rgb_img.quantize(colors=max_colors, method=Image.Quantize.MEDIANCUT).convert('RGB')
    quantized.putalpha(mask)
    return quantized

def generate_preview_2k(sprites_dir, portraits_dir, bg_dir, out_path):
    """
    Check 1 & Check 3:
    - Lines up the 7 hero frames side-by-side (idle, run1, run2, jump, attack, dash, hurt).
    - Composites hero and narrator frames onto hall_far.jpg and arena_far.jpg.
    - Tests 200px shrunk silhouettes.
    """
    hero_frames = ['hero_idle.png', 'hero_run1.png', 'hero_run2.png', 'hero_jump.png', 'hero_attack.png', 'hero_dash.png', 'hero_hurt.png']
    
    # Load hall_far and arena_far
    hall_bg = Image.open(os.path.join(bg_dir, 'hall_far.jpg')).convert('RGBA')
    arena_bg = Image.open(os.path.join(bg_dir, 'arena_far.jpg')).convert('RGBA')
    
    # Create master preview canvas: 1920 x 1440
    preview = Image.new('RGBA', (1920, 1440), (18, 14, 24, 255))
    draw = ImageDraw.Draw(preview)
    
    # Section 1: Line up the 7 hero frames side-by-side
    # 7 frames of 512x512 scaled to fit horizontally across 1920: scale factor ~0.5 (256x256 each)
    thumb_w, thumb_h = 260, 260
    start_x = (1920 - (len(hero_frames) * thumb_w)) // 2
    for i, name in enumerate(hero_frames):
        p = os.path.join(sprites_dir, name)
        if os.path.exists(p):
            f = Image.open(p).convert('RGBA')
            f_resized = f.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
            preview.paste(f_resized, (start_x + i * thumb_w, 40), f_resized)
            
    # Section 2: Hall scene composite (scaled to 940x528)
    hall_thumb = hall_bg.resize((940, 528), Image.Resampling.LANCZOS)
    # Paste hero_idle and narrator on hall
    hero_idle_p = os.path.join(sprites_dir, 'hero_idle.png')
    if os.path.exists(hero_idle_p):
        hero_spr = Image.open(hero_idle_p).convert('RGBA').resize((240, 240), Image.Resampling.LANCZOS)
        # place on floor
        hall_thumb.paste(hero_spr, (200, 528 - 240 - 20), hero_spr)
    masked_villain_p = os.path.join(sprites_dir, 'masked_villain.png')
    if os.path.exists(masked_villain_p):
        mv_spr = Image.open(masked_villain_p).convert('RGBA').resize((320, 320), Image.Resampling.LANCZOS)
        hall_thumb.paste(mv_spr, (550, 528 - 320 - 20), mv_spr)
    preview.paste(hall_thumb, (15, 340), hall_thumb)
    
    # Section 3: Arena scene composite (scaled to 940x528)
    arena_thumb = arena_bg.resize((940, 528), Image.Resampling.LANCZOS)
    hero_attack_p = os.path.join(sprites_dir, 'hero_attack.png')
    if os.path.exists(hero_attack_p):
        hero_att = Image.open(hero_attack_p).convert('RGBA').resize((260, 260), Image.Resampling.LANCZOS)
        arena_thumb.paste(hero_att, (180, 528 - 260 - 20), hero_att)
    narrator_boss_p = os.path.join(sprites_dir, 'narrator_boss.png')
    if os.path.exists(narrator_boss_p):
        nb_spr = Image.open(narrator_boss_p).convert('RGBA').resize((330, 330), Image.Resampling.LANCZOS)
        arena_thumb.paste(nb_spr, (520, 528 - 330 - 20), nb_spr)
    preview.paste(arena_thumb, (965, 340), arena_thumb)
    
    # Section 4: 200px silhouette check row
    silh_y = 900
    for i, name in enumerate(hero_frames):
        p = os.path.join(sprites_dir, name)
        if os.path.exists(p):
            f = Image.open(p).convert('RGBA').resize((200, 200), Image.Resampling.LANCZOS)
            preview.paste(f, (start_x + i * thumb_w + 30, silh_y), f)
            
    # Section 5: Portraits strip (hero, narrator_friendly, narrator_evil)
    portraits = ['hero.png', 'narrator_friendly.png', 'narrator_evil.png']
    port_start_x = (1920 - len(portraits) * 220) // 2
    for i, name in enumerate(portraits):
        p = os.path.join(portraits_dir, name)
        if os.path.exists(p):
            f = Image.open(p).convert('RGBA').resize((180, 180), Image.Resampling.LANCZOS)
            preview.paste(f, (port_start_x + i * 220, 1140), f)
            
    preview.save(out_path)
    print("Saved 2K preview to", out_path)

def generate_preview_720(sprites_dir, portraits_dir, bg_dir, out_path):
    """
    Check 1 for 720p:
    Composites 720p sprites scaled x3 nearest-neighbor on neon_mid.png.
    """
    neon_p = os.path.join(bg_dir, 'neon_mid.png')
    neon_bg = Image.open(neon_p).convert('RGBA')
    # Scale neon_mid up x3 with nearest-neighbor
    nw, nh = neon_bg.size
    neon_x3 = neon_bg.resize((nw * 3, nh * 3), Image.Resampling.NEAREST)
    
    # Take a 1920x810 crop of the street
    street_crop = neon_x3.crop((0, 0, min(1920, nw * 3), nh * 3))
    preview = Image.new('RGBA', (1920, 1080), (12, 10, 18, 255))
    preview.paste(street_crop, (0, 0), street_crop)
    
    # Line up pixel hero frames (scaled x3 nearest neighbor) along the sidewalk
    px_frames = ['px_hero.png', 'px_hero_run1.png', 'px_hero_run2.png', 'px_hero_punch.png', 'px_hero_kick.png', 'px_hero_roll.png', 'px_hero_hurt.png']
    
    # Sidewalk ground y-coordinate in neon_mid is 236 -> *3 = 708
    ground_y = 236 * 3
    spacing = 240
    start_x = 100
    for i, name in enumerate(px_frames):
        p = os.path.join(sprites_dir, name)
        if os.path.exists(p):
            spr = Image.open(p).convert('RGBA')
            spr_x3 = spr.resize((spr.width * 3, spr.height * 3), Image.Resampling.NEAREST)
            # Paste with feet at ground_y
            py = ground_y - spr_x3.height
            preview.paste(spr_x3, (start_x + i * spacing, py), spr_x3)
            
    # Pixel portraits section at bottom
    px_ports = ['px_narrator_friendly.png', 'px_narrator_evil.png']
    for i, name in enumerate(px_ports):
        p = os.path.join(portraits_dir, name)
        if os.path.exists(p):
            port = Image.open(p).convert('RGBA')
            port_x3 = port.resize((port.width * 2, port.height * 2), Image.Resampling.NEAREST)
            preview.paste(port_x3, (1500 + i * 200, 850), port_x3)
            
    preview.save(out_path)
    print("Saved 720p preview to", out_path)

if __name__ == '__main__':
    print("Sprite processing module compiled successfully.")

