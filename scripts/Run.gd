extends Node2D
# A run through Line One: five rooms (two fights, an elite, a shrine, the boss).
# Clear a room, then pick a door. Rewards: Gifts, Echoes, or Mending.

const PlayerScript = preload("res://scripts/Player.gd")
const EnemyScript = preload("res://scripts/Enemy.gd")
const BossScript = preload("res://scripts/Boss.gd")
const GiftsScript = preload("res://scripts/Gifts.gd")
const DoorScript = preload("res://scripts/Door.gd")
const DecoScript = preload("res://scripts/Deco.gd")
const CardUIScript = preload("res://scripts/CardUI.gd")
const PauseScript = preload("res://scripts/PauseMenu.gd")

const TILE = 48
const COLS = 34
const ROWS = 20
const ARENA = Rect2(0, 0, 1632, 960)
const PLAY = Rect2(48, 96, 1536, 816)
const ROOM_PLAN = ["combat", "combat", "elite", "shrine", "boss"]
# Line data. Colors are [r, g, b]. To add a new Line, add an entry here and open it in Game.line_open().
const LINES = {
    "sunken": {
        "name": "The Sunken Hall", "theme": "sunken", "boss": "warden", "boss_name": "THE JACKAL WARDEN",
        "rooms": ["Flooded Antechamber", "Hall of Reeds", "Court of the Weighed", "Shrine of Scales", "The Warden's Hall"],
        "enemies": [[["husk", 5]], [["husk", 5], ["wisp", 2]], [["brute", 2], ["husk", 4], ["wisp", 2]], [], [["warden", 1]]],
        "hp_mult": 1.0, "reward_mult": 1.0, "music": "run", "snow": false,
        "floor": [1.0, 1.0, 1.0], "ambient": [0.62, 0.65, 0.82], "banner": "wall_banner_red", "rune": [0.95, 0.75, 0.3],
        "shrine_title": "THE SHRINE OF SCALES", "shrine": ["Scale of Greed", "Scale of Blood", "Scale of Mercy"],
        "reck_key": "warden", "reck_title": "THE JACKAL WARDEN KNEELS", "reck_line": "Oru: \"Its scales are broken. Choose, Keeper.\""
    },
    "rime": {
        "name": "The Rime Road", "theme": "rime", "boss": "jarl", "boss_name": "THE FROST JARL",
        "rooms": ["Frozen Gate", "Hall of Howling Winds", "Court of the Frost Wolves", "Shrine of the Norns", "The Jarl's Longhall"],
        "enemies": [[["husk", 6], ["charger", 1]], [["husk", 5], ["wisp", 3], ["charger", 2]], [["brute", 3], ["wisp", 2], ["charger", 2], ["husk", 3]], [], [["jarl", 1]]],
        "hp_mult": 1.35, "reward_mult": 1.5, "music": "rime", "snow": true,
        "floor": [0.82, 0.94, 1.25], "ambient": [0.6, 0.7, 0.95], "banner": "wall_banner_blue", "rune": [0.6, 0.85, 1.0],
        "shrine_title": "THE SHRINE OF THE NORNS", "shrine": ["Thread of Greed", "Thread of Blood", "Thread of Mercy"],
        "reck_key": "jarl", "reck_title": "THE FROST JARL KNEELS", "reck_line": "Oru: \"Even the cold must end somewhere. Choose, Keeper.\""
    }
}
# Layout pieces: [kind, column, row] in tiles. A "column" is 1x3 tiles tall, a "crate" is 1x1.
const LAYOUTS = [
    [["column", 7, 6], ["column", 26, 6], ["column", 7, 12], ["column", 26, 12]],
    [["column", 16, 8], ["crate", 8, 6], ["crate", 9, 6], ["crate", 24, 13], ["crate", 25, 13], ["crate", 8, 14], ["crate", 25, 5]],
    [["crate", 10, 9], ["crate", 11, 9], ["crate", 22, 9], ["crate", 23, 9], ["crate", 16, 6], ["crate", 17, 13], ["crate", 6, 14], ["crate", 27, 5]],
    [["column", 10, 9], ["column", 23, 9]],
    [["column", 6, 8], ["column", 27, 8], ["crate", 14, 14], ["crate", 19, 5]]
]
const REWARD_NAMES = {"gift": "Gift", "echoes": "Echoes", "heal": "Mending"}
const DEATH_LINES = [
    "Oru: \"Again. Death is only a door, Keeper.\"",
    "Oru: \"You are still warm. Get up.\"",
    "Oru: \"The gods are watching. Do not disappoint them.\"",
    "Oru: \"Every death teaches. Most of it is pain.\""
]

