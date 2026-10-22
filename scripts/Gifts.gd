extends Reference
# Gifts: random upgrades offered by the fading gods between waves.
# To add a new gift: add a line here AND a matching case in Player.gd apply_gift().

const LIST = [
    {"id": "ember", "name": "Ember Edge", "desc": "+1 attack damage"},
    {"id": "reach", "name": "Lantern Reach", "desc": "Longer, wider sword arc"},
    {"id": "wind", "name": "Wind Step", "desc": "Dash recharges faster"},
    {"id": "heart", "name": "Hollow Heart", "desc": "+2 max HP and heal 2"},
    {"id": "swift", "name": "Swift Soul", "desc": "Move 12% faster"},
    {"id": "vamp", "name": "Hungry Flame", "desc": "Heal 1 HP every few kills"},
    {"id": "shock", "name": "Thunder Step", "desc": "Dash hurts enemies you pass"},
    {"id": "quick", "name": "Quick Hands", "desc": "Attack 25% faster"}
]

static func random_choices(count):
    var pool = LIST.duplicate()
    pool.shuffle()
    var out = []
    for i in range(min(count, pool.size())):
        out.append(pool[i])
    return out
