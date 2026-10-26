extends Node
# Saved profile (your progress), Keeper level, permanent Forge upgrades, run results.
# Save file: user://save.json  (in Godot's user folder on your PC)

const SAVE_PATH = "user://save.json"
const VERSION = "0.3"

const FORGE = [
    {"id": "vitality", "name": "Vessel of Lamplight", "desc": "Permanently adds 10 max HP for each level.", "max": 5, "costs": [40, 80, 140, 220, 320]},
    {"id": "edge", "name": "Whetted Blade", "desc": "Permanently adds 8% attack damage for each level.", "max": 5, "costs": [50, 100, 170, 260, 380]},
    {"id": "agility", "name": "Fleet Soul", "desc": "Permanently adds 4% movement speed for each level.", "max": 5, "costs": [40, 80, 140, 220, 320]},
    {"id": "windsigil", "name": "Wind Sigil", "desc": "Your dash recharges 6% faster for each level.", "max": 5, "costs": [45, 90, 150, 230, 340]},
    {"id": "fortune", "name": "Echo Magnet", "desc": "You earn 15% more Echoes for each level.", "max": 5, "costs": [60, 120, 190, 280, 400]}
]

var data = {}
var last_run = null
var selected_line = "sunken"

func default_data():
    return {
        "runs": 0, "deaths": 0, "wins": 0, "kills_total": 0,
        "echoes": 0, "xp": 0, "level": 1, "best_room": 0,
        "forge": {"vitality": 0, "edge": 0, "agility": 0, "windsigil": 0, "fortune": 0},
        "warden": "",
        "jarl": "",
        "cleared": {},
        "warden_hist": {"restore": 0, "bind": 0, "release": 0},
        "flags": {}, "bonds": {"mara": 0}, "talked": {}
    }

func _ready():
    data = default_data()

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
    return false

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
    last_run = {"result": result, "rooms": rooms, "kills": kills, "echoes": echoes, "xp": xp, "levels": levels, "level": data["level"]}
    save()
