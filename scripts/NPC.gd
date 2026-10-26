extends Node2D
# A character standing in the Terminus. Hub.gd decides when you can talk to them.

var npc_id = "oru"
var display_name = "Oru"
var body_color = Color(1.0, 0.8, 0.4)
var kind = "person"   # person or flame
var sprite = ""       # sprite base name, e.g. "elf_f"
var tint = Color(1, 1, 1)
var watch = null      # who to look at (the player)
var clock = 0.0
var label = null
var flip = false

func _ready():
    clock = randf() * 6.0
    var lh = 16.0 - Art.size_of(sprite + "_idle_anim_f0").y * Art.SCALE - 26.0
    if kind == "flame":
        lh = -68.0
    label = FX.label(self, Vector2(-70, lh), display_name, 16, body_color)
    label.rect_size = Vector2(140, 22)
    label.align = Label.ALIGN_CENTER

func _process(delta):
    clock += delta
    if watch != null and is_instance_valid(watch):
        flip = watch.global_position.x < global_position.x
    update()

func _draw():
    var c = body_color
    if kind == "flame":
        var bob = sin(clock * 2.0) * 5.0
        draw_circle(Vector2(0, bob), 36.0, Color(c.r, c.g, c.b, 0.12))
        draw_circle(Vector2(0, bob), 22.0, Color(c.r, c.g, c.b, 0.18))
        var pts = PoolVector2Array([Vector2(0, -28 + bob), Vector2(15, 4 + bob), Vector2(0, 18 + bob), Vector2(-15, 4 + bob)])
        draw_colored_polygon(pts, Color(c.r, c.g, c.b, 0.95))
        draw_circle(Vector2(0, 3 + bob), 7.0, Color(1, 1, 0.9))
        return
    Art.shadow(self, Vector2(0, 14), 20.0)
    var fname = Art.frame_name(sprite + "_idle_anim", clock, 5.0)
    if not Art.draw(self, fname, Vector2(0, 16), Art.SCALE, flip, tint):
        draw_circle(Vector2(0, -10), 14.0, c)
