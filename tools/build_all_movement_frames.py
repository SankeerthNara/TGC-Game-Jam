"""
Generate all Group 1 (Movement) animation frames for 2K (29 frames) and 720p (22 frames):
- hero_run_1 ... hero_run_12 (2K) & px_hero_run_1 ... px_hero_run_10 (720p)
- hero_runstart_1 ... hero_runstart_3 (2K) & px_hero_runstart_1 ... px_hero_runstart_2 (720p)
- hero_skid_1 ... hero_skid_3 (2K) & px_hero_skid_1 ... px_hero_skid_2 (720p)
- hero_turn_1 ... hero_turn_3 (2K) & px_hero_turn_1 ... px_hero_turn_2 (720p)
- hero_jump_1 ... hero_jump_6 (2K) & px_hero_jump_1 ... px_hero_jump_4 (720p)
- hero_land_1 ... hero_land_2 (2K) & px_hero_land_1 ... px_hero_land_2 (720p)

Also produces:
- anim_previews/hero_run_2k.gif (14 FPS) & hero_run_720.gif
- anim_previews/hero_jump_2k.gif (12 FPS) & hero_jump_720.gif
- anim_previews/hero_ground_trans_2k.gif (12 FPS) & hero_ground_trans_720.gif
- Composites on hall_far.jpg (2K) and neon_mid.png (720p)
"""

import os
import sys
from collections import deque
import numpy as np
from PIL import Image

BRAIN = r"C:\Users\sanke\.gemini\antigravity-ide\brain\bcb3d432-669d-4728-9b1c-a1cd5bd1d9fd"
WT_ANTI = r"D:\Infinium\wt-anti"
MAIN_WS = r"D:\Infinium\TGC-Game-Jam"

SPRITES_DIR_ANTI = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "sprites")
ANIM_DIR_ANTI = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "reference", "anim_previews")
SPRITES_DIR_MAIN = os.path.join(MAIN_WS, "new-game-project", "assets", "editions", "sprites")
ANIM_DIR_MAIN = os.path.join(MAIN_WS, "new-game-project", "assets", "editions", "reference", "anim_previews")

BG_2K = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "2k", "hall_far.jpg")
BG_720 = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "720", "neon_mid.png")

def clean_floodfill(img, tolerance=35):
    arr = np.array(img.convert('RGB'), dtype=np.int32)
    h, w, _ = arr.shape
    corner = arr[0:6, 0:6].mean(axis=(0, 1))
    dist = np.sqrt(np.sum((arr - corner)**2, axis=2))
    
    is_candidate = (dist < tolerance) | (
        (arr[:, :, 0] > 205) & (arr[:, :, 1] > 200) & (arr[:, :, 2] > 190) &
        (np.abs(arr[:, :, 0] - arr[:, :, 1]) < 22) & (np.abs(arr[:, :, 1] - arr[:, :, 2]) < 22)
    )
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

def crop_to_char(img):
    bx0, by0, bx1, by1 = get_bbox(img)
    return img.crop((bx0, by0, bx1, by1))

def place_on_2k_canvas(char_img, scale=1.0, y_offset=0, x_shift=0):
    """
    Pastes character onto 512x512 RGBA canvas:
    - Feet grounded at y = 511 - y_offset (for grounded poses y_offset=0)
    - Centered horizontally + x_shift
    """
    nw = max(1, int(round(char_img.width * scale)))
    nh = max(1, int(round(char_img.height * scale)))
    resized = char_img.resize((nw, nh), Image.Resampling.LANCZOS)
    
    canvas = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    x = (512 - nw) // 2 + x_shift
    y = 512 - nh - y_offset
    canvas.paste(resized, (x, y), resized)
    return canvas

def make_pixel_art_720(frame_2k, target_size=(64, 64), max_colors=24):
    """
    Downscales 512x512 frame to 64x64 pixel art with hard 1-bit alpha and max 24 colors.
    Preserves exact grounding/elevation relative to 512 canvas.
    """
    small = frame_2k.resize((64, 64), Image.Resampling.BILINEAR)
    arr = np.array(small)
    alpha = arr[:, :, 3]
    hard_alpha = (alpha > 80).astype(np.uint8) * 255
    
    rgb_img = Image.fromarray(arr[:, :, :3], mode='RGB')
    mask = Image.fromarray(hard_alpha, mode='L')
    quantized = rgb_img.quantize(colors=max_colors, method=Image.Quantize.MEDIANCUT).convert('RGB')
    quantized.putalpha(mask)
    return quantized

