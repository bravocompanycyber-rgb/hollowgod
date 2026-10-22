extends Node2D
# The Sunken Hall: three waves, a boss, gifts between waves, and the first Reckoning choice.

const PlayerScript = preload("res://scripts/Player.gd")
const EnemyScript = preload("res://scripts/Enemy.gd")
const BossScript = preload("res://scripts/Boss.gd")
const GiftsScript = preload("res://scripts/Gifts.gd")

const ARENA = Rect2(0, 0, 1600, 900)
# Each wave is a list of [kind, count]
const WAVES = [
	[["husk", 4]],
	[["husk", 6], ["wisp", 2]],
	[["husk", 6], ["brute", 2], ["wisp", 2]],
	[["warden", 1]]
]
const PILLARS = [
	Rect2(380, 250, 80, 80), Rect2(1140, 250, 80, 80),
	Rect2(380, 570, 80, 80), Rect2(1140, 570, 80, 80)
]
const OPENING = {
	"": "Oru: \"Wake up, Keeper. The tunnels are open.\"",
	"restore": "Oru: \"You healed the Warden last time. It remembers.\"",
	"bind": "Oru: \"You wear the Warden's power. It wears you back.\"",
	"release": "Oru: \"The Warden is gone. The halls are quieter. Too quiet.\""
}
const DEATH_LINES = [
	"Oru: \"Again. Death is only a door, Keeper.\"",
	"Oru: \"You are still warm. Get up.\"",
	"Oru: \"The gods are watching. Do not disappoint them.\"",
	"Oru: \"Every death teaches. Most of it is pain.\""
]

var player = null
var wave_index = -1
var alive_enemies = 0
var kills = 0
var wave_timer = 1.5
var state = "countdown"   # countdown, fighting, choosing, reckoning, ended
var message_time = 0.0
var gifts_taken = []

var ui_layer = null
var hp_fill = null
var hp_label = null
var dash_fill = null
var wave_label = null
var gifts_label = null
var message_label = null
var boss_bg = null
var boss_fill = null
var boss_label = null
var card_root = null
var card_options = []
var card_mode = ""

func _ready():
	randomize()
	FX.reset()
	FX.world = self
	Ledger.data["runs"] += 1
	Ledger.save()
	var mod = CanvasModulate.new()
	mod.color = Color(0.5, 0.55, 0.72)
	add_child(mod)
	_build_walls()
	_build_dust()
	player = PlayerScript.new()
	player.position = ARENA.size / 2.0 + Vector2(0, 200)
	add_child(player)
	player.set_camera_limits(ARENA)
	player.connect("hp_changed", self, "_on_hp_changed")
	player.connect("died", self, "_on_player_died")
	_build_hud()
	_on_hp_changed(player.hp, player.max_hp)
	var oru = OPENING[""]
	if OPENING.has(Ledger.data["warden"]):
		oru = OPENING[Ledger.data["warden"]]
	_show_message("HOLLOWGOD\nThe Sunken Hall\n" + oru, 3.5)

# ---------- world ----------

func _build_walls():
	_wall(Rect2(-64, -64, ARENA.size.x + 128, 64))
	_wall(Rect2(-64, ARENA.size.y, ARENA.size.x + 128, 64))
	_wall(Rect2(-64, 0, 64, ARENA.size.y))
	_wall(Rect2(ARENA.size.x, 0, 64, ARENA.size.y))
	for r in PILLARS:
		_wall(r)

