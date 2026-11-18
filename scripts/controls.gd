extends RefCounted

const KEYS := {
	"walk_up": [KEY_W, KEY_UP], "walk_down": [KEY_S, KEY_DOWN], "walk_left": [KEY_A, KEY_LEFT], "walk_right": [KEY_D, KEY_RIGHT],
	"sprint": [KEY_SHIFT], "interact": [KEY_E], "camera": [KEY_C], "orbit_left": [KEY_Q], "orbit_right": [KEY_R],
	"inventory": [KEY_TAB, KEY_I], "map_view": [KEY_M], "save_game": [KEY_P], "pause_game": [KEY_ESCAPE],
	"slot1": [KEY_1], "slot2": [KEY_2], "slot3": [KEY_3], "slot4": [KEY_4], "slot5": [KEY_5], "slot6": [KEY_6]
}

static func register() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
