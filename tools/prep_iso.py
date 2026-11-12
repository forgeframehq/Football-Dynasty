#!/usr/bin/env python3
"""Normalise generated isometric building images for the club city.

usage: python3 -I tools/prep_iso.py <src dir> [<src dir> ...]
Removes stray fragments, scales the base to a fixed width and puts the
bottom corner of the base at a fixed anchor, so every sprite sits on the grid.
Output: assets/iso/<name>.png (640x640, anchor at 320,620, base width 600).
"""
import glob, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "iso")
SIZE, BASE_W, AX, AY = 640, 600, 320, 620

def prep(path):
    im = Image.open(path).convert("RGBA")
    a = np.array(im)
    solid = a[..., 3] > 40
    lab, n = ndi.label(solid)
    sizes = ndi.sum(solid, lab, range(1, n + 1))
    big = int(sizes.argmax()) + 1
    for i, sz in enumerate(sizes):
        if i + 1 != big and sz < 0.01 * sizes[big - 1]:
            a[lab == i + 1] = 0
    m = lab == big
    cols = np.where(m.any(0))[0]
    bot = np.array([np.where(m[:, x])[0].max() for x in cols])
    w = cols.max() - cols.min() + 1
    # bottom corner = where the two lower edges of the base meet (robust to rounded or clipped tips)
    L = (cols > cols.min() + 0.08 * w) & (cols < cols.min() + 0.35 * w)
    R = (cols < cols.max() - 0.08 * w) & (cols > cols.max() - 0.35 * w)
    a1, b1 = np.polyfit(cols[L], bot[L], 1)
    a2, b2 = np.polyfit(cols[R], bot[R], 1)
    xb = (b2 - b1) / (a1 - a2)
    yb = a1 * xb + b1
    top = int(np.where(m.any(1))[0].min())
    k = min(BASE_W / w, (AY - 8) / (yb - top + 1))
    im = Image.fromarray(a)
    nw, nh = round(im.width * k), round(im.height * k)
    im = im.resize((nw, nh), Image.LANCZOS)
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.alpha_composite(im, (0, 0)) if False else out.paste(im, (round(AX - xb * k), round(AY - yb * k)), im)
    name = os.path.splitext(os.path.basename(path))[0]
    out.save(os.path.join(OUT, name + ".png"), optimize=True)
    return name, round(k, 3)

os.makedirs(OUT, exist_ok=True)
for d in sys.argv[1:]:
    for f in sorted(glob.glob(os.path.join(d, "**", "*.png"), recursive=True)):
        print(*prep(f))
