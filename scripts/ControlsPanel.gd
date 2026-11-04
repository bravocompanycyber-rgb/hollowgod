extends Control
# Rebind keyboard keys. Click a button, then press the new key (Esc cancels).

signal closed

const ACTIONS = [["move_up", "Move up"], ["move_down", "Move down"], ["move_left", "Move left"], ["move_right", "Move right"],
    ["dash", "Dash"], ["attack", "Attack"], ["interact", "Talk / confirm"]]

var buttons = {}
var waiting = ""
var hint = null

func _init():
    rect_size = Vector2(1280, 720)
    mouse_filter = Control.MOUSE_FILTER_STOP

func _ready():
    var dim = ColorRect.new()
    dim.rect_size = Vector2(1280, 720)
    dim.color = Color(0.02, 0.02, 0.04, 0.99)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(dim)
    var t = FX.label(self, Vector2(0, 70), "KEY BINDINGS", 40, Color(0.95, 0.78, 0.3), true)
    t.rect_size = Vector2(1280, 50)
    t.align = Label.ALIGN_CENTER
    var y = 160
    for a in ACTIONS:
        FX.label(self, Vector2(380, y + 6), a[1], 20, Color(0.95, 0.95, 1.0))
        var b = _button("", Vector2(700, y), Vector2(200, 40))
        b.connect("pressed", self, "_bind", [a[0]])
        buttons[a[0]] = b
        y += 54
    var reset = _button("Reset to defaults", Vector2(440, y + 14), Vector2(190, 44))
    reset.connect("pressed", self, "_reset")
    var back = _button("Back", Vector2(650, y + 14), Vector2(190, 44))
    back.connect("pressed", self, "_close")
    hint = FX.label(self, Vector2(0, 640), "Click a button, then press the new key. Esc cancels. Mouse and gamepad stay as they are.", 15, Color(1, 1, 1, 0.55))
    hint.rect_size = Vector2(1280, 20)
    hint.align = Label.ALIGN_CENTER
    _refresh()

func _button(text, pos, size):
    var b = Button.new()
    b.text = text
    b.rect_position = pos
    b.rect_size = size
    var f = FX.font(18)
    if f != null:
        b.add_font_override("font", f)
    b.add_color_override("font_color", Color(1, 0.95, 0.85))
    b.add_stylebox_override("normal", FX.card_style(Color(0.08, 0.08, 0.14, 0.97), Color(0.6, 0.48, 0.2)))
    b.add_stylebox_override("hover", FX.card_style(Color(0.18, 0.15, 0.26, 0.98), Color(1.0, 0.85, 0.4)))
    b.add_stylebox_override("focus", FX.card_style(Color(0.18, 0.15, 0.26, 0.98), Color(1.0, 0.85, 0.4), 3))
    b.add_stylebox_override("pressed", FX.card_style(Color(0.24, 0.2, 0.3), Color(1.0, 0.95, 0.6)))
    add_child(b)
    return b

func _key_text(action):
    if Game.settings["keys"].has(action):
        return OS.get_scancode_string(int(Game.settings["keys"][action]))
    var names = []
    for ev in InputMap.get_action_list(action):
        if ev is InputEventKey:
            names.append(OS.get_scancode_string(ev.scancode))
    return " / ".join(names) if names.size() > 0 else "-"

func _refresh():
    for a in ACTIONS:
        buttons[a[0]].text = "Press a key..." if waiting == a[0] else _key_text(a[0])

func _bind(action):
    Sfx.play("click")
    waiting = action
    _refresh()

func _reset():
    Sfx.play("click")
    Game.settings["keys"] = {}
    Inputs.apply_keys()
    waiting = ""
    _refresh()

func _input(event):
    if waiting != "" and event is InputEventKey and event.pressed and not event.echo:
        get_viewport().set_input_as_handled()
        if event.scancode != KEY_ESCAPE:
            Game.settings["keys"][waiting] = event.scancode
            Inputs.apply_keys()
            Sfx.play("pickup")
        waiting = ""
        _refresh()
    elif waiting == "" and visible and event.is_action_pressed("pause"):
        get_viewport().set_input_as_handled()
        _close()

func open():
    visible = true
    waiting = ""
    _refresh()

func _close():
    Game.save_settings()
    Sfx.play("back")
    visible = false
    emit_signal("closed")
