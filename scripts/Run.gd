extends Node2D
# A run through Line One: five rooms (two fights, an elite, a shrine, the boss).
# Clear a room, then pick a door. Rewards: Gifts, Echoes, or Mending.

const PlayerScript = preload("res://scripts/Player.gd")
const EnemyScript = preload("res://scripts/Enemy.gd")
const BossScript = preload("res://scripts/Boss.gd")
const GiftsScript = preload("res://scripts/Gifts.gd")
const DoorScript = preload("res://scripts/Door.gd")
const CardUIScript = preload("res://scripts/CardUI.gd")
const PauseScript = preload("res://scripts/PauseMenu.gd")

const ARENA = Rect2(0, 0, 1600, 900)
const ROOM_PLAN = ["combat", "combat", "elite", "shrine", "boss"]
const ROOM_NAMES = ["Flooded Antechamber", "Hall of Reeds", "Court of the Weighed", "Shrine of Scales", "The Warden's Hall"]
const ROOM_ENEMIES = [
    [["husk", 5]],
    [["husk", 5], ["wisp", 2]],
    [["brute", 2], ["husk", 4], ["wisp", 2]],
    [],
    [["warden", 1]]
]
const LAYOUTS = [
    [Rect2(380, 250, 80, 80), Rect2(1140, 250, 80, 80), Rect2(380, 570, 80, 80), Rect2(1140, 570, 80, 80)],
    [Rect2(760, 380, 80, 140), Rect2(360, 300, 80, 80), Rect2(1160, 300, 80, 80)],
    [Rect2(300, 250, 70, 70), Rect2(765, 250, 70, 70), Rect2(1230, 250, 70, 70), Rect2(300, 560, 70, 70), Rect2(765, 560, 70, 70), Rect2(1230, 560, 70, 70)],
    [Rect2(500, 450, 60, 60), Rect2(1040, 450, 60, 60)],
    [Rect2(300, 350, 70, 70), Rect2(1230, 350, 70, 70)]
]
const REWARD_NAMES = {"gift": "Gift", "echoes": "Echoes", "heal": "Mending"}
const DEATH_LINES = [
    "Oru: \"Again. Death is only a door, Keeper.\"",
    "Oru: \"You are still warm. Get up.\"",
    "Oru: \"The gods are watching. Do not disappoint them.\"",
    "Oru: \"Every death teaches. Most of it is pain.\""
]

var pillars = []
var player = null
var wall_root = null
var doors = []
var room_index = -1
var room_type = ""
var room_reward = "gift"
var state = "intro"   # intro, fighting, choosing, doors, shrine, reckoning, transition, ended, dead
var wave_timer = 1.0
var alive_enemies = 0
var message_time = 0.0
var gifts_taken = []
var run_kills = 0
var run_echoes = 0
var run_xp = 0
var rooms_cleared = 0
var card = null
var card_mode = ""
var card_options = []
var run_over = false
var boss_spawned = false

var ui_layer = null
var hp_fill = null
var hp_label = null
var dash_fill = null
var room_label = null
var stat_label = null
var gifts_label = null
var message_label = null
var boss_bg = null
var boss_fill = null
var boss_label = null
var fade = null
var pause_menu = null

func _ready():
    randomize()
    FX.reset()
    FX.world = self
    Sfx.music("run")
    Game.run_started()
    var mod = CanvasModulate.new()
    mod.color = Color(0.5, 0.55, 0.72)
    add_child(mod)
    wall_root = Node2D.new()
    add_child(wall_root)
    _build_dust()
    player = PlayerScript.new()
    player.position = Vector2(800, 780)
    add_child(player)
    player.setup_from_profile()
    player.set_camera_limits(ARENA)
    player.connect("hp_changed", self, "_on_hp_changed")
    player.connect("died", self, "_on_player_died")
    _build_hud()
    pause_menu = PauseScript.new()
    pause_menu.mode = "run"
    add_child(pause_menu)
    pause_menu.connect("abandon", self, "_on_abandon")
    _on_hp_changed(player.hp, player.max_hp)
    _enter_room(0, "gift")

# ---------- world ----------

