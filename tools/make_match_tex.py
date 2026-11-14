# Builds the textures the 3D match view uses: the pitch (grass, mown stripes, markings), a crowd strip and a goal net.
#   python3 tools/make_match_tex.py     (needs tools/grass_src.jpg)
import random, math
from PIL import Image, ImageDraw, ImageEnhance
L, W, M = 105.0, 68.0, 7.0            # pitch metres and the grass margin around it
PX = 18                               # pixels per metre
tw, th = int((L + 2 * M) * PX), int((W + 2 * M) * PX)
g = Image.open("tools/grass_src.jpg").convert("RGB")
g = ImageEnhance.Color(g).enhance(0.9)
tex = Image.new("RGB", (tw, th))
for x in range(0, tw, g.size[0]):
    for y in range(0, th, g.size[1]):
        tex.paste(g, (x, y))
# even out and set the base green
tex = Image.blend(tex, Image.new("RGB", (tw, th), (58, 122, 52)), 0.55)
d = ImageDraw.Draw(tex, "RGBA")
def X(m): return int((m + M) * PX)
def Y(m): return int((m + M) * PX)
n = 14
for i in range(n):
    if i % 2 == 0:
        d.rectangle([X(L * i / n), Y(0), X(L * (i + 1) / n), Y(W)], fill=(0, 0, 0, 34))
    else:
        d.rectangle([X(L * i / n), Y(0), X(L * (i + 1) / n), Y(W)], fill=(255, 255, 255, 14))
wl = (245, 248, 245, 235)
lw = 3
def rect(x0, y0, x1, y1): d.rectangle([X(x0), Y(y0), X(x1), Y(y1)], outline=wl, width=lw)
rect(0, 0, L, W)
d.line([X(L / 2), Y(0), X(L / 2), Y(W)], fill=wl, width=lw)
r = 9.15
d.ellipse([X(L / 2 - r), Y(W / 2 - r), X(L / 2 + r), Y(W / 2 + r)], outline=wl, width=lw)
d.ellipse([X(L / 2) - 5, Y(W / 2) - 5, X(L / 2) + 5, Y(W / 2) + 5], fill=wl)
for s in (0, 1):
    gx = 0 if s == 0 else L
    sg = 1 if s == 0 else -1
    rect(min(gx, gx + sg * 16.5), W / 2 - 20.16, max(gx, gx + sg * 16.5), W / 2 + 20.16)
    rect(min(gx, gx + sg * 5.5), W / 2 - 9.16, max(gx, gx + sg * 5.5), W / 2 + 9.16)
    px = gx + sg * 11
    d.ellipse([X(px) - 4, Y(W / 2) - 4, X(px) + 4, Y(W / 2) + 4], fill=wl)
    a0 = math.degrees(math.acos(5.5 / r))
    if s == 0:
        d.arc([X(px - r), Y(W / 2 - r), X(px + r), Y(W / 2 + r)], -a0, a0, fill=wl, width=lw)
    else:
        d.arc([X(px - r), Y(W / 2 - r), X(px + r), Y(W / 2 + r)], 180 - a0, 180 + a0, fill=wl, width=lw)
for cx, cy, a in ((0, 0, 0), (L, 0, 90), (L, W, 180), (0, W, 270)):
    d.arc([X(cx - 1), Y(cy - 1), X(cx + 1), Y(cy + 1)], a, a + 90, fill=wl, width=lw)
tex = tex.resize((2048, int(2048 * th / tw)), Image.LANCZOS)
tex.save("assets/m3d/pitch.jpg", quality=88)
# crowd: rows of small heads and shoulders in mixed colours on dark seats
random.seed(4)
cw, ch = 512, 256
c = Image.new("RGB", (cw, ch), (26, 26, 34))
cd = ImageDraw.Draw(c)
rows = 16
for r_ in range(rows):
    y = int(ch * (r_ + 0.5) / rows)
    cd.rectangle([0, y + 5, cw, y + 7], fill=(40, 40, 52))
    x = random.randint(0, 6)
    while x < cw:
        if random.random() < 0.9:
            shade = random.choice([(205, 205, 210), (60, 60, 70), (150, 40, 40), (40, 70, 140), (220, 190, 60), (90, 90, 100), (230, 230, 235), (120, 60, 30)])
            skin = random.choice([(224, 172, 140), (190, 140, 105), (140, 95, 70), (245, 205, 175)])
            cd.rectangle([x, y - 2, x + 6, y + 5], fill=shade)
            cd.ellipse([x + 1, y - 8, x + 5, y - 3], fill=skin)
        x += random.randint(8, 11)
c.save("assets/m3d/crowd.jpg", quality=85)
# net: a white mesh on transparent
n_ = Image.new("RGBA", (128, 128), (255, 255, 255, 18))
nd = ImageDraw.Draw(n_)
for i in range(0, 128, 12):
    nd.line([i, 0, i, 128], fill=(255, 255, 255, 190), width=1)
    nd.line([0, i, 128, i], fill=(255, 255, 255, 190), width=1)
n_.save("assets/m3d/net.png")
# soft round shadow
s = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
for y in range(64):
    for x in range(64):
        dd = math.hypot(x - 31.5, y - 31.5) / 31.5
        if dd < 1:
            s.putpixel((x, y), (0, 0, 0, int(150 * (1 - dd) ** 1.3)))
s.save("assets/m3d/shadow.png")
print("ok", tex.size)
