# Builds store key art and capsules from the game's own sprites and fonts. Run: python3 tools/make_keyart.py
import re, os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'store')
atlas = Image.open(os.path.join(ROOT, 'assets/art/sprites_hd.png')).convert('RGBA')
src = open(os.path.join(ROOT, 'scripts/ArtHD.gd')).read()
FR = {m[0]: tuple(map(int, m[1:])) for m in re.findall(r'"([a-z0-9_]+)": \[(\d+), (\d+), (\d+), (\d+), (\d+), (\d+)\]', src)}
SERIF = os.path.join(ROOT, 'assets/fonts/DejaVuSerif-Bold.ttf')
SANS = os.path.join(ROOT, 'assets/fonts/DejaVuSans.ttf')

def sprite(name, height, tint=None):
    x, y, w, h, sw, sh = FR[name]
    im = atlas.crop((x, y, x + w, y + h))
    s = height / float(h)
    im = im.resize((max(1, int(w * s)), max(1, int(h * s))), Image.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=max(1.5, h * s / 120.0), percent=170, threshold=2))
    if tint:
        a = np.asarray(im).astype(np.float32)
        a[:, :, 0] *= tint[0]; a[:, :, 1] *= tint[1]; a[:, :, 2] *= tint[2]
        im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')
    return im

def glow(size, center, radius, color, alpha=0.5):
    w, h = size
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt((xx - center[0]) ** 2 + (yy - center[1]) ** 2) / radius
    a = np.clip(1 - d, 0, 1) ** 2 * alpha
    arr = np.zeros((h, w, 4), dtype=np.uint8)
    arr[:, :, 0] = color[0]; arr[:, :, 1] = color[1]; arr[:, :, 2] = color[2]
    arr[:, :, 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(arr, 'RGBA')

def background(w, h):
    yy = np.linspace(0, 1, h)[:, None]
    top = np.array([18, 12, 34]); bot = np.array([6, 4, 14])
    arr = (top * (1 - yy) + bot * yy)[:, None, :].repeat(w, axis=1)
    arr = np.concatenate([arr, np.full((h, w, 1), 255)], axis=2).astype(np.uint8)
    im = Image.fromarray(arr, 'RGBA')
    im.alpha_composite(glow((w, h), (w * 0.5, h * 0.62), h * 0.95, (230, 170, 70), 0.42))
    im.alpha_composite(glow((w, h), (w * 0.2, h * 0.3), h * 0.6, (120, 80, 200), 0.25))
    im.alpha_composite(glow((w, h), (w * 0.82, h * 0.34), h * 0.6, (60, 140, 200), 0.22))
    # floor haze
    rng = np.random.RandomState(3)
    d = ImageDraw.Draw(im)
    for _ in range(int(w * h / 9000)):
        x = rng.randint(0, w); y = rng.randint(0, h)
        r = rng.randint(1, max(2, h // 300))
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 220, 150, rng.randint(30, 120)))
    return im

def title(im, text, cx, cy, size, tagline=None):
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(SERIF, size)
    tw = d.textlength(text, font=f)
    # shadow + glow
    sh = Image.new('RGBA', im.size, (0, 0, 0, 0))
    ds = ImageDraw.Draw(sh)
    ds.text((cx - tw / 2, cy), text, font=f, fill=(255, 190, 70, 255))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(size * 0.10)))
    d.text((cx - tw / 2 + size * 0.03, cy + size * 0.04), text, font=f, fill=(20, 10, 30, 255))
    d.text((cx - tw / 2, cy), text, font=f, fill=(247, 205, 90, 255))
    if tagline:
        f2 = ImageFont.truetype(SANS, int(size * 0.2))
        tw2 = d.textlength(tagline, font=f2)
        d.text((cx - tw2 / 2, cy + size * 1.18), tagline, font=f2, fill=(235, 230, 245, 235))

def vignette(im, strength=0.6):
    w, h = im.size
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2)
    a = np.clip((d - 0.55) / 0.9, 0, 1) ** 1.6 * strength
    arr = np.zeros((h, w, 4), dtype=np.uint8)
    arr[:, :, 3] = (a * 255).astype(np.uint8)
    arr[:, :, 0] = 2; arr[:, :, 2] = 8
    im.alpha_composite(Image.fromarray(arr, 'RGBA'))

