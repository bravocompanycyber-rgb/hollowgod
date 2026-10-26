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
    _add_keys("interact", [KEY_E, KEY_ENTER, KEY_KP_ENTER])
    _add_keys("pause", [KEY_ESCAPE])
    _add_keys("cancel", [KEY_BACKSPACE])
    _add_keys("pick1", [KEY_1])
    _add_keys("pick2", [KEY_2])
    _add_keys("pick3", [KEY_3])
    _add_keys("pick4", [KEY_4])
    _add_keys("pick5", [KEY_5])
    _add_keys("fullscreen", [KEY_F11])
    _add_mouse("attack", BUTTON_LEFT)
    # Gamepad (Xbox-style layout)
    _add_axis("move_left", 0, -1.0)
    _add_axis("move_right", 0, 1.0)
    _add_axis("move_up", 1, -1.0)
    _add_axis("move_down", 1, 1.0)
    for a in ["move_left", "move_right", "move_up", "move_down"]:
        InputMap.action_set_deadzone(a, 0.3)
    _add_button("dash", 0)
    _add_button("dash", 4)
    _add_button("attack", 2)
    _add_button("attack", 5)
    _add_button("interact", 0)
    _add_button("cancel", 1)
    _add_button("pause", 11)
    _add_button("pick1", 14)
    _add_button("pick2", 12)
    _add_button("pick3", 15)
    _add_button("pick4", 13)

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

func _add_axis(action, axis, value):
    _add_action(action)
    var e = InputEventJoypadMotion.new()
    e.axis = axis
    e.axis_value = value
    InputMap.action_add_event(action, e)

func _add_button(action, button):
    _add_action(action)
    var e = InputEventJoypadButton.new()
    e.button_index = button
    InputMap.action_add_event(action, e)
