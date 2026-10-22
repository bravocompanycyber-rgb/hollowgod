extends KinematicBody2D
# The Threshold Keeper. Move (WASD), dash (Space), attack (click or J).

signal died
signal hp_changed(hp, max_hp)

const RADIUS = 11.0
const DASH_SPEED = 660.0
const DASH_TIME = 0.16

# Stats (Gifts change these)
var speed = 230.0
var accel = 2400.0
var friction = 2800.0
var dash_cooldown = 0.55
var attack_cooldown = 0.30
var attack_range = 80.0
var attack_arc = 2.0
var damage = 1
var max_hp = 6
var hp = 6
var shock = false
var vamp = 0
var kills_for_heal = 0

var alive = true
var velocity = Vector2.ZERO
var facing = Vector2.RIGHT
var dash_dir = Vector2.RIGHT
var dash_time_left = 0.0
var dash_cooldown_left = 0.0
var attack_cooldown_left = 0.0
var attack_vis = 0.0
var invuln = 0.0
var trail = []
var dash_hit = []
var cam = null
var light = null
var clock = 0.0

func _ready():
    add_to_group("player")
    collision_layer = 2
    collision_mask = 1
    var shape = CircleShape2D.new()
    shape.radius = RADIUS
    var cs = CollisionShape2D.new()
    cs.shape = shape
    add_child(cs)
    # Lantern light that follows the player
    light = Light2D.new()
    light.texture = FX.light_texture()
    light.texture_scale = 6.0
    light.color = Color(1.0, 0.86, 0.6)
    light.energy = 0.95
    add_child(light)
    # Camera
    cam = Camera2D.new()
    cam.current = true
    cam.smoothing_enabled = true
    cam.smoothing_speed = 8.0
    add_child(cam)
    FX.camera = cam

func set_camera_limits(rect):
    cam.limit_left = int(rect.position.x)
    cam.limit_top = int(rect.position.y)
    cam.limit_right = int(rect.position.x + rect.size.x)
    cam.limit_bottom = int(rect.position.y + rect.size.y)

func apply_gift(id):
    if id == "ember":
        damage += 1
    elif id == "reach":
        attack_range += 22.0
        attack_arc += 0.25
    elif id == "wind":
        dash_cooldown *= 0.65
    elif id == "heart":
        max_hp += 2
        hp = min(max_hp, hp + 2)
        emit_signal("hp_changed", hp, max_hp)
    elif id == "swift":
        speed *= 1.12
    elif id == "vamp":
        vamp += 1
    elif id == "shock":
        shock = true
    elif id == "quick":
        attack_cooldown *= 0.75

func heal(n):
    if hp >= max_hp:
        return
    hp = min(max_hp, hp + n)
    FX.popup(global_position, "+" + str(n), Color(0.4, 1.0, 0.5))
    emit_signal("hp_changed", hp, max_hp)

func on_kill():
    if vamp > 0:
        kills_for_heal += 1
        var need = int(max(2, 8 - 2 * vamp))
        if kills_for_heal >= need:
            kills_for_heal = 0
            heal(1)

func _physics_process(delta):
    clock += delta
    if light != null:
        light.energy = 0.95 + 0.08 * sin(clock * 9.0)
    if not alive:
        return
    dash_cooldown_left = max(0.0, dash_cooldown_left - delta)
    attack_cooldown_left = max(0.0, attack_cooldown_left - delta)
    attack_vis = max(0.0, attack_vis - delta)
    invuln = max(0.0, invuln - delta)
    dash_time_left = max(0.0, dash_time_left - delta)

    var to_mouse = get_global_mouse_position() - global_position
    if to_mouse.length() > 4.0:
        facing = to_mouse.normalized()

    var input = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up"))
    if input.length() > 1.0:
        input = input.normalized()

    if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0 and dash_time_left <= 0.0:
        if input.length() > 0.1:
            dash_dir = input.normalized()
        else:
            dash_dir = facing
        dash_time_left = DASH_TIME
        dash_cooldown_left = dash_cooldown
        dash_hit = []
        FX.shake(2.0)

    if dash_time_left > 0.0:
        velocity = dash_dir * DASH_SPEED
        trail.append([global_position, 0.22])
        if shock:
            _dash_shock()
    elif input.length() > 0.1:
        velocity = velocity.move_toward(input * speed, accel * delta)
    else:
        velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

    if Input.is_action_just_pressed("attack") and attack_cooldown_left <= 0.0 and dash_time_left <= 0.0:
        _attack()

    velocity = move_and_slide(velocity)

    for t in trail:
        t[1] -= delta
    while trail.size() > 0 and trail[0][1] <= 0.0:
        trail.pop_front()
    update()

