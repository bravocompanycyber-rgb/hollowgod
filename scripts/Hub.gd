extends Node2D
# The Terminus: the hub between runs. Talk to Oru, Mara, Sable and Bryn, spend Echoes at the Forge,
# and board Line One. Your progress is saved here.

const PlayerScript = preload("res://scripts/Player.gd")
const NPCScript = preload("res://scripts/NPC.gd")
const DialogueScript = preload("res://scripts/Dialogue.gd")
const DialogueUIScript = preload("res://scripts/DialogueUI.gd")
const CardUIScript = preload("res://scripts/CardUI.gd")
const PauseScript = preload("res://scripts/PauseMenu.gd")
const DecoScript = preload("res://scripts/Deco.gd")

const TILE = 48
const AREA = Rect2(0, 0, 1536, 960)
const PROPS = [Rect2(240, 336, 192, 48), Rect2(1056, 288, 240, 48), Rect2(1104, 576, 144, 72)]
const GATE_POS = Vector2(768, 150)

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
var deco = null

func _ready():
    FX.reset()
    FX.world = self
    Sfx.music("hub")
    Game.save()
    var mod = CanvasModulate.new()
    mod.color = Color(0.6, 0.62, 0.78)
    add_child(mod)
    _build_walls()
    _build_lights()
    _build_deco()
    _build_npcs()
    player = PlayerScript.new()
    player.combat = false
    player.position = Vector2(768, 560)
    add_child(player)
    for n in npcs:
        n.watch = player
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
    _wall(Rect2(-64, -64, AREA.size.x + 128, 64 + 144))
    _wall(Rect2(-64, 720, AREA.size.x + 128, 300))
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
    var occ = LightOccluder2D.new()
    var poly = OccluderPolygon2D.new()
    var hx = rect.size.x / 2.0
    var hy = rect.size.y / 2.0
    poly.polygon = PoolVector2Array([Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)])
    occ.occluder = poly
    body.add_child(occ)
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
    _light(Vector2(400, 470), Color(1.0, 0.85, 0.6), 6.0, 0.7)
    _light(Vector2(1140, 470), Color(1.0, 0.85, 0.6), 6.0, 0.7)
    _light(GATE_POS + Vector2(0, 50), Color(0.4, 0.9, 1.0), 6.0, 0.9)
    _light(Vector2(1176, 610), Color(1.0, 0.55, 0.2), 5.0, 1.0)

func _build_deco():
    deco = DecoScript.new()
    add_child(deco)
    var items = []
    for c in [11, 20]:
        items.append({"name": "wall_fountain_top", "pos": Vector2(c * TILE, 0), "anchor": "topleft"})
        items.append({"name": "wall_fountain_mid_blue_anim", "pos": Vector2(c * TILE, TILE), "anchor": "topleft", "fps": 5.0})
        items.append({"name": "wall_fountain_basin_blue_anim", "pos": Vector2(c * TILE, 2 * TILE), "anchor": "topleft", "fps": 5.0})
    # Molten forge glow
    for x in [1104, 1152, 1200]:
        items.append({"name": "wall_fountain_basin_red_anim", "pos": Vector2(x, 576), "anchor": "topleft", "fps": 6.0})
    items.append({"name": "chest_full_open_anim_f0", "pos": Vector2(1290, 670), "anchor": "bottom"})
    items.append({"name": "coin_anim", "pos": Vector2(1250, 690), "anchor": "bottom", "fps": 6.0})
    items.append({"name": "coin_anim", "pos": Vector2(1266, 700), "anchor": "bottom", "fps": 5.0})
    deco.items = items

func _build_npcs():
    var defs = [["oru", "Oru", Color(1.0, 0.8, 0.4), "flame", "", Color(1, 1, 1), Vector2(700, 480)],
        ["mara", "Mara Voss", Color(0.95, 0.55, 0.55), "person", "elf_f", Color(1, 1, 1), Vector2(336, 500)],
        ["sable", "Sable", Color(0.7, 0.82, 1.0), "person", "wizard_f", Color(0.75, 0.88, 1.15, 0.82), Vector2(1176, 425)],
        ["bryn", "Bryn", Color(1.0, 0.62, 0.3), "person", "orc_warrior", Color(1, 1, 1), Vector2(1060, 625)]]
    for d in defs:
        var n = NPCScript.new()
        n.npc_id = d[0]
        n.display_name = d[1]
        n.body_color = d[2]
        n.kind = d[3]
        n.sprite = d[4]
        n.tint = d[5]
        n.position = d[6]
        add_child(n)
        npcs.append(n)

