extends Node2D
# A character standing in the Terminus. Hub.gd decides when you can talk to them.

var npc_id = "oru"
var display_name = "Oru"
var body_color = Color(1.0, 0.8, 0.4)
var kind = "person"   # person or flame
var clock = 0.0
var label = null

func _ready():
    clock = randf() * 6.0
    label = FX.label(self, Vector2(-70, -52), display_name, 15, body_color)
    label.rect_size = Vector2(140, 20)
    label.align = Label.ALIGN_CENTER

func _process(delta):
    clock += delta
    update()

func _draw():
    var bob = sin(clock * 2.0) * (4.0 if kind == "flame" else 1.5)
    var c = body_color
    draw_circle(Vector2(0, bob), 30.0, Color(c.r, c.g, c.b, 0.12))
    if kind == "flame":
        var pts = PoolVector2Array([Vector2(0, -22 + bob), Vector2(12, 4 + bob), Vector2(0, 14 + bob), Vector2(-12, 4 + bob)])
        draw_colored_polygon(pts, Color(c.r, c.g, c.b, 0.9))
        draw_circle(Vector2(0, 2 + bob), 6.0, Color(1, 1, 0.9))
        return
    var cloak = PoolVector2Array([Vector2(0, -6 + bob), Vector2(15, 22 + bob), Vector2(-15, 22 + bob)])
    draw_colored_polygon(cloak, Color(c.r * 0.45, c.g * 0.45, c.b * 0.45))
    draw_circle(Vector2(0, -10 + bob), 11.0, c)
    draw_circle(Vector2(0, -10 + bob), 7.0, Color(c.r * 0.35, c.g * 0.35, c.b * 0.35))
    draw_circle(Vector2(-3, -11 + bob), 1.6, Color(1, 1, 0.85))
    draw_circle(Vector2(3, -11 + bob), 1.6, Color(1, 1, 0.85))
