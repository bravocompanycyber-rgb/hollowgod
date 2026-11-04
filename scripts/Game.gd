extends Node
# Saved profile (your progress), Keeper level, permanent Forge upgrades, run results.
# Save file: user://save.json  (in Godot's user folder on your PC)

const SAVE_PATH = "user://save.json"
const SETTINGS_PATH = "user://settings.json"
const VERSION = "0.9"

const FORGE = [
    {"id": "vitality", "name": "Vessel of Lamplight", "desc": "Permanently adds 10 max HP for each level.", "max": 5, "costs": [40, 80, 140, 220, 320]},
    {"id": "edge", "name": "Whetted Blade", "desc": "Permanently adds 8% attack damage for each level.", "max": 5, "costs": [50, 100, 170, 260, 380]},
    {"id": "agility", "name": "Fleet Soul", "desc": "Permanently adds 4% movement speed for each level.", "max": 5, "costs": [40, 80, 140, 220, 320]},
    {"id": "windsigil", "name": "Wind Sigil", "desc": "Your dash recharges 6% faster for each level.", "max": 5, "costs": [45, 90, 150, 230, 340]},
    {"id": "fortune", "name": "Echo Magnet", "desc": "You earn 15% more Echoes for each level.", "max": 5, "costs": [60, 120, 190, 280, 400]}
]

const ACHIEVEMENTS = [
    {"id": "first_blood", "name": "First Blood", "desc": "Defeat your first enemy."},
    {"id": "clean_room", "name": "Untouchable", "desc": "Clear a room without taking damage."},
    {"id": "deflector", "name": "Deflector", "desc": "Swat 25 enemy bolts out of the air."},
    {"id": "collector", "name": "Collector", "desc": "Hold 8 Gifts in one run."},
    {"id": "epic_find", "name": "Epic Find", "desc": "Take an Epic Gift."},
    {"id": "second_wind", "name": "Jonah's Wish", "desc": "Be saved by Second Wind."},
    {"id": "smith", "name": "Apprentice Smith", "desc": "Buy a Forge upgrade."},
    {"id": "master_smith", "name": "Master Smith", "desc": "Max out a Forge upgrade."},
    {"id": "level5", "name": "Seasoned Keeper", "desc": "Reach Keeper level 5."},
    {"id": "level10", "name": "Veteran Keeper", "desc": "Reach Keeper level 10."},
    {"id": "persistent", "name": "Death Is A Door", "desc": "Die 10 times."},
    {"id": "slayer", "name": "Slayer", "desc": "Defeat 500 enemies in total."},
    {"id": "warden", "name": "Weighed And Found Light", "desc": "Defeat the Jackal Warden."},
    {"id": "jarl", "name": "Warmth In The Frost", "desc": "Defeat the Frost Jarl."},
    {"id": "lord", "name": "Nine Trials Done", "desc": "Defeat the Lord of Mictlan."},
    {"id": "hollow", "name": "The Bottom Of Everything", "desc": "Defeat the Hollow."},
    {"id": "all_endings", "name": "Every Road", "desc": "Find all six endings."},
    {"id": "truth", "name": "The Truth", "desc": "Find the secret ending."},
    {"id": "ascended", "name": "Rising Heat", "desc": "Clear a Line on Ascension 3 or higher."},
    {"id": "fast", "name": "Swift Descent", "desc": "Clear a Line in under 8 minutes."},
    {"id": "contractor", "name": "Contractor", "desc": "Complete 5 contracts from Mara."}
]

# Contracts: optional goals Mara offers before a run. Finish one during the run for bonus Echoes and XP.
const BOUNTIES = [
    {"id": "slay30", "name": "Cull the Dead", "desc": "Defeat 30 enemies in one run.", "stat": "kills", "goal": 30, "echoes": 60, "xp": 60},
    {"id": "slay50", "name": "Mass Cull", "desc": "Defeat 50 enemies in one run.", "stat": "kills", "goal": 50, "echoes": 110, "xp": 110},
    {"id": "parry8", "name": "Bolt Breaker", "desc": "Swat 8 enemy bolts in one run.", "stat": "parries", "goal": 8, "echoes": 70, "xp": 60},
    {"id": "clean2", "name": "Untouched", "desc": "Clear 2 rooms without taking damage.", "stat": "clean_rooms", "goal": 2, "echoes": 90, "xp": 80},
    {"id": "gifts4", "name": "Greedy Hands", "desc": "Collect 4 Gifts in one run.", "stat": "gifts", "goal": 4, "echoes": 80, "xp": 70},
    {"id": "chargers6", "name": "Hound Hunter", "desc": "Defeat 6 Chargers in one run.", "stat": "chargers", "goal": 6, "echoes": 90, "xp": 80},
    {"id": "brutes4", "name": "Giant Slayer", "desc": "Defeat 4 Brutes in one run.", "stat": "brutes", "goal": 4, "echoes": 100, "xp": 90}
]