func _enter_room(i, reward):
    room_index = i
    room_type = ROOM_PLAN[i]
    room_reward = reward
    pillars = LAYOUTS[i]
    for c in wall_root.get_children():
        c.queue_free()
    _wall(Rect2(-64, -64, ARENA.size.x + 128, 64))
    _wall(Rect2(-64, ARENA.size.y, ARENA.size.x + 128, 64))
    _wall(Rect2(-64, 0, 64, ARENA.size.y))
    _wall(Rect2(ARENA.size.x, 0, 64, ARENA.size.y))
    for r in pillars:
        _wall(r)
    for d in doors:
        d.queue_free()
    doors = []
    _clear_hazards()
    for e in get_tree().get_nodes_in_group("enemies"):
        e.queue_free()
    alive_enemies = 0
    player.global_position = Vector2(800, 780)
    player.velocity = Vector2.ZERO
    player.can_attack = false
    state = "intro"
    wave_timer = 1.0
    update()
    _update_labels()
    if room_type == "boss":
        _show_message(ROOM_NAMES[i] + "\nTHE JACKAL WARDEN", 2.2)
    else:
        _show_message("Room %d / %d\n%s" % [i + 1, ROOM_PLAN.size(), ROOM_NAMES[i]], 2.0)
    fade.color = Color(0, 0, 0, 1)
    var tw = Tween.new()
    fade.add_child(tw)
    tw.interpolate_property(fade, "color:a", 1.0, 0.0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tw.connect("tween_all_completed", tw, "queue_free")
    tw.start()

func _wall(rect):
    var body = StaticBody2D.new()
    body.collision_layer = 1
    body.position = rect.position + rect.size / 2.0
    var cs = CollisionShape2D.new()
    var sh = RectangleShape2D.new()
    sh.extents = rect.size / 2.0
    cs.shape = sh
    body.add_child(cs)
    wall_root.add_child(body)

func _build_dust():
    var d = CPUParticles2D.new()
    d.position = ARENA.size / 2.0
    d.amount = 45
    d.lifetime = 9.0
    d.preprocess = 9.0
    d.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    d.emission_rect_extents = ARENA.size / 2.0
    d.gravity = Vector2(0, -8)
    d.initial_velocity = 6.0
    d.spread = 180.0
    d.scale_amount = 2.5
    d.color = Color(1.0, 0.9, 0.6, 0.5)
    add_child(d)

func _ankh(pos, size, col):
    draw_arc(pos + Vector2(0, -size * 0.95), size * 0.45, 0.0, TAU, 16, col, 2.0)
    draw_line(pos + Vector2(0, -size * 0.5), pos + Vector2(0, size), col, 2.0)
    draw_line(pos + Vector2(-size * 0.6, 0), pos + Vector2(size * 0.6, 0), col, 2.0)

func _draw():
    var tint = Color(0.0, 0.0, 0.0)
    if room_type == "elite":
        tint = Color(0.05, -0.02, 0.06)
    elif room_type == "shrine":
        tint = Color(0.04, 0.0, 0.07)
    elif room_type == "boss":
        tint = Color(0.07, -0.01, -0.03)
    for ty in range(9):
        for tx in range(16):
            var shade = 0.0 if (tx + ty) % 2 == 0 else 0.035
            draw_rect(Rect2(tx * 100, ty * 100, 100, 100), Color(0.43 + shade + tint.r, 0.41 + shade + tint.g, 0.5 + shade + tint.b))
    var rng = RandomNumberGenerator.new()
    rng.seed = 4242 + room_index
    for i in range(40):
        var a = Vector2(rng.randf_range(20, ARENA.size.x - 20), rng.randf_range(20, ARENA.size.y - 20))
        var b = a + Vector2(rng.randf_range(-50, 50), rng.randf_range(-50, 50))
        draw_line(a, b, Color(0.2, 0.19, 0.25, 0.6), 1.5)
    for x in range(0, 1601, 100):
        draw_line(Vector2(x, 0), Vector2(x, ARENA.size.y), Color(0.25, 0.24, 0.32, 0.7), 1.0)
    for y in range(0, 901, 100):
        draw_line(Vector2(0, y), Vector2(ARENA.size.x, y), Color(0.25, 0.24, 0.32, 0.7), 1.0)
    var c = ARENA.size / 2.0
    var gold = Color(0.9, 0.7, 0.25, 0.55)
    draw_arc(c, 200.0, 0.0, TAU, 64, gold, 3.0)
    draw_arc(c, 150.0, 0.0, TAU, 64, Color(0.9, 0.7, 0.25, 0.35), 2.0)
    draw_arc(c, 90.0, 0.0, TAU, 48, gold, 3.0)
    for i in range(8):
        var ang = TAU * i / 8.0
        draw_line(c + Vector2.RIGHT.rotated(ang) * 90.0, c + Vector2.RIGHT.rotated(ang) * 200.0, Color(0.9, 0.7, 0.25, 0.3), 2.0)
    for i in range(1, 10):
        _ankh(Vector2(i * 160, 24), 12.0, Color(0.85, 0.68, 0.3, 0.55))
        _ankh(Vector2(i * 160, ARENA.size.y - 30), 12.0, Color(0.85, 0.68, 0.3, 0.55))
    for r in pillars:
        draw_rect(Rect2(r.position + Vector2(6, 6), r.size), Color(0, 0, 0, 0.35))
        draw_rect(r, Color(0.2, 0.19, 0.27))
        draw_rect(r.grow(-8), Color(0.28, 0.26, 0.36))
        draw_rect(r, Color(0.8, 0.62, 0.25), false, 2.0)
        _ankh(r.position + r.size / 2.0 + Vector2(0, 2), 10.0, Color(0.85, 0.68, 0.3, 0.8))
    draw_rect(ARENA, Color(0.8, 0.62, 0.2), false, 6.0)

# ---------- hud ----------

func _build_hud():
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    FX.add_vignette(ui_layer)
    var bg = ColorRect.new()
    bg.rect_position = Vector2(24, 24)
    bg.rect_size = Vector2(266, 28)
    bg.color = Color(0, 0, 0, 0.65)
    ui_layer.add_child(bg)
    hp_fill = ColorRect.new()
    hp_fill.rect_position = Vector2(27, 27)
    hp_fill.rect_size = Vector2(260, 22)
    hp_fill.color = Color(0.85, 0.2, 0.3)
    ui_layer.add_child(hp_fill)
    hp_label = FX.label(ui_layer, Vector2(34, 28), "", 16)
    var dbg = ColorRect.new()
    dbg.rect_position = Vector2(24, 58)
    dbg.rect_size = Vector2(146, 10)
    dbg.color = Color(0, 0, 0, 0.65)
    ui_layer.add_child(dbg)
    dash_fill = ColorRect.new()
    dash_fill.rect_position = Vector2(27, 61)
    dash_fill.rect_size = Vector2(140, 4)
    dash_fill.color = Color(0.5, 0.9, 1.0)
    ui_layer.add_child(dash_fill)
    room_label = FX.label(ui_layer, Vector2(24, 76), "", 20, Color(0.95, 0.8, 0.4), true)
    stat_label = FX.label(ui_layer, Vector2(24, 106), "", 16, Color(0.8, 0.95, 1.0))
    gifts_label = FX.label(ui_layer, Vector2(24, 500), "", 14, Color(0.95, 0.85, 0.5))
    var hint = FX.label(ui_layer, Vector2(24, 692), "WASD move | SPACE dash | Click/J attack (swats bolts) | Esc pause", 14, Color(1, 1, 1, 0.6))
    message_label = FX.label(ui_layer, Vector2(0, 230), "", 30, Color(1, 0.95, 0.8), true)
    message_label.rect_size = Vector2(1280, 160)
    message_label.align = Label.ALIGN_CENTER
    boss_bg = ColorRect.new()
    boss_bg.rect_position = Vector2(340, 24)
    boss_bg.rect_size = Vector2(600, 20)
    boss_bg.color = Color(0, 0, 0, 0.7)
    boss_bg.visible = false
    ui_layer.add_child(boss_bg)
    boss_fill = ColorRect.new()
    boss_fill.rect_position = Vector2(343, 27)
    boss_fill.rect_size = Vector2(594, 14)
    boss_fill.color = Color(0.9, 0.7, 0.2)
    boss_fill.visible = false
    ui_layer.add_child(boss_fill)
    boss_label = FX.label(ui_layer, Vector2(340, 48), "THE JACKAL WARDEN", 16, Color(0.95, 0.8, 0.4), true)
    boss_label.rect_size = Vector2(600, 22)
    boss_label.align = Label.ALIGN_CENTER
    boss_label.visible = false
    fade = ColorRect.new()
    fade.rect_size = Vector2(1280, 720)
    fade.color = Color(0, 0, 0, 1)
    fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_layer.add_child(fade)

func _show_message(text, seconds):
    message_label.text = text
    message_label.visible = true
    message_time = seconds

func _on_hp_changed(hp, max_hp):
    hp_fill.rect_size.x = 260.0 * clamp(float(hp) / float(max_hp), 0.0, 1.0)
    hp_label.text = "HP  %d / %d" % [max(hp, 0), max_hp]

func _update_labels():
    room_label.text = "Room %d / %d" % [room_index + 1, ROOM_PLAN.size()]
    stat_label.text = "Kills %d      Echoes %d" % [run_kills, run_echoes]
    var counts = {}
    var order = []
    for g in gifts_taken:
        var k = g["name"] + " (" + g["tag"] + ")"
        if not counts.has(k):
            counts[k] = 0
            order.append(k)
        counts[k] += 1
    var lines = []
    for k in order:
        lines.append(k if counts[k] == 1 else k + " x" + str(counts[k]))
    var shown = lines.slice(max(0, lines.size() - 8), lines.size() - 1)
    gifts_label.text = "Gifts\n" + PoolStringArray(shown).join("\n") if lines.size() > 0 else ""

# ---------- flow ----------

func _process(delta):
    if Input.is_action_just_pressed("fullscreen"):
        OS.window_fullscreen = not OS.window_fullscreen
    if message_time > 0.0:
        message_time -= delta
        if message_time <= 0.0:
            message_label.visible = false
    if player != null and player.dash_cooldown > 0.0:
        dash_fill.rect_size.x = 140.0 * (1.0 - clamp(player.dash_cooldown_left / player.dash_cooldown, 0.0, 1.0))
    player.can_attack = (state == "fighting")
    if state == "intro":
        wave_timer -= delta
        if wave_timer <= 0.0:
            _start_room()
    elif state == "doors":
        for d in doors:
            if player.global_position.distance_to(d.position) < 42.0:
                _take_door(d)
                break
    elif state == "ended" or state == "dead":
        if Input.is_action_just_pressed("interact") and not run_over:
            _end_run("win" if state == "ended" else "death")

func _start_room():
    if room_type == "shrine":
        _open_shrine()
        return
    state = "fighting"
    var scale = 1.0 + 0.08 * room_index
    for group in ROOM_ENEMIES[room_index]:
        for i in range(group[1]):
            _spawn_enemy(group[0], scale)

func _spawn_enemy(kind, scale = 1.0):
    var e = null
    if kind == "warden":
        e = BossScript.new()
        e.position = Vector2(ARENA.size.x / 2.0, 230)
        e.connect("hp_changed", self, "_on_boss_hp")
        e.connect("summon_request", self, "_on_summon")
        e.connect("died", self, "_on_boss_died")
        boss_bg.visible = true
        boss_fill.visible = true
        boss_label.visible = true
        boss_fill.rect_size.x = 594.0
        Sfx.play("boss")
    else:
        e = EnemyScript.new()
        e.position = _random_spawn()
        e.hp_mult = scale
        e.connect("died", self, "_on_enemy_died", [kind])
    e.setup(kind, player)
    alive_enemies += 1
    add_child(e)

func _random_spawn():
    for i in range(30):
        var p = Vector2(rand_range(90, ARENA.size.x - 90), rand_range(110, ARENA.size.y - 90))
        var blocked = false
        for r in pillars:
            if r.grow(40).has_point(p):
                blocked = true
        if not blocked and p.distance_to(player.global_position) > 350.0:
            return p
    return Vector2(120, 140)

func _on_summon(kind, count):
    for i in range(count):
        _spawn_enemy(kind, 1.0)

func _echo_for(kind):
    var base = 3
    if kind == "wisp":
        base = 4
    elif kind == "brute":
        base = 8
    elif kind == "warden":
        base = 60
    return int(round(base * Game.echo_mult()))

func _xp_for(kind):
    if kind == "wisp":
        return 7
    if kind == "brute":
        return 14
    if kind == "warden":
        return 100
    return 5

func _on_enemy_died(kind):
    alive_enemies -= 1
    run_kills += 1
    run_echoes += _echo_for(kind)
    run_xp += _xp_for(kind)
    player.on_kill()
    _update_labels()
    if alive_enemies <= 0 and state == "fighting":
        _room_cleared()

func _on_boss_hp(hp, max_hp):
    boss_fill.rect_size.x = 594.0 * clamp(float(hp) / float(max_hp), 0.0, 1.0)

func _on_boss_died():
    alive_enemies -= 1
    run_kills += 1
    run_echoes += _echo_for("warden")
    run_xp += _xp_for("warden")
    rooms_cleared += 1
    state = "reckoning"
    boss_bg.visible = false
    boss_fill.visible = false
    boss_label.visible = false
    _clear_hazards()
    for e in get_tree().get_nodes_in_group("enemies"):
        e._die()
    _update_labels()
    var opts = [
        {"name": "Restore", "tag": "Mercy", "tag_color": Color(0.5, 1.0, 0.7), "border": Color(0.4, 0.9, 0.6),
         "desc": "Heal the Warden and balance its scales.\nYou gain +30 max HP and heal fully for the rest of this run."},
        {"name": "Bind", "tag": "Power", "tag_color": Color(0.8, 0.5, 1.0), "border": Color(0.7, 0.4, 0.95),
         "desc": "Take the Warden's power for yourself.\nYou gain +30% attack damage but lose 20 max HP."},
        {"name": "Release", "tag": "Freedom", "tag_color": Color(0.5, 0.8, 1.0), "border": Color(0.4, 0.7, 1.0),
         "desc": "Let the Warden die in peace.\nYou move 20% faster and your dash recharges 40% faster."}]
    _show_cards("reckon", "THE JACKAL WARDEN KNEELS", "Oru: \"Its scales are broken. Choose, Keeper.\"", opts)

func _clear_hazards():
    for p in get_tree().get_nodes_in_group("projectiles"):
        p.queue_free()

func _room_cleared():
    _clear_hazards()
    rooms_cleared += 1
    var xp_room = 20
    run_xp += xp_room
    Sfx.play("pickup")
    _update_labels()
    if room_reward == "gift":
        state = "choosing"
        _show_cards("gift", "A GIFT FROM THE FADING GODS", "Choose one", GiftsScript.random_choices(3))
    elif room_reward == "echoes":
        var amt = int(round((35 + 10 * room_index) * Game.echo_mult()))
        run_echoes += amt
        FX.popup(player.global_position, "+" + str(amt) + " Echoes", Color(0.5, 0.95, 1.0), 24)
        _update_labels()
        _open_doors()
    else:
        player.heal(int(player.max_hp * 0.35))
        _open_doors()

func _open_doors():
    var nxt = room_index + 1
    if nxt >= ROOM_PLAN.size():
        return
    state = "doors"
    var t = ROOM_PLAN[nxt]
    if t == "combat" or t == "elite":
        var rewards = ["gift", "echoes", "heal"]
        rewards.shuffle()
        var xs = [650, 950]
        for i in range(2):
            var d = DoorScript.new()
            d.reward = rewards[i]
            d.label_text = ROOM_NAMES[nxt] + "\n" + ("Elite: " if t == "elite" else "") + REWARD_NAMES[rewards[i]]
            d.position = Vector2(xs[i], 72)
            add_child(d)
            doors.append(d)
    else:
        var d2 = DoorScript.new()
        d2.reward = "shrine" if t == "shrine" else "boss"
        d2.label_text = ROOM_NAMES[nxt]
        d2.position = Vector2(800, 72)
        add_child(d2)
        doors.append(d2)
    Sfx.play("door")
    _show_message("The doors open.\nChoose your path.", 2.0)

func _take_door(d):
    state = "transition"
    Sfx.play("door")
    var rw = d.reward
    var tw = Tween.new()
    fade.add_child(tw)
    tw.interpolate_property(fade, "color:a", 0.0, 1.0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tw.start()
    yield(tw, "tween_all_completed")
    tw.queue_free()
    _enter_room(room_index + 1, rw)

func _open_shrine():
    state = "shrine"
    var opts = [
        {"name": "Scale of Greed", "tag": "Bargain", "tag_color": Color(1.0, 0.8, 0.3), "border": Color(1.0, 0.75, 0.25),
         "desc": "Pay 30 HP now.\nGain 150 Echoes (more with Echo Magnet)."},
        {"name": "Scale of Blood", "tag": "Bargain", "tag_color": Color(1.0, 0.4, 0.4), "border": Color(0.95, 0.3, 0.3),
         "desc": "Lose 20 max HP.\nGain +25% attack damage for the rest of this run."},
        {"name": "Scale of Mercy", "tag": "Rest", "tag_color": Color(0.5, 1.0, 0.7), "border": Color(0.4, 0.9, 0.6),
         "desc": "Take nothing.\nHeal 30% of your max HP."}]
    _show_cards("shrine", "THE SHRINE OF SCALES", "Oru: \"Every bargain has a price. Choose which you can pay.\"", opts)

# ---------- cards ----------

func _show_cards(mode, title, sub, opts):
    card_mode = mode
    card_options = opts
    card = CardUIScript.new()
    ui_layer.add_child(card)
    card.setup(title, sub, opts)
    card.connect("picked", self, "_pick")

func _pick(i):
    if card == null:
        return
    var opt = card_options[i]
    card.queue_free()
    card = null
    Sfx.play("pickup")
    if card_mode == "gift":
        player.apply_gift(opt["id"], opt["mult"])
        gifts_taken.append({"name": opt["name"], "tag": opt["tag"]})
        FX.popup(player.global_position, opt["name"], opt["tag_color"], 22)
        _update_labels()
        _open_doors()
    elif card_mode == "shrine":
        rooms_cleared += 1
        if i == 0:
            player.hp = int(max(1, player.hp - 30))
            run_echoes += int(round(150 * Game.echo_mult()))
            player.emit_signal("hp_changed", player.hp, player.max_hp)
        elif i == 1:
            player.max_hp = int(max(30, player.max_hp - 20))
            player.hp = int(min(player.hp, player.max_hp))
            player.gift_dmg += 0.25
            player.emit_signal("hp_changed", player.hp, player.max_hp)
        else:
            player.heal(int(player.max_hp * 0.3))
        _update_labels()
        _open_doors()
    else:
        _apply_reckoning(i)

func _apply_reckoning(i):
    var id = ["restore", "bind", "release"][i]
    Game.data["warden"] = id
    Game.data["warden_hist"][id] += 1
    var text = ""
    if id == "restore":
        player.max_hp += 30
        player.hp = player.max_hp
        text = "You restored the Warden.\nThe floodwater clears. Something below stirs."
    elif id == "bind":
        player.gift_dmg += 0.30
        player.max_hp = int(max(30, player.max_hp - 20))
        player.hp = int(min(player.hp, player.max_hp))
        text = "You bound the Warden's power.\nIts jackal eyes now burn in yours."
    else:
        player.speed *= 1.2
        player.dash_cooldown *= 0.6
        text = "You released the Warden.\nThe halls fall silent. Nothing here is watching now."
    player.emit_signal("hp_changed", player.hp, player.max_hp)
    state = "ended"
    run_xp += 150
    run_echoes += int(round(100 * Game.echo_mult()))
    _update_labels()
    _show_message(text + "\n\nThe Ledger remembers.\nPress ENTER to return to the Terminus", 99999.0)

# ---------- end of run ----------

func _on_player_died():
    state = "dead"
    _show_message("YOU DIED\n" + DEATH_LINES[randi() % DEATH_LINES.size()] + "\n\nPress ENTER to return to the Terminus", 99999.0)

func _on_abandon():
    if not run_over:
        _end_run("abandon")

func _end_run(result):
    run_over = true
    Game.finish_run(result, rooms_cleared, run_kills, run_echoes, run_xp)
    Game.goto("res://scenes/Hub.tscn")
