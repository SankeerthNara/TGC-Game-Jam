"""
Removes stray marks the generator left above a sprite's figure: small separate specks (scraps of a
label, a bright bar along the top edge) that would float above the hero's head in the game.

A mark is a connected piece of the picture that lies entirely above the top of the main figure (the
largest piece) and is either small (under 1.5% of all painted pixels) or sits in the top fifth of the
canvas (a bar or label along the top edge). Sparkles and effects beside or over
the figure are kept.

Usage: python tools/remove_stray_marks.py <sprite.png> [...]   (rewrites the files in place)
"""

import sys
from collections import deque

import numpy as np
from PIL import Image


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
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        q.append((ny, nx))
        yield np.array(py), np.array(px)


def fix(path):
    img = Image.open(path).convert('RGBA')
    im = np.array(img)
    mask = im[:, :, 3] > 16
    parts = list(components(mask))
    if len(parts) < 2:
        print(path, 'clean')
        return
    total = mask.sum()
    main = max(parts, key=lambda p: len(p[0]))
    top = main[0].min()
    margin = max(2, im.shape[0] // 64)
    removed = 0
    for py, px in parts:
        near_top = py.max() < 0.2 * im.shape[0]  # a bar or label along the top edge, whatever its size
        if (len(py) < 0.015 * total or near_top) and py.max() < top - margin:
            im[py, px, 3] = 0
            removed += len(py)
    if removed:
        Image.fromarray(im, 'RGBA').save(path)
        print(path, 'removed %d stray pixels' % removed)
    else:
        print(path, 'clean')


if __name__ == '__main__':
    for p in sys.argv[1:]:
        fix(p)
