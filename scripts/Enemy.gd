extends KinematicBody2D
# Enemies. Kinds: "husk" (fast, weak), "brute" (slow, tough), "wisp" (shoots bolts).

signal died

const ProjectileScript = preload("res://scripts/Projectile.gd")

var kind = "husk"
var hp = 3
var speed = 100.0
var radius = 12.0
var contact_damage = 1
var color = Color(0.95, 0.3, 0.35)
var target = null
var knock = Vector2.ZERO
var flash = 0.0
var touch_cooldown = 0.0
var spawn_total = 0.7
var spawn_left = 0.7
var spawning = true
var dead = false
var shoot_timer = 1.5
var strafe = 1.0
var charging = false

func setup(p_kind, p_target):
    kind = p_kind
    target = p_target
    strafe = 1.0 if randf() < 0.5 else -1.0
    if kind == "brute":
        hp = 8
        speed = 62.0
        radius = 20.0
        contact_damage = 2
        color = Color(0.7, 0.4, 0.95)
    elif kind == "wisp":
        hp = 2
        speed = 85.0
        radius = 10.0
        contact_damage = 1
        color = Color(0.3, 0.9, 1.0)
        shoot_timer = rand_range(1.2, 2.2)
    else:
        hp = 3
        speed = 100.0
        radius = 12.0
        contact_damage = 1
        color = Color(0.95, 0.3, 0.35)

func _ready():
    add_to_group("enemies")
    collision_layer = 4
    collision_mask = 1 | 4
    var shape = CircleShape2D.new()
    shape.radius = radius
    var cs = CollisionShape2D.new()
    cs.shape = shape
    add_child(cs)

func _physics_process(delta):
    if dead:
        return
    flash = max(0.0, flash - delta)
    touch_cooldown = max(0.0, touch_cooldown - delta)
    if spawning:
        spawn_left -= delta
        if spawn_left <= 0.0:
            spawning = false
        update()
        return
    if target != null and is_instance_valid(target) and target.alive:
        var to_t = target.global_position - global_position
        var dir = to_t.normalized()
        var move_dir = dir
        if kind == "wisp":
            var dist = to_t.length()
            if dist > 330.0:
                move_dir = dir
            elif dist < 230.0:
                move_dir = -dir
            else:
                move_dir = dir.rotated(PI / 2.0 * strafe)
            shoot_timer -= delta
            charging = shoot_timer < 0.5
            if shoot_timer <= 0.0:
                _shoot(dir, 250.0, 1)
                shoot_timer = rand_range(2.0, 2.8)
                charging = false
        var v = move_dir * speed + knock
        knock = knock.move_toward(Vector2.ZERO, 900.0 * delta)
        move_and_slide(v)
        if to_t.length() < radius + target.RADIUS + 2.0 and touch_cooldown <= 0.0:
            target.take_damage(contact_damage, global_position)
            touch_cooldown = 0.9
    update()

func _shoot(dir, spd, dmg):
    var p = ProjectileScript.new()
    p.position = global_position + dir * (radius + 6.0)
    p.vel = dir * spd
    p.damage = dmg
    p.target = target
    p.color = color
    get_parent().add_child(p)

func take_hit(amount, dir):
    if dead or spawning:
        return
    hp -= amount
    knock = dir * (220.0 if kind == "brute" else 380.0)
    flash = 0.1
    FX.shake(3.0)
    FX.popup(global_position, amount, Color(1.0, 0.92, 0.5))
    FX.burst(global_position, color, 6, 120.0)
    if hp <= 0:
        _die()

func _die():
    dead = true
    remove_from_group("enemies")
    FX.burst(global_position, color, 24, 180.0)
    FX.shake(4.0)
    emit_signal("died")
    queue_free()

func _draw():
    if spawning:
        var k = clamp(spawn_left / spawn_total, 0.0, 1.0)
        draw_arc(Vector2.ZERO, radius + 4.0 + 14.0 * k, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.9 - 0.5 * k), 2.0)
        draw_circle(Vector2.ZERO, radius * (1.0 - k), Color(color.r, color.g, color.b, 0.35))
        return
    var c = color
    if flash > 0.0:
        c = Color(1, 1, 1)
    draw_circle(Vector2.ZERO, radius + 5.0, Color(color.r, color.g, color.b, 0.16))
    draw_circle(Vector2.ZERO, radius, c)
    draw_circle(Vector2.ZERO, radius * 0.6, Color(c.r * 0.3, c.g * 0.3, c.b * 0.3))
    if charging:
        draw_arc(Vector2.ZERO, radius + 7.0, 0.0, TAU, 20, Color(1, 1, 1, 0.8), 2.0)
    if target != null and is_instance_valid(target):
        var d = (target.global_position - global_position).normalized()
        var side = d.rotated(PI / 2.0)
        draw_circle(d * radius * 0.5 + side * radius * 0.3, radius * 0.17, Color(1.0, 0.95, 0.6))
        draw_circle(d * radius * 0.5 - side * radius * 0.3, radius * 0.17, Color(1.0, 0.95, 0.6))
