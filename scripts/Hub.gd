extends Node2D
# The Terminus: the hub between runs. Talk to Oru, Mara, Sable and Bryn, spend Echoes at the Forge,
# and board Line One. Your progress is saved here.

const PlayerScript = preload("res://scripts/Player.gd")
const NPCScript = preload("res://scripts/NPC.gd")
const DialogueScript = preload("res://scripts/Dialogue.gd")
const DialogueUIScript = preload("res://scripts/DialogueUI.gd")
const CardUIScript = preload("res://scripts/CardUI.gd")
const PauseScript = preload("res://scripts/PauseMenu.gd")

const AREA = Rect2(0, 0, 1500, 900)
const PROPS = [Rect2(250, 300, 200, 40), Rect2(1030, 250, 220, 50), Rect2(1080, 520, 130, 70)]
const GATE_POS = Vector2(750, 130)

var player = null
var npcs = []
var ui_layer = null
var dialogue = null
var card = null
var card_mode = ""
var prompt = null
var hud_level = null
var hud_xp = null
var current_npc = ""
var current_key = ""
var nearest = null
var clock = 0.0

func _ready():
    FX.reset()
    FX.world = self
    Sfx.music("hub")
    Game.save()
    var mod = CanvasModulate.new()
    mod.color = Color(0.5, 0.52, 0.66)
    add_child(mod)
    _build_walls()
    _build_lights()
    _build_npcs()
    player = PlayerScript.new()
    player.combat = false
    player.position = Vector2(750, 520)
    add_child(player)
    player.set_camera_limits(AREA)
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    FX.add_vignette(ui_layer)
    hud_level = FX.label(ui_layer, Vector2(24, 20), "", 20, Color(0.95, 0.8, 0.4), true)
    hud_xp = ColorRect.new()
    hud_xp.rect_position = Vector2(24, 52)
    hud_xp.rect_size = Vector2(200, 8)
    hud_xp.color = Color(0.5, 0.9, 1.0)
    var xbg = ColorRect.new()
    xbg.rect_position = Vector2(22, 50)
    xbg.rect_size = Vector2(204, 12)
    xbg.color = Color(0, 0, 0, 0.6)
    ui_layer.add_child(xbg)
    ui_layer.add_child(hud_xp)
    var hint = FX.label(ui_layer, Vector2(24, 690), "WASD move   |   E talk / interact   |   Esc menu", 14, Color(1, 1, 1, 0.6))
    prompt = FX.label(ui_layer, Vector2(0, 600), "", 22, Color(1, 0.95, 0.7))
    prompt.rect_size = Vector2(1280, 30)
    prompt.align = Label.ALIGN_CENTER
    dialogue = DialogueUIScript.new()
    add_child(dialogue)
    dialogue.connect("finished", self, "_on_dialogue_done")
    var pm = PauseScript.new()
    pm.mode = "hub"
    add_child(pm)
    _update_hud()
    if Game.last_run != null:
        _show_summary()

func _update_hud():
    hud_level.text = "Keeper Level %d      Echoes %d" % [Game.data["level"], Game.data["echoes"]]
    hud_xp.rect_size.x = 200.0 * clamp(float(Game.data["xp"]) / float(Game.xp_to_next()), 0.0, 1.0)

# ---------- world ----------

func _build_walls():
    _wall(Rect2(-64, -64, AREA.size.x + 128, 64))
    _wall(Rect2(-64, 716, AREA.size.x + 128, 64))
    _wall(Rect2(-64, 0, 64, AREA.size.y))
    _wall(Rect2(AREA.size.x, 0, 64, AREA.size.y))
    for r in PROPS:
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

func _light(pos, color, scale, energy):
    var l = Light2D.new()
    l.position = pos
    l.texture = FX.light_texture()
    l.texture_scale = scale
    l.color = color
    l.energy = energy
    add_child(l)

