"""Tile screenshots into one contact sheet: python3 dev/sheet.py out.png [files...] (default: /tmp/shots/*.png)."""
import glob
import sys

from PIL import Image

out = sys.argv[1]
files = sys.argv[2:] or sorted(glob.glob("/tmp/shots/*.png"))
ims = [Image.open(f).convert("RGB") for f in files]
cols = 1 if len(ims) <= 2 else 2
w, h = ims[0].size
scale = 1.0 if cols == 1 else 0.75
tw, th = int(w * scale), int(h * scale)
rows = (len(ims) + cols - 1) // cols
sheet = Image.new("RGB", (tw * cols, th * rows), "black")
for i, im in enumerate(ims):
    sheet.paste(im.resize((tw, th), Image.LANCZOS), ((i % cols) * tw, (i // cols) * th))
sheet.save(out)
print(out, sheet.size)
