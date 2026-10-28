extends KinematicBody2D
# The Threshold Keeper. Move (WASD), dash (Space), attack (click or J).
# In the Terminus hub, combat = false (no fighting, walking only).

signal died
signal hp_changed(hp, max_hp)

const RADIUS = 13.0
const DASH_SPEED = 760.0
const DASH_TIME = 0.16

var combat = true
var can_attack = true
var frozen = false

# Stats (Gifts, Forge and level change these)
var speed = 265.0
var accel = 2800.0
var friction = 3200.0
var dash_cooldown = 0.55
var attack_cooldown = 0.30
var attack_range = 96.0
var attack_arc = 2.0
var damage_base = 10.0
var dmg_mult = 1.0
var gift_dmg = 0.0
var crit_chance = 0.0
var crit_mult = 2.0
var guard = 0.0
var max_hp = 100
var hp = 100
var shock_pct = 0.0
var lifesteal_hp = 0.0
var kills_for_heal = 0
var second_wind = false

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
var aim_mode = "mouse"
var last_mouse = Vector2.ZERO
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
    light = Light2D.new()
    light.texture = FX.light_texture()
    light.texture_scale = 7.0
    light.color = Color(1.0, 0.86, 0.6)
    light.energy = 0.95
    light.range_height = 70.0
    light.shadow_enabled = Game.settings["effects"]
    light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
    light.shadow_gradient_length = 14.0
    light.shadow_buffer_size = 1024
    light.shadow_color = Color(0, 0, 0, 0.78)
    add_child(light)
    material = Art.sprite_material(Art.SCALE)
    cam = Camera2D.new()
    cam.current = true
    cam.smoothing_enabled = true
    cam.smoothing_speed = 8.0
    add_child(cam)
    FX.camera = cam

func setup_from_profile():
    max_hp = 100 + Game.bonus_hp()
    hp = max_hp
    dmg_mult = Game.bonus_damage()
    speed = 265.0 * Game.bonus_speed()
    dash_cooldown = 0.55 * Game.dash_cd_mult()
    second_wind = Game.has_flag("second_wind")

func apply_quality():
    if light != null:
        light.shadow_enabled = Game.settings["effects"]

func set_camera_limits(rect):
    cam.limit_left = int(rect.position.x)
    cam.limit_top = int(rect.position.y)
    cam.limit_right = int(rect.position.x + rect.size.x)
    cam.limit_bottom = int(rect.position.y + rect.size.y)

func attack_damage():
    return damage_base * dmg_mult * (1.0 + gift_dmg)

func roll_damage():
    var d = attack_damage()
    var crit = randf() < crit_chance
    if crit:
        d *= crit_mult
    return [d, crit]

func apply_gift(id, m):
    if id == "ember":
        gift_dmg += 0.15 * m
    elif id == "reach":
        attack_range += 20.0 * m
        attack_arc = min(4.2, attack_arc + 0.2 * m)
    elif id == "wind":
        dash_cooldown = max(0.12, dash_cooldown * (1.0 - 0.18 * m))
    elif id == "heart":
        var add = int(20 * m)
        max_hp += add
        hp += add
        emit_signal("hp_changed", hp, max_hp)
    elif id == "swift":
        speed *= 1.0 + 0.08 * m
    elif id == "vamp":
        lifesteal_hp += 3.0 * m
    elif id == "shock":
        shock_pct += 1.0 * m
    elif id == "quick":
        attack_cooldown = max(0.1, attack_cooldown * (1.0 - 0.15 * m))
    elif id == "guard":
        guard = min(0.6, guard + 0.08 * m)
    elif id == "crit":
        crit_chance = min(0.8, crit_chance + 0.10 * m)

func heal(n):
    n = int(n)
    if hp >= max_hp or n <= 0:
        return
    hp = int(min(max_hp, hp + n))
    FX.popup(global_position, "+" + str(n), Color(0.4, 1.0, 0.5))
    emit_signal("hp_changed", hp, max_hp)

