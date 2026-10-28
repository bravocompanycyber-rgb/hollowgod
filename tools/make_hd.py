import json, re, math
import numpy as np
from PIL import Image, ImageFilter

SRC = '/home/claude/hollowgod/assets/art/dungeon_tileset.png'
FR = '/home/claude/hollowgod/scripts/ArtFrames.gd'
text = open(FR).read()
frames = {k: tuple(map(int, v)) for k, v in re.findall(r'"([a-z0-9_]+)": \[(\d+), (\d+), (\d+), (\d+)\]', text) and
          [(m[0], m[1:]) for m in re.findall(r'"([a-z0-9_]+)": \[(\d+), (\d+), (\d+), (\d+)\]', text)]}
atlas = Image.open(SRC).convert('RGBA')

BASES = ['knight_m', 'elf_f', 'wizard_f', 'orc_warrior', 'necromancer', 'big_demon', 'ogre', 'big_zombie', 'zombie',
         'tiny_zombie', 'skeleton', 'goblin', 'ice_zombie', 'chort', 'imp', 'wogol', 'masked_orc', 'orc_shaman']
EXTRA = ['skull', 'weapon_knight_sword', 'weapon_axe', 'weapon_hammer', 'flask_big_blue', 'flask_big_green', 'chest_full_open_anim_f0']
names = []
for k in frames:
    for b in BASES:
        if re.match(r'^%s_(idle|run|hit)_anim_f\d+$' % b, k):
            names.append(k)
for k in EXTRA:
    if k in frames:
        names.append(k)
names = sorted(set(names))
print(len(names), 'frames')

K = 4          # upscale factor
P = 3          # source-pixel padding (room for outline)

def epx(a):
    # Scale2x / EPX on an (H, W, 4) uint8 array
    H, W, _ = a.shape
    pad = np.pad(a, ((1, 1), (1, 1), (0, 0)), mode='edge')
    P_ = a
    A = pad[0:H, 1:W + 1]      # up
    B = pad[1:H + 1, 2:W + 2]  # right
    C = pad[1:H + 1, 0:W]      # left
    D = pad[2:H + 2, 1:W + 1]  # down
    def eq(x, y):
        return np.all(x == y, axis=2)
    out = np.zeros((H * 2, W * 2, 4), dtype=np.uint8)
    e1 = eq(C, A) & ~eq(C, D) & ~eq(A, B)
    e2 = eq(A, B) & ~eq(A, C) & ~eq(B, D)
    e3 = eq(D, C) & ~eq(D, B) & ~eq(C, A)
    e4 = eq(B, D) & ~eq(B, A) & ~eq(D, C)
    out[0::2, 0::2] = np.where(e1[..., None], A, P_)
    out[0::2, 1::2] = np.where(e2[..., None], B, P_)
    out[1::2, 0::2] = np.where(e3[..., None], C, P_)
    out[1::2, 1::2] = np.where(e4[..., None], D, P_)
    return out

def gauss(m, r):
    return np.asarray(Image.fromarray(np.clip(m * 255, 0, 255).astype(np.uint8), 'L').filter(ImageFilter.GaussianBlur(r))).astype(np.float32) / 255.0

