"""
Removes white background trapped inside a sprite's silhouette (between an arm and the body, inside
an ink swirl). The cutout step only removes background connected to the image border, so enclosed
pockets stay opaque white and show as white blobs on dark stages.

A pocket is a connected region of pure white whose surrounding ring is dark (ink outlines, the body).
White that sits in a bright ring (the glowing light blade) is kept. Edge pixels between a pocket and
the ink are un-blended from white so no light fringe is left.

Usage: python tools/fix_enclosed_white.py <sprite.png> [...]   (rewrites the files in place)
"""

import sys
from collections import deque

import numpy as np
from PIL import Image, ImageFilter

RING_MAX_LUM = 150.0  # a darker ring than this means the white is trapped background
MIN_AREA = 8


def components(mask):
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    ys, xs = np.nonzero(mask)
    for sy, sx in zip(ys, xs):
        if seen[sy, sx]:
            continue
        q = deque([(sy, sx)])
        seen[sy, sx] = True
        py, px = [], []
        while q:
            y, x = q.popleft()
            py.append(y)
            px.append(x)
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    q.append((ny, nx))
        yield np.array(py), np.array(px)


def head_box(im):
    """The face: skin-coloured pixels in the top part of the figure, grown a little (or None)."""
    r, g, b, a = im[:, :, 0], im[:, :, 1], im[:, :, 2], im[:, :, 3]
    ys = np.nonzero(a.max(1) > 100)[0]
    if len(ys) == 0:
        return None
    top, bottom = ys.min(), ys.max()
    skin = (a > 200) & (r > 170) & (g > 110) & (b > 70) & (r > g) & (g > b)
    skin[int(top + 0.45 * (bottom - top)):, :] = False
    sy, sx = np.nonzero(skin)
    if len(sy) < 20:
        return None
    return (sx.min() - 18, sy.min() - 18, sx.max() + 18, sy.max() + 18)


def fix(path):
    img = Image.open(path).convert('RGBA')
    im = np.array(img).astype(float)
    a = im[:, :, 3]
    mn = im[:, :, :3].min(2)
    mx = im[:, :, :3].max(2)
    lum = im[:, :, :3].mean(2)
    white = (a > 200) & (mn > 225) & (mx - mn < 25)
    head = head_box(im)
    pockets = np.zeros(white.shape, np.uint8)
    removed = 0
    for py, px in components(white):
        if len(py) < MIN_AREA:
            continue
        cy, cx = py.mean(), px.mean()
        if head is not None and head[0] <= cx <= head[2] and head[1] <= cy <= head[3] and len(py) < 150:
            continue  # eyes, teeth, a monocle glint: white on purpose
        m = np.zeros(white.shape, np.uint8)
        m[py, px] = 255
        ring = (np.array(Image.fromarray(m).filter(ImageFilter.MaxFilter(7))) > 0) & (m == 0) & (a > 100)
        if ring.any() and lum[ring].mean() < RING_MAX_LUM:
            pockets[py, px] = 255
            removed += len(py)
    if removed == 0:
        print(path, 'clean')
        return
    core = pockets > 0
    edge = (np.array(Image.fromarray(pockets).filter(ImageFilter.MaxFilter(5))) > 0) & ~core
    # pockets: fully transparent
    im[core, 3] = 0
    # edges: un-blend from white (colour = alpha * ink + (1 - alpha) * white)
    al = np.clip((255.0 - mn) / 230.0, 0.0, 1.0)
    sel = edge & (al < 0.999)
    for ch in range(3):
        c = im[:, :, ch]
        fg = np.where(al > 0.05, (c - (1.0 - al) * 255.0) / np.maximum(al, 0.05), 0.0)
        c[sel] = np.clip(fg[sel], 0, 255)
    im[sel, 3] = np.minimum(im[sel, 3], al[sel] * 255.0)
    Image.fromarray(im.round().astype(np.uint8), 'RGBA').save(path)
    print(path, 'removed %d trapped white pixels' % removed)


if __name__ == '__main__':
    for p in sys.argv[1:]:
        fix(p)