func on_kill():
    if lifesteal_hp > 0.0:
        kills_for_heal += 1
        if kills_for_heal >= 5:
            kills_for_heal = 0
            heal(int(lifesteal_hp))

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

    var input = Vector2.ZERO
    if not frozen:
        input = Vector2(
            Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
            Input.get_action_strength("move_down") - Input.get_action_strength("move_up"))
        if input.length() > 1.0:
            input = input.normalized()
    _update_aim(input)
    if not frozen and not combat and input.length() > 0.1:
        facing = input.normalized()

    if not frozen and Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0 and dash_time_left <= 0.0:
        if input.length() > 0.1:
            dash_dir = input.normalized()
        else:
            dash_dir = facing
        dash_time_left = DASH_TIME
        dash_cooldown_left = dash_cooldown
        dash_hit = []
        FX.shake(2.0)
        Sfx.play("dash", -4.0)

    if dash_time_left > 0.0:
        velocity = dash_dir * DASH_SPEED
        trail.append([global_position, 0.22])
        if shock_pct > 0.0 and combat:
            _dash_shock()
    elif input.length() > 0.1:
        velocity = velocity.move_toward(input * speed, accel * delta)
    else:
        velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

    if combat and can_attack and not frozen and Input.is_action_just_pressed("attack") and attack_cooldown_left <= 0.0 and dash_time_left <= 0.0:
        _attack()

    velocity = move_and_slide(velocity)

    for t in trail:
        t[1] -= delta
    while trail.size() > 0 and trail[0][1] <= 0.0:
        trail.pop_front()
    update()

func _update_aim(input):
    var mp = get_viewport().get_mouse_position()
    if mp.distance_to(last_mouse) > 3.0:
        aim_mode = "mouse"
        last_mouse = mp
    var stick = Vector2(Input.get_joy_axis(0, 2), Input.get_joy_axis(0, 3))
    if stick.length() > 0.35:
        aim_mode = "pad"
        facing = stick.normalized()
    elif aim_mode == "mouse":
        var to_mouse = get_global_mouse_position() - global_position
        if to_mouse.length() > 4.0:
            facing = to_mouse.normalized()
    elif combat:
        # Gamepad aim assist: face the nearest enemy, otherwise face where you walk
        var best = null
        var bd = 520.0
        for e in get_tree().get_nodes_in_group("enemies"):
            if is_instance_valid(e) and not e.dead and not e.spawning:
                var d = e.global_position.distance_to(global_position)
                if d < bd:
                    bd = d
                    best = e
        if best != null:
            facing = (best.global_position - global_position).normalized()
        elif input.length() > 0.1:
            facing = input.normalized()

func _dash_shock():
    for e in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(e) or e.dead or e.spawning or dash_hit.has(e):
            continue
        if global_position.distance_to(e.global_position) < RADIUS + e.radius + 16.0:
            dash_hit.append(e)
            e.take_hit(attack_damage() * shock_pct, (e.global_position - global_position).normalized(), false)
            FX.shake(4.0)

func _attack():
    attack_cooldown_left = attack_cooldown
    attack_vis = 0.15
    velocity += facing * 220.0
    Sfx.play("swing", -6.0)
    var hit_any = false
    for e in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(e) or e.dead or e.spawning:
            continue
        var to_e = e.global_position - global_position
        if to_e.length() <= attack_range + e.radius:
            if abs(facing.angle_to(to_e)) <= attack_arc / 2.0 or to_e.length() < e.radius + 14.0:
                var r = roll_damage()
                e.take_hit(r[0], to_e.normalized(), r[1])
                hit_any = true
    for p in get_tree().get_nodes_in_group("projectiles"):
        if not is_instance_valid(p):
            continue
        var to_p = p.global_position - global_position
        if to_p.length() <= attack_range + 12.0 and abs(facing.angle_to(to_p)) <= attack_arc / 2.0 + 0.3:
            FX.burst(p.global_position, Color(1, 1, 1), 8, 120.0)
            FX.popup(p.global_position, "parry", Color(0.7, 0.95, 1.0), 16)
            Sfx.play("parry")
            p.queue_free()
            hit_any = true
    if hit_any:
        FX.shake(5.0)
        FX.hitstop(45)

