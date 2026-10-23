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
    {"id": "crit", "name": "Jackal's Mark"}
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
    return ""

static func roll_rarity():
    var r = randf()
    if r < 0.08:
        return "epic"
    if r < 0.35:
        return "rare"
    return "common"

static func random_choices(count):
    var pool = LIST.duplicate()
    pool.shuffle()
    var out = []
    for i in range(int(min(count, pool.size()))):
        var g = pool[i]
        var rk = roll_rarity()
        var m = rarity_mult(rk)
        out.append({"id": g["id"], "name": g["name"], "tag": rarity_name(rk), "tag_color": rarity_color(rk),
            "border": rarity_color(rk), "mult": m, "rarity": rk, "desc": describe(g["id"], m)})
    return out