func _draw():
    var rng = RandomNumberGenerator.new()
    rng.seed = 99
    var cols = 32
    draw_rect(AREA, Color(0.1, 0.09, 0.13))
    for r in range(20):
        for c in range(cols):
            var rect = Rect2(c * TILE, r * TILE, TILE, TILE)
            if r == 0:
                Art.tile(self, "wall_top_mid", rect)
            elif r == 1 or r == 2:
                Art.tile(self, "wall_mid", rect, Color(0.95, 0.95, 1.0))
            elif r <= 14:
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
                Art.tile(self, name, rect)
    for c in [3, 7, 24, 28]:
        Art.tile(self, "wall_banner_blue" if c < 12 else "wall_banner_red", Rect2(c * TILE, TILE, TILE, TILE))
    # Gate to Line One
    draw_rect(Rect2(GATE_POS.x - 120, 28, 240, 120), Color(0.03, 0.05, 0.09))
    Art.draw(self, "doors_all", Vector2(GATE_POS.x, 144), 3.5, false, Color(1, 1, 1), "bottom", Vector2.ONE, true)
    draw_rect(Rect2(GATE_POS.x - 112, 36, 224, 108), Color(0.2, 0.7, 0.8, 0.12))
    # Platform edge and tracks
    draw_rect(Rect2(0, 720, AREA.size.x, 14), Color(0.9, 0.75, 0.15))
    draw_rect(Rect2(0, 734, AREA.size.x, AREA.size.y - 734), Color(0.06, 0.06, 0.09))
    for x in range(0, 1536, 64):
        draw_rect(Rect2(x, 800, 40, 8), Color(0.22, 0.16, 0.12))
        draw_rect(Rect2(x, 880, 40, 8), Color(0.22, 0.16, 0.12))
    draw_line(Vector2(0, 796), Vector2(AREA.size.x, 796), Color(0.45, 0.45, 0.5), 3.0)
    draw_line(Vector2(0, 876), Vector2(AREA.size.x, 876), Color(0.45, 0.45, 0.5), 3.0)
    # Ghost carriage waiting on the tracks
    draw_rect(Rect2(260, 770, 860, 110), Color(0.12, 0.16, 0.24, 0.9))
    for i in range(8):
        draw_rect(Rect2(292 + i * 104, 788, 60, 44), Color(0.5, 0.78, 0.92, 0.2))
    draw_rect(Rect2(260, 770, 860, 110), Color(0.3, 0.42, 0.58, 0.7), false, 2.0)
    # Bench, Sable's desk, Bryn's forge
    var bench = PROPS[0]
    draw_rect(Rect2(bench.position + Vector2(6, 10), bench.size), Color(0, 0, 0, 0.3))
    draw_rect(bench, Color(0.32, 0.2, 0.13))
    draw_rect(Rect2(bench.position.x, bench.position.y, bench.size.x, 12), Color(0.48, 0.32, 0.2))
    draw_rect(bench, Color(0.6, 0.42, 0.24), false, 2.0)
    var desk = PROPS[1]
    draw_rect(Rect2(desk.position + Vector2(6, 10), desk.size), Color(0, 0, 0, 0.3))
    draw_rect(desk, Color(0.2, 0.2, 0.32))
    draw_rect(desk, Color(0.6, 0.7, 0.92), false, 2.0)
    for i in range(5):
        draw_rect(Rect2(desk.position.x + 14 + i * 40, desk.position.y + 8, 28, 10), Color(0.85, 0.85, 0.95, 0.75))
    Art.draw(self, "flask_big_blue", Vector2(desk.position.x + 190, desk.position.y + 18), 2.5, false, Color(1, 1, 1), "bottom", Vector2.ONE, true)
    Art.draw(self, "flask_big_green", Vector2(desk.position.x + 215, desk.position.y + 20), 2.5, false, Color(1, 1, 1), "bottom", Vector2.ONE, true)
    var forge = PROPS[2]
    draw_rect(Rect2(forge.position + Vector2(6, 10), forge.size), Color(0, 0, 0, 0.35))
    draw_rect(forge, Color(0.2, 0.15, 0.14))
    draw_rect(forge, Color(0.85, 0.5, 0.22), false, 2.0)
    Art.draw(self, "weapon_axe", Vector2(1096, 582), 2.5, false, Color(1, 1, 1), "bottom", Vector2.ONE, true)
    Art.draw(self, "weapon_hammer", Vector2(1256, 584), 2.5, false, Color(1, 1, 1), "bottom", Vector2.ONE, true)

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
        prompt.text = "[E]  Board a Line"
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
    Sfx.play("open")
    card_mode = mode
    card = CardUIScript.new()
    ui_layer.add_child(card)
    card.setup(title, sub, opts, can_close, extra)
    card.connect("picked", self, "_on_card_picked")
    card.connect("closed", self, "_close_card")

func _close_card():
    if card != null:
        Sfx.play("close")
        card.queue_free()
        card = null
    card_mode = ""
    _update_hud()