func _build_lights():
    _light(Vector2(400, 420), Color(1.0, 0.85, 0.6), 5.0, 0.6)
    _light(Vector2(1100, 400), Color(1.0, 0.85, 0.6), 5.0, 0.6)
    _light(GATE_POS + Vector2(0, 40), Color(0.4, 0.9, 1.0), 5.0, 0.8)
    _light(Vector2(1145, 555), Color(1.0, 0.55, 0.2), 4.5, 0.9)

func _build_npcs():
    var defs = [["oru", "Oru", Color(1.0, 0.8, 0.4), "flame", Vector2(690, 430)],
        ["mara", "Mara Voss", Color(0.95, 0.55, 0.55), "person", Vector2(350, 390)],
        ["sable", "Sable", Color(0.7, 0.82, 1.0), "person", Vector2(1140, 335)],
        ["bryn", "Bryn", Color(1.0, 0.62, 0.3), "person", Vector2(1020, 560)]]
    for d in defs:
        var n = NPCScript.new()
        n.npc_id = d[0]
        n.display_name = d[1]
        n.body_color = d[2]
        n.kind = d[3]
        n.position = d[4]
        add_child(n)
        npcs.append(n)

func _draw():
    # Platform floor
    for ty in range(9):
        for tx in range(15):
            var shade = 0.0 if (tx + ty) % 2 == 0 else 0.03
            draw_rect(Rect2(tx * 100, ty * 100, 100, 100), Color(0.4 + shade, 0.4 + shade, 0.46 + shade))
    var rng = RandomNumberGenerator.new()
    rng.seed = 99
    for i in range(30):
        var a = Vector2(rng.randf_range(20, 1480), rng.randf_range(140, 700))
        draw_line(a, a + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40)), Color(0.2, 0.2, 0.26, 0.6), 1.5)
    # Back wall
    draw_rect(Rect2(0, 0, 1500, 130), Color(0.16, 0.15, 0.22))
    draw_rect(Rect2(0, 126, 1500, 5), Color(0.6, 0.48, 0.2))
    for i in range(1, 15):
        draw_rect(Rect2(i * 100 - 4, 0, 8, 126), Color(0.12, 0.11, 0.17))
    # Gate to Line One
    draw_rect(Rect2(GATE_POS.x - 70, 16, 140, 112), Color(0.04, 0.05, 0.1))
    draw_rect(Rect2(GATE_POS.x - 60, 28, 120, 100), Color(0.1, 0.3, 0.35, 0.8))
    draw_rect(Rect2(GATE_POS.x - 70, 16, 140, 112), Color(0.85, 0.68, 0.3), false, 4.0)
    for i in range(3):
        var ax = GATE_POS.x - 30 + i * 30
        draw_arc(Vector2(ax, 52), 7.0, 0.0, TAU, 12, Color(0.9, 0.75, 0.35, 0.8), 2.0)
        draw_line(Vector2(ax, 59), Vector2(ax, 84), Color(0.9, 0.75, 0.35, 0.8), 2.0)
        draw_line(Vector2(ax - 8, 66), Vector2(ax + 8, 66), Color(0.9, 0.75, 0.35, 0.8), 2.0)
    # Platform edge and tracks
    draw_rect(Rect2(0, 700, 1500, 16), Color(0.85, 0.7, 0.15))
    draw_rect(Rect2(0, 716, 1500, 184), Color(0.08, 0.08, 0.11))
    for x in range(0, 1500, 60):
        draw_rect(Rect2(x, 760, 36, 8), Color(0.2, 0.15, 0.12))
        draw_rect(Rect2(x, 830, 36, 8), Color(0.2, 0.15, 0.12))
    draw_line(Vector2(0, 756), Vector2(1500, 756), Color(0.4, 0.4, 0.45), 3.0)
    draw_line(Vector2(0, 836), Vector2(1500, 836), Color(0.4, 0.4, 0.45), 3.0)
    # Ghost carriage on the tracks
    draw_rect(Rect2(260, 740, 820, 100), Color(0.12, 0.16, 0.24, 0.85))
    for i in range(8):
        draw_rect(Rect2(290 + i * 100, 756, 56, 40), Color(0.5, 0.75, 0.9, 0.18))
    draw_rect(Rect2(260, 740, 820, 100), Color(0.3, 0.4, 0.55, 0.6), false, 2.0)
    # Props: bench, Sable's desk, Bryn's forge
    var bench = PROPS[0]
    draw_rect(bench, Color(0.3, 0.2, 0.14))
    draw_rect(bench, Color(0.55, 0.4, 0.22), false, 2.0)
    var desk = PROPS[1]
    draw_rect(desk, Color(0.2, 0.2, 0.3))
    draw_rect(desk, Color(0.6, 0.7, 0.9), false, 2.0)
    for i in range(5):
        draw_rect(Rect2(desk.position.x + 12 + i * 40, desk.position.y + 8, 28, 10), Color(0.8, 0.8, 0.9, 0.7))
    var forge = PROPS[2]
    draw_rect(forge, Color(0.18, 0.13, 0.12))
    draw_rect(Rect2(forge.position.x + 20, forge.position.y + 10, 90, 20), Color(1.0, 0.45, 0.1, 0.8))
    draw_rect(forge, Color(0.8, 0.45, 0.2), false, 2.0)