var L = {}
var dust = null
var pillars = []
var pillar_kinds = []
var deco = null
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
    L = LINES.get(Game.selected_line, LINES["sunken"])
    Sfx.music(L["music"])
    Game.run_started()
    var mod = CanvasModulate.new()
    mod.color = Color(L["ambient"][0], L["ambient"][1], L["ambient"][2])
    add_child(mod)
    wall_root = Node2D.new()
    add_child(wall_root)
    _build_dust()
    deco = DecoScript.new()
    add_child(deco)
    player = PlayerScript.new()
    player.position = Vector2(816, 860)
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
    pillars = []
    pillar_kinds = []
    for piece in LAYOUTS[i]:
        var h = TILE * 3 if piece[0] == "column" else TILE
        pillars.append(Rect2(piece[1] * TILE, piece[2] * TILE, TILE, h))
        pillar_kinds.append(piece[0])
    for c in wall_root.get_children():
        c.queue_free()
    _wall(Rect2(-64, -64, ARENA.size.x + 128, 64 + 96))
    _wall(Rect2(-64, 912, ARENA.size.x + 128, 112))
    _wall(Rect2(-64, 0, 64 + 48, ARENA.size.y))
    _wall(Rect2(ARENA.size.x - 48, 0, 112, ARENA.size.y))
    for r in pillars:
        _wall(r)
    for d in doors:
        d.queue_free()
    doors = []
    _clear_hazards()
    for e in get_tree().get_nodes_in_group("enemies"):
        e.queue_free()
    alive_enemies = 0
    player.global_position = Vector2(816, 860)
    player.velocity = Vector2.ZERO
    _set_deco()
    player.can_attack = false
    state = "intro"
    wave_timer = 1.0
    update()
    _update_labels()
    if room_type == "boss":
        _show_message(L["rooms"][i] + "\n" + L["boss_name"], 2.2)
    else:
        _show_message("%s\nRoom %d / %d: %s" % [L["name"], i + 1, ROOM_PLAN.size(), L["rooms"][i]], 2.0)
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
    if L["snow"]:
        d.amount = 90
        d.gravity = Vector2(-10, 40)
        d.initial_velocity = 12.0
        d.scale_amount = 3.0
        d.color = Color(0.9, 0.97, 1.0, 0.7)
    dust = d
    add_child(d)

func _set_deco():
    var blue = room_type != "boss" or L["boss"] == "jarl"
    var mid = "wall_fountain_mid_blue_anim" if blue else "wall_fountain_mid_red_anim"
    var basin = "wall_fountain_basin_blue_anim" if blue else "wall_fountain_basin_red_anim"
    var items = []
    for c in [12, 21]:
        items.append({"name": "wall_fountain_top", "pos": Vector2(c * TILE, 0), "anchor": "topleft"})
        items.append({"name": mid, "pos": Vector2(c * TILE, TILE), "anchor": "topleft", "fps": 5.0})
        items.append({"name": basin, "pos": Vector2(c * TILE, 2 * TILE), "anchor": "topleft", "fps": 5.0})
    deco.items = items

