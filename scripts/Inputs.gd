extends Node
# Registers all game controls in code, so there is nothing to set up by hand.
# To change a key later, edit the lists below.

func _ready():
    _add_keys("move_left", [KEY_A, KEY_LEFT])
    _add_keys("move_right", [KEY_D, KEY_RIGHT])
    _add_keys("move_up", [KEY_W, KEY_UP])
    _add_keys("move_down", [KEY_S, KEY_DOWN])
    _add_keys("dash", [KEY_SPACE, KEY_SHIFT])
    _add_keys("attack", [KEY_J])
    _add_keys("restart", [KEY_R])
    _add_keys("pick1", [KEY_1])
    _add_keys("pick2", [KEY_2])
    _add_keys("pick3", [KEY_3])
    _add_keys("fullscreen", [KEY_F11])
    _add_mouse("attack", BUTTON_LEFT)

func _add_action(action):
    if not InputMap.has_action(action):
        InputMap.add_action(action)

func _add_keys(action, keys):
    _add_action(action)
    for k in keys:
        var e = InputEventKey.new()
        e.scancode = k
        InputMap.action_add_event(action, e)

func _add_mouse(action, button):
    _add_action(action)
    var e = InputEventMouseButton.new()
    e.button_index = button
    InputMap.action_add_event(action, e)