# ---------- interaction ----------

func _modal():
    return dialogue.active or card != null

func _process(delta):
    clock += delta
    if Input.is_action_just_pressed("fullscreen"):
        OS.window_fullscreen = not OS.window_fullscreen
    player.frozen = _modal()
    if _modal():
        prompt.text = ""
        return
    nearest = null
    var best = 95.0
    for n in npcs:
        var d = player.global_position.distance_to(n.position)
        if d < best:
            best = d
            nearest = n
    var gd = player.global_position.distance_to(GATE_POS + Vector2(0, 60))
    var at_gate = false
    if gd < 110.0 and gd < best:
        at_gate = true
        nearest = null
    if at_gate:
        prompt.text = "[E]  Board Line One: The Sunken Hall"
    elif nearest != null:
        prompt.text = "[E]  Talk to " + nearest.display_name
    else:
        prompt.text = ""
    if Input.is_action_just_pressed("interact"):
        if at_gate:
            _open_gate()
        elif nearest != null:
            _talk(nearest.npc_id)

func _talk(id):
    Sfx.play("click")
    current_npc = id
    var c = DialogueScript.conv(id, Game.data)
    current_key = c["key"]
    dialogue.start(c["lines"], c["choices"])

func _on_dialogue_done(choice_id):
    var res = DialogueScript.apply(current_npc, current_key, choice_id, Game.data)
    Game.save()
    if res == "shop":
        _open_shop()
    elif res == "ledger":
        _open_ledger()

func _open_card(mode, title, sub, opts, can_close = false, extra = ""):
    card_mode = mode
    card = CardUIScript.new()
    ui_layer.add_child(card)
    card.setup(title, sub, opts, can_close, extra)
    card.connect("picked", self, "_on_card_picked")
    card.connect("closed", self, "_close_card")

func _close_card():
    if card != null:
        card.queue_free()
        card = null
    card_mode = ""
    _update_hud()

func _on_card_picked(i):
    if card_mode == "gate":
        _close_card()
        if i == 0:
            Sfx.play("door")
            Game.goto("res://scenes/Run.tscn")
    elif card_mode == "shop":
        _buy(i)
    else:
        _close_card()

