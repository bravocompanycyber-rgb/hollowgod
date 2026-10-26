extends Reference
# All Terminus conversations. Each returns {key, lines, choices}. Lines: [speaker, text].
# apply() records what the player chose (bonds, flags, saved perks) in the save data.
# To add story later: add a new "if" block with a new key. Keys already seen are saved in data["talked"].

static func conv(npc, d):
    if npc == "oru":
        return _oru(d)
    if npc == "mara":
        return _mara(d)
    if npc == "sable":
        return _sable(d)
    return _bryn(d)

static func _seen(d, key):
    return d["talked"].has(key) and d["talked"][key]

static func _pick(list, d):
    var i = (d["runs"] + d["deaths"] + d["kills_total"]) % list.size()
    return list[i]

static func _oru(d):
    if not _seen(d, "oru_intro"):
        return {"key": "oru_intro", "lines": [
            ["oru", "Ah. You're awake. Don't panic. Well, panic a little. You died."],
            ["oru", "Last night. The Hollowing. Every god on Earth went silent at once, and every grave in the city opened."],
            ["oru", "I am Oru, a guide of souls. Retired, technically. Currently a lantern flame with opinions."],
            ["oru", "I caught you before you slipped away. So now you are my hands, Keeper."],
            ["oru", "Every subway line under this station now leads into somebody's afterlife. Descend. Find out who is still alive down there."]],
            "choices": [
                {"id": "why", "text": "Why me?", "reply": [["oru", "Because you were closest, and you died with your lantern lit. Don't read into it."], ["oru", "...Read into it a little."]]},
                {"id": "go", "text": "Fine. Where do I start?", "reply": [["oru", "Line One. The Sunken Hall. Its Warden weighs the dead. Try not to be weighed."]]}]}
    if d["deaths"] >= 1 and not _seen(d, "oru_death"):
        return {"key": "oru_death", "lines": [
            ["oru", "You came back. Good. Dying gets easier, in the sense that you stop being surprised."],
            ["oru", "Every Echo you collect is a fragment of someone the gods forgot. Bryn can forge them into something useful."],
            ["oru", "Spend them. The dead do not need them. The living do."]], "choices": []}
    if d["wins"] >= 1 and not _seen(d, "oru_warden"):
        var w = d["warden"]
        var lines = []
        if w == "restore":
            lines = [["oru", "You healed the Warden. I did not expect that."], ["oru", "Its scales are balanced again. For the first time since the Hollowing, something down there is whole."],
                ["oru", "Mercy is a strange weapon. We will see what it cuts."]]
        elif w == "bind":
            lines = [["oru", "You took the Warden's power. I felt it go through you."], ["oru", "Power has a price. It always asks for something back, usually when you are not paying attention."],
                ["oru", "Carry it well, Keeper. Or it will carry you."]]
        else:
            lines = [["oru", "You let the Warden die. The Sunken Hall is quiet now."], ["oru", "Quiet is not the same as safe. Something is feeding on the empty places."],
                ["oru", "We will need to look deeper."]]
        lines.append(["oru", "Before it fell, the Warden whispered a name. The Hollow. Whatever eats the gods lives at the very bottom of all the lines."])
        return {"key": "oru_warden", "lines": lines, "choices": []}
    if d["wins"] >= 1 and _seen(d, "oru_warden") and not _seen(d, "oru_rime"):
        return {"key": "oru_rime", "lines": [
            ["oru", "Line Two is open. The Rime Road. The Norse dead keep their halls cold and their grudges colder."],
            ["oru", "Their ruler, the Frost Jarl, never forgave anyone for anything. Expect to be tested."],
            ["oru", "Take Gifts. Take Bryn's steel. And do not stand where the floor is about to break."]], "choices": []}
    if int(d["cleared"].get("rime", 0)) >= 1 and not _seen(d, "oru_jarl"):
        var j = d["jarl"]
        var jl = []
        if j == "restore":
            jl = [["oru", "You rekindled the Jarl's hearth. The Rime Road is warm for the first time in an age."]]
        elif j == "bind":
            jl = [["oru", "You bound the Jarl's frost to your blade. I can feel the cold from here."]]
        else:
            jl = [["oru", "You let the Jarl go. The wind sounds almost relieved."]]
        jl.append(["oru", "Two gods spoke the same word before they fell. The Hollow. It waits at the bottom of every line."])
        jl.append(["oru", "More lines will open. For now, rest."])
        return {"key": "oru_jarl", "lines": jl, "choices": []}
    var idle = [
        [["oru", "The tunnels are quiet. That is never a good sign."]],
        [["oru", "Remember: swat the bolts, dodge the charges, and do not stand still."]],
        [["oru", "I miss the old days. Souls were polite. They queued."]],
        [["oru", "Each god you meet is dying slowly. Decide what kind of mercy you can afford."]],
        [["oru", "Rest if you must. The Hollowing does not."]]]
    return {"key": "oru_idle", "lines": _pick(idle, d), "choices": []}

