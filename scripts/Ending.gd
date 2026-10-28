extends Node2D
# The ending: a few story pages, THE END, then the credits. Which ending you see depends on your choices.

const DATA = {
    "The Keeper": {
        "pages": [
            "The Hollow shudders, and for the first time in an age, it remembers what it swallowed.",
            "One by one the gods return: the Warden with his scales, the Jarl with his hearth, the Lord with his nine roads.",
            "They are weaker than before, and kinder. They ask only that you keep the doors between the worlds.",
            "Meridian wakes to a quiet morning. Somewhere under the station, a lantern burns. Oru has never been so tired, or so proud."],
        "sprites": ["big_demon_idle_anim", "ogre_idle_anim", "skeleton_idle_anim"]
    },
    "The Usurper": {
        "pages": [
            "You reach into the Hollow and close your hand around everything it held.",
            "The gods kneel, because there is nothing else left for them to do. Every crown of every road is yours.",
            "Power is a patient thing. It does not demand payment. It simply waits.",
            "Meridian prospers beneath a lantern that never goes out. Oru watches you, and says nothing at all."],
        "sprites": ["skeleton_idle_anim"]
    },
    "The Wake": {
        "pages": [
            "You open your hand, and the Hollow lets go.",
            "The gods are free, and so are the dead. The roads empty out. The halls fall silent.",
            "Nothing answers prayers any more. Humanity wakes to a sky with no one watching it.",
            "It is lonely. It is also theirs. Oru fades like a candle, smiling."],
        "sprites": []
    },
    "The Ferryman": {
        "pages": [
            "You have mended, taken, and let go. Three roads, three different answers.",
            "The Hollow understands, at last, that an ending is not one thing.",
            "You take the oar of the ferry the dead have always needed. The gods keep their halls; the dead keep their rest.",
            "You will carry them across for as long as there are shores. Oru takes the lantern and walks beside you."],
        "sprites": ["elf_f_idle_anim", "wizard_f_idle_anim"]
    },
    "The Hollow Crown": {
        "pages": [
            "You took too much, from too many.",
            "The Hollow does not fight you. It simply wears you, as it wore the gods.",
            "Your lantern goes out. Your name is the last thing to go.",
            "Somewhere in Meridian, a new voice speaks from the dark. It sounds just like Oru's. It is not."],
        "sprites": ["necromancer_idle_anim"]
    },
    "The Truth": {
        "pages": [
            "You do not strike. You take Oru's hand, and the Hollow stops.",
            "It was never a monster. It was the grief of every god who lost a world, grown too large to carry alone.",
            "Jonah's lighter flares in your pocket, and a grey coat steps out of the dark, owing someone lunch.",
            "The gods mourn together at last. The Hollowing ends. Oru is, for once, completely speechless. And then he laughs."],
        "sprites": ["elf_f_idle_anim", "wizard_f_idle_anim", "orc_warrior_idle_anim"]
    }
}

const CREDITS = "H O L L O W G O D\n\n\nA game by\nB R A V O C O M P A N Y C Y B E R\n\n\nA game of descents and choices\n\n\nART\nDungeonTileset II by Robert (0x72)\nCC0 public domain\n\n\nINTERFACE SOUNDS\nKenney (kenney.nl)\nCC0 public domain\n\n\nFONTS\nDejaVu Sans and DejaVu Serif Bold\n\n\nBUILT WITH\nGodot Engine 3.5\n\n\nDESIGN, STORY AND CODE\nBravocompanycyber\n\n\nThank you for playing."

var ending = "The Keeper"
var pages = []
var idx = 0
var phase = "pages"
var chars = 0.0
var typing = true
var clock = 0.0
var text_label = null
var hint_label = null
var title_label = null
var sub_label = null
var credits_label = null
var layer = null
var fade = null
var deco = null