def paste_center_bottom(im, spr, cx, bottom):
    im.alpha_composite(spr, (int(cx - spr.width / 2), int(bottom - spr.height)))

def silhouette(im, name, height, cx, bottom, alpha, tint):
    spr = sprite(name, height, tint)
    a = np.asarray(spr).astype(np.float32)
    a[:, :, 3] *= alpha
    spr = Image.fromarray(a.astype(np.uint8), 'RGBA').filter(ImageFilter.GaussianBlur(max(1, height / 90)))
    im.alpha_composite(spr, (int(cx - spr.width / 2), int(bottom - spr.height)))

def key_art(w, h, tag=True, hero=0.5, ttl=0.17, ty=0.07):
    im = background(w, h)
    floor = int(h * 0.93)
    # huge faded gods looming behind the hero
    silhouette(im, 'big_demon_idle_anim_f0', h * 1.05, w * 0.5, h * 1.02, 0.22, (0.5, 0.3, 0.6))
    silhouette(im, 'ogre_idle_anim_f0', h * 0.9, w * 0.14, h * 0.98, 0.18, (0.4, 0.5, 0.8))
    silhouette(im, 'necromancer_idle_anim_f0', h * 0.85, w * 0.88, h * 0.98, 0.18, (0.6, 0.4, 0.8))
    cast = [('big_demon_idle_anim_f0', 0.34, 0.80, (1, 0.9, 0.7)), ('ogre_idle_anim_f0', 0.30, 0.20, (0.8, 0.95, 1.2)),
            ('necromancer_idle_anim_f0', 0.27, 0.68, (0.8, 0.7, 1.1)), ('chort_idle_anim_f0', 0.24, 0.32, None),
            ('skeleton_idle_anim_f0', 0.20, 0.90, (1, 0.9, 0.8)), ('imp_idle_anim_f0', 0.16, 0.08, None)]
    for name, rel, px, tint in cast:
        spr = sprite(name, h * rel, tint)
        paste_center_bottom(im, spr, w * px, floor - h * 0.02 * (px % 0.3))
    hero_spr = sprite('knight_m_idle_anim_f0', h * hero)
    # lantern glow on the hero
    im.alpha_composite(glow((w, h), (w * 0.5, floor - h * hero * 0.5), h * 0.55, (255, 205, 110), 0.55))
    paste_center_bottom(im, hero_spr, w * 0.5, floor)
    sw = sprite('weapon_knight_sword', h * hero * 0.55).rotate(-25, expand=True, resample=Image.BICUBIC)
    im.alpha_composite(sw, (int(w * 0.5 + hero_spr.width * 0.1), int(floor - h * hero * 0.85)))
    title(im, 'HOLLOWGOD', w / 2, h * ty, int(h * ttl), 'Descend. Choose. Become what the gods feared.' if tag else None)
    vignette(im)
    return im

def save(im, name, flatten=True):
    p = os.path.join(OUT, name)
    (im.convert('RGB') if flatten else im).save(p, optimize=True)
    print(name, im.size)

os.makedirs(OUT, exist_ok=True)
save(key_art(3840, 1240, True, 0.52, 0.2, 0.06), 'steam_library_hero_3840x1240.png')
save(key_art(1920, 1080, True, 0.5, 0.17, 0.07), 'key_art_1920x1080.png')
save(key_art(460, 215, False, 0.5, 0.2, 0.06), 'steam_header_460x215.png')
save(key_art(616, 353, False, 0.5, 0.17, 0.05), 'steam_main_capsule_616x353.png')
save(key_art(231, 87, False, 0.55, 0.3, 0.05), 'steam_small_capsule_231x87.png')
save(key_art(374, 448, False, 0.42, 0.13, 0.05), 'steam_vertical_capsule_374x448.png')
save(key_art(600, 900, False, 0.40, 0.11, 0.07), 'steam_library_capsule_600x900.png')
save(key_art(630, 500, True, 0.5, 0.15, 0.05), 'itch_cover_630x500.png')
save(key_art(1200, 630, True, 0.5, 0.17, 0.06), 'social_share_1200x630.png')
# transparent logo
logo = Image.new('RGBA', (1280, 720), (0, 0, 0, 0))
title(logo, 'HOLLOWGOD', 640, 250, 150, 'Descend. Choose. Become what the gods feared.')
save(logo, 'steam_logo_1280x720_transparent.png', flatten=False)