func _on_card_picked(i):
    if card_mode == "gate":
        if i == 4:
            _close_card()
            return
        var line = ["sunken", "rime", "obsidian", "hollow"][i]
        if not Game.line_open(line):
            Sfx.play("error")
            return
        _close_card()
        Game.selected_line = line
        Sfx.play("door")
        Game.goto("res://scenes/Run.tscn")
    elif card_mode == "shop":
        _buy(i)
    else:
        _close_card()

func _open_gate():
    Sfx.play("click")
    var rime_open = Game.line_open("rime")
    var obs_open = Game.line_open("obsidian")
    var hol_open = Game.line_open("hollow")
    var opts = [
        {"name": "Line One", "tag": "The Sunken Hall", "tag_color": Color(0.5, 0.9, 1.0), "border": Color(0.4, 0.8, 0.9),
         "desc": "Five rooms of a drowned temple, ending with the Jackal Warden.\nChoose doors, collect Gifts, make your choices. You keep your Echoes and XP even if you die.",
         "foot": "Cleared %d time(s)" % int(Game.data["cleared"].get("sunken", 0))},
        {"name": "Line Two", "tag": "The Rime Road", "tag_color": Color(0.7, 0.9, 1.0), "border": Color(0.6, 0.85, 1.0),
         "desc": "A frozen road through the halls of the Norse dead.\nTougher enemies, charging frost wolves, and the Frost Jarl.\nBetter rewards." if rime_open else "Locked.\nDefeat the Jackal Warden on Line One to open this line.",
         "foot": ("Cleared %d time(s)" % int(Game.data["cleared"].get("rime", 0))) if rime_open else "LOCKED", "disabled": not rime_open},
        {"name": "Line Three", "tag": "The Obsidian Road", "tag_color": Color(1.0, 0.7, 0.4), "border": Color(1.0, 0.55, 0.25),
         "desc": "The nine trials of Mictlan, the realm of the dead in Aztec belief. Obsidian winds, charging hounds, and the Lord of Mictlan. The hardest line, with the best rewards." if obs_open else "Locked.\nDefeat the Frost Jarl on Line Two to open this line.",
         "foot": ("Cleared %d time(s)" % int(Game.data["cleared"].get("obsidian", 0))) if obs_open else "LOCKED", "disabled": not obs_open},
        {"name": "The Hollow", "tag": "The final descent", "tag_color": Color(0.8, 0.6, 1.0), "border": Color(0.7, 0.5, 1.0),
         "desc": "Whatever eats the gods waits at the bottom of every road. Your choices decide how this ends." if hol_open else "Locked.\nClear Lines One, Two and Three to open the way down.",
         "foot": ("Endings found: %d / 6" % Game.endings_found()) if hol_open else "LOCKED", "disabled": not hol_open},
        {"name": "Stay", "tag": "Terminus Station", "desc": "Talk to the others, visit the Forge, or check the Ledger."}]
    _open_card("gate", "BOARD A LINE", "Oru: \"Where to, Keeper?\"", opts, true)

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

func _ending_list(d):
    var names = d["endings"].keys()
    if names.size() == 0:
        return ""
    return "  (" + PoolStringArray(names).join(", ") + ")"

func _choice_name(c):
    if c == "restore":
        return "Restored"
    if c == "bind":
        return "Bound"
    if c == "release":
        return "Released"
    return "Undecided"

func _open_ledger():
    var d = Game.data
    var wn = "Undecided"
    if d["warden"] == "restore":
        wn = "Restored"
    elif d["warden"] == "bind":
        wn = "Bound"
    elif d["warden"] == "release":
        wn = "Released"
    var desc = "Keeper Level %d    (XP %d / %d)\nRuns: %d     Deaths: %d     Victories: %d\nTotal kills: %d     Deepest room: %d / 5\n\nThe Jackal Warden: %s     The Frost Jarl: %s     The Lord of Mictlan: %s\nThe Hollow: %s     Endings found: %d / 6%s\nLines cleared: Sunken Hall x%d, Rime Road x%d, Obsidian Road x%d\nBond with Mara Voss: %d\nSecond Wind (Jonah's lighter): %s" % [
        d["level"], d["xp"], Game.xp_to_next(), d["runs"], d["deaths"], d["wins"], d["kills_total"], d["best_room"], wn, _choice_name(d["jarl"]), _choice_name(d["lord"]), _choice_name(d["hollow"]), Game.endings_found(), _ending_list(d), int(d["cleared"].get("sunken", 0)), int(d["cleared"].get("rime", 0)), int(d["cleared"].get("obsidian", 0)), Game.bond("mara"),
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
    if card == null or card_mode != "shop" or i < 0 or i >= Game.FORGE.size():
        return
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