func _draw():
    var base = Color(L["floor"][0], L["floor"][1], L["floor"][2])
    var tint = base
    var banner = L["banner"]
    if room_type == "elite":
        tint = Color(base.r * 1.0, base.g * 0.88, base.b * 1.08)
        banner = "wall_banner_green"
    elif room_type == "shrine":
        tint = Color(base.r * 0.9, base.g * 0.96, base.b * 1.1)
        banner = "wall_banner_blue"
    elif room_type == "boss":
        tint = Color(base.r * 1.1, base.g * 0.86, base.b * 0.8) if L["boss"] == "warden" else Color(base.r * 0.85, base.g * 0.95, base.b * 1.15)
        banner = "wall_banner_yellow" if L["boss"] == "warden" else "wall_banner_blue"
    var rng = RandomNumberGenerator.new()
    rng.seed = 777 + room_index * 13
    # Dark stone behind the walls
    draw_rect(ARENA, Color(0.1, 0.09, 0.13))
    for r in range(ROWS):
        for c in range(COLS):
            var rect = Rect2(c * TILE, r * TILE, TILE, TILE)
            if r == 0:
                Art.tile(self, "wall_top_mid", rect, tint)
            elif r == 1:
                Art.tile(self, "wall_mid", rect, tint)
            elif r == ROWS - 1 or c == 0 or c == COLS - 1:
                pass
            else:
                var roll = rng.randf()
                var name = "floor_1"
                if roll > 0.97:
                    name = "floor_6"
                elif roll > 0.93:
                    name = "floor_4"
                elif roll > 0.84:
                    name = "floor_5"
                elif roll > 0.74:
                    name = "floor_3"
                elif roll > 0.62:
                    name = "floor_2"
                Art.tile(self, name, rect, tint)
    # Soft edge where the floor meets the border walls
    draw_rect(Rect2(PLAY.position.x, PLAY.end.y - 6, PLAY.size.x, 6), Color(0, 0, 0, 0.35))
    draw_rect(Rect2(PLAY.position.x, PLAY.position.y, 6, PLAY.size.y), Color(0, 0, 0, 0.35))
    draw_rect(Rect2(PLAY.end.x - 6, PLAY.position.y, 6, PLAY.size.y), Color(0, 0, 0, 0.35))
    for c in [4, 8, 25, 29]:
        Art.tile(self, banner, Rect2(c * TILE, TILE, TILE, TILE))
    # Faint rune circle in the middle of the floor
    var cen = Vector2(816, 520)
    var rc = L["rune"]
    var gold = Color(rc[0], rc[1], rc[2], 0.32)
    draw_arc(cen, 210.0, 0.0, TAU, 64, gold, 3.0)
    draw_arc(cen, 150.0, 0.0, TAU, 64, Color(rc[0], rc[1], rc[2], 0.2), 2.0)
    draw_arc(cen, 90.0, 0.0, TAU, 48, gold, 3.0)
    for i in range(8):
        var ang = TAU * i / 8.0
        draw_line(cen + Vector2.RIGHT.rotated(ang) * 90.0, cen + Vector2.RIGHT.rotated(ang) * 210.0, Color(rc[0], rc[1], rc[2], 0.18), 2.0)
    # Columns and crates
    for k in range(pillars.size()):
        var r = pillars[k]
        draw_rect(Rect2(r.position + Vector2(8, r.size.y - 14), Vector2(r.size.x, 22)), Color(0, 0, 0, 0.3))
        if pillar_kinds[k] == "column":
            Art.tile(self, "column_top", Rect2(r.position.x, r.position.y, TILE, TILE), tint)
            Art.tile(self, "column_mid", Rect2(r.position.x, r.position.y + TILE, TILE, TILE), tint)
            Art.tile(self, "column_base", Rect2(r.position.x, r.position.y + 2 * TILE, TILE, TILE), tint)
        else:
            Art.tile(self, "crate", Rect2(r.position.x, r.position.y - 18, TILE, 66), tint)

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
    var scale = (1.0 + 0.08 * room_index) * L["hp_mult"]
    for group in L["enemies"][room_index]:
        for i in range(group[1]):
            _spawn_enemy(group[0], scale)

