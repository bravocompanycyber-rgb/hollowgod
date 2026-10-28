extends Node
# Sprite loader for the CC0 "DungeonTileset II" atlas by 0x72 (see assets/art/CREDITS.md).
# Draws named frames from one packed picture. Pixel art is drawn with no smoothing.

const ATLAS = "res://assets/art/dungeon_tileset.png"
const ATLAS_N = "res://assets/art/dungeon_tileset_n.png"
const FramesData = preload("res://scripts/ArtFrames.gd")
const HdData = preload("res://scripts/ArtHD.gd")
const ATLAS_HD = "res://assets/art/sprites_hd.png"
const ATLAS_HD_N = "res://assets/art/sprites_hd_n.png"
const SCALE = 3.0
const TILE = 48.0

var tex = null          # crisp (no smoothing): tiles
var tex_smooth = null   # smoothed: characters (used with the smoothing shader)
var tex_n = null        # normal map for 3D relief lighting
var materials = {}
var use_normals = true
var tex_hd = null
var tex_hd_n = null
var hd = {}
var hd_ready = false
var frames = {}
var counts = {}

func _load_image(path):
    # Prefer the imported texture (works in exported games); fall back to the raw file before import.
    if ResourceLoader.exists(path):
        var res = load(path)
        if res is Texture:
            return res.get_data()
    var raw = Image.new()
    if raw.load(path) == OK:
        return raw
    return null

func _ready():
    var img = _load_image(ATLAS)
    if img != null:
        var t = ImageTexture.new()
        t.create_from_image(img, 0)
        tex = t
        var ts = ImageTexture.new()
        ts.create_from_image(img, Texture.FLAG_FILTER)
        tex_smooth = ts
    var nimg = _load_image(ATLAS_N)
    if nimg != null:
        var tn = ImageTexture.new()
        tn.create_from_image(nimg, 0)
        tex_n = tn
    var himg = _load_image(ATLAS_HD)
    if himg != null:
        var th = ImageTexture.new()
        th.create_from_image(himg, Texture.FLAG_FILTER)
        tex_hd = th
        var hn = _load_image(ATLAS_HD_N)
        if hn != null:
            var thn = ImageTexture.new()
            thn.create_from_image(hn, Texture.FLAG_FILTER)
            tex_hd_n = thn
        for k in HdData.FRAMES.keys():
            hd[k] = HdData.FRAMES[k]
        hd_ready = hd.size() > 0
    var data = FramesData.FRAMES
    for k in data.keys():
        var a = data[k]
        frames[k] = Rect2(a[0], a[1], a[2], a[3])
        var p = k.rfind("_f")
        if p > 0 and k.substr(p + 2).is_valid_integer():
            var base = k.substr(0, p)
            var n = int(k.substr(p + 2)) + 1
            if not counts.has(base) or counts[base] < n:
                counts[base] = n

# A shader that smooths the jagged edges of pixel art while keeping the colours crisp.
# s = how many screen pixels one art pixel covers (the draw scale).
func material_for(s):
    var key = int(round(s * 10.0))
    if materials.has(key):
        return materials[key]
    var sh = Shader.new()
    sh.code = """shader_type canvas_item;
uniform float s = 3.0;
varying vec4 vcol;
void vertex() {
    vcol = COLOR;
}
void fragment() {
    vec2 p = UV / TEXTURE_PIXEL_SIZE;
    vec2 seam = floor(p + 0.5);
    p = seam + clamp((p - seam) * s, -0.5, 0.5);
    COLOR = texture(TEXTURE, p * TEXTURE_PIXEL_SIZE) * vcol;
}"""
    var m = ShaderMaterial.new()
    m.shader = sh
    m.set_shader_param("s", s)
    materials[key] = m
    return m

# Material for sprite nodes: the HD sprites need none; the old pixel path uses the smoothing shader.
func sprite_material(s):
    if hd_ready:
        return null
    return material_for(s)

# Draw a sprite rotated around a point (its bottom-centre sits at pos). Used for the sword.
func draw_at(ci, name, pos, rot, scale = 3.0, mod = Color(1, 1, 1)):
    ci.draw_set_transform(pos, rot, Vector2(1, 1))
    var ok = draw(ci, name, Vector2.ZERO, scale, false, mod, "bottom")
    ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 1))
    return ok

func ready_ok():
    return tex != null and frames.size() > 0

# Name of the animation frame to show at time t.
func frame_name(base, t, fps = 8.0):
    var n = counts.get(base, 0)
    if n <= 0:
        return base
    return "%s_f%d" % [base, int(t * fps) % n]

func size_of(name):
    if frames.has(name):
        return frames[name].size
    return Vector2.ZERO

# Draw a frame with its bottom-centre at pos (anchor "bottom") or its centre at pos (anchor "center").
func draw(ci, name, pos, scale = 3.0, flip = false, mod = Color(1, 1, 1), anchor = "bottom", stretch = Vector2(1, 1), crisp = false):
    if hd_ready and not crisp and hd.has(name):
        var e = hd[name]
        var sw = float(e[4])
        var sh = float(e[5])
        var bw = sw * scale * stretch.x
        var bh = sh * scale * stretch.y
        var bx = pos.x - bw / 2.0
        var by = pos.y - bh
        if anchor == "center":
            by = pos.y - bh / 2.0
        elif anchor == "topleft":
            bx = pos.x
            by = pos.y
        var pw = HdData.PAD * scale * stretch.x
        var ph = HdData.PAD * scale * stretch.y
        var hsrc = Rect2(e[0], e[1], e[2], e[3])
        if flip:
            hsrc = Rect2(e[0] + e[2], e[1], -e[2], e[3])
        ci.draw_texture_rect_region(tex_hd, Rect2(bx - pw, by - ph, bw + 2.0 * pw, bh + 2.0 * ph), hsrc, mod, false, tex_hd_n if use_normals else null)
        return true
    if tex == null or not frames.has(name):
        return false
    if hd_ready:
        crisp = true
    var r = frames[name]
    var w = r.size.x * scale * stretch.x
    var h = r.size.y * scale * stretch.y
    var x = pos.x - w / 2.0
    var y = pos.y - h
    if anchor == "center":
        y = pos.y - h / 2.0
    elif anchor == "topleft":
        x = pos.x
        y = pos.y
    var src = r
    if flip:
        src = Rect2(r.position.x + r.size.x, r.position.y, -r.size.x, r.size.y)
    var t = tex if (crisp or tex_smooth == null) else tex_smooth
    ci.draw_texture_rect_region(t, Rect2(x, y, w, h), src, mod, false, tex_n if use_normals else null)
    return true

# Draw one tile (16x16 frame) filling a rectangle.
func tile(ci, name, rect, mod = Color(1, 1, 1)):
    if tex == null or not frames.has(name):
        return
    ci.draw_texture_rect_region(tex, rect, frames[name], mod, false, tex_n if use_normals else null)

func atlas_texture(name):
    if tex == null or not frames.has(name):
        return null
    var at = AtlasTexture.new()
    at.atlas = tex
    at.region = frames[name]
    return at

# Soft oval shadow under a character.
func shadow(ci, pos, radius):
    ci.draw_set_transform(pos, 0.0, Vector2(1.0, 0.4))
    ci.draw_circle(Vector2.ZERO, radius, Color(0, 0, 0, 0.38))
    ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