func _wall(rect):
	var body = StaticBody2D.new()
	body.collision_layer = 1
	body.position = rect.position + rect.size / 2.0
	var cs = CollisionShape2D.new()
	var sh = RectangleShape2D.new()
	sh.extents = rect.size / 2.0
	cs.shape = sh
	body.add_child(cs)
	add_child(body)

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
	# Stone floor tiles
	for ty in range(9):
		for tx in range(16):
			var shade = 0.0 if (tx + ty) % 2 == 0 else 0.035
			draw_rect(Rect2(tx * 100, ty * 100, 100, 100), Color(0.43 + shade, 0.41 + shade, 0.5 + shade))
	# Cracks (same every time)
	var rng = RandomNumberGenerator.new()
	rng.seed = 4242
	for i in range(40):
		var a = Vector2(rng.randf_range(20, ARENA.size.x - 20), rng.randf_range(20, ARENA.size.y - 20))
		var b = a + Vector2(rng.randf_range(-50, 50), rng.randf_range(-50, 50))
		draw_line(a, b, Color(0.2, 0.19, 0.25, 0.6), 1.5)
	# Tile seams
	for x in range(0, 1601, 100):
		draw_line(Vector2(x, 0), Vector2(x, ARENA.size.y), Color(0.25, 0.24, 0.32, 0.7), 1.0)
	for y in range(0, 901, 100):
		draw_line(Vector2(0, y), Vector2(ARENA.size.x, y), Color(0.25, 0.24, 0.32, 0.7), 1.0)
	# Centre rune circle
	var c = ARENA.size / 2.0
	var gold = Color(0.9, 0.7, 0.25, 0.55)
	draw_arc(c, 200.0, 0.0, TAU, 64, gold, 3.0)
	draw_arc(c, 150.0, 0.0, TAU, 64, Color(0.9, 0.7, 0.25, 0.35), 2.0)
	draw_arc(c, 90.0, 0.0, TAU, 48, gold, 3.0)
	for i in range(8):
		var ang = TAU * i / 8.0
		draw_line(c + Vector2.RIGHT.rotated(ang) * 90.0, c + Vector2.RIGHT.rotated(ang) * 200.0, Color(0.9, 0.7, 0.25, 0.3), 2.0)
	# Ankh carvings along the north and south walls
	for i in range(1, 10):
		_ankh(Vector2(i * 160, 42), 14.0, Color(0.85, 0.68, 0.3, 0.6))
		_ankh(Vector2(i * 160, ARENA.size.y - 42), 14.0, Color(0.85, 0.68, 0.3, 0.6))
	# Pillars
	for r in PILLARS:
		draw_rect(Rect2(r.position + Vector2(6, 6), r.size), Color(0, 0, 0, 0.35))
		draw_rect(r, Color(0.2, 0.19, 0.27))
		draw_rect(r.grow(-8), Color(0.28, 0.26, 0.36))
		draw_rect(r, Color(0.8, 0.62, 0.25), false, 2.0)
		_ankh(r.position + r.size / 2.0 + Vector2(0, 2), 12.0, Color(0.85, 0.68, 0.3, 0.8))
	# Border
	draw_rect(ARENA, Color(0.8, 0.62, 0.2), false, 6.0)

# ---------- hud ----------

func _label(parent, pos, text, scale):
	var l = Label.new()
	l.rect_position = pos
	l.rect_scale = Vector2(scale, scale)
	l.text = text
	l.add_color_override("font_color_shadow", Color(0, 0, 0, 0.9))
	l.add_constant_override("shadow_offset_x", 1)
	l.add_constant_override("shadow_offset_y", 1)
	parent.add_child(l)
	return l

func _build_hud():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var vig = TextureRect.new()
	vig.texture = FX.vignette_texture()
	vig.expand = true
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.rect_size = Vector2(1280, 720)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(vig)
	var bg = ColorRect.new()
	bg.rect_position = Vector2(24, 24)
	bg.rect_size = Vector2(226, 26)
	bg.color = Color(0, 0, 0, 0.65)
	ui_layer.add_child(bg)
	hp_fill = ColorRect.new()
	hp_fill.rect_position = Vector2(27, 27)
	hp_fill.rect_size = Vector2(220, 20)
	hp_fill.color = Color(0.85, 0.2, 0.3)
	ui_layer.add_child(hp_fill)
	hp_label = _label(ui_layer, Vector2(34, 28), "", 1.0)
	var dbg = ColorRect.new()
	dbg.rect_position = Vector2(24, 56)
	dbg.rect_size = Vector2(126, 10)
	dbg.color = Color(0, 0, 0, 0.65)
	ui_layer.add_child(dbg)
	dash_fill = ColorRect.new()
	dash_fill.rect_position = Vector2(27, 59)
	dash_fill.rect_size = Vector2(120, 4)
	dash_fill.color = Color(0.5, 0.9, 1.0)
	ui_layer.add_child(dash_fill)
	wave_label = _label(ui_layer, Vector2(24, 74), "", 1.4)
	wave_label.add_color_override("font_color", Color(0.95, 0.8, 0.4))
	gifts_label = _label(ui_layer, Vector2(24, 655), "", 1.0)
	gifts_label.add_color_override("font_color", Color(0.95, 0.8, 0.4))
	var hint = _label(ui_layer, Vector2(24, 688), "WASD move  |  SPACE dash  |  Click or J attack (also swats bolts)  |  R restart  |  F11 fullscreen", 1.0)
	hint.modulate = Color(1, 1, 1, 0.65)
	message_label = _label(ui_layer, Vector2(0, 250), "", 2.0)
	message_label.rect_size = Vector2(640, 120)
	message_label.align = Label.ALIGN_CENTER
	# Boss bar (hidden until the boss appears)
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
	boss_label = _label(ui_layer, Vector2(340, 46), "THE JACKAL WARDEN", 1.0)
	boss_label.rect_size = Vector2(600, 20)
	boss_label.align = Label.ALIGN_CENTER
	boss_label.add_color_override("font_color", Color(0.95, 0.8, 0.4))
	boss_label.visible = false

