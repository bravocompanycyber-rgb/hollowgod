extends CanvasLayer
# Press Esc to pause. mode = "hub" or "run".

signal abandon

var mode = "hub"
var enabled = true
var menu_root = null
var controls_label = null
var buttons = []
var sound_button = null
var shown = false
var options = null

const CONTROLS = "WASD or arrows    Move\nMouse    Aim\nLeft click or J    Attack (also swats bolts)\nSpace or Shift    Dash\nE or Enter    Talk, confirm, continue\n1 2 3 4 5    Pick a card or choice\nEsc    Pause\nF11    Fullscreen"

func _ready():
    layer = 100
    pause_mode = Node.PAUSE_MODE_PROCESS
    menu_root = Control.new()
    menu_root.mouse_filter = Control.MOUSE_FILTER_STOP
    menu_root.rect_size = Vector2(1280, 720)
    add_child(menu_root)
    var dim = ColorRect.new()
    dim.rect_size = Vector2(1280, 720)
    dim.color = Color(0, 0, 0, 0.75)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    menu_root.add_child(dim)
    var t = FX.label(menu_root, Vector2(0, 110), "PAUSED", 44, Color(0.95, 0.78, 0.3), true)
    t.rect_size = Vector2(1280, 56)
    t.align = Label.ALIGN_CENTER
    var items = []
    if mode == "hub":
        items = [["Resume", "resume"], ["Save game", "save"], ["Options", "options"], ["Controls", "controls"], ["Quit to title", "title"]]
    else:
        items = [["Resume", "resume"], ["Options", "options"], ["Controls", "controls"], ["Abandon run (return to Terminus)", "abandon"], ["Quit to title", "title"]]
    var y = 205
    for it in items:
        var b = Button.new()
        b.text = it[0]
        b.rect_position = Vector2(440, y)
        b.rect_size = Vector2(400, 46)
        var f = FX.font(20)
        if f != null:
            b.add_font_override("font", f)
        b.add_color_override("font_color", Color(1, 0.95, 0.85))
        b.add_stylebox_override("normal", FX.card_style(Color(0.08, 0.08, 0.14, 0.97), Color(0.6, 0.48, 0.2)))
        b.add_stylebox_override("hover", FX.card_style(Color(0.18, 0.15, 0.26, 0.98), Color(1.0, 0.85, 0.4)))
        b.add_stylebox_override("focus", FX.card_style(Color(0.18, 0.15, 0.26, 0.98), Color(1.0, 0.85, 0.4), 3))
        b.add_stylebox_override("pressed", FX.card_style(Color(0.24, 0.2, 0.3), Color(1.0, 0.95, 0.6)))
        menu_root.add_child(b)
        b.connect("pressed", self, "_act", [it[1]])
        buttons.append(b)
        y += 56
    controls_label = FX.label(menu_root, Vector2(340, 200), CONTROLS, 19, Color(0.95, 0.95, 1.0))
    controls_label.rect_size = Vector2(600, 300)
    controls_label.visible = false
    options = load("res://scripts/OptionsPanel.gd").new()
    options.visible = false
    menu_root.add_child(options)
    options.connect("closed", self, "_options_closed")
    menu_root.visible = false

func _input(event):
    if event.is_action_pressed("pause") and enabled:
        get_tree().set_input_as_handled()
        if shown and options.visible:
            options._close()
        elif shown and controls_label.visible:
            _show_controls(false)
        elif shown:
            _close()
        else:
            _open()

func _open():
    shown = true
    menu_root.visible = true
    get_tree().paused = true
    Sfx.play("open")
    buttons[0].grab_focus()

func _options_closed():
    for b in buttons:
        b.visible = true
    buttons[0].grab_focus()

func _close():
    Sfx.play("close")
    shown = false
    menu_root.visible = false
    get_tree().paused = false

func _show_controls(on):
    controls_label.visible = on
    for b in buttons:
        b.visible = not on

func _act(id):
    if id != "options":
        Sfx.play("click")
    if id == "resume":
        _close()
    elif id == "save":
        Game.save()
        FX.popup(Vector2(640, 660), "Game saved", Color(0.5, 1, 0.6), 22)
    elif id == "options":
        for b in buttons:
            b.visible = false
        options.open()
    elif id == "controls":
        _show_controls(true)
    elif id == "abandon":
        _close()
        emit_signal("abandon")
    elif id == "title":
        Game.save()
        Game.goto("res://scenes/Title.tscn")