func _spawn_enemy(kind, scale = 1.0):
    var e = null
    if kind == "warden" or kind == "jarl":
        e = BossScript.new()
        e.boss_kind = kind
        e.position = Vector2(816, 290)
        e.connect("hp_changed", self, "_on_boss_hp")
        e.connect("summon_request", self, "_on_summon")
        e.connect("died", self, "_on_boss_died")
        boss_bg.visible = true
        boss_fill.visible = true
        boss_label.visible = true
        boss_label.text = L["boss_name"]
        boss_fill.rect_size.x = 594.0
        Sfx.play("boss")
    else:
        e = EnemyScript.new()
        e.position = _random_spawn()
        e.hp_mult = scale
        e.theme = L["theme"]
        e.connect("died", self, "_on_enemy_died", [kind])
    e.setup(kind, player)
    alive_enemies += 1
    add_child(e)

func _random_spawn():
    for i in range(30):
        var p = Vector2(rand_range(PLAY.position.x + 50, PLAY.end.x - 50), rand_range(PLAY.position.y + 60, PLAY.end.y - 50))
        var blocked = false
        for r in pillars:
            if r.grow(40).has_point(p):
                blocked = true
        if not blocked and p.distance_to(player.global_position) > 350.0:
            return p
    return Vector2(150, 200)

func _on_summon(kind, count):
    for i in range(count):
        _spawn_enemy(kind, 1.0)

func _echo_for(kind):
    var base = 3
    if kind == "wisp":
        base = 4
    elif kind == "charger":
        base = 5
    elif kind == "brute":
        base = 8
    elif kind == "warden":
        base = 60
    elif kind == "jarl":
        base = 90
    return int(round(base * Game.echo_mult() * L["reward_mult"]))

func _xp_for(kind):
    var base = 5
    if kind == "wisp":
        base = 7
    elif kind == "charger":
        base = 8
    elif kind == "brute":
        base = 14
    elif kind == "warden":
        base = 100
    elif kind == "jarl":
        base = 140
    return int(round(base * L["reward_mult"]))

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
    run_echoes += _echo_for(L["boss"])
    run_xp += _xp_for(L["boss"])
    rooms_cleared += 1
    state = "reckoning"
    boss_bg.visible = false
    boss_fill.visible = false
    boss_label.visible = false
    _clear_hazards()
    for e in get_tree().get_nodes_in_group("enemies"):
        e._die()
    _update_labels()
    _show_cards("reckon", L["reck_title"], L["reck_line"], _reck_options())