static func _mara(d):
    if not _seen(d, "mara_intro"):
        return {"key": "mara_intro", "lines": [
            ["mara", "Easy. You're the new one. Name's Mara Voss. I used to be a detective. Now I talk to people who stopped answering."],
            ["mara", "My partner went into the tunnels the night of the Hollowing. Jonah. Grey coat, bad jokes."],
            ["mara", "If you find him, tell him he still owes me lunch."]],
            "choices": [
                {"id": "promise", "text": "I'll look for him.", "reply": [["mara", "Don't promise. Just look. That's all anyone can do down here."]]},
                {"id": "cold", "text": "Not my problem.", "reply": [["mara", "Fair. Everyone's got their own dead. Mine are just louder."]]}]}
    if d["wins"] >= 1 and not _seen(d, "mara_jonah"):
        if Game_bond(d) >= 1:
            return {"key": "mara_jonah", "lines": [
                ["mara", "Word travels fast down here. The Warden kept a ledger of the weighed. Jonah's name was in it."],
                ["mara", "He was weighed and found light. Not guilty, just light. He'd have laughed at that."],
                ["mara", "Take this. His lighter. It still holds one good wish. It will pull you back from the edge, once, each time you descend."]], "choices": []}
        return {"key": "mara_jonah", "lines": [
            ["mara", "You beat the Warden. So the rumours are true."],
            ["mara", "Jonah's name was in its ledger. I'd like to think he went well."],
            ["mara", "I have his lighter. It holds one good wish. It could save your life, once per run. Do you want it?"]],
            "choices": [
                {"id": "take", "text": "Yes. Thank you, Mara.", "reply": [["mara", "Don't thank me. Just come back."]]},
                {"id": "refuse", "text": "I don't need charity.", "reply": [["mara", "Suit yourself. Offer stands."]]}]}
    var idle = [
        [["mara", "Every ghost down there has a story. Most of them are lying."]],
        [["mara", "I keep a list of the missing. It gets longer."]],
        [["mara", "If you see a grey coat, ask him about the lunch."]],
        [["mara", "You look tired. Dead people shouldn't look tired."]]]
    return {"key": "mara_idle", "lines": _pick(idle, d), "choices": []}

static func Game_bond(d):
    return int(d["bonds"].get("mara", 0))

static func _sable(d):
    var ch = [{"id": "ledger", "text": "Show me the Ledger."}, {"id": "leave", "text": "Not now."}]
    if not _seen(d, "sable_intro"):
        return {"key": "sable_intro", "lines": [
            ["sable", "Sable. Archivist. Dead, but employed."],
            ["sable", "Every god you spare, bind or end, I write down. The Ledger does not judge. I do, but quietly."]], "choices": ch}
    if d["wins"] >= 1 and not _seen(d, "sable_warden"):
        var w = d["warden"]
        var t = "You ended the Warden. I have struck its name from the roll."
        if w == "restore":
            t = "You restored the Warden. I have written: Mercy, first entry."
        elif w == "bind":
            t = "You bound the Warden. I have written: Power, taken. Cost, pending."
        return {"key": "sable_warden", "lines": [["sable", t], ["sable", "The Ledger remembers what you choose. Even when you would rather forget."]], "choices": ch}
    var idle = [
        [["sable", "Another day, another reckoning."]],
        [["sable", "The Ledger has room. It always has room."]],
        [["sable", "I have read every life in this station. Yours is getting interesting."]]]
    return {"key": "sable_idle", "lines": _pick(idle, d), "choices": ch}

static func _bryn(d):
    var ch = [{"id": "shop", "text": "Browse the forge."}, {"id": "leave", "text": "Not now."}]
    if not _seen(d, "bryn_intro"):
        return {"key": "bryn_intro", "lines": [
            ["bryn", "Bryn. I forge. Bring me Echoes, the leftovers of the forgotten, and I'll make you harder to kill."],
            ["bryn", "Everything I make lasts. Even after you don't."]], "choices": ch}
    if d["wins"] >= 1 and not _seen(d, "bryn_debt"):
        return {"key": "bryn_debt", "lines": [
            ["bryn", "I owed the Warden a favour once. Long story. You've settled it, one way or another."],
            ["bryn", "Keep swinging. I'll keep the fire hot."]], "choices": ch}
    var idle = [
        [["bryn", "Good steel hums when it's ready."]],
        [["bryn", "More Echoes, more edge. That's all there is to it."]],
        [["bryn", "Don't touch the anvil. It's still angry."]]]
    return {"key": "bryn_idle", "lines": _pick(idle, d), "choices": ch}

# Records the outcome of a conversation. Returns the choice id.
static func apply(npc, key, choice, d):
    var mark = true
    if key == "mara_intro":
        if choice == "promise":
            d["bonds"]["mara"] = int(d["bonds"].get("mara", 0)) + 1
            d["flags"]["mara_promise"] = true
        else:
            d["flags"]["mara_cold"] = true
    elif key == "mara_jonah":
        if choice == "refuse":
            mark = false
        else:
            if choice == "take":
                d["bonds"]["mara"] = int(d["bonds"].get("mara", 0)) + 1
            d["flags"]["second_wind"] = true
    if mark:
        d["talked"][key] = true
    return choice
