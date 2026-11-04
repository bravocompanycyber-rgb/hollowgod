extends Control
# Shows every achievement, locked ones greyed out.

signal closed
var skip = true

func _init():
    rect_size = Vector2(1280, 720)
    mouse_filter = Control.MOUSE_FILTER_STOP

func _ready():
    var dim = ColorRect.new()
    dim.rect_size = Vector2(1280, 720)
    dim.color = Color(0, 0, 0, 0.85)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(dim)
    var t = FX.label(self, Vector2(0, 40), "ACHIEVEMENTS", 38, Color(0.95, 0.78, 0.3), true)
    t.rect_size = Vector2(1280, 50)
    t.align = Label.ALIGN_CENTER
    var done = Game.data["achievements"].keys().size()
    var sub = FX.label(self, Vector2(0, 92), "%d of %d unlocked" % [done, Game.ACHIEVEMENTS.size()], 18, Color(0.85, 0.9, 1.0))
    sub.rect_size = Vector2(1280, 26)
    sub.align = Label.ALIGN_CENTER
    var half = int(ceil(Game.ACHIEVEMENTS.size() / 2.0))
    for i in range(Game.ACHIEVEMENTS.size()):
        var a = Game.ACHIEVEMENTS[i]
        var got = Game.data["achievements"].has(a["id"])
        var col = i / half
        var row = i % half
        var x = 90 + col * 600
        var y = 140 + row * 52
        FX.label(self, Vector2(x, y), ("* " if got else "- ") + a["name"], 18, Color(1.0, 0.85, 0.4) if got else Color(0.5, 0.5, 0.56), true)
        var d = FX.label(self, Vector2(x + 18, y + 24), a["desc"], 14, Color(0.9, 0.9, 0.95) if got else Color(0.42, 0.42, 0.48))
        d.rect_size = Vector2(540, 20)
    var hint = FX.label(self, Vector2(0, 676), "[E] or Backspace to close", 15, Color(1, 1, 1, 0.55))
    hint.rect_size = Vector2(1280, 20)
    hint.align = Label.ALIGN_CENTER

func _process(delta):
    if skip:
        skip = false
        return
    if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("pause"):
        emit_signal("closed")