func _open_gate():
    Sfx.play("click")
    var opts = [
        {"name": "Descend", "tag": "Line One: The Sunken Hall", "tag_color": Color(0.5, 0.9, 1.0), "border": Color(0.4, 0.8, 0.9),
         "desc": "Five rooms of the drowned temple, ending in the Jackal Warden.\nPick a path through the doors, collect Gifts, and make your choices.\nDying is not the end. You keep your Echoes and XP."},
        {"name": "Stay", "tag": "Terminus Station", "desc": "Talk to the others, visit the Forge, or check the Ledger first."}]
    _open_card("gate", "BOARD THE LINE", "Oru: \"Ready, Keeper?\"", opts, true)

func _show_summary():
    var r = Game.last_run
    Game.last_run = null
    var title = "YOU RETURN TO THE TERMINUS"
    var sub = "A victory over the Warden." if r["result"] == "win" else ("You withdrew." if r["result"] == "abandon" else "You were pulled back from death.")
    var desc = "Rooms cleared: %d\nEnemies slain: %d\nEchoes gained: +%d\nXP gained: +%d" % [r["rooms"], r["kills"], r["echoes"], r["xp"]]
    if r["levels"] > 0:
        desc += "\n\nKEEPER LEVEL UP!  Now level %d\n(+5 max HP, +2%% attack damage per level)" % r["level"]
        Sfx.play("levelup")
    var opts = [{"name": "Run summary", "tag": "Saved", "tag_color": Color(0.5, 1, 0.6), "desc": desc, "border": Color(0.5, 0.9, 1.0)}]
    _open_card("summary", title, sub, opts)

func _open_ledger():
    var d = Game.data
    var wn = "Undecided"
    if d["warden"] == "restore":
        wn = "Restored"
    elif d["warden"] == "bind":
        wn = "Bound"
    elif d["warden"] == "release":
        wn = "Released"
    var desc = "Keeper Level %d    (XP %d / %d)\nRuns: %d     Deaths: %d     Victories: %d\nTotal kills: %d     Deepest room: %d / 5\n\nThe Jackal Warden: %s\nBond with Mara Voss: %d\nSecond Wind (Jonah's lighter): %s" % [
        d["level"], d["xp"], Game.xp_to_next(), d["runs"], d["deaths"], d["wins"], d["kills_total"], d["best_room"], wn, Game.bond("mara"),
        "Yes" if Game.has_flag("second_wind") else "Not yet"]
    var opts = [{"name": "The Pantheon Ledger", "tag": "Sable's record of you", "tag_color": Color(0.7, 0.82, 1.0), "desc": desc, "border": Color(0.7, 0.82, 1.0)}]
    _open_card("ledger", "THE LEDGER", "Every choice is written down.", opts, true)

func _forge_options():
    var out = []
    for f in Game.FORGE:
        var lv = Game.forge_level(f["id"])
        var o = {"name": f["name"], "desc": f["desc"], "tag": "Level %d / %d" % [lv, f["max"]], "tag_color": Color(1.0, 0.7, 0.4), "border": Color(1.0, 0.6, 0.3)}
        if lv >= f["max"]:
            o["foot"] = "MAXED"
            o["disabled"] = true
        else:
            var c = f["costs"][lv]
            o["foot"] = "Cost: %d Echoes" % c
            if Game.data["echoes"] < c:
                o["disabled"] = true
        out.append(o)
    return out

func _open_shop():
    _open_card("shop", "BRYN'S FORGE", "Permanent upgrades. They stay with you after death.", _forge_options(), true, "Echoes: %d" % Game.data["echoes"])

func _buy(i):
    var f = Game.FORGE[i]
    var lv = Game.forge_level(f["id"])
    if lv >= f["max"]:
        return
    var cost = f["costs"][lv]
    if Game.data["echoes"] < cost:
        return
    Game.data["echoes"] -= cost
    Game.data["forge"][f["id"]] = lv + 1
    Game.save()
    Sfx.play("pickup")
    FX.popup(player.global_position, f["name"] + " Lv" + str(lv + 1), Color(1.0, 0.8, 0.4), 20)
    card.options = _forge_options()
    card.extra_text = "Echoes: %d" % Game.data["echoes"]
    card.rebuild()
