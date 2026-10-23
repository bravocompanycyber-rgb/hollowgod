extends Node2D
# A door to the next room. Walk into it to choose that path.

var reward = ""
var label_text = ""
var clock = 0.0

func _ready():
    var l = FX.label(self, Vector2(-90, 50), label_text, 15, Color(1, 0.92, 0.65))
    l.rect_size = Vector2(180, 40)
    l.align = Label.ALIGN_CENTER

func _process(delta):
    clock += delta
    update()

func _color():
    if reward == "gift":
        return Color(1.0, 0.8, 0.3)
    if reward == "echoes":
        return Color(0.4, 0.9, 1.0)
    if reward == "heal":
        return Color(0.4, 1.0, 0.5)
    if reward == "shrine":
        return Color(0.8, 0.5, 1.0)
    return Color(1.0, 0.35, 0.3)

func _draw():
    var col = _color()
    var glow = 0.25 + 0.15 * sin(clock * 3.0)
    draw_circle(Vector2.ZERO, 62.0, Color(col.r, col.g, col.b, 0.10))
    draw_rect(Rect2(-34, -44, 68, 88), Color(0.07, 0.06, 0.11))
    draw_rect(Rect2(-28, -38, 56, 76), Color(col.r, col.g, col.b, glow))
    draw_rect(Rect2(-34, -44, 68, 88), col, false, 3.0)
    if reward == "gift":
        draw_colored_polygon(PoolVector2Array([Vector2(0, -16), Vector2(14, 0), Vector2(0, 16), Vector2(-14, 0)]), Color(1, 0.95, 0.7))
    elif reward == "echoes":
        draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 20, Color(1, 1, 1), 3.0)
        draw_circle(Vector2.ZERO, 4.0, Color(1, 1, 1))
    elif reward == "heal":
        draw_rect(Rect2(-4, -14, 8, 28), Color(1, 1, 1))
        draw_rect(Rect2(-14, -4, 28, 8), Color(1, 1, 1))
    elif reward == "shrine":
        draw_line(Vector2(-14, -10), Vector2(14, -10), Color(1, 1, 1), 3.0)
        draw_line(Vector2(0, -10), Vector2(0, 14), Color(1, 1, 1), 3.0)
        draw_arc(Vector2(-14, 2), 6.0, 0.0, PI, 10, Color(1, 1, 1), 2.0)
        draw_arc(Vector2(14, 2), 6.0, 0.0, PI, 10, Color(1, 1, 1), 2.0)
    else:
        draw_circle(Vector2(0, -4), 11.0, Color(1, 0.9, 0.9))
        draw_rect(Rect2(-6, 4, 12, 8), Color(1, 0.9, 0.9))
        draw_circle(Vector2(-4, -5), 3.0, col)
        draw_circle(Vector2(4, -5), 3.0, col)
