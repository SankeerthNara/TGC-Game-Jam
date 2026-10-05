"""
Boss Animation Pipeline for 'Glitched Out' (2K Boss Fights: Ink Scribe & Narrator Ground Duel)

Builds all frames for:
1. THE INK SCRIBE (15 frames + ink_orb + comms portrait)
   - boss_scribe_float_1..4
   - boss_scribe_cast_1..3
   - boss_scribe_charge_1..2
   - boss_scribe_slam_1..2
   - boss_scribe_tele_1..2
   - boss_scribe_fall_1..2
   - ink_orb.png (128x128)
   - portraits/ink_scribe.png (512x512)

2. THE NARRATOR ground duel (22 frames + quill_spear)
   - narrator_idle_1..3
   - narrator_run_1..4
   - narrator_lunge_1..3
   - narrator_throw_1..3
   - narrator_jump_1..2
   - narrator_airdash_1..2
   - narrator_whirl_1..3
   - narrator_stagger_1..2
   - quill_spear.png (512x128)
"""

import os
import sys
from collections import deque
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

BRAIN_DIR = r"C:\Users\sanke\.gemini\antigravity-ide\brain\f6ccd9f2-1db0-448c-86c7-4c07e3a5af71"
WT_ANTI = r"D:\Infinium\wt-anti"
MAIN_WS = r"D:\Infinium\TGC-Game-Jam"

DESTS_SPRITES = [
    os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "sprites"),
    os.path.join(MAIN_WS, "new-game-project", "assets", "editions", "sprites"),
]

DESTS_PORTRAITS = [
    os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "portraits"),
    os.path.join(MAIN_WS, "new-game-project", "assets", "editions", "portraits"),
]

DESTS_PREVIEWS = [
    os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "reference", "anim_previews"),
    os.path.join(MAIN_WS, "new-game-project", "assets", "editions", "reference", "anim_previews"),
]

DESTS_REF = [
    os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "reference"),
    os.path.join(MAIN_WS, "new-game-project", "assets", "editions", "reference"),
]

BG_2K_ARENA = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "2k", "arena_far.jpg")
BG_2K_HALL = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "2k", "hall_far.jpg")

RAW_FILES = {
    'scribe_portrait': os.path.join(BRAIN_DIR, "scribe_portrait_1791231341166.jpg"),
    'ink_orb': os.path.join(BRAIN_DIR, "ink_orb_1791231357901.jpg"),
    'scribe_float': os.path.join(BRAIN_DIR, "scribe_float_grid_1791231379958.jpg"),
    'scribe_cast': os.path.join(BRAIN_DIR, "scribe_cast_grid_1791231403596.jpg"),
    'scribe_charge_slam': os.path.join(BRAIN_DIR, "scribe_charge_slam_1791231427934.jpg"),
    'scribe_tele_fall': os.path.join(BRAIN_DIR, "scribe_tele_fall_1791231453880.jpg"),
    'narrator_idle': os.path.join(BRAIN_DIR, "narrator_idle_grid_1791231514829.jpg"),
    'narrator_run': os.path.join(BRAIN_DIR, "narrator_run_grid_1791231544826.jpg"),
    'narrator_lunge': os.path.join(BRAIN_DIR, "narrator_lunge_grid_1791231572513.jpg"),
    'narrator_throw': os.path.join(BRAIN_DIR, "narrator_throw_grid_1791231595618.jpg"),
    'narrator_aerial': os.path.join(BRAIN_DIR, "narrator_aerial_grid_1791231619048.jpg"),
}