func _reck_options():
    if L["boss"] == "jarl":
        return [
            {"name": "Restore", "tag": "Mercy", "tag_color": Color(0.5, 1.0, 0.7), "border": Color(0.4, 0.9, 0.6),
             "desc": "Rekindle the Jarl's hearth fire.\nYou gain +40 max HP and heal fully for the rest of this run."},
            {"name": "Bind", "tag": "Power", "tag_color": Color(0.8, 0.5, 1.0), "border": Color(0.7, 0.4, 0.95),
             "desc": "Bind the Jarl's frost to your blade.\nYou gain +35% attack damage but lose 25 max HP."},
            {"name": "Release", "tag": "Freedom", "tag_color": Color(0.5, 0.8, 1.0), "border": Color(0.4, 0.7, 1.0),
             "desc": "Let the Jarl fade into the snow.\nYou move 20% faster and gain +15% critical hit chance."}]
    return [
        {"name": "Restore", "tag": "Mercy", "tag_color": Color(0.5, 1.0, 0.7), "border": Color(0.4, 0.9, 0.6),
         "desc": "Heal the Warden and balance its scales.\nYou gain +30 max HP and heal fully for the rest of this run."},
        {"name": "Bind", "tag": "Power", "tag_color": Color(0.8, 0.5, 1.0), "border": Color(0.7, 0.4, 0.95),
         "desc": "Take the Warden's power for yourself.\nYou gain +30% attack damage but lose 20 max HP."},
        {"name": "Release", "tag": "Freedom", "tag_color": Color(0.5, 0.8, 1.0), "border": Color(0.4, 0.7, 1.0),
         "desc": "Let the Warden die in peace.\nYou move 20% faster and your dash recharges 40% faster."}]

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
        var xs = [700, 932]
        for i in range(2):
            var d = DoorScript.new()
            d.reward = rewards[i]
            d.label_text = L["rooms"][nxt] + "\n" + ("Elite: " if t == "elite" else "") + REWARD_NAMES[rewards[i]]
            d.position = Vector2(xs[i], 128)
            add_child(d)
            doors.append(d)
    else:
        var d2 = DoorScript.new()
        d2.reward = "shrine" if t == "shrine" else "boss"
        d2.label_text = L["rooms"][nxt]
        d2.position = Vector2(816, 128)
        add_child(d2)
        doors.append(d2)
    Sfx.play("door")
    _show_message("The doors open.\nChoose your path.", 2.0)

func _take_door(d):
    state = "transition"
    Sfx.play("door")
    var rw = d.reward
    var next_room = room_index + 1
    if next_room >= ROOM_PLAN.size():
        state = "ended"
        return
    var tw = Tween.new()
    fade.add_child(tw)
    tw.interpolate_property(fade, "color:a", 0.0, 1.0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tw.start()
    yield(tw, "tween_all_completed")
    tw.queue_free()
    if run_over or not is_inside_tree():
        return
    _enter_room(next_room, rw)

func _open_shrine():
    state = "shrine"
    var opts = [
        {"name": L["shrine"][0], "tag": "Bargain", "tag_color": Color(1.0, 0.8, 0.3), "border": Color(1.0, 0.75, 0.25),
         "desc": "Pay 30 HP now.\nGain 150 Echoes (more with Echo Magnet)."},
        {"name": L["shrine"][1], "tag": "Bargain", "tag_color": Color(1.0, 0.4, 0.4), "border": Color(0.95, 0.3, 0.3),
         "desc": "Lose 20 max HP.\nGain +25% attack damage for the rest of this run."},
        {"name": L["shrine"][2], "tag": "Rest", "tag_color": Color(0.5, 1.0, 0.7), "border": Color(0.4, 0.9, 0.6),
         "desc": "Take nothing.\nHeal 30% of your max HP."}]
    _show_cards("shrine", L["shrine_title"], "Oru: \"Every bargain has a price. Choose which you can pay.\"", opts)

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
    var key = L["reck_key"]
    Game.data[key] = id
    if key == "warden":
        Game.data["warden_hist"][id] += 1
    var text = ""
    if L["boss"] == "jarl":
        if id == "restore":
            player.max_hp += 40
            player.hp = player.max_hp
            text = "You rekindled the Jarl's hearth.\nWarmth spreads through the frozen halls."
        elif id == "bind":
            player.gift_dmg += 0.35
            player.max_hp = int(max(30, player.max_hp - 25))
            player.hp = int(min(player.hp, player.max_hp))
            text = "You bound the Jarl's frost to your blade.\nIt hums with a cold, patient hunger."
        else:
            player.speed *= 1.2
            player.crit_chance = min(0.8, player.crit_chance + 0.15)
            text = "You released the Jarl.\nThe snow takes him, and the wind goes quiet."
    else:
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
    run_xp += int(round(150 * L["reward_mult"]))
    run_echoes += int(round(100 * Game.echo_mult() * L["reward_mult"]))
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
    Game.finish_run(result, rooms_cleared, run_kills, run_echoes, run_xp, Game.selected_line)
    Game.goto("res://scenes/Hub.tscn")
