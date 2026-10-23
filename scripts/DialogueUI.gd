extends CanvasLayer
# Dialogue box with typewriter text and branching choices.
# lines: [[speaker_id, text], ...]   choices: [{id, text, reply: [[speaker_id, text], ...]}]

signal finished(choice_id)

const SPEAKERS = {
    "oru": ["Oru", Color(1.0, 0.8, 0.4)],
    "mara": ["Mara Voss", Color(0.95, 0.55, 0.55)],
    "sable": ["Sable", Color(0.7, 0.82, 1.0)],
    "bryn": ["Bryn", Color(1.0, 0.62, 0.3)],
    "narr": ["", Color(0.75, 0.75, 0.8)]
}

var lines = []
var choices = []
var idx = 0
var phase = "lines"   # lines, choices, reply
var active = false
var typing = false
var chars = 0.0
var skip = false
var chosen = ""
var panel = null
var name_label = null
var text_label = null
var hint_label = null
var choice_root = null

func _ready():
    layer = 40
    panel = Panel.new()
    panel.rect_position = Vector2(60, 500)
    panel.rect_size = Vector2(1160, 190)
    panel.add_stylebox_override("panel", FX.card_style(Color(0.05, 0.05, 0.1, 0.94), Color(0.7, 0.55, 0.2)))
    add_child(panel)
    name_label = FX.label(panel, Vector2(24, 12), "", 22, Color(1, 0.8, 0.4), true)
    text_label = FX.label(panel, Vector2(24, 50), "", 20, Color(0.95, 0.95, 1.0))
    text_label.autowrap = true
    text_label.rect_size = Vector2(1110, 110)
    hint_label = FX.label(panel, Vector2(900, 158), "[E] continue", 14, Color(1, 1, 1, 0.55))
    hint_label.rect_size = Vector2(240, 20)
    hint_label.align = Label.ALIGN_RIGHT
    choice_root = Control.new()
    choice_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(choice_root)
    panel.visible = false

func start(p_lines, p_choices):
    lines = p_lines
    choices = p_choices
    idx = 0
    phase = "lines"
    chosen = ""
    active = true
    skip = true
    panel.visible = true
    _show_line()

func _show_line():
    var ln = lines[idx]
    var sp = SPEAKERS.get(ln[0], ["", Color(1, 1, 1)])
    name_label.text = sp[0]
    name_label.add_color_override("font_color", sp[1])
    text_label.text = ln[1]
    text_label.visible_characters = 0
    chars = 0.0
    typing = true
    hint_label.visible = true

func advance():
    if typing:
        typing = false
        text_label.visible_characters = -1
        return
    idx += 1
    if idx < lines.size():
        _show_line()
    else:
        _lines_done()

func _lines_done():
    if phase == "lines" and choices.size() > 0:
        phase = "choices"
        hint_label.visible = false
        _build_choices()
    else:
        _finish()

func _build_choices():
    for c in choice_root.get_children():
        c.queue_free()
    for i in range(choices.size()):
        var b = Button.new()
        b.text = "[%d]  %s" % [i + 1, choices[i]["text"]]
        b.rect_position = Vector2(240, 330 + i * 56 - (choices.size() - 2) * 28)
        b.rect_size = Vector2(800, 46)
        b.focus_mode = Control.FOCUS_NONE
        var f = FX.font(19)
        if f != null:
            b.add_font_override("font", f)
        b.add_color_override("font_color", Color(1, 0.95, 0.85))
        b.add_color_override("font_color_hover", Color(1, 1, 1))
        b.add_stylebox_override("normal", FX.card_style(Color(0.08, 0.08, 0.14, 0.96), Color(0.6, 0.48, 0.2)))
        b.add_stylebox_override("hover", FX.card_style(Color(0.18, 0.15, 0.26, 0.98), Color(1.0, 0.85, 0.4)))
        b.add_stylebox_override("pressed", FX.card_style(Color(0.24, 0.2, 0.3), Color(1.0, 0.95, 0.6)))
        choice_root.add_child(b)
        b.connect("pressed", self, "choose", [i])

func choose(i):
    if phase != "choices":
        return
    chosen = choices[i]["id"]
    for c in choice_root.get_children():
        c.queue_free()
    var reply = choices[i].get("reply", [])
    if reply.size() > 0:
        lines = reply
        idx = 0
        phase = "reply"
        skip = true
        _show_line()
    else:
        _finish()

func _finish():
    active = false
    panel.visible = false
    for c in choice_root.get_children():
        c.queue_free()
    emit_signal("finished", chosen)

func _process(delta):
    if not active:
        return
    if skip:
        skip = false
        return
    if phase == "choices":
        for i in range(choices.size()):
            if Input.is_action_just_pressed("pick%d" % (i + 1)):
                choose(i)
                return
        return
    if typing:
        chars += delta * 60.0
        text_label.visible_characters = int(chars)
        if int(chars) >= text_label.text.length():
            typing = false
            text_label.visible_characters = -1
    if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack"):
        advance()
