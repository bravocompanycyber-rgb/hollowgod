extends Node2D
# Animated decorations (fountains, chests, coins...). items: [{name, pos, scale, anchor, fps}]

var items = []
var clock = 0.0

func _process(delta):
    clock += delta
    update()

func _draw():
    for it in items:
        var base = it["name"]
        var n = base
        if Art.counts.has(base):
            n = Art.frame_name(base, clock, it.get("fps", 4.0))
        Art.draw(self, n, it["pos"], it.get("scale", 3.0), false, it.get("mod", Color(1, 1, 1)), it.get("anchor", "bottom"))