func _ready():
    FX.reset()
    Sfx.music("hub")
    ending = Game.pending_ending if DATA.has(Game.pending_ending) else "The Keeper"
    pages = DATA[ending]["pages"]
    layer = CanvasLayer.new()
    add_child(layer)
    var bg = ColorRect.new()
    bg.rect_size = Vector2(1280, 720)
    bg.color = Color(0.02, 0.02, 0.05)
    layer.add_child(bg)
    deco = load("res://scripts/Deco.gd").new()
    deco.mat_scale = 6.0
    var items = [{"name": "knight_m_idle_anim", "pos": Vector2(640, 600), "scale": 6.0, "fps": 5.0}]
    var sp = DATA[ending]["sprites"]
    for i in range(sp.size()):
        var x = 640 + (i + 1) * 130 * (1 if i % 2 == 0 else -1)
        items.append({"name": sp[i], "pos": Vector2(x, 596), "scale": 5.0, "fps": 5.0, "mod": Color(0.85, 0.85, 1.0, 0.9)})
    deco.items = items
    layer.add_child(deco)
    FX.add_vignette(layer)
    text_label = FX.label(layer, Vector2(240, 190), "", 28, Color(0.96, 0.93, 0.85), true)
    text_label.autowrap = true
    text_label.rect_size = Vector2(800, 260)
    text_label.align = Label.ALIGN_CENTER
    hint_label = FX.label(layer, Vector2(0, 676), "[E] continue", 15, Color(1, 1, 1, 0.5))
    hint_label.rect_size = Vector2(1280, 20)
    hint_label.align = Label.ALIGN_CENTER
    title_label = FX.label(layer, Vector2(0, 170), "", 64, Color(0.95, 0.78, 0.3), true)
    title_label.rect_size = Vector2(1280, 80)
    title_label.align = Label.ALIGN_CENTER
    sub_label = FX.label(layer, Vector2(0, 270), "", 22, Color(0.9, 0.9, 0.95))
    sub_label.rect_size = Vector2(1280, 60)
    sub_label.align = Label.ALIGN_CENTER
    credits_label = FX.label(layer, Vector2(0, 720), CREDITS, 24, Color(0.95, 0.93, 0.88), true)
    credits_label.rect_size = Vector2(1280, 1400)
    credits_label.align = Label.ALIGN_CENTER
    credits_label.visible = false
    fade = ColorRect.new()
    fade.rect_size = Vector2(1280, 720)
    fade.color = Color(0, 0, 0, 1)
    fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(fade)
    var tw = Tween.new()
    fade.add_child(tw)
    tw.interpolate_property(fade, "color:a", 1.0, 0.0, 1.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tw.start()
    _show_page()

func _show_page():
    text_label.text = pages[idx]
    text_label.visible_characters = 0
    chars = 0.0
    typing = true

func _process(delta):
    clock += delta
    if phase == "pages" and typing:
        chars += delta * 38.0
        text_label.visible_characters = int(chars)
        if int(chars) >= text_label.text.length():
            typing = false
            text_label.visible_characters = -1
    if phase == "credits":
        credits_label.rect_position.y -= delta * 48.0
        if credits_label.rect_position.y < -1250.0:
            _finish()
    if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack"):
        advance()

func advance():
    if phase == "pages":
        if typing:
            typing = false
            text_label.visible_characters = -1
            return
        idx += 1
        if idx >= pages.size():
            _show_end()
        else:
            _show_page()
    elif phase == "end":
        _start_credits()
    elif phase == "credits":
        _finish()

func _show_end():
    phase = "end"
    text_label.text = ""
    title_label.text = "THE END"
    sub_label.text = "Ending: %s\n%d of 6 endings found" % [ending, Game.endings_found()]
    Sfx.play("levelup")

func _start_credits():
    phase = "credits"
    title_label.text = ""
    sub_label.text = ""
    hint_label.text = "[E] skip"
    credits_label.visible = true
    credits_label.rect_position.y = 720.0

func _finish():
    if phase == "done":
        return
    phase = "done"
    Game.pending_ending = ""
    Game.save()
    Game.goto("res://scenes/Hub.tscn")
