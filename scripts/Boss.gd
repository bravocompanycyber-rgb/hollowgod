extends "res://scripts/Enemy.gd"
# The Jackal Warden: ruler of the Sunken Hall. Charges, fires rings of bolts, calls minions at half health.

signal hp_changed(hp, max_hp)
signal summon_request(kind, count)

var max_hp = 600
var state = "chase"
var t = 1.8
var next_attack = "charge"
var charge_dir = Vector2.RIGHT
var phase = 1
var face = Vector2.RIGHT
var ring_offset = 0.0

func setup(p_kind, p_target):
    kind = "warden"
    target = p_target
    hp = 600
    max_hp = 600
    speed = 75.0
    radius = 30.0
    contact_damage = 25
    color = Color(0.95, 0.75, 0.25)
    spawn_total = 1.4
    spawn_left = 1.4

func _physics_process(delta):
    if dead:
        return
    flash = max(0.0, flash - delta)
    touch_cooldown = max(0.0, touch_cooldown - delta)
    if spawning:
        spawn_left -= delta
        if spawn_left <= 0.0:
            spawning = false
            state = "chase"
            t = 1.6
        update()
        return
    if target == null or not is_instance_valid(target) or not target.alive:
        update()
        return
    var to_t = target.global_position - global_position
    var dir = to_t.normalized()
    face = dir
    t -= delta
    var sp = speed * (1.3 if phase == 2 else 1.0)
    var v = Vector2.ZERO
    if state == "chase":
        v = dir * sp
        if t <= 0.0:
            if next_attack == "charge":
                state = "windup"
                t = 0.75
                charge_dir = dir
                next_attack = "volley"
            else:
                state = "volley_windup"
                t = 0.6
                next_attack = "charge"
    elif state == "windup":
        if t <= 0.0:
            state = "charge"
            t = 0.55
            FX.shake(6.0)
    elif state == "charge":
        v = charge_dir * 540.0
        if t <= 0.0:
            state = "recover"
            t = 0.7
    elif state == "recover":
        if t <= 0.0:
            state = "chase"
            t = 1.5
    elif state == "volley_windup":
        if t <= 0.0:
            _fire_ring()
            state = "chase"
            t = 1.4
    v += knock
    knock = knock.move_toward(Vector2.ZERO, 900.0 * delta)
    move_and_slide(v)
    if to_t.length() < radius + target.RADIUS + 2.0 and touch_cooldown <= 0.0:
        target.take_damage(contact_damage, global_position)
        touch_cooldown = 0.9
    if phase == 1 and hp <= max_hp / 2:
        phase = 2
        FX.shake(12.0)
        FX.popup(global_position, "ENRAGED", Color(1.0, 0.4, 0.3))
        emit_signal("summon_request", "husk", 4)
    update()

func _fire_ring():
    var n = 10 if phase == 1 else 16
    ring_offset += 0.3
    for i in range(n):
        _shoot(Vector2.RIGHT.rotated(TAU * i / n + ring_offset), 190.0, 12)
    FX.shake(5.0)
    Sfx.play("boss", -2.0)

func take_hit(amount, dir, crit = false):
    if dead or spawning:
        return
    hp -= amount
    flash = 0.08
    FX.shake(3.0)
    if crit:
        FX.popup(global_position, str(int(round(amount))) + "!", Color(1.0, 0.55, 0.2), 28)
    else:
        FX.popup(global_position, int(round(amount)), Color(1.0, 0.92, 0.5), 20)
    FX.burst(global_position, color, 6, 120.0)
    Sfx.play("hit", -3.0)
    emit_signal("hp_changed", int(max(hp, 0)), max_hp)
    if hp <= 0:
        _die()

func _die():
    dead = true
    remove_from_group("enemies")
    FX.burst(global_position, color, 60, 260.0)
    FX.burst(global_position, Color(1, 1, 1), 30, 160.0)
    FX.shake(14.0)
    FX.hitstop(220)
    Sfx.play("kill")
    emit_signal("died")
    queue_free()

func _draw():
    if spawning:
        var k = clamp(spawn_left / spawn_total, 0.0, 1.0)
        draw_arc(Vector2.ZERO, radius + 6.0 + 30.0 * k, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.9 - 0.5 * k), 3.0)
        draw_circle(Vector2.ZERO, radius * (1.0 - k), Color(color.r, color.g, color.b, 0.35))
        return
    var c = color
    if flash > 0.0:
        c = Color(1, 1, 1)
    if state == "windup":
        draw_line(Vector2.ZERO, charge_dir * 460.0, Color(1.0, 0.3, 0.2, 0.55), 4.0)
    draw_circle(Vector2.ZERO, radius + 10.0, Color(color.r, color.g, color.b, 0.15))
    # Jackal ears
    var ang = face.angle()
    for s in [-1.0, 1.0]:
        var a = ang + s * 1.0
        var p1 = Vector2.RIGHT.rotated(a - 0.3) * radius
        var p2 = Vector2.RIGHT.rotated(a + 0.3) * radius
        var tip = Vector2.RIGHT.rotated(a) * radius * 1.8
        draw_colored_polygon(PoolVector2Array([p1, tip, p2]), c)
    draw_circle(Vector2.ZERO, radius, c)
    draw_circle(Vector2.ZERO, radius * 0.7, Color(c.r * 0.3, c.g * 0.3, c.b * 0.3))
    var side = face.rotated(PI / 2.0)
    var eye = Color(1.0, 0.25, 0.2)
    if phase == 2:
        eye = Color(1.0, 0.9, 0.3)
    draw_circle(face * radius * 0.45 + side * radius * 0.3, radius * 0.14, eye)
    draw_circle(face * radius * 0.45 - side * radius * 0.3, radius * 0.14, eye)
    if state == "volley_windup":
        draw_arc(Vector2.ZERO, radius + 12.0, 0.0, TAU, 28, Color(1, 1, 1, 0.8), 3.0)