func take_damage(amount, from_pos):
    if not alive or invuln > 0.0 or dash_time_left > 0.0 or not combat:
        return
    amount = int(max(1, round(amount * (1.0 - guard))))
    hp -= amount
    invuln = 0.9
    velocity = (global_position - from_pos).normalized() * 320.0
    FX.shake(9.0)
    FX.hitstop(70)
    Sfx.play("hurt")
    FX.popup(global_position, "-" + str(amount), Color(1.0, 0.3, 0.3), 20)
    if hp <= 0:
        if second_wind:
            second_wind = false
            hp = int(max_hp * 0.4)
            invuln = 2.5
            FX.shake(12.0)
            FX.popup(global_position + Vector2(0, -20), "SECOND WIND", Color(1.0, 0.85, 0.4), 24)
            Sfx.play("levelup")
        else:
            hp = 0
            alive = false
            update()
            emit_signal("hp_changed", hp, max_hp)
            emit_signal("died")
            return
    emit_signal("hp_changed", hp, max_hp)

func _draw():
    Art.shadow(self, Vector2(0, RADIUS), 18.0)
    var flip = facing.x < 0.0
    var moving = velocity.length() > 40.0
    # Dash afterimages
    for t in trail:
        var a = clamp(t[1] / 0.22, 0.0, 1.0) * 0.45
        Art.draw(self, "knight_m_run_anim_f1", to_local(t[0]) + Vector2(0, RADIUS + 2), Art.SCALE, flip, Color(0.6, 0.85, 1.0, a))
    # Sword swing glow (matches the real hit area)
    if attack_vis > 0.0:
        var a2 = clamp(attack_vis / 0.15, 0.0, 1.0)
        var ang = facing.angle()
        draw_arc(Vector2.ZERO, attack_range * 0.85, ang - attack_arc / 2.0, ang + attack_arc / 2.0, 20, Color(1.0, 0.95, 0.7, a2 * 0.8), 7.0)
        draw_arc(Vector2.ZERO, attack_range * 0.62, ang - attack_arc / 2.0, ang + attack_arc / 2.0, 20, Color(1.0, 0.8, 0.4, a2 * 0.5), 3.0)
    # Body sprite
    var base = "knight_m_run_anim" if moving else "knight_m_idle_anim"
    var fname = Art.frame_name(base, clock, 11.0 if moving else 5.0)
    var bob = 0.0
    var stretch = Vector2(1.0 - 0.015 * sin(clock * 3.0), 1.0 + 0.025 * sin(clock * 3.0))
    if dash_time_left > 0.0:
        stretch = Vector2(1.28, 0.8)
    elif attack_vis > 0.0:
        stretch = Vector2(1.1, 0.92)
    elif moving:
        bob = -abs(sin(clock * 12.0)) * 3.0
        stretch = Vector2(1.0 + 0.03 * sin(clock * 24.0), 1.0 - 0.03 * sin(clock * 24.0))
    var mod = Color(1, 1, 1)
    if not alive:
        fname = "knight_m_hit_anim_f0"
        mod = Color(0.5, 0.5, 0.55)
    elif invuln > 0.0 and int(invuln * 20.0) % 2 == 0:
        mod = Color(2.0, 0.7, 0.7)
    if not Art.draw(self, fname, Vector2(0, RADIUS + 2 + bob), Art.SCALE, flip, mod, "bottom", stretch):
        draw_circle(Vector2.ZERO, RADIUS, Color(0.8, 0.92, 1.0))
    # Sword in hand
    if alive:
        var sx = -1.0 if flip else 1.0
        var hand = Vector2(sx * 16.0, -16.0)
        var rot = sx * 0.55
        if attack_vis > 0.0:
            var p2 = 1.0 - clamp(attack_vis / 0.15, 0.0, 1.0)
            var a3 = facing.angle() - attack_arc / 2.0 + attack_arc * p2
            hand = Vector2(0, -12) + Vector2.RIGHT.rotated(a3) * 10.0
            rot = a3 + PI / 2.0
        Art.draw_at(self, "weapon_knight_sword", hand, rot, Art.SCALE * 0.8)
    # Lantern glow (so you can see where you are aiming)
    draw_circle(facing * (RADIUS + 10.0), 7.0, Color(1.0, 0.85, 0.4, 0.28))
    draw_circle(facing * (RADIUS + 10.0), 3.5, Color(1.0, 0.92, 0.55))
    if combat and dash_cooldown_left > 0.0:
        var ratio = 1.0 - clamp(dash_cooldown_left / dash_cooldown, 0.0, 1.0)
        draw_arc(Vector2.ZERO, RADIUS + 9.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 20, Color(0.5, 0.9, 1.0, 0.55), 2.0)