func _show_message(text, seconds):
	message_label.text = text
	message_label.visible = true
	message_time = seconds

func _on_hp_changed(hp, max_hp):
	hp_fill.rect_size.x = 220.0 * clamp(float(hp) / float(max_hp), 0.0, 1.0)
	hp_label.text = "HP  %d / %d" % [max(hp, 0), max_hp]

func _update_wave_label():
	if wave_index >= WAVES.size() - 1:
		wave_label.text = "BOSS   Kills %d" % kills
	else:
		wave_label.text = "Wave %d / %d   Kills %d" % [wave_index + 1, WAVES.size() - 1, kills]

func _update_gifts_label():
	if gifts_taken.size() == 0:
		gifts_label.text = ""
	else:
		gifts_label.text = "Gifts: " + PoolStringArray(gifts_taken).join(", ")

# ---------- flow ----------

func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message_label.visible = false
	if card_root != null:
		for i in range(card_options.size()):
			if Input.is_action_just_pressed("pick%d" % (i + 1)):
				_pick(i)
				break
	if player != null and player.dash_cooldown > 0.0:
		dash_fill.rect_size.x = 120.0 * (1.0 - clamp(player.dash_cooldown_left / player.dash_cooldown, 0.0, 1.0))
	if state == "countdown":
		wave_timer -= delta
		if wave_timer <= 0.0:
			_start_next_wave()

func _start_next_wave():
	wave_index += 1
	state = "fighting"
	_update_wave_label()
	if wave_index >= WAVES.size() - 1:
		_show_message("THE JACKAL WARDEN", 2.0)
	else:
		_show_message("WAVE %d" % (wave_index + 1), 1.5)
	for group in WAVES[wave_index]:
		for i in range(group[1]):
			_spawn_enemy(group[0])

func _spawn_enemy(kind):
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
	else:
		e = EnemyScript.new()
		e.position = _random_spawn()
		e.connect("died", self, "_on_enemy_died")
	e.setup(kind, player)
	alive_enemies += 1
	add_child(e)

func _random_spawn():
	for i in range(30):
		var p = Vector2(rand_range(90, ARENA.size.x - 90), rand_range(90, ARENA.size.y - 90))
		var blocked = false
		for r in PILLARS:
			if r.grow(40).has_point(p):
				blocked = true
		if not blocked and p.distance_to(player.global_position) > 350.0:
			return p
	return Vector2(120, 120)

func _on_summon(kind, count):
	for i in range(count):
		_spawn_enemy(kind)

func _on_enemy_died():
	alive_enemies -= 1
	kills += 1
	player.on_kill()
	_update_wave_label()
	if alive_enemies <= 0 and state == "fighting":
		_wave_cleared()

func _on_boss_hp(hp, max_hp):
	boss_fill.rect_size.x = 594.0 * clamp(float(hp) / float(max_hp), 0.0, 1.0)

func _on_boss_died():
	alive_enemies -= 1
	kills += 1
	state = "reckoning"
	boss_bg.visible = false
	boss_fill.visible = false
	boss_label.visible = false
	_clear_hazards()
	for e in get_tree().get_nodes_in_group("enemies"):
		e._die()
	_update_wave_label()
	var opts = [
		{"id": "restore", "name": "Restore", "desc": "Heal the Warden.\n+3 max HP, full heal."},
		{"id": "bind", "name": "Bind", "desc": "Take its power.\n+2 damage, -2 max HP."},
		{"id": "release", "name": "Release", "desc": "Let it die.\nFaster dash, +20% speed."}
	]
	_show_cards("THE JACKAL WARDEN KNEELS", "Oru: \"Its scales are broken. Choose, Keeper.\"", opts, "reckon")

