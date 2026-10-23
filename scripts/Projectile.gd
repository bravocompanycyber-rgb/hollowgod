extends Node2D
# An enemy bolt. Hurts the player on touch. Your sword can destroy it.

var vel = Vector2.ZERO
var damage = 10
var life = 5.0
var radius = 6.0
var target = null
var color = Color(0.3, 0.85, 0.95)

func _ready():
    add_to_group("projectiles")

func _physics_process(delta):
    position += vel * delta
    life -= delta
    if life <= 0.0:
        queue_free()
        return
    var main = get_parent()
    if not main.ARENA.has_point(position):
        queue_free()
        return
    for r in main.pillars:
        if r.has_point(position):
            FX.burst(global_position, color, 5, 80.0)
            queue_free()
            return
    if target != null and is_instance_valid(target) and target.alive:
        if global_position.distance_to(target.global_position) < radius + target.RADIUS:
            target.take_damage(damage, global_position - vel.normalized() * 10.0)
            FX.burst(global_position, color, 8, 100.0)
            queue_free()
            return
    update()

func _draw():
    draw_circle(Vector2.ZERO, radius + 6.0, Color(color.r, color.g, color.b, 0.22))
    draw_circle(Vector2.ZERO, radius + 2.0, Color(color.r, color.g, color.b, 0.55))
    draw_circle(Vector2.ZERO, radius, color)
    draw_circle(Vector2.ZERO, radius * 0.5, Color(1, 1, 1))
