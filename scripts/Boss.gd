extends "res://scripts/Enemy.gd"
# Bosses. boss_kind "warden" = Jackal Warden (Sunken Hall), "jarl" = Frost Jarl (Rime Road).
# Set boss_kind before calling setup().

signal hp_changed(hp, max_hp)
signal summon_request(kind, count)

var boss_kind = "warden"
var max_hp = 600
var state = "chase"
var t = 1.8
var cycle = ["charge", "volley"]
var cycle_i = 0
var charge_dir = Vector2.RIGHT
var phase = 1
var face = Vector2.RIGHT
var ring_offset = 0.0
var wave_r = 0.0
var wave_hit = false
var boss_tint = Color(1.0, 0.9, 0.62)
var sprite_base = "big_demon"
var sprite_scale = 4.5
var phase_marks = [0.5]
var max_phase = 2

func setup(p_kind, p_target):
    target = p_target
    if boss_kind == "hollow":
        kind = "hollow"
        hp = 1800
        max_hp = 1800
        speed = 90.0
        radius = 58.0
        contact_damage = 32
        color = Color(0.7, 0.5, 1.0)
        sprite_base = "necromancer"
        sprite_scale = 9.0
        boss_tint = Color(0.66, 0.54, 1.0)
        cycle = ["slam", "volley", "fan", "charge", "volley"]
        phase_marks = [0.66, 0.33]
        max_phase = 3
    elif boss_kind == "lord":
        kind = "lord"
        hp = 1200
        max_hp = 1200
        speed = 85.0
        radius = 54.0
        contact_damage = 30
        color = Color(1.0, 0.6, 0.25)
        sprite_base = "skeleton"
        sprite_scale = 8.5
        boss_tint = Color(1.0, 0.95, 0.8)
        cycle = ["fan", "slam", "volley", "charge"]
    elif boss_kind == "jarl":
        kind = "jarl"
        hp = 900
        max_hp = 900
        speed = 80.0
        radius = 52.0
        contact_damage = 28
        color = Color(0.6, 0.85, 1.0)
        sprite_base = "ogre"
        sprite_scale = 5.5
        boss_tint = Color(0.7, 0.92, 1.4)
        cycle = ["slam", "charge", "fan"]
    else:
        kind = "warden"
        hp = 600
        max_hp = 600
        speed = 85.0
        radius = 46.0
        contact_damage = 25
        color = Color(0.95, 0.75, 0.25)
        sprite_base = "big_demon"
        sprite_scale = 4.5
        boss_tint = Color(1.0, 0.9, 0.62)
        cycle = ["charge", "volley"]
    spawn_total = 1.4
    spawn_left = 1.4
    mat_scale = sprite_scale

func _physics_process(delta):
    if dead:
        return
    clock += delta
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
    var sp = speed * (1.0 + 0.3 * (phase - 1))
    var v = Vector2.ZERO
    if state == "chase":
        v = dir * sp
        if t <= 0.0:
            _next_attack(dir)
    elif state == "windup":
        if t <= 0.0:
            state = "charge"
            t = 0.55
            FX.shake(6.0)
    elif state == "charge":
        v = charge_dir * 600.0
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
    elif state == "fan_windup":
        if t <= 0.0:
            _fire_fan(dir)
            state = "chase"
            t = 1.3
    elif state == "slam_windup":
        if t <= 0.0:
            state = "slam"
            t = 0.75
            wave_r = 0.0
            wave_hit = false
            FX.shake(10.0)
            Sfx.play("slam")
    elif state == "slam":
        wave_r = 470.0 * (1.0 - clamp(t / 0.75, 0.0, 1.0))
        if not wave_hit and abs(to_t.length() - wave_r) < 28.0:
            wave_hit = true
            target.take_damage(22, global_position)
        if t <= 0.0:
            state = "recover"
            t = 0.8
    v += knock
    knock = knock.move_toward(Vector2.ZERO, 900.0 * delta)
    move_and_slide(v)
    if to_t.length() < radius + target.RADIUS + 2.0 and touch_cooldown <= 0.0:
        target.take_damage(contact_damage, global_position)
        touch_cooldown = 0.9
    if phase < max_phase and hp <= max_hp * phase_marks[phase - 1]:
        phase += 1
        _phase_up()
    update()

func _phase_up():
    FX.shake(12.0)
    FX.popup(global_position, "ENRAGED" if phase == 2 and max_phase == 2 else ("PHASE %d" % phase), Color(1.0, 0.4, 0.3), 28)
    if boss_kind == "hollow":
        if phase == 2:
            emit_signal("summon_request", "wisp", 3)
            emit_signal("summon_request", "charger", 2)
        else:
            emit_signal("summon_request", "husk", 4)
            emit_signal("summon_request", "charger", 3)
            emit_signal("summon_request", "wisp", 2)
    elif boss_kind == "lord":
        emit_signal("summon_request", "charger", 3)
        emit_signal("summon_request", "wisp", 2)
    elif boss_kind == "jarl":
        emit_signal("summon_request", "wisp", 2)
        emit_signal("summon_request", "charger", 2)
    else:
        emit_signal("summon_request", "husk", 4)