var data = {}
var last_run = null
var selected_line = "sunken"
var selected_ascension = 0
var run_seconds = 0.0
var pending_ending = ""
var settings = {"music": 0.8, "sfx": 1.0, "fullscreen": false, "effects": true, "keys": {}}

func default_data():
    return {
        "runs": 0, "deaths": 0, "wins": 0, "kills_total": 0,
        "echoes": 0, "xp": 0, "level": 1, "best_room": 0,
        "forge": {"vitality": 0, "edge": 0, "agility": 0, "windsigil": 0, "fortune": 0},
        "warden": "",
        "jarl": "",
        "lord": "",
        "hollow": "",
        "endings": {},
        "achievements": {},
        "bounty": "",
        "bounties_done": 0,
        "ascension_max": 0,
        "parries": 0,
        "cleared": {},
        "warden_hist": {"restore": 0, "bind": 0, "release": 0},
        "flags": {}, "bonds": {"mara": 0}, "talked": {}
    }

func _ready():
    data = default_data()
    load_settings()

func load_settings():
    var f = File.new()
    if not f.file_exists(SETTINGS_PATH):
        return
    if f.open(SETTINGS_PATH, File.READ) != OK:
        return
    var r = JSON.parse(f.get_as_text())
    f.close()
    if r.error == OK and typeof(r.result) == TYPE_DICTIONARY:
        for k in r.result.keys():
            if settings.has(k):
                settings[k] = r.result[k]
    settings["music"] = clamp(float(settings["music"]), 0.0, 1.0)
    settings["sfx"] = clamp(float(settings["sfx"]), 0.0, 1.0)
    settings["fullscreen"] = bool(settings["fullscreen"])
    settings["effects"] = bool(settings["effects"])
    if typeof(settings["keys"]) != TYPE_DICTIONARY:
        settings["keys"] = {}

func save_settings():
    var f = File.new()
    if f.open(SETTINGS_PATH, File.WRITE) == OK:
        f.store_string(JSON.print(settings))
        f.close()

func apply_settings():
    OS.window_fullscreen = settings["fullscreen"]
    Sfx.set_volumes(settings["music"], settings["sfx"])
    Art.use_normals = settings["effects"]
    Inputs.apply_keys()
    if get_tree() != null:
        get_tree().call_group("player", "apply_quality")

func has_save():
    var f = File.new()
    return f.file_exists(SAVE_PATH)

func new_game():
    data = default_data()
    last_run = null
    save()

func load_game():
    var f = File.new()
    if not f.file_exists(SAVE_PATH):
        return false
    if f.open(SAVE_PATH, File.READ) != OK:
        return false
    var r = JSON.parse(f.get_as_text())
    f.close()
    if r.error != OK or typeof(r.result) != TYPE_DICTIONARY:
        return false
    var fresh = default_data()
    for k in r.result.keys():
        if typeof(fresh.get(k)) == TYPE_DICTIONARY and typeof(r.result[k]) == TYPE_DICTIONARY:
            for k2 in r.result[k].keys():
                fresh[k][k2] = r.result[k][k2]
        else:
            fresh[k] = r.result[k]
    for k in ["runs", "deaths", "wins", "kills_total", "echoes", "xp", "level", "best_room"]:
        fresh[k] = int(fresh[k])
    for k in fresh["forge"].keys():
        fresh["forge"][k] = int(fresh["forge"][k])
    for k in fresh["bonds"].keys():
        fresh["bonds"][k] = int(fresh["bonds"][k])
    for k in fresh["warden_hist"].keys():
        fresh["warden_hist"][k] = int(fresh["warden_hist"][k])
    for k in fresh["cleared"].keys():
        fresh["cleared"][k] = int(fresh["cleared"][k])
    data = fresh
    last_run = null
    return true

func save():
    var f = File.new()
    if f.open(SAVE_PATH, File.WRITE) == OK:
        f.store_string(JSON.print(data))
        f.close()

func goto(path):
    get_tree().paused = false
    Engine.time_scale = 1.0
    get_tree().change_scene(path)

# ----- stats from level and Forge -----

func forge_level(id):
    return int(data["forge"].get(id, 0))

func bonus_hp():
    return (data["level"] - 1) * 5 + forge_level("vitality") * 10

func bonus_damage():
    return 1.0 + (data["level"] - 1) * 0.02 + forge_level("edge") * 0.08

func bonus_speed():
    return 1.0 + forge_level("agility") * 0.04