def process(img):
    w, h = img.size
    canvas = Image.new('RGBA', (w + 2 * P, h + 2 * P), (0, 0, 0, 0))
    canvas.paste(img, (P, P))
    a = np.asarray(canvas)
    a = epx(epx(a))                                   # 4x with smoothed diagonals
    f = a.astype(np.float32) / 255.0
    alpha = f[:, :, 3]
    # premultiplied blur to round the stair steps
    pm = f[:, :, :3] * alpha[..., None]
    pmb = np.stack([gauss(pm[:, :, c], 1.0) for c in range(3)], axis=2)
    ab = gauss(alpha, 1.0)
    rgb = pmb / np.maximum(ab[..., None], 1e-4)
    # clean antialiased silhouette
    a2 = gauss(alpha, 1.4)
    a2 = np.clip((a2 - 0.38) / 0.28, 0, 1)
    a2 = a2 * a2 * (3 - 2 * a2)
    # baked soft volume: rounded height from the silhouette, light from the upper left
    hgt = gauss(a2, 5.0) * 9.0
    gy, gx = np.gradient(hgt)
    nz = np.ones_like(hgt)
    ln = np.sqrt(gx * gx + gy * gy + nz * nz)
    nx, ny, nz = -gx / ln, -gy / ln, nz / ln
    L = np.array([-0.45, -0.55, 0.70]); L /= np.linalg.norm(L)
    lam = nx * L[0] + ny * L[1] + nz * L[2]
    shade = 0.86 + 0.34 * lam
    # slightly darker toward the feet, lighter at the top
    yy = np.linspace(1.07, 0.88, a2.shape[0])[:, None]
    rgb = np.clip(rgb * shade[..., None] * yy[..., None], 0, 1)
    # dark outline from a dilated silhouette
    sil = Image.fromarray((a2 * 255).astype(np.uint8), 'L')
    dil = np.asarray(sil.filter(ImageFilter.MaxFilter(7))).astype(np.float32) / 255.0
    dil = gauss(dil, 1.0)
    ring = np.clip(dil - a2, 0, 1)
    ring = np.clip(ring * 1.6, 0, 1)
    out_rgb = rgb * a2[..., None] + np.array([0.05, 0.03, 0.09])[None, None, :] * ring[..., None]
    out_a = np.clip(a2 + ring * (1 - a2), 0, 1)
    out_rgb = out_rgb / np.maximum(out_a[..., None], 1e-4)
    out = np.dstack([np.clip(out_rgb, 0, 1), out_a])
    # normal map for relief lighting
    hh = gauss(out_a, 4.0) * 8.0 + gauss((0.3 * rgb[:, :, 0] + 0.59 * rgb[:, :, 1] + 0.11 * rgb[:, :, 2]) * out_a, 1.2) * 1.5
    gy2, gx2 = np.gradient(hh)
    n3 = np.ones_like(hh)
    l2 = np.sqrt(gx2 * gx2 + gy2 * gy2 + n3 * n3)
    nmap = np.dstack([(-gx2 / l2) * 0.5 + 0.5, (gy2 / l2) * 0.5 + 0.5, (n3 / l2) * 0.5 + 0.5, np.ones_like(hh)])
    return (out * 255).astype(np.uint8), (nmap * 255).astype(np.uint8)

tiles = []
for n in names:
    x, y, w, h = frames[n]
    img = atlas.crop((x, y, x + w, y + h))
    color, nm = process(img)
    tiles.append((n, color, nm, w, h))

# shelf pack into a 2048 wide atlas
W = 2048
x = y = 0
rowh = 0
placed = {}
for n, color, nm, w, h in sorted(tiles, key=lambda t: -t[1].shape[0]):
    th, tw = color.shape[:2]
    if x + tw > W:
        x = 0
        y += rowh
        rowh = 0
    placed[n] = (x, y, tw, th, w, h)
    x += tw
    rowh = max(rowh, th)
H = y + rowh
H2 = 1
while H2 < H:
    H2 *= 2
print('atlas', W, H2)
ca = np.zeros((H2, W, 4), dtype=np.uint8)
na = np.zeros((H2, W, 4), dtype=np.uint8)
na[:, :, 0] = 128; na[:, :, 1] = 128; na[:, :, 2] = 255; na[:, :, 3] = 255
for n, color, nm, w, h in tiles:
    px, py, tw, th, _, _ = placed[n]
    ca[py:py + th, px:px + tw] = color
    na[py:py + th, px:px + tw] = nm
Image.fromarray(ca, 'RGBA').save('/home/claude/hollowgod/assets/art/sprites_hd.png', optimize=True)
Image.fromarray(na, 'RGBA').save('/home/claude/hollowgod/assets/art/sprites_hd_n.png', optimize=True)
lines = ['extends Reference', '# HD sprite frames: name -> [x, y, w, h, source_w, source_h] in the HD atlas (assets/art/sprites_hd.png).',
         '# Built from DungeonTileset II (CC0) by tools/make_hd.py: smoothed, outlined and shaded.', '', 'const K = %d' % K, 'const PAD = %d' % P, 'const FRAMES = {']
items = sorted(placed.items())
for i, (n, v) in enumerate(items):
    lines.append('    "%s": [%d, %d, %d, %d, %d, %d]%s' % (n, v[0], v[1], v[2], v[3], v[4], v[5], ',' if i < len(items) - 1 else ''))
lines.append('}')
open('/home/claude/hollowgod/scripts/ArtHD.gd', 'w').write('\n'.join(lines) + '\n')
print('done', len(placed))