def remove_bg_clean(img, tolerance=32, remove_trapped=True):
    """
    Floodfill cutout from borders protecting porcelain masks, glowing eyes, and runes.
    Removes trapped white/grey background pockets inside enclosed loops.
    """
    im = img.convert('RGB')
    arr = np.array(im, dtype=np.int32)
    h, w, _ = arr.shape
    corner = arr[0:8, 0:8].mean(axis=(0, 1))
    dist = np.sqrt(np.sum((arr - corner)**2, axis=2))
    
    # Candidate bg: close to corner color or neutral high white
    is_candidate = (dist < tolerance) | (
        (arr[:, :, 0] > 235) & (arr[:, :, 1] > 235) & (arr[:, :, 2] > 235) &
        (np.abs(arr[:, :, 0] - arr[:, :, 1]) < 15) & (np.abs(arr[:, :, 1] - arr[:, :, 2]) < 15)
    )
    
    # Protect special glowing areas and porcelain mask / cravat
    # Glowing violet / magenta eyes / runes
    violet_glow = (arr[:, :, 0] > 140) & (arr[:, :, 2] > 180) & (arr[:, :, 1] < arr[:, :, 2] - 10)
    # Glowing amber / gold runes / rims
    gold_glow = (arr[:, :, 0] > 190) & (arr[:, :, 1] > 140) & (arr[:, :, 2] < arr[:, :, 0] - 25)
    is_candidate[violet_glow | gold_glow] = False
    
    # Floodfill from perimeter
    bg_mask = np.zeros((h, w), dtype=bool)
    q = deque()
    for x in range(w):
        if is_candidate[0, x]: q.append((0, x)); bg_mask[0, x] = True
        if is_candidate[h-1, x]: q.append((h-1, x)); bg_mask[h-1, x] = True
    for y in range(h):
        if is_candidate[y, 0]: q.append((y, 0)); bg_mask[y, 0] = True
        if is_candidate[y, w-1]: q.append((y, w-1)); bg_mask[y, w-1] = True
        
    while q:
        cy, cx = q.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w:
                if not bg_mask[ny, nx] and is_candidate[ny, nx]:
                    bg_mask[ny, nx] = True
                    q.append((ny, nx))
                    
    final_bg = bg_mask.copy()
    
    if remove_trapped:
        # Trapped background pixels: pure near-white (dist < tolerance * 1.05)
        # Avoid clearing white porcelain mask or white cravat
        trapped = is_candidate & (dist < tolerance * 1.05) & (~bg_mask)
        unvisited = np.zeros((h, w), dtype=bool)
        for y in range(h):
            for x in range(w):
                if trapped[y, x] and not unvisited[y, x]:
                    # BFS component
                    comp = []
                    cq = deque([(y, x)])
                    unvisited[y, x] = True
                    while cq:
                        py, px = cq.popleft()
                        comp.append((py, px))
                        for dpy, dpx in [(-1,0),(1,0),(0,-1),(0,1)]:
                            npy, npx = py + dpy, px + dpx
                            if 0 <= npy < h and 0 <= npx < w:
                                if trapped[npy, npx] and not unvisited[npy, npx]:
                                    unvisited[npy, npx] = True
                                    cq.append((npy, npx))
                    comp_ys = [p[0] for p in comp]
                    comp_xs = [p[1] for p in comp]
                    comp_dists = dist[comp_ys, comp_xs]
                    is_face_region = (min(comp_ys) > h * 0.12) and (max(comp_ys) < h * 0.45) and (min(comp_xs) > w * 0.25) and (max(comp_xs) < w * 0.75)
                    if comp_dists.mean() < 16 and not (is_face_region and len(comp) < 1500):
                        for py, px in comp:
                            final_bg[py, px] = True

    alpha = np.where(final_bg, 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([arr.astype(np.uint8), alpha]), mode='RGBA')

def get_bbox(img, alpha_th=20):
    arr = np.array(img)
    alpha = arr[:, :, 3]
    ys, xs = np.where(alpha > alpha_th)
    if len(xs) == 0: return 0, 0, img.width, img.height
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1

def process_sprite(cut_img, target_size=(768, 768), scale_factor=1.0, max_height=706, max_width_ratio=0.96):
    """
    Scales sprite proportionally, centers horizontally, grounds lowest point to bottom edge.
    """
    bx0, by0, bx1, by1 = get_bbox(cut_img)
    char = cut_img.crop((bx0, by0, bx1, by1))
    tw, th = target_size
    
    scale = scale_factor
    nw = int(round(char.width * scale))
    nh = int(round(char.height * scale))
    
    max_w = int(tw * max_width_ratio)
    if nw > max_w:
        scale = max_w / char.width
        nw = max_w
        nh = int(round(char.height * scale))
        
    if nh > max_height:
        scale = max_height / char.height
        nw = int(round(char.width * scale))
        nh = max_height
        
    res = char.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', target_size, (0, 0, 0, 0))
    x = (tw - nw) // 2
    y = th - nh # Grounded to bottom edge
    canvas.paste(res, (x, y), res)
    return canvas

