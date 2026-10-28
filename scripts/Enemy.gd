extends KinematicBody2D
# Enemies. Kinds: "husk" (fast, weak), "brute" (slow, tough), "wisp" (shoots bolts).

signal died

const ProjectileScript = preload("res://scripts/Projectile.gd")

var kind = "husk"
var hp = 30.0
var speed = 100.0
var radius = 12.0
var contact_damage = 10
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
var hp_mult = 1.0
var visual = "zombie"
var theme = "sunken"
var tint = Color(1, 1, 1)
var cstate = "idle"
var ct = 0.0
var cdir = Vector2.RIGHT
var cooldown = 2.0
var mat_scale = 3.0
var tilt = 0.0
var clock = 0.0
var face_left = false

func setup(p_kind, p_target):
    kind = p_kind
    target = p_target
    strafe = 1.0 if randf() < 0.5 else -1.0
    clock = randf() * 4.0
    var rime = theme == "rime"
    var obs = theme == "obsidian"
    var hol = theme == "hollow"
    tint = Color(0.78, 0.92, 1.25) if rime else (Color(1.05, 0.78, 1.0) if obs else (Color(0.62, 0.55, 0.95) if hol else Color(1, 1, 1)))
    if kind == "brute":
        hp = 80.0
        speed = 72.0
        radius = 30.0
        contact_damage = 20
        color = Color(0.7, 0.4, 0.95)
        visual = "big_zombie" if rime else ("ogre" if (obs or hol) else ["ogre", "big_zombie"][randi() % 2])
    elif kind == "wisp":
        hp = 20.0
        speed = 95.0
        radius = 13.0
        contact_damage = 8
        color = Color(0.3, 0.9, 1.0)
        shoot_timer = rand_range(1.2, 2.2)
        visual = "orc_shaman" if rime else ("necromancer" if not hol else ["necromancer", "orc_shaman"][randi() % 2])
    elif kind == "charger":
        hp = 40.0
        speed = 105.0
        radius = 15.0
        contact_damage = 14
        color = Color(1.0, 0.6, 0.25)
        cooldown = rand_range(1.2, 2.6)
        visual = ["wogol", "masked_orc"][randi() % 2] if rime else (["chort", "chort", "imp"][randi() % 3] if obs else (["chort", "wogol", "imp"][randi() % 3] if hol else ["imp", "chort"][randi() % 2]))
    else:
        hp = 30.0
        speed = 118.0
        radius = 14.0
        contact_damage = 10
        color = Color(0.95, 0.3, 0.35)
        visual = ["ice_zombie", "skeleton", "tiny_zombie"][randi() % 3] if rime else (["skeleton", "skeleton", "imp", "goblin"][randi() % 4] if obs else (["zombie", "skeleton", "ice_zombie", "goblin"][randi() % 4] if hol else ["zombie", "tiny_zombie", "skeleton", "goblin"][randi() % 4]))
    hp *= hp_mult

func _ready():
    add_to_group("enemies")
    material = Art.sprite_material(mat_scale)
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
    clock += delta
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
            if dist > 360.0:
                move_dir = dir
            elif dist < 250.0:
                move_dir = -dir
            else:
                move_dir = dir.rotated(PI / 2.0 * strafe)
            shoot_timer -= delta
            charging = shoot_timer < 0.5
            if shoot_timer <= 0.0:
                _shoot(dir, 270.0, 10)
                shoot_timer = rand_range(2.0, 2.8)
                charging = false
        face_left = dir.x < 0.0
        var v = move_dir * speed + knock
        if kind == "charger":
            ct -= delta
            if cstate == "idle":
                cooldown -= delta
                if cooldown <= 0.0 and to_t.length() < 440.0:
                    cstate = "windup"
                    ct = 0.6
                    cdir = dir
            elif cstate == "windup":
                v = knock
                charging = true
                if ct <= 0.0:
                    cstate = "dash"
                    ct = 0.45
                    charging = false
            elif cstate == "dash":
                v = cdir * 600.0 + knock
                if ct <= 0.0:
                    cstate = "idle"
                    cooldown = rand_range(2.0, 3.2)
        knock = knock.move_toward(Vector2.ZERO, 900.0 * delta)
        move_and_slide(v)
        tilt = lerp(tilt, clamp(v.x / 260.0, -0.2, 0.2), 0.2)
        if to_t.length() < radius + target.RADIUS + 2.0 and touch_cooldown <= 0.0:
            target.take_damage(contact_damage, global_position)
            touch_cooldown = 0.9
    update()

