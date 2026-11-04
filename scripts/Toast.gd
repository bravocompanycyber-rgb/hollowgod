extends CanvasLayer
# Little pop-up notices (achievements). Works even while the game is paused.

var queue = []
var busy = false
var panel = null
var title_label = null
var text_label = null
var tween = null

func _ready():
    layer = 90
    pause_mode = Node.PAUSE_MODE_PROCESS
    panel = Panel.new()
    panel.rect_size = Vector2(380, 84)
    panel.rect_position = Vector2(1280 - 400, -100)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_stylebox_override("panel", FX.card_style(Color(0.06, 0.05, 0.1, 0.96), Color(0.95, 0.78, 0.3), 2))
    add_child(panel)
    title_label = FX.label(panel, Vector2(16, 8), "", 15, Color(0.95, 0.78, 0.3), true)
    text_label = FX.label(panel, Vector2(16, 32), "", 15, Color(0.95, 0.95, 1.0))
    text_label.autowrap = true
    text_label.rect_size = Vector2(350, 46)
    tween = Tween.new()
    add_child(tween)
    tween.connect("tween_all_completed", self, "_done")

func push(title, text):
    queue.append([title, text])
    if not busy:
        _next()

func _next():
    if queue.size() == 0:
        busy = false
        return
    busy = true
    var it = queue.pop_front()
    title_label.text = it[0]
    text_label.text = it[1]
    var x = 1280 - 400
    tween.interpolate_property(panel, "rect_position", Vector2(x, -100), Vector2(x, 18), 0.4, Tween.TRANS_BACK, Tween.EASE_OUT)
    tween.interpolate_property(panel, "rect_position", Vector2(x, 18), Vector2(x, -100), 0.4, Tween.TRANS_QUAD, Tween.EASE_IN, 3.6)
    tween.start()

func _done():
    _next()