func _dash_shock():
    for e in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(e) or e.dead or e.spawning or dash_hit.has(e):
            continue
        if global_position.distance_to(e.global_position) < RADIUS + e.radius + 16.0:
            dash_hit.append(e)
            e.take_hit(damage, (e.global_position - global_position).normalized())
            FX.shake(4.0)

func _attack():
    attack_cooldown_left = attack_cooldown
    attack_vis = 0.15
    velocity += facing * 220.0
    var hit_any = false
    for e in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(e) or e.dead or e.spawning:
            continue
        var to_e = e.global_position - global_position
        if to_e.length() <= attack_range + e.radius:
            if abs(facing.angle_to(to_e)) <= attack_arc / 2.0 or to_e.length() < e.radius + 14.0:
                e.take_hit(damage, to_e.normalized())
                hit_any = true
    # Your sword can swat enemy bolts out of the air
    for p in get_tree().get_nodes_in_group("projectiles"):
        if not is_instance_valid(p):
            continue
        var to_p = p.global_position - global_position
        if to_p.length() <= attack_range + 12.0 and abs(facing.angle_to(to_p)) <= attack_arc / 2.0 + 0.3:
            FX.burst(p.global_position, Color(1, 1, 1), 8, 120.0)
            FX.popup(p.global_position, "parry", Color(0.7, 0.95, 1.0))
            p.queue_free()
            hit_any = true
    if hit_any:
        FX.shake(5.0)
        FX.hitstop(45)

func take_damage(amount, from_pos):
    if not alive or invuln > 0.0 or dash_time_left > 0.0:
        return
    hp -= amount
    invuln = 0.9
    velocity = (global_position - from_pos).normalized() * 320.0
    FX.shake(9.0)
    FX.hitstop(70)
    FX.popup(global_position, "-" + str(amount), Color(1.0, 0.3, 0.3))
    emit_signal("hp_changed", hp, max_hp)
    if hp <= 0:
        alive = false
        update()
        emit_signal("died")

func _draw():
    # Dash afterimages
    for t in trail:
        var a = clamp(t[1] / 0.22, 0.0, 1.0) * 0.4
        draw_circle(to_local(t[0]), RADIUS, Color(0.6, 0.85, 1.0, a))
    # Sword arc
    if attack_vis > 0.0:
        var a = clamp(attack_vis / 0.15, 0.0, 1.0)
        var ang = facing.angle()
        draw_arc(Vector2.ZERO, attack_range * 0.85, ang - attack_arc / 2.0, ang + attack_arc / 2.0, 20, Color(1.0, 0.95, 0.7, a), 8.0)
        draw_arc(Vector2.ZERO, attack_range * 0.65, ang - attack_arc / 2.0, ang + attack_arc / 2.0, 20, Color(1.0, 0.8, 0.4, a * 0.6), 3.0)
    # Cloak tail
    var side = facing.rotated(PI / 2.0)
    var tail = PoolVector2Array([-facing * RADIUS * 2.1, side * RADIUS * 0.95, -side * RADIUS * 0.95])
    draw_colored_polygon(tail, Color(0.18, 0.22, 0.42))
    var body = Color(0.8, 0.92, 1.0)
    if not alive:
        body = Color(0.35, 0.35, 0.4)
    elif invuln > 0.0 and int(invuln * 20.0) % 2 == 0:
        body = Color(1.0, 0.45, 0.45)
    draw_circle(Vector2.ZERO, RADIUS + 3.0, Color(0.5, 0.75, 1.0, 0.18))
    draw_circle(Vector2.ZERO, RADIUS, body)
    draw_circle(Vector2.ZERO, RADIUS - 4.0, Color(0.15, 0.2, 0.35))
    # Lantern
    draw_circle(facing * (RADIUS + 4.0), 6.0, Color(1.0, 0.85, 0.4, 0.35))
    draw_circle(facing * (RADIUS + 4.0), 3.5, Color(1.0, 0.9, 0.5))
    # Dash recharge ring
    if dash_cooldown_left > 0.0:
        var ratio = 1.0 - clamp(dash_cooldown_left / dash_cooldown, 0.0, 1.0)
        draw_arc(Vector2.ZERO, RADIUS + 7.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 20, Color(0.5, 0.9, 1.0, 0.55), 2.0)