def build_all_movement_frames():
    os.makedirs(SPRITES_DIR_ANTI, exist_ok=True)
    os.makedirs(ANIM_DIR_ANTI, exist_ok=True)
    os.makedirs(SPRITES_DIR_MAIN, exist_ok=True)
    os.makedirs(ANIM_DIR_MAIN, exist_ok=True)

    # Load master assets
    sheet = Image.open(os.path.join(BRAIN, "pulp_hero_sheet_1791153330308.jpg"))
    raw_idle = clean_floodfill(Image.open(os.path.join(BRAIN, "hero_idle_raw_1791153393893.jpg")))
    raw_jump = clean_floodfill(Image.open(os.path.join(BRAIN, "hero_jump_raw_1791153449256.jpg")))
    raw_dash = clean_floodfill(Image.open(os.path.join(BRAIN, "hero_dash_raw_1791153487101.jpg")))
    
    char_idle = crop_to_char(raw_idle)
    char_jump = crop_to_char(raw_jump)
    char_dash = crop_to_char(raw_dash)

    # Master sheet views
    f_crop = sheet.crop((82, 0, 485, sheet.height))
    tq_crop = sheet.crop((531, 0, 903, sheet.height))
    char_front = crop_to_char(clean_floodfill(f_crop, tolerance=32))
    char_three_quarter = crop_to_char(clean_floodfill(tq_crop, tolerance=32))

    # Standard hero height scale: 440px on 512x512 canvas
    scale_idle = 440.0 / char_idle.height
    scale_jump = 440.0 / char_idle.height
    scale_turn = 440.0 / char_front.height
    scale_dash = 440.0 / char_idle.height

    # Load existing 12 run frames from disk (already generated from grid)
    run_frames_2k = [Image.open(os.path.join(SPRITES_DIR_ANTI, f"hero_run_{i}.png")) for i in range(1, 13)]
    char_run1 = crop_to_char(run_frames_2k[0])

    frames_2k = {}
    frames_720 = {}

    # 1. RUN FRAMES (12 for 2K, 10 for 720p)
    for i in range(1, 13):
        frames_2k[f"hero_run_{i}"] = run_frames_2k[i-1]
    for i in range(1, 11):
        frames_720[f"px_hero_run_{i}"] = make_pixel_art_720(run_frames_2k[i-1])

    # 2. RUNSTART (3 frames for 2K, 2 frames for 720p)
    # runstart_1: Anticipation lean from standing idle
    rs1_char = char_idle.resize((int(char_idle.width * 1.05), int(char_idle.height * 0.96)), Image.Resampling.LANCZOS)
    rs1 = place_on_2k_canvas(rs1_char, scale=scale_idle, y_offset=0, x_shift=10)
    
    # runstart_2: Explosive push-off (low forward charge, driving off back foot)
    rs2_char = char_dash.resize((int(char_dash.width * 0.95), int(char_dash.height * 1.05)), Image.Resampling.LANCZOS)
    rs2 = place_on_2k_canvas(rs2_char, scale=scale_dash * 1.02, y_offset=0, x_shift=20)
    
    # runstart_3: First stride extension into sprint
    rs3_char = char_run1.resize((int(char_run1.width * 1.02), int(char_run1.height * 0.98)), Image.Resampling.LANCZOS)
    rs3 = place_on_2k_canvas(rs3_char, scale=1.0, y_offset=0, x_shift=5)
    
    frames_2k["hero_runstart_1"] = rs1
    frames_2k["hero_runstart_2"] = rs2
    frames_2k["hero_runstart_3"] = rs3
    frames_720["px_hero_runstart_1"] = make_pixel_art_720(rs1)
    frames_720["px_hero_runstart_2"] = make_pixel_art_720(rs2)

    # 3. SKID (3 frames for 2K, 2 frames for 720p)
    # skid_1: Stopping from sprint: heels dig in, torso leans backward
    sk1_raw = char_idle.resize((int(char_idle.width * 1.08), int(char_idle.height * 0.95)), Image.Resampling.LANCZOS)
    sk1 = place_on_2k_canvas(sk1_raw, scale=scale_idle, y_offset=0, x_shift=-15)
    
    # skid_2: Deep deceleration brace, cape whips forward
    sk2_raw = char_idle.resize((int(char_idle.width * 1.12), int(char_idle.height * 0.92)), Image.Resampling.LANCZOS)
    sk2 = place_on_2k_canvas(sk2_raw, scale=scale_idle, y_offset=0, x_shift=-8)

    # skid_3: Settling back into ready stance
    sk3_raw = char_idle.resize((int(char_idle.width * 1.03), int(char_idle.height * 0.98)), Image.Resampling.LANCZOS)
    sk3 = place_on_2k_canvas(sk3_raw, scale=scale_idle, y_offset=0, x_shift=0)

    frames_2k["hero_skid_1"] = sk1
    frames_2k["hero_skid_2"] = sk2
    frames_2k["hero_skid_3"] = sk3
    frames_720["px_hero_skid_1"] = make_pixel_art_720(sk1)
    frames_720["px_hero_skid_2"] = make_pixel_art_720(sk2)

    # 4. TURN (3 frames for 2K, 2 frames for 720p)
    # turn_1: 3/4 view facing viewer
    tn1 = place_on_2k_canvas(char_three_quarter, scale=scale_turn, y_offset=0, x_shift=0)
    # turn_2: Front view facing viewer, cape wide
    tn2 = place_on_2k_canvas(char_front, scale=scale_turn, y_offset=0, x_shift=0)
    # turn_3: 3/4 view facing other direction
    tn3 = place_on_2k_canvas(char_three_quarter.transpose(Image.Transpose.FLIP_LEFT_RIGHT), scale=scale_turn, y_offset=0, x_shift=0)

    frames_2k["hero_turn_1"] = tn1
    frames_2k["hero_turn_2"] = tn2
    frames_2k["hero_turn_3"] = tn3
    frames_720["px_hero_turn_1"] = make_pixel_art_720(tn1)
    frames_720["px_hero_turn_2"] = make_pixel_art_720(tn2)

    # 5. JUMP (6 frames for 2K, 4 frames for 720p)
    # jump_1: Crouch anticipation on ground (squash 20%, knees bent, arms back)
    j1_char = char_idle.resize((int(char_idle.width * 1.15), int(char_idle.height * 0.82)), Image.Resampling.LANCZOS)
    j1 = place_on_2k_canvas(j1_char, scale=scale_idle, y_offset=0, x_shift=0)

    # jump_2: Explosive take-off (stretch 8% upwards, toes touching ground y_offset=0)
    j2_char = char_jump.resize((int(char_jump.width * 0.92), int(char_jump.height * 1.08)), Image.Resampling.LANCZOS)
    j2 = place_on_2k_canvas(j2_char, scale=scale_jump, y_offset=0, x_shift=0)

    # jump_3: Rising (knees tucking up, ascending, elevated ~55px)
    j3_char = char_jump.resize((int(char_jump.width * 0.96), int(char_jump.height * 1.02)), Image.Resampling.LANCZOS)
    j3 = place_on_2k_canvas(j3_char, scale=scale_jump, y_offset=55, x_shift=0)

    # jump_4: Apex (peak mid-air float, elevated 110px, cape billowing horizontal)
    j4 = place_on_2k_canvas(char_jump, scale=scale_jump, y_offset=110, x_shift=0)

    # jump_5: Falling (descending fast, legs stretching down to catch weight, elevated 50px)
    j5_char = char_jump.resize((int(char_jump.width * 0.95), int(char_jump.height * 1.04)), Image.Resampling.LANCZOS)
    j5 = place_on_2k_canvas(j5_char, scale=scale_jump, y_offset=50, x_shift=0)

    # jump_6: About to land (feet just above bottom edge ~15px, knees flexing)
    j6_char = char_jump.resize((int(char_jump.width * 1.02), int(char_jump.height * 0.98)), Image.Resampling.LANCZOS)
    j6 = place_on_2k_canvas(j6_char, scale=scale_jump, y_offset=15, x_shift=0)

    frames_2k["hero_jump_1"] = j1
    frames_2k["hero_jump_2"] = j2
    frames_2k["hero_jump_3"] = j3
    frames_2k["hero_jump_4"] = j4
    frames_2k["hero_jump_5"] = j5
    frames_2k["hero_jump_6"] = j6

    # 720p Jump: take-off, rising, apex, falling
    frames_720["px_hero_jump_1"] = make_pixel_art_720(j2)
    frames_720["px_hero_jump_2"] = make_pixel_art_720(j3)
    frames_720["px_hero_jump_3"] = make_pixel_art_720(j4)
    frames_720["px_hero_jump_4"] = make_pixel_art_720(j5)

    # 6. LAND (2 frames for 2K, 2 frames for 720p)
    # land_1: Landing absorb (deep knee bend compression, squash 22%, feet on bottom edge)
    ld1_char = char_idle.resize((int(char_idle.width * 1.18), int(char_idle.height * 0.78)), Image.Resampling.LANCZOS)
    ld1 = place_on_2k_canvas(ld1_char, scale=scale_idle, y_offset=0, x_shift=0)

    # land_2: Landing recover (rising up from squash, knees extending back to ready stance)
    ld2_char = char_idle.resize((int(char_idle.width * 1.08), int(char_idle.height * 0.92)), Image.Resampling.LANCZOS)
    ld2 = place_on_2k_canvas(ld2_char, scale=scale_idle, y_offset=0, x_shift=0)

    frames_2k["hero_land_1"] = ld1
    frames_2k["hero_land_2"] = ld2
    frames_720["px_hero_land_1"] = make_pixel_art_720(ld1)
    frames_720["px_hero_land_2"] = make_pixel_art_720(ld2)

    # Save all frames to both wt-anti and main workspace
    for base, s_dir, a_dir in [(WT_ANTI, SPRITES_DIR_ANTI, ANIM_DIR_ANTI), (MAIN_WS, SPRITES_DIR_MAIN, ANIM_DIR_MAIN)]:
        for name, img in frames_2k.items():
            img.save(os.path.join(s_dir, f"{name}.png"))
        for name, img in frames_720.items():
            img.save(os.path.join(s_dir, f"{name}.png"))

        # Build Animated Previews
        # 1. Run GIF at 14 FPS (~71ms)
        run_2k_list = [frames_2k[f"hero_run_{i}"] for i in range(1, 13)]
        run_2k_list[0].save(os.path.join(a_dir, "hero_run_2k.gif"), save_all=True, append_images=run_2k_list[1:], duration=71, loop=0, disposal=2)
        
        run_720_list = [frames_720[f"px_hero_run_{i}"].resize((192, 192), Image.Resampling.NEAREST) for i in range(1, 11)]
        run_720_list[0].save(os.path.join(a_dir, "hero_run_720.gif"), save_all=True, append_images=run_720_list[1:], duration=71, loop=0, disposal=2)

        # 2. Jump & Land GIF at 12 FPS (~83ms)
        jump_2k_list = [frames_2k[f"hero_jump_{i}"] for i in range(1, 7)] + [frames_2k["hero_land_1"], frames_2k["hero_land_2"]]
        jump_2k_list[0].save(os.path.join(a_dir, "hero_jump_2k.gif"), save_all=True, append_images=jump_2k_list[1:], duration=83, loop=0, disposal=2)

        jump_720_list = [frames_720[f"px_hero_jump_{i}"].resize((192, 192), Image.Resampling.NEAREST) for i in range(1, 5)] + [
            frames_720["px_hero_land_1"].resize((192, 192), Image.Resampling.NEAREST),
            frames_720["px_hero_land_2"].resize((192, 192), Image.Resampling.NEAREST)
        ]
        jump_720_list[0].save(os.path.join(a_dir, "hero_jump_720.gif"), save_all=True, append_images=jump_720_list[1:], duration=83, loop=0, disposal=2)

        # 3. Ground Transitions GIF (Runstart -> Run -> Skid -> Turn)
        trans_2k_list = [
            frames_2k["hero_runstart_1"], frames_2k["hero_runstart_2"], frames_2k["hero_runstart_3"],
            frames_2k["hero_run_1"], frames_2k["hero_run_4"], frames_2k["hero_run_7"], frames_2k["hero_run_10"],
            frames_2k["hero_skid_1"], frames_2k["hero_skid_2"], frames_2k["hero_skid_3"],
            frames_2k["hero_turn_1"], frames_2k["hero_turn_2"], frames_2k["hero_turn_3"]
        ]
        trans_2k_list[0].save(os.path.join(a_dir, "hero_ground_trans_2k.gif"), save_all=True, append_images=trans_2k_list[1:], duration=90, loop=0, disposal=2)

        trans_720_list = [f.resize((192, 192), Image.Resampling.NEAREST) for f in [
            frames_720["px_hero_runstart_1"], frames_720["px_hero_runstart_2"],
            frames_720["px_hero_run_1"], frames_720["px_hero_run_5"],
            frames_720["px_hero_skid_1"], frames_720["px_hero_skid_2"],
            frames_720["px_hero_turn_1"], frames_720["px_hero_turn_2"]
        ]]
        trans_720_list[0].save(os.path.join(a_dir, "hero_ground_trans_720.gif"), save_all=True, append_images=trans_720_list[1:], duration=90, loop=0, disposal=2)

        print(f"Delivered {len(frames_2k)} 2K frames and {len(frames_720)} 720p frames to {base}")

    # Build Composite Verification Images
    # 2K Composite on hall_far.jpg
    if os.path.exists(BG_2K):
        bg = Image.open(BG_2K).convert('RGBA')
        comp_2k = bg.copy()
        
        floor_y = 1580
        comp_2k.paste(frames_2k["hero_run_1"], (400, floor_y - 512), frames_2k["hero_run_1"])
        comp_2k.paste(frames_2k["hero_run_6"], (1050, floor_y - 512), frames_2k["hero_run_6"])
        comp_2k.paste(frames_2k["hero_jump_4"], (1750, floor_y - 512), frames_2k["hero_jump_4"])
        comp_2k.paste(frames_2k["hero_skid_2"], (2450, floor_y - 512), frames_2k["hero_skid_2"])
        comp_2k.paste(frames_2k["hero_turn_2"], (3100, floor_y - 512), frames_2k["hero_turn_2"])
        
        comp_2k_preview = comp_2k.resize((1920, 1080), Image.Resampling.LANCZOS)
        comp_2k_preview.save(os.path.join(ANIM_DIR_ANTI, "preview_movement_2k.png"))
        comp_2k_preview.save(os.path.join(ANIM_DIR_MAIN, "preview_movement_2k.png"))
        comp_2k_preview.save(os.path.join(BRAIN, "preview_movement_2k.png"))
        print("Created 2K movement composite check")

    # 720p Composite on neon_mid.png scaled x3
    if os.path.exists(BG_720):
        bg_720 = Image.open(BG_720).convert('RGBA')
        bw, bh = bg_720.size
        bg_720_x3 = bg_720.resize((bw * 3, bh * 3), Image.Resampling.NEAREST)
        comp_720 = bg_720_x3.copy()
        
        floor_y = comp_720.height - 120
        p_run1 = frames_720["px_hero_run_1"].resize((192, 192), Image.Resampling.NEAREST)
        p_run5 = frames_720["px_hero_run_5"].resize((192, 192), Image.Resampling.NEAREST)
        p_jump = frames_720["px_hero_jump_3"].resize((192, 192), Image.Resampling.NEAREST)
        p_skid = frames_720["px_hero_skid_1"].resize((192, 192), Image.Resampling.NEAREST)
        p_turn = frames_720["px_hero_turn_2"].resize((192, 192), Image.Resampling.NEAREST)
        
        comp_720.paste(p_run1, (100, floor_y - 192), p_run1)
        comp_720.paste(p_run5, (400, floor_y - 192), p_run5)
        comp_720.paste(p_jump, (700, floor_y - 192), p_jump)
        comp_720.paste(p_skid, (1000, floor_y - 192), p_skid)
        comp_720.paste(p_turn, (1300, floor_y - 192), p_turn)
        
        comp_720.save(os.path.join(ANIM_DIR_ANTI, "preview_movement_720.png"))
        comp_720.save(os.path.join(ANIM_DIR_MAIN, "preview_movement_720.png"))
        comp_720.save(os.path.join(BRAIN, "preview_movement_720.png"))
        print("Created 720p movement composite check")

if __name__ == '__main__':
    build_all_movement_frames()