func _clear_hazards():
	for p in get_tree().get_nodes_in_group("projectiles"):
		p.queue_free()

func _wave_cleared():
	_clear_hazards()
	state = "choosing"
	_show_cards("A GIFT FROM THE FADING GODS", "Choose one   (press 1, 2 or 3, or click)", GiftsScript.random_choices(3), "gift")

func _on_player_died():
	state = "ended"
	Ledger.data["deaths"] += 1
	Ledger.save()
	_show_message("YOU DIED\n" + DEATH_LINES[randi() % DEATH_LINES.size()] + "\nPress R to try again", 99999.0)

# ---------- choice cards ----------

func _show_cards(title, subtitle, options, mode):
	card_options = options
	card_mode = mode
	card_root = Control.new()
	card_root.rect_scale = Vector2(1.5, 1.5)
	ui_layer.add_child(card_root)
	var dim = ColorRect.new()
	dim.rect_size = Vector2(854, 480)
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(dim)
	var t = Label.new()
	t.text = title
	t.rect_position = Vector2(0, 70)
	t.rect_size = Vector2(854, 20)
	t.align = Label.ALIGN_CENTER
	t.add_color_override("font_color", Color(0.95, 0.78, 0.3))
	card_root.add_child(t)
	var st = Label.new()
	st.text = subtitle
	st.rect_position = Vector2(0, 100)
	st.rect_size = Vector2(854, 20)
	st.align = Label.ALIGN_CENTER
	st.modulate = Color(1, 1, 1, 0.85)
	card_root.add_child(st)
	var n = options.size()
	var w = 240.0
	var gap = 20.0
	var x0 = (854.0 - (n * w + (n - 1) * gap)) / 2.0
	for i in range(n):
		var o = options[i]
		var b = Button.new()
		b.text = "[%d]  %s\n\n%s" % [i + 1, o["name"], o["desc"]]
		b.rect_position = Vector2(x0 + i * (w + gap), 150)
		b.rect_size = Vector2(w, 150)
		b.focus_mode = Control.FOCUS_NONE
		b.add_stylebox_override("normal", _card_style(Color(0.1, 0.1, 0.18), Color(0.55, 0.45, 0.2)))
		b.add_stylebox_override("hover", _card_style(Color(0.18, 0.15, 0.25), Color(1.0, 0.8, 0.3)))
		b.add_stylebox_override("pressed", _card_style(Color(0.25, 0.2, 0.3), Color(1.0, 0.9, 0.5)))
		b.add_color_override("font_color", Color(1, 0.95, 0.85))
		b.add_color_override("font_color_hover", Color(1, 1, 1))
		b.connect("pressed", self, "_pick", [i])
		card_root.add_child(b)

func _card_style(bg, border):
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	return sb

func _pick(i):
	if card_root == null:
		return
	var opt = card_options[i]
	card_root.queue_free()
	card_root = null
	if card_mode == "gift":
		player.apply_gift(opt["id"])
		gifts_taken.append(opt["name"])
		_update_gifts_label()
		FX.popup(player.global_position, opt["name"], Color(1.0, 0.85, 0.4))
		state = "countdown"
		wave_timer = 1.2
	else:
		_apply_reckoning(opt["id"])

func _apply_reckoning(id):
	Ledger.data["warden"] = id
	Ledger.data["wins"] += 1
	Ledger.save()
	var text = ""
	if id == "restore":
		player.max_hp += 3
		player.hp = player.max_hp
		text = "You restored the Warden.\nThe floodwater clears. Something below stirs.\n"
	elif id == "bind":
		player.damage += 2
		player.max_hp = int(max(2, player.max_hp - 2))
		player.hp = int(min(player.hp, player.max_hp))
		text = "You bound the Warden's power.\nIts jackal eyes now burn in yours.\n"
	else:
		player.speed *= 1.2
		player.dash_cooldown *= 0.6
		text = "You released the Warden.\nThe halls fall silent. Nothing here is watching now.\n"
	player.emit_signal("hp_changed", player.hp, player.max_hp)
	state = "ended"
	_show_message(text + "The Ledger remembers.\nPress R to descend again", 99999.0)
