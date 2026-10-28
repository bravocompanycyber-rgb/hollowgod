extends Control
# Options: music volume, sound volume, fullscreen. Saved to user://settings.json.

signal closed

var music_slider = null
var sfx_slider = null
var full_button = null
var fx_button = null
var back_button = null

func _init():
    rect_size = Vector2(1280, 720)
    mouse_filter = Control.MOUSE_FILTER_STOP

func _ready():
    var dim = ColorRect.new()
    dim.rect_size = Vector2(1280, 720)
    dim.color = Color(0, 0, 0, 0.82)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(dim)
    var t = FX.label(self, Vector2(0, 120), "OPTIONS", 44, Color(0.95, 0.78, 0.3), true)
    t.rect_size = Vector2(1280, 56)
    t.align = Label.ALIGN_CENTER
    FX.label(self, Vector2(440, 250), "Music volume", 20, Color(0.95, 0.95, 1.0))
    music_slider = _slider(Vector2(440, 285), Game.settings["music"])
    FX.label(self, Vector2(440, 340), "Sound effects volume", 20, Color(0.95, 0.95, 1.0))
    sfx_slider = _slider(Vector2(440, 375), Game.settings["sfx"])
    full_button = _button("", Vector2(440, 430), Vector2(400, 46))
    full_button.connect("pressed", self, "_toggle_full")
    fx_button = _button("", Vector2(440, 490), Vector2(400, 46))
    fx_button.connect("pressed", self, "_toggle_fx")
    back_button = _button("Back", Vector2(440, 565), Vector2(400, 46))
    back_button.connect("pressed", self, "_close")
    _refresh()
    music_slider.connect("value_changed", self, "_music_changed")
    sfx_slider.connect("value_changed", self, "_sfx_changed")
    sfx_slider.connect("drag_ended", self, "_sfx_released")

func _slider(pos, value):
    var s = HSlider.new()
    s.rect_position = pos
    s.rect_size = Vector2(400, 30)
    s.min_value = 0.0
    s.max_value = 1.0
    s.step = 0.05
    s.value = value
    s.focus_mode = Control.FOCUS_ALL
    var track = FX.card_style(Color(0.12, 0.1, 0.16), Color(0.45, 0.36, 0.16), 1)
    track.content_margin_top = 5
    track.content_margin_bottom = 5
    var fill = FX.card_style(Color(0.85, 0.65, 0.2), Color(0.95, 0.8, 0.35), 1)
    fill.content_margin_top = 5
    fill.content_margin_bottom = 5
    s.add_stylebox_override("slider", track)
    s.add_stylebox_override("grabber_area", fill)
    s.add_stylebox_override("grabber_area_highlight", fill)
    add_child(s)
    return s

func _button(text, pos, size):
    var b = Button.new()
    b.text = text
    b.rect_position = pos
    b.rect_size = size
    var f = FX.font(20)
    if f != null:
        b.add_font_override("font", f)
    b.add_color_override("font_color", Color(1, 0.95, 0.85))
    b.add_stylebox_override("normal", FX.card_style(Color(0.08, 0.08, 0.14, 0.97), Color(0.6, 0.48, 0.2)))
    b.add_stylebox_override("hover", FX.card_style(Color(0.18, 0.15, 0.26, 0.98), Color(1.0, 0.85, 0.4)))
    b.add_stylebox_override("focus", FX.card_style(Color(0.18, 0.15, 0.26, 0.98), Color(1.0, 0.85, 0.4), 3))
    b.add_stylebox_override("pressed", FX.card_style(Color(0.24, 0.2, 0.3), Color(1.0, 0.95, 0.6)))
    add_child(b)
    return b

func _refresh():
    full_button.text = "Fullscreen: ON" if Game.settings["fullscreen"] else "Fullscreen: OFF"
    fx_button.text = "Lighting effects: ON" if Game.settings["effects"] else "Lighting effects: OFF (faster)"

func _music_changed(v):
    Game.settings["music"] = v
    Game.apply_settings()

func _sfx_changed(v):
    Game.settings["sfx"] = v
    Game.apply_settings()

func _sfx_released(changed):
    Sfx.play("click")

func _toggle_full():
    Game.settings["fullscreen"] = not Game.settings["fullscreen"]
    Game.apply_settings()
    Sfx.play("click")
    _refresh()

func _toggle_fx():
    Game.settings["effects"] = not Game.settings["effects"]
    Game.apply_settings()
    Sfx.play("click")
    _refresh()

func open():
    visible = true
    music_slider.value = Game.settings["music"]
    sfx_slider.value = Game.settings["sfx"]
    _refresh()
    back_button.grab_focus()

func _close():
    Game.save_settings()
    Sfx.play("back")
    visible = false
    emit_signal("closed")