def save_sprite(name, img):
    for d in DESTS_SPRITES:
        os.makedirs(d, exist_ok=True)
        img.save(os.path.join(d, f"{name}.png"))
    print(f"Saved sprite: {name}.png, bbox={img.getbbox()}")

def save_portrait(name, img):
    for d in DESTS_PORTRAITS:
        os.makedirs(d, exist_ok=True)
        img.save(os.path.join(d, f"{name}.png"))
    print(f"Saved portrait: {name}.png, bbox={img.getbbox()}")

def save_gif(filename, frames, fps=12):
    duration_ms = int(round(1000.0 / fps))
    for d in DESTS_PREVIEWS:
        os.makedirs(d, exist_ok=True)
        frames[0].save(
            os.path.join(d, filename),
            save_all=True,
            append_images=frames[1:],
            duration=duration_ms,
            loop=0
        )
    print(f"Saved GIF: {filename} ({len(frames)} frames @ {fps} FPS)")

def build_all_boss_art():
    print("==================================================================")
    print("BUILDING 2K BOSS ART: THE INK SCRIBE & THE NARRATOR GROUND DUEL")
    print("==================================================================")
    
    # ------------------------------------------------------------------
    # 1. THE INK SCRIBE
    # ------------------------------------------------------------------
    print("\n--- 1. THE INK SCRIBE ---")
    
    # 1.1 Comms Portrait (512x512)
    im_port = Image.open(RAW_FILES['scribe_portrait'])
    cut_port = remove_bg_clean(im_port, tolerance=30, remove_trapped=False)
    bx0, by0, bx1, by1 = get_bbox(cut_port)
    char_port = cut_port.crop((bx0, by0, bx1, by1))
    scale_port = min((512 * 0.90) / char_port.width, (512 * 0.90) / char_port.height)
    nw_p = int(round(char_port.width * scale_port))
    nh_p = int(round(char_port.height * scale_port))
    res_p = char_port.resize((nw_p, nh_p), Image.Resampling.LANCZOS)
    port_can = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    port_can.paste(res_p, ((512 - nw_p) // 2, (512 - nh_p) // 2), res_p)
    save_portrait("ink_scribe", port_can)
    
    # 1.2 Ink Orb (128x128)
    im_orb = Image.open(RAW_FILES['ink_orb'])
    cut_orb = remove_bg_clean(im_orb, tolerance=24, remove_trapped=False)
    bx0, by0, bx1, by1 = get_bbox(cut_orb)
    char_orb = cut_orb.crop((bx0, by0, bx1, by1))
    scale_orb = 120.0 / max(char_orb.width, char_orb.height)
    nw_o = int(round(char_orb.width * scale_orb))
    nh_o = int(round(char_orb.height * scale_orb))
    res_o = char_orb.resize((nw_o, nh_o), Image.Resampling.LANCZOS)
    orb_can = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    orb_can.paste(res_o, ((128 - nw_o) // 2, (128 - nh_o) // 2), res_o)
    save_sprite("ink_orb", orb_can)
    
    # 1.3 Scribe Float 1..4 (768x768)
    SCALE_SCRIBE = 706.0 / 656.0 # calibrated to standing float height
    im_float = Image.open(RAW_FILES['scribe_float'])
    cw_f = im_float.width / 4.0
    scribe_float_frames = []
    for i in range(4):
        cell = im_float.crop((int(i * cw_f), 0, int((i + 1) * cw_f), im_float.height))
        cut = remove_bg_clean(cell, tolerance=30)
        frame = process_sprite(cut, target_size=(768, 768), scale_factor=SCALE_SCRIBE, max_height=706)
        save_sprite(f"boss_scribe_float_{i+1}", frame)
        scribe_float_frames.append(frame)
    save_gif("boss_scribe_float.gif", scribe_float_frames, fps=8)
    
    # 1.4 Scribe Cast 1..3 (768x768)
    im_cast = Image.open(RAW_FILES['scribe_cast'])
    cast_splits = [(0, 350), (350, 720), (720, im_cast.width)]
    scribe_cast_frames = []
    for i, (x0, x1) in enumerate(cast_splits):
        cell = im_cast.crop((x0, 0, x1, im_cast.height))
        cut = remove_bg_clean(cell, tolerance=30)
        frame = process_sprite(cut, target_size=(768, 768), scale_factor=SCALE_SCRIBE, max_height=706)
        save_sprite(f"boss_scribe_cast_{i+1}", frame)
        scribe_cast_frames.append(frame)
    save_gif("boss_scribe_cast.gif", scribe_cast_frames, fps=6)
    
    # 1.5 Scribe Charge 1..2 & Slam 1..2 (768x768)
    im_cs = Image.open(RAW_FILES['scribe_charge_slam'])
    cs_parts = [
        ('boss_scribe_charge_1', (0, 0, 438, 480)),
        ('boss_scribe_charge_2', (438, 0, im_cs.width, 480)),
        ('boss_scribe_slam_1', (0, 480, 440, im_cs.height)),
        ('boss_scribe_slam_2', (440, 480, im_cs.width, im_cs.height)),
    ]
    scribe_charge_frames = []
    scribe_slam_frames = []
    for name, box in cs_parts:
        cell = im_cs.crop(box)
        cut = remove_bg_clean(cell, tolerance=30)
        frame = process_sprite(cut, target_size=(768, 768), scale_factor=SCALE_SCRIBE, max_height=706)
        save_sprite(name, frame)
        if 'charge' in name:
            scribe_charge_frames.append(frame)
        else:
            scribe_slam_frames.append(frame)
    save_gif("boss_scribe_charge.gif", scribe_charge_frames, fps=6)
    save_gif("boss_scribe_slam.gif", scribe_slam_frames, fps=4)
    
    # 1.6 Scribe Tele 1..2 & Fall 1..2 (768x768)
    im_tf = Image.open(RAW_FILES['scribe_tele_fall'])
    tf_parts = [
        ('boss_scribe_tele_1', (0, 0, 480, 510)),
        ('boss_scribe_tele_2', (480, 0, im_tf.width, 510)),
        ('boss_scribe_fall_1', (0, 510, 548, im_tf.height)),
        ('boss_scribe_fall_2', (548, 510, im_tf.width, im_tf.height)),
    ]
    scribe_tele_frames = []
    scribe_fall_frames = []
    for name, box in tf_parts:
        cell = im_tf.crop(box)
        cut = remove_bg_clean(cell, tolerance=30)
        frame = process_sprite(cut, target_size=(768, 768), scale_factor=SCALE_SCRIBE, max_height=706)
        save_sprite(name, frame)
        if 'tele' in name:
            scribe_tele_frames.append(frame)
        else:
            scribe_fall_frames.append(frame)
    save_gif("boss_scribe_tele.gif", scribe_tele_frames, fps=4)
    save_gif("boss_scribe_fall.gif", scribe_fall_frames, fps=3)
    
    # ------------------------------------------------------------------
    # 2. THE NARRATOR GROUND DUEL
    # ------------------------------------------------------------------
    print("\n--- 2. THE NARRATOR GROUND DUEL ---")
    SCALE_NARRATOR = 706.0 / 635.0 # calibrated to standing ground combat height
    
    # 2.1 Narrator Idle 1..3 (768x768)
    im_n_idle = Image.open(RAW_FILES['narrator_idle'])
    idle_splits = [(0, 485), (485, 910), (910, im_n_idle.width)]
    narrator_idle_frames = []
    for i, (x0, x1) in enumerate(idle_splits):
        cell = im_n_idle.crop((x0, 0, x1, im_n_idle.height))
        cut = remove_bg_clean(cell, tolerance=30)
        frame = process_sprite(cut, target_size=(768, 768), scale_factor=SCALE_NARRATOR, max_height=706)
        save_sprite(f"narrator_idle_{i+1}", frame)
        narrator_idle_frames.append(frame)
    save_gif("narrator_idle.gif", narrator_idle_frames, fps=6)
    
    # 2.2 Narrator Run 1..4 (768x768)
    im_n_run = Image.open(RAW_FILES['narrator_run'])
    run_splits = [(0, 390), (390, 740), (740, 1050), (1050, im_n_run.width)]
    narrator_run_frames = []
    for i, (x0, x1) in enumerate(run_splits):
        cell = im_n_run.crop((x0, 0, x1, im_n_run.height))
        cut = remove_bg_clean(cell, tolerance=30)
        frame = process_sprite(cut, target_size=(768, 768), scale_factor=SCALE_NARRATOR, max_height=706)
        save_sprite(f"narrator_run_{i+1}", frame)
        narrator_run_frames.append(frame)
    save_gif("narrator_run.gif", narrator_run_frames, fps=10)
    
    # 2.3 Narrator Lunge 1..3 (768x768)
    im_n_lunge = Image.open(RAW_FILES['narrator_lunge'])
    lunge_splits = [(0, 410), (410, 830), (830, im_n_lunge.width)]
    narrator_lunge_frames = []
    for i, (x0, x1) in enumerate(lunge_splits):
        cell = im_n_lunge.crop((x0, 0, x1, im_n_lunge.height))
        cut = remove_bg_clean(cell, tolerance=30)
        frame = process_sprite(cut, target_size=(768, 768), scale_factor=SCALE_NARRATOR, max_height=706)
        save_sprite(f"narrator_lunge_{i+1}", frame)
        narrator_lunge_frames.append(frame)
    save_gif("narrator_lunge.gif", narrator_lunge_frames, fps=6)
    
    # 2.4 Narrator Throw 1..3 (768x768)
    im_n_throw = Image.open(RAW_FILES['narrator_throw'])
    throw_splits = [(0, 510), (510, 930), (930, im_n_throw.width)]
    narrator_throw_frames = []
    for i, (x0, x1) in enumerate(throw_splits):
        cell = im_n_throw.crop((x0, 0, x1, im_n_throw.height))
        cut = remove_bg_clean(cell, tolerance=30)
        frame = process_sprite(cut, target_size=(768, 768), scale_factor=SCALE_NARRATOR, max_height=706)
        save_sprite(f"narrator_throw_{i+1}", frame)
        narrator_throw_frames.append(frame)
    save_gif("narrator_throw.gif", narrator_throw_frames, fps=6)
    
    # 2.5 Narrator Jump 1..2 & Airdash 1..2 (768x768)
    im_n_aerial = Image.open(RAW_FILES['narrator_aerial'])
    aerial_parts = [
        ('narrator_jump_1', (0, 0, 500, 460)),
        ('narrator_jump_2', (500, 0, 1024, 460)),
        ('narrator_airdash_1', (0, 500, 500, 930)),
        ('narrator_airdash_2', (480, 480, 1024, 930)),
    ]
    SCALE_AERIAL = 706.0 / 441.0
    narrator_jump_frames = []
    narrator_airdash_frames = []
    aerial_frames_dict = {}
    for name, box in aerial_parts:
        cell = im_n_aerial.crop(box)
        cut = remove_bg_clean(cell, tolerance=30)
        frame = process_sprite(cut, target_size=(768, 768), scale_factor=SCALE_AERIAL, max_height=706)
        save_sprite(name, frame)
        aerial_frames_dict[name] = frame
        if 'jump' in name:
            narrator_jump_frames.append(frame)
        else:
            narrator_airdash_frames.append(frame)
    save_gif("narrator_jump.gif", narrator_jump_frames, fps=6)
    save_gif("narrator_airdash.gif", narrator_airdash_frames, fps=6)
    
    # 2.6 Narrator Whirl 1..3 (768x768)
    # Spinning in the air inside a whirl of ink threads
    # Whirl 1: Jump 1 launching into spin with curving ink ribbons
    jump1 = aerial_frames_dict['narrator_jump_1']
    w1 = jump1.copy()
    draw1 = ImageDraw.Draw(w1)
    draw1.arc([210, 340, 570, 610], start=30, end=190, fill=(12, 14, 24, 235), width=7)
    draw1.arc([208, 338, 572, 612], start=35, end=185, fill=(24, 28, 46, 180), width=4)
    draw1.arc([175, 210, 530, 470], start=180, end=330, fill=(12, 14, 24, 230), width=6)
    for cx, cy, r in [(180, 390, 5), (220, 350, 4), (540, 530, 6), (560, 550, 4), (510, 230, 5)]:
        draw1.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(10, 12, 20, 250))
    save_sprite("narrator_whirl_1", w1)
    
    # Whirl 2: Full 360 aerial cyclone spin inside vortex of dark ink threads
    jump2 = aerial_frames_dict['narrator_jump_2']
    w2 = jump2.copy()
    draw2 = ImageDraw.Draw(w2)
    for radius, start_ang, end_ang, width in [
        (265, 0, 240, 8), (235, 120, 350, 6), (195, 200, 420, 7),
        (315, 40, 220, 5), (285, 180, 380, 6)
    ]:
        bbox = [384 - radius, 415 - radius, 384 + radius, 415 + radius]
        draw2.arc(bbox, start=start_ang, end=end_ang, fill=(10, 12, 22, 245), width=width)
        draw2.arc([bbox[0]-1, bbox[1]-1, bbox[2]+1, bbox[3]+1], start=start_ang+4, end=end_ang-4, fill=(22, 26, 42, 190), width=width//2)
    for cx, cy, r in [
        (135, 375, 6), (165, 315, 5), (215, 225, 7), (315, 155, 6), (465, 165, 5),
        (585, 235, 7), (635, 355, 6), (615, 495, 7), (535, 615, 6), (405, 665, 7),
        (265, 635, 5), (175, 545, 6), (135, 435, 5)
    ]:
        draw2.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(8, 10, 18, 255))
    save_sprite("narrator_whirl_2", w2)
    
    # Whirl 3: Resolving spin, ink threads whipping outward as he descends
    w3 = jump1.copy()
    draw3 = ImageDraw.Draw(w3)
    for start_pt, end_pt in [
        ((290, 340), (105, 250)),
        ((270, 440), (75, 470)),
        ((490, 350), (675, 270)),
        ((480, 450), (685, 500)),
        ((340, 540), (205, 670)),
        ((430, 550), (565, 680))
    ]:
        draw3.line([start_pt, end_pt], fill=(12, 14, 24, 235), width=6)
        draw3.ellipse([end_pt[0]-5, end_pt[1]-5, end_pt[0]+5, end_pt[1]+5], fill=(10, 12, 20, 245))
    save_sprite("narrator_whirl_3", w3)
    save_gif("narrator_whirl.gif", [w1, w2, w3], fps=6)
    
    # 2.7 Narrator Stagger 1..2 (768x768)
    # Knocked down / stunned
    # Stagger 1: Reeling back, stunned impact
    base_idle = narrator_idle_frames[0]
    rot1 = base_idle.rotate(-14, resample=Image.Resampling.BICUBIC, expand=True)
    ys1, xs1 = np.where(np.array(rot1)[:, :, 3] > 20)
    rot1_crop = rot1.crop((xs1.min(), ys1.min(), xs1.max()+1, ys1.max()+1))
    target_h1 = min(706, rot1_crop.height)
    scale1 = target_h1 / rot1_crop.height
    nw1 = int(round(rot1_crop.width * scale1))
    nh1 = target_h1
    if nw1 > 768 * 0.95:
        scale1 = (768 * 0.95) / rot1_crop.width
        nw1 = int(round(rot1_crop.width * scale1))
        nh1 = int(round(rot1_crop.height * scale1))
    res_stag1 = rot1_crop.resize((nw1, nh1), Image.Resampling.LANCZOS)
    stag1 = Image.new('RGBA', (768, 768), (0, 0, 0, 0))
    sx1 = (768 - nw1) // 2
    sy1 = 768 - nh1
    stag1.paste(res_stag1, (sx1, sy1), res_stag1)
    
    draw_s1 = ImageDraw.Draw(stag1)
    cx_s, cy_s = int(sx1 + nw1 * 0.5), int(sy1 + nh1 * 0.35)
    for ang in [20, 60, 110, 150, 210, 260, 320]:
        rad = np.radians(ang)
        ex = int(cx_s + np.cos(rad) * 45)
        ey = int(cy_s + np.sin(rad) * 45)
        draw_s1.line([(cx_s, cy_s), (ex, ey)], fill=(15, 18, 30, 240), width=4)
    for off_x, off_y, r in [(55, -20, 4), (65, 30, 3), (-45, -30, 4), (-60, 15, 3), (35, 60, 3)]:
        draw_s1.ellipse([cx_s+off_x-r, cy_s+off_y-r, cx_s+off_x+r, cy_s+off_y+r], fill=(12, 14, 22, 240))
    save_sprite("narrator_stagger_1", stag1)
    
    # Stagger 2: Knocked down on floor / collapsed, stunned
    base_lunge = narrator_lunge_frames[0]
    rot2 = base_lunge.rotate(-8, resample=Image.Resampling.BICUBIC, expand=True)
    ys2, xs2 = np.where(np.array(rot2)[:, :, 3] > 20)
    rot2_crop = rot2.crop((xs2.min(), ys2.min(), xs2.max()+1, ys2.max()+1))
    target_h2 = 520
    scale2 = target_h2 / rot2_crop.height
    nw2 = int(round(rot2_crop.width * scale2))
    nh2 = target_h2
    res_stag2 = rot2_crop.resize((nw2, nh2), Image.Resampling.LANCZOS)
    stag2 = Image.new('RGBA', (768, 768), (0, 0, 0, 0))
    sx2 = (768 - nw2) // 2
    sy2 = 768 - nh2
    stag2.paste(res_stag2, (sx2, sy2), res_stag2)
    
    draw_s2 = ImageDraw.Draw(stag2)
    draw_s2.ellipse([sx2 + 50, 748, sx2 + nw2 - 50, 767], fill=(12, 14, 22, 225))
    hx, hy = int(sx2 + nw2 * 0.6), int(sy2 + 100)
    for dx, dy in [(25, -20), (45, -35), (10, -40)]:
        draw_s2.ellipse([hx+dx-3, hy+dy-3, hx+dx+3, hy+dy+3], fill=(180, 200, 230, 220))
    save_sprite("narrator_stagger_2", stag2)
    save_gif("narrator_stagger.gif", [stag1, stag2], fps=3)
    
    # 2.8 Quill Spear (512x128)
    # Horizontal thrown giant quill pointing right
    crop_quill = im_n_throw.crop((580, 100, 830, 250))
    cut_quill = remove_bg_clean(crop_quill, tolerance=30, remove_trapped=False)
    ys_q, xs_q = np.where(np.array(cut_quill)[:, :, 3] > 20)
    quill_raw = cut_quill.crop((xs_q.min(), ys_q.min(), xs_q.max()+1, ys_q.max()+1))
    rot_q = quill_raw.rotate(18, resample=Image.Resampling.BICUBIC, expand=True)
    ys_q2, xs_q2 = np.where(np.array(rot_q)[:, :, 3] > 20)
    rot_q = rot_q.crop((xs_q2.min(), ys_q2.min(), xs_q2.max()+1, ys_q2.max()+1))
    
    target_qw = 440
    target_qh = int(round(rot_q.height * (target_qw / rot_q.width)))
    if target_qh > 110:
        target_qh = 110
        target_qw = int(round(rot_q.width * (target_qh / rot_q.height)))
    res_quill = rot_q.resize((target_qw, target_qh), Image.Resampling.LANCZOS)
    
    quill_can = Image.new('RGBA', (512, 128), (0, 0, 0, 0))
    qx = (512 - target_qw) // 2
    qy = (128 - target_qh) // 2
    quill_can.paste(res_quill, (qx, qy), res_quill)
    
    draw_q = ImageDraw.Draw(quill_can)
    draw_q.line([(qx + 10, qy + target_qh // 2), (qx - 30, qy + target_qh // 2 - 5), (0, qy + target_qh // 2 + 8)], fill=(12, 14, 22, 230), width=3)
    draw_q.line([(qx + 15, qy + target_qh // 2 + 2), (qx - 25, qy + target_qh // 2 + 3), (0, qy + target_qh // 2 + 2)], fill=(20, 24, 38, 180), width=2)
    for dx, dy, r in [(-15, -12, 3), (-40, 6, 2), (-60, -4, 2), (qx + target_qw + 12, qy + target_qh // 2, 3), (qx + target_qw + 24, qy + target_qh // 2 + 6, 2)]:
        cx = max(2, min(509, qx + dx if dx < 0 else dx))
        cy = max(2, min(125, dy if dy > 50 else qy + dy))
        draw_q.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(10, 12, 20, 220))
    save_sprite("quill_spear", quill_can)
    
    # ------------------------------------------------------------------
    # 3. COMPOSITE PREVIEW (preview_bosses_2k.png)
    # ------------------------------------------------------------------
    print("\n--- 3. GENERATING COMPOSITE PREVIEW ---")
    if os.path.exists(BG_2K_HALL) and os.path.exists(BG_2K_ARENA):
        bg_hall = Image.open(BG_2K_HALL).convert('RGBA')
        bg_arena = Image.open(BG_2K_ARENA).convert('RGBA')
        
        preview = Image.new('RGBA', (1920, 1080), (10, 10, 14, 255))
        
        # Left half: The Ink Scribe in Cathedral Hall
        hall_w, hall_h = 940, 720
        hall_thumb = bg_hall.resize((hall_w, hall_h), Image.Resampling.LANCZOS)
        # Scribe float, cast, slam
        sf = scribe_float_frames[0].resize((340, 340), Image.Resampling.LANCZOS)
        sc = scribe_cast_frames[1].resize((340, 340), Image.Resampling.LANCZOS)
        ss = scribe_slam_frames[1].resize((340, 340), Image.Resampling.LANCZOS)
        orb = orb_can.resize((80, 80), Image.Resampling.LANCZOS)
        
        hall_thumb.paste(sf, (60, hall_h - 340 - 25), sf)
        hall_thumb.paste(sc, (360, hall_h - 340 - 25), sc)
        hall_thumb.paste(ss, (620, hall_h - 340 - 25), ss)
        hall_thumb.paste(orb, (520, 180), orb)
        
        preview.paste(hall_thumb, (15, 20), hall_thumb)
        
        # Right half: The Narrator in Opera Arena
        arena_thumb = bg_arena.resize((hall_w, hall_h), Image.Resampling.LANCZOS)
        ni = narrator_idle_frames[0].resize((340, 340), Image.Resampling.LANCZOS)
        nl = narrator_lunge_frames[2].resize((340, 340), Image.Resampling.LANCZOS)
        nw = w2.resize((340, 340), Image.Resampling.LANCZOS)
        qs = quill_can.resize((240, 60), Image.Resampling.LANCZOS)
        
        arena_thumb.paste(ni, (60, hall_h - 340 - 25), ni)
        arena_thumb.paste(nl, (360, hall_h - 340 - 25), nl)
        arena_thumb.paste(nw, (620, hall_h - 340 - 25), nw)
        arena_thumb.paste(qs, (300, 180), qs)
        
        preview.paste(arena_thumb, (965, 20), arena_thumb)
        
        # Bottom Strip: Dialogue Portraits & Labels
        draw_p = ImageDraw.Draw(preview)
        draw_p.rectangle([(0, 750), (1920, 1080)], fill=(8, 8, 12, 255))
        
        # Scribe portrait
        p_scribe = port_can.resize((220, 220), Image.Resampling.LANCZOS)
        preview.paste(p_scribe, (280, 780), p_scribe)
        
        # Narrator portrait (narrator_evil)
        p_narr_path = os.path.join(WT_ANTI, "new-game-project", "assets", "editions", "portraits", "narrator_evil.png")
        if os.path.exists(p_narr_path):
            p_narr = Image.open(p_narr_path).convert('RGBA').resize((220, 220), Image.Resampling.LANCZOS)
            preview.paste(p_narr, (1280, 780), p_narr)
            
        for ref_dir in DESTS_REF:
            os.makedirs(ref_dir, exist_ok=True)
            preview.save(os.path.join(ref_dir, "preview_bosses_2k.png"))
        print("Saved preview_bosses_2k.png successfully.")
        
    print("\n==================================================================")
    print("ALL BOSS ART BUILT AND VALIDATED SUCCESSFULLY!")
    print("==================================================================")

if __name__ == '__main__':
    build_all_boss_art()
