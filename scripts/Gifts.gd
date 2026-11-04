extends Reference
# Gifts: random upgrades offered by the fading gods. Each comes in a rarity:
# Common (x1), Rare (x1.5), Epic (x2.2). Higher rarity = stronger numbers.
# To add a new gift: add it to LIST, add text in describe(), and a case in Player.apply_gift().

const LIST = [
    {"id": "ember", "name": "Ember Edge"},
    {"id": "reach", "name": "Lantern Reach"},
    {"id": "wind", "name": "Wind Step"},
    {"id": "heart", "name": "Hollow Heart"},
    {"id": "swift", "name": "Swift Soul"},
    {"id": "vamp", "name": "Hungry Flame"},
    {"id": "shock", "name": "Thunder Step"},
    {"id": "quick", "name": "Quick Hands"},
    {"id": "guard", "name": "Aegis of the Dead"},
    {"id": "crit", "name": "Jackal's Mark"},
    {"id": "burn", "name": "Ember Brand"},
    {"id": "chain", "name": "Chain Lightning"},
    {"id": "thorns", "name": "Thorned Mantle"},
    {"id": "fortune", "name": "Gilded Touch"},
    {"id": "regen", "name": "Lamplight Blessing"},
    {"id": "execute", "name": "Executioner's Eye"}
]

static func rarity_name(rk):
    if rk == "epic":
        return "Epic"
    if rk == "rare":
        return "Rare"
    return "Common"

static func rarity_mult(rk):
    if rk == "epic":
        return 2.2
    if rk == "rare":
        return 1.5
    return 1.0

static func rarity_color(rk):
    if rk == "epic":
        return Color(0.8, 0.5, 1.0)
    if rk == "rare":
        return Color(0.4, 0.7, 1.0)
    return Color(0.82, 0.82, 0.85)

static func describe(id, m):
    if id == "ember":
        return "Raises your attack damage by %d%%.\nStacks with itself." % int(15 * m)
    if id == "reach":
        return "Your sword reaches %d units further and sweeps a wider arc.\nStacks." % int(20 * m)
    if id == "wind":
        return "Your dash recharges %d%% faster.\nStacks." % int(18 * m)
    if id == "heart":
        return "Gain %d max HP and heal that much right now." % int(20 * m)
    if id == "swift":
        return "You move %d%% faster.\nStacks." % int(8 * m)
    if id == "vamp":
        return "Every 5 kills, heal %d HP.\nStacks." % int(3 * m)
    if id == "shock":
        return "Dashing through enemies hurts them for %d%% of your attack damage.\nStacks." % int(100 * m)
    if id == "quick":
        return "You attack %d%% faster.\nStacks." % int(15 * m)
    if id == "guard":
        return "You take %d%% less damage from all sources.\nStacks, up to 60%%." % int(8 * m)
    if id == "crit":
        return "%d%% chance to land a critical hit for double damage.\nStacks, up to 80%%." % int(10 * m)
    if id == "burn":
        return "Your hits set enemies ablaze, dealing %d%% of the hit over 1.5 seconds.\nStacks." % int(25 * m)
    if id == "chain":
        return "%d%% chance for a hit to arc lightning to a nearby enemy for 60%% damage.\nStacks, up to 70%%." % int(20 * m)
    if id == "thorns":
        return "Enemies that hurt you take %d%% of that damage back.\nStacks." % int(30 * m)
    if id == "fortune":
        return "You earn %d%% more Echoes during this run.\nStacks." % int(25 * m)
    if id == "regen":
        return "Regenerate %.1f HP every second.\nStacks." % (0.4 * m)
    if id == "execute":
        return "Deal %d%% more damage to enemies below 30%% health.\nStacks." % int(50 * m)
    return ""

static func roll_rarity():
    var r = randf()
    if r < 0.08:
        return "epic"
    if r < 0.35:
        return "rare"
    return "common"

static func _make(g, rk):
    var m = rarity_mult(rk)
    return {"id": g["id"], "name": g["name"], "tag": rarity_name(rk), "tag_color": rarity_color(rk),
        "border": rarity_color(rk), "mult": m, "rarity": rk, "desc": describe(g["id"], m)}

static func roll_one(rk):
    var pool = LIST.duplicate()
    pool.shuffle()
    return _make(pool[0], rk)

static func random_choices(count):
    var pool = LIST.duplicate()
    pool.shuffle()
    var out = []
    for i in range(int(min(count, pool.size()))):
        out.append(_make(pool[i], roll_rarity()))
    return out