func _next_attack(dir):
    var a = cycle[cycle_i % cycle.size()]
    cycle_i += 1
    if a == "charge":
        state = "windup"
        t = 0.75
        charge_dir = dir
    elif a == "volley":
        state = "volley_windup"
        t = 0.6
    elif a == "fan":
        state = "fan_windup"
        t = 0.55
    else:
        state = "slam_windup"
        t = 0.9

func _fire_ring():
    var n = 10 + 6 * (phase - 1)
    ring_offset += 0.3
    for i in range(n):
        _shoot(Vector2.RIGHT.rotated(TAU * i / n + ring_offset), 210.0, 12)
    FX.shake(5.0)
    Sfx.play("boss", -2.0)

func _fire_fan(dir):
    var spread = 2 + phase
    for i in range(-spread, spread + 1):
        _shoot(dir.rotated(i * 0.2), 280.0, 12)
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
    var anchor = Vector2(0, radius * 0.9)
    var sc = sprite_scale
    var bn = sprite_base
    if spawning:
        var k = clamp(spawn_left / spawn_total, 0.0, 1.0)
        draw_arc(Vector2.ZERO, radius + 6.0 + 40.0 * k, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.9 - 0.5 * k), 3.0)
        Art.draw(self, bn + "_idle_anim_f0", anchor, sc, false, Color(boss_tint.r, boss_tint.g, boss_tint.b, 0.6 * (1.0 - k)))
        return
    Art.shadow(self, anchor, radius * 1.2)
    var mod = boss_tint
    if phase == 2:
        mod = Color(boss_tint.r * 1.0, boss_tint.g * 0.8, boss_tint.b * 0.85)
    if flash > 0.0:
        mod = Color(2.6, 2.6, 2.6)
    if state == "windup":
        draw_line(Vector2.ZERO, charge_dir * 520.0, Color(1.0, 0.3, 0.2, 0.55), 5.0)
        mod = Color(1.6, 0.8, 0.7)
    if state == "slam_windup":
        draw_arc(Vector2.ZERO, 470.0, 0.0, TAU, 64, Color(1.0, 0.3, 0.3, 0.35), 3.0)
        mod = Color(1.5, 0.9, 0.9)
    if state == "slam":
        draw_arc(Vector2.ZERO, wave_r, 0.0, TAU, 64, Color(0.7, 0.95, 1.0, 0.9), 8.0)
        draw_arc(Vector2.ZERO, max(wave_r - 14.0, 1.0), 0.0, TAU, 64, Color(1, 1, 1, 0.5), 3.0)
    var moving = state == "chase" or state == "charge"
    var fname = Art.frame_name(bn + ("_run_anim" if moving else "_idle_anim"), clock, 8.0)
    var breathe = Vector2(1.0 - 0.02 * sin(clock * 2.5), 1.0 + 0.03 * sin(clock * 2.5))
    if boss_kind == "hollow":
        draw_circle(Vector2(0, -50), radius + 60.0, Color(0.5, 0.3, 0.9, 0.10))
        draw_circle(Vector2(0, -50), radius + 28.0, Color(0.6, 0.4, 1.0, 0.14))
    if boss_kind == "lord":
        draw_circle(Vector2(0, -40), radius + 36.0, Color(1.0, 0.5, 0.15, 0.12))
        draw_circle(Vector2(0, -40), radius + 14.0, Color(1.0, 0.55, 0.2, 0.14))
    if not Art.draw(self, fname, anchor, sc, face.x < 0.0, mod, "bottom", breathe):
        draw_circle(Vector2.ZERO, radius, color)
    if boss_kind == "hollow":
        # The swallowed gods orbit the Hollow
        var gods = ["big_demon_idle_anim_f0", "ogre_idle_anim_f0", "skeleton_idle_anim_f0"]
        var gs = [2.2, 2.2, 3.0]
        for i in range(3):
            var ga = clock * (0.9 + 0.35 * phase) + TAU * i / 3.0
            var gp = Vector2(cos(ga) * 130.0, -60.0 + sin(ga) * 44.0)
            Art.draw(self, gods[i], gp, gs[i], false, Color(0.7, 0.6, 1.0, 0.85), "center")
        draw_circle(Vector2(-14, -108), 5.0, Color(1, 1, 1, 0.9))
        draw_circle(Vector2(14, -108), 5.0, Color(1, 1, 1, 0.9))
    if boss_kind == "lord":
        var top = anchor.y - 16.0 * sc + 22.0
        var gold = Color(1.0, 0.78, 0.25)
        draw_colored_polygon(PoolVector2Array([Vector2(-34, top), Vector2(-34, top - 22), Vector2(-17, top - 8), Vector2(0, top - 30), Vector2(17, top - 8), Vector2(34, top - 22), Vector2(34, top)]), gold)
        draw_rect(Rect2(-34, top - 2, 68, 6), Color(0.7, 0.45, 0.1))
        for i in range(3):
            var a = clock * 1.4 + TAU * i / 3.0
            var sp = Vector2(cos(a) * 96.0, -50.0 + sin(a) * 30.0)
            Art.draw(self, "skull", sp, 2.5, false, Color(1.0, 0.9, 0.7, 0.95), "center")
    if state == "volley_windup" or state == "fan_windup":
        draw_arc(Vector2.ZERO, radius + 14.0, 0.0, TAU, 28, Color(1, 1, 1, 0.8), 3.0)
