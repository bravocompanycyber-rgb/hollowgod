extends Node
# Game-feel helper: screen shake, hit-stop, particles, damage numbers, light textures.

var shake_amount = 0.0
var hitstop_until = 0
var camera = null
var world = null
var _light_tex = null
var _vignette_tex = null

func shake(amount):
    shake_amount = max(shake_amount, amount)

func hitstop(milliseconds):
    Engine.time_scale = 0.05
    hitstop_until = OS.get_ticks_msec() + milliseconds

func reset():
    Engine.time_scale = 1.0
    shake_amount = 0.0

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

# Little burst of sparks at a position.
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

# Floating number or word that rises and fades.
func popup(pos, text, color):
    if world == null or not is_instance_valid(world):
        return
    var l = Label.new()
    l.text = str(text)
    l.rect_scale = Vector2(1.4, 1.4)
    l.rect_position = pos + Vector2(-8, -26)
    l.add_color_override("font_color", color)
    l.add_color_override("font_color_shadow", Color(0, 0, 0, 0.9))
    l.add_constant_override("shadow_offset_x", 1)
    l.add_constant_override("shadow_offset_y", 1)
    world.add_child(l)
    var tw = Tween.new()
    l.add_child(tw)
    tw.interpolate_property(l, "rect_position", l.rect_position, l.rect_position + Vector2(rand_range(-12, 12), -36), 0.7, Tween.TRANS_QUAD, Tween.EASE_OUT)
    tw.interpolate_property(l, "modulate:a", 1.0, 0.0, 0.35, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.35)
    tw.connect("tween_all_completed", l, "queue_free")
    tw.start()

# A soft round glow image, made in code (no art file needed).
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

# Dark edges of the screen (vignette), made in code.
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
