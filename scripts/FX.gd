extends Node
# Game-feel and UI helper: screen shake, hit-stop, particles, damage numbers, fonts, textures.

var shake_amount = 0.0
var hitstop_until = 0
var camera = null
var world = null
var _light_tex = null
var _vignette_tex = null
var _fonts = {}

func shake(amount):
    shake_amount = max(shake_amount, amount)

func hitstop(milliseconds):
    Engine.time_scale = 0.05
    hitstop_until = OS.get_ticks_msec() + milliseconds

func reset():
    Engine.time_scale = 1.0
    shake_amount = 0.0
    camera = null
    world = null

func _process(delta):
    if Engine.time_scale < 1.0 and OS.get_ticks_msec() >= hitstop_until:
        Engine.time_scale = 1.0
    var real_delta = delta / max(Engine.time_scale, 0.01)
    if camera != null and is_instance_valid(camera):
        if shake_amount > 0.1:
            camera.offset = Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0)) * shake_amount
            shake_amount = lerp(shake_amount, 0.0, clamp(12.0 * real_delta, 0.0, 1.0))
        else:
            shake_amount = 0.0
            camera.offset = Vector2.ZERO

# ----- fonts and labels -----

func font(size, serif = false):
    var key = str(size) + ("s" if serif else "n")
    if _fonts.has(key):
        return _fonts[key]
    var path = "res://assets/fonts/" + ("DejaVuSerif-Bold.ttf" if serif else "DejaVuSans.ttf")
    var f = null
    var d = null
    if ResourceLoader.exists(path):
        d = load(path)
    if d == null:
        var file = File.new()
        if file.file_exists(path):
            d = DynamicFontData.new()
            d.font_path = path
    if d != null:
        f = DynamicFont.new()
        f.font_data = d
        f.size = size
        f.use_filter = true
    _fonts[key] = f
    return f

func style(l, size, color = Color(1, 1, 1), serif = false):
    var f = font(size, serif)
    if f != null:
        l.add_font_override("font", f)
    l.add_color_override("font_color", color)
    l.add_color_override("font_color_shadow", Color(0, 0, 0, 0.85))
    l.add_constant_override("shadow_offset_x", 1)
    l.add_constant_override("shadow_offset_y", 1)
    return l

func label(parent, pos, text, size = 16, color = Color(1, 1, 1), serif = false):
    var l = Label.new()
    l.rect_position = pos
    l.text = text
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    style(l, size, color, serif)
    if parent != null:
        parent.add_child(l)
    return l

func card_style(bg, border, width = 2):
    var sb = StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = border
    sb.set_border_width_all(width)
    sb.set_corner_radius_all(5)
    return sb

# ----- effects -----

func burst(pos, color, amount, speed):
    if world == null or not is_instance_valid(world):
        return
    var p = CPUParticles2D.new()
    p.position = pos
    p.emitting = true
    p.one_shot = true
    p.explosiveness = 1.0
    p.amount = amount
    p.lifetime = 0.55
    p.spread = 180.0
    p.gravity = Vector2.ZERO
    p.initial_velocity = speed
    p.initial_velocity_random = 0.6
    p.scale_amount = 4.0
    p.scale_amount_random = 0.5
    p.color = color
    world.add_child(p)
    var t = Timer.new()
    t.wait_time = 1.2
    t.one_shot = true
    t.autostart = true
    p.add_child(t)
    t.connect("timeout", p, "queue_free")

func popup(pos, text, color, size = 18):
    if world == null or not is_instance_valid(world):
        return
    var l = Label.new()
    l.text = str(text)
    l.rect_position = pos + Vector2(-14, -28)
    style(l, size, color, true)
    world.add_child(l)
    var tw = Tween.new()
    l.add_child(tw)
    tw.interpolate_property(l, "rect_position", l.rect_position, l.rect_position + Vector2(rand_range(-12, 12), -38), 0.75, Tween.TRANS_QUAD, Tween.EASE_OUT)
    tw.interpolate_property(l, "modulate:a", 1.0, 0.0, 0.35, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.4)
    tw.connect("tween_all_completed", l, "queue_free")
    tw.start()

func light_texture():
    if _light_tex != null:
        return _light_tex
    var size = 128
    var img = Image.new()
    img.create(size, size, false, Image.FORMAT_RGBA8)
    img.lock()
    var c = (size - 1) / 2.0
    for y in range(size):
        for x in range(size):
            var d = Vector2(x - c, y - c).length() / c
            var a = clamp(1.0 - d, 0.0, 1.0)
            a = a * a
            img.set_pixel(x, y, Color(a, a, a, 1.0))
    img.unlock()
    var tex = ImageTexture.new()
    tex.create_from_image(img)
    _light_tex = tex
    return tex

func vignette_texture():
    if _vignette_tex != null:
        return _vignette_tex
    var size = 128
    var img = Image.new()
    img.create(size, size, false, Image.FORMAT_RGBA8)
    img.lock()
    var c = (size - 1) / 2.0
    for y in range(size):
        for x in range(size):
            var d = Vector2(x - c, y - c).length() / c
            var a = clamp((d - 0.55) / 0.85, 0.0, 1.0)
            a = a * a * 0.85
            img.set_pixel(x, y, Color(0.02, 0.0, 0.05, a))
    img.unlock()
    var tex = ImageTexture.new()
    tex.create_from_image(img)
    _vignette_tex = tex
    return tex

func add_vignette(layer):
    var vig = TextureRect.new()
    vig.texture = vignette_texture()
    vig.expand = true
    vig.stretch_mode = TextureRect.STRETCH_SCALE
    vig.rect_size = Vector2(1280, 720)
    vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(vig)
