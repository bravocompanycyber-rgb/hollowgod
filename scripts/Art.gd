extends Node
# Sprite loader for the CC0 "DungeonTileset II" atlas by 0x72 (see assets/art/CREDITS.md).
# Draws named frames from one packed picture. Pixel art is drawn with no smoothing.

const ATLAS = "res://assets/art/dungeon_tileset.png"
const FramesData = preload("res://scripts/ArtFrames.gd")
const SCALE = 3.0
const TILE = 48.0

var tex = null
var frames = {}
var counts = {}

func _ready():
    # Prefer the imported texture (works in exported games and has no warnings).
    # Before Godot has imported the picture, fall back to loading the raw file.
    var img = null
    if ResourceLoader.exists(ATLAS):
        var res = load(ATLAS)
        if res is Texture:
            img = res.get_data()
    if img == null:
        var raw = Image.new()
        if raw.load(ATLAS) == OK:
            img = raw
    if img != null:
        var t = ImageTexture.new()
        t.create_from_image(img, 0)   # flags 0 = no smoothing, crisp pixels
        tex = t
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
func draw(ci, name, pos, scale = 3.0, flip = false, mod = Color(1, 1, 1), anchor = "bottom"):
    if tex == null or not frames.has(name):
        return false
    var r = frames[name]
    var w = r.size.x * scale
    var h = r.size.y * scale
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
    ci.draw_texture_rect_region(tex, Rect2(x, y, w, h), src, mod)
    return true

# Draw one tile (16x16 frame) filling a rectangle.
func tile(ci, name, rect, mod = Color(1, 1, 1)):
    if tex == null or not frames.has(name):
        return
    ci.draw_texture_rect_region(tex, rect, frames[name], mod)

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