func dash_cd_mult():
    return max(0.4, 1.0 - forge_level("windsigil") * 0.06)

func echo_mult():
    return 1.0 + forge_level("fortune") * 0.15

func xp_to_next():
    return 100 + (data["level"] - 1) * 60

func has_flag(name):
    return data["flags"].has(name) and data["flags"][name]

func bounty_def(id):
    for b in BOUNTIES:
        if b["id"] == id:
            return b
    return null

# Three contracts that change after every run.
func random_bounties(n):
    var rng = RandomNumberGenerator.new()
    rng.seed = 1000 + int(data["runs"]) * 7 + int(data["deaths"]) * 13 + int(data["wins"]) * 31
    var pool = BOUNTIES.duplicate()
    var out = []
    while out.size() < n and pool.size() > 0:
        var i = rng.randi() % pool.size()
        out.append(pool[i])
        pool.remove(i)
    return out

func unlock(id):
    if data["achievements"].has(id):
        return
    data["achievements"][id] = true
    for a in ACHIEVEMENTS:
        if a["id"] == id:
            Toast.push("Achievement unlocked", a["name"] + "\n" + a["desc"])
    Sfx.play("levelup")
    save()

# Ascension: optional extra difficulty for better rewards (unlocked by clearing a Line).
func asc_hp():
    return 1.0 + 0.2 * selected_ascension

func asc_speed():
    return 1.0 + 0.04 * selected_ascension

func asc_damage():
    return 1.0 + 0.1 * selected_ascension

func asc_reward():
    return 1.0 + 0.25 * selected_ascension

func bond(id):
    return int(data["bonds"].get(id, 0))

func run_started():
    data["runs"] += 1
    save()

func line_open(id):
    if id == "sunken":
        return true
    if id == "rime":
        return int(data["wins"]) >= 1 or int(data["cleared"].get("sunken", 0)) >= 1
    if id == "obsidian":
        return int(data["cleared"].get("rime", 0)) >= 1
    if id == "hollow":
        return int(data["cleared"].get("sunken", 0)) >= 1 and int(data["cleared"].get("rime", 0)) >= 1 and int(data["cleared"].get("obsidian", 0)) >= 1
    return false

func truth_available():
    return has_flag("second_wind") and data["warden"] != "" and data["jarl"] != "" and data["lord"] != ""

# Which ending the player earns, from the three earlier Reckonings plus the final choice.
func compute_ending(final_choice):
    if final_choice == "truth":
        return "The Truth"
    var cs = [data["warden"], data["jarl"], data["lord"]]
    if cs.has("restore") and cs.has("bind") and cs.has("release"):
        return "The Ferryman"
    var binds = 0
    for c in cs:
        if c == "bind":
            binds += 1
    if final_choice == "bind" and binds >= 2:
        return "The Hollow Crown"
    if final_choice == "restore":
        return "The Keeper"
    if final_choice == "bind":
        return "The Usurper"
    return "The Wake"

func endings_found():
    return data["endings"].keys().size()

func finish_run(result, rooms, kills, echoes, xp, line = "sunken"):
    var levels = 0
    data["echoes"] += echoes
    data["xp"] += xp
    while data["xp"] >= xp_to_next():
        data["xp"] -= xp_to_next()
        data["level"] += 1
        levels += 1
    data["kills_total"] += kills
    if result == "death":
        data["deaths"] += 1
    elif result == "win":
        data["wins"] += 1
        data["cleared"][line] = int(data["cleared"].get(line, 0)) + 1
    data["best_room"] = int(max(data["best_room"], rooms))
    var asc_note = ""
    if result == "win":
        var ids = {"sunken": "warden", "rime": "jarl", "obsidian": "lord", "hollow": "hollow"}
        if ids.has(line):
            unlock(ids[line])
        if selected_ascension >= 3:
            unlock("ascended")
        if run_seconds > 0.0 and run_seconds <= 480.0:
            unlock("fast")
        if selected_ascension == int(data["ascension_max"]) and data["ascension_max"] < 5:
            data["ascension_max"] = int(data["ascension_max"]) + 1
            asc_note = "Ascension %d unlocked!" % data["ascension_max"]
    if data["level"] >= 5:
        unlock("level5")
    if data["level"] >= 10:
        unlock("level10")
    if data["deaths"] >= 10:
        unlock("persistent")
    if data["kills_total"] >= 500:
        unlock("slayer")
    if data["endings"].keys().size() >= 6:
        unlock("all_endings")
    if data["endings"].has("The Truth"):
        unlock("truth")
    last_run = {"result": result, "rooms": rooms, "kills": kills, "echoes": echoes, "xp": xp, "levels": levels, "level": data["level"], "note": asc_note}
    save()