func _shoot(dir, spd, dmg):
    var p = ProjectileScript.new()
    p.position = global_position + dir * (radius + 8.0) + Vector2(0, -radius * 0.6)
    p.vel = dir * spd
    p.damage = dmg
    p.target = target
    p.color = color
    get_parent().add_child(p)
    Sfx.play("shoot", -8.0)

func take_hit(amount, dir, crit = false):
    if dead or spawning:
        return
    hp -= amount
    knock = dir * (240.0 if kind == "brute" else 420.0)
    flash = 0.1
    FX.shake(3.0)
    if crit:
        FX.popup(global_position, str(int(round(amount))) + "!", Color(1.0, 0.55, 0.2), 26)
    else:
        FX.popup(global_position, int(round(amount)), Color(1.0, 0.92, 0.5), 18)
    FX.burst(global_position, color, 6, 120.0)
    Sfx.play("hit", -3.0)
    if hp <= 0:
        _die()

func _die():
    dead = true
    remove_from_group("enemies")
    FX.burst(global_position, color, 24, 180.0)
    FX.shake(4.0)
    Sfx.play("kill", -2.0)
    emit_signal("died")
    queue_free()

func _draw():
    var anchor = Vector2(0, radius * 0.85)
    var sc = Art.SCALE
    if spawning:
        var k = clamp(spawn_left / spawn_total, 0.0, 1.0)
        draw_arc(Vector2.ZERO, radius + 4.0 + 16.0 * k, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.9 - 0.5 * k), 2.0)
        Art.draw(self, Art.frame_name(visual + "_idle_anim", clock, 6.0), anchor, sc, face_left, Color(tint.r, tint.g, tint.b, 0.55 * (1.0 - k)), "bottom", Vector2(1.0 - 0.35 * k, 1.0 - 0.35 * k))
        return
    Art.shadow(self, anchor, radius * 1.1)
    var mod = tint
    if flash > 0.0:
        mod = Color(2.6, 2.6, 2.6)
    if kind == "charger" and cstate == "windup":
        draw_line(Vector2.ZERO, cdir * 300.0, Color(1.0, 0.4, 0.2, 0.6), 4.0)
        mod = Color(tint.r * 1.5, tint.g * 0.8, tint.b * 0.7)
    var fname = Art.frame_name(visual + "_run_anim", clock, 8.0)
    var hop = -abs(sin(clock * 9.0)) * 3.0
    var st = Vector2(1.0 + 0.04 * sin(clock * 18.0), 1.0 - 0.04 * sin(clock * 18.0))
    # Soft glow so they stand out from the floor and feel alive
    draw_circle(Vector2(0, -radius * 0.5), radius * 2.1, Color(color.r, color.g, color.b, 0.06))
    draw_circle(Vector2(0, -radius * 0.5), radius * 1.4, Color(color.r, color.g, color.b, 0.09))
    draw_set_transform(anchor, tilt, Vector2(1, 1))
    var drew = Art.draw(self, fname, Vector2(0, hop), sc, face_left, mod, "bottom", st)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 1))
    if not drew:
        draw_circle(Vector2.ZERO, radius, color)
    if kind == "wisp" and charging:
        draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 20, Color(0.7, 1.0, 1.0, 0.9), 2.5)
        draw_circle(Vector2(0, -radius), 6.0, Color(0.5, 1.0, 1.0, 0.5))
