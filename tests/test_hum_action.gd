# tests/test_hum_action.gd
extends RefCounted

func test_hum_action_exists() -> void:
	GameState._ensure_input_actions()
	TestHelper.is_true(InputMap.has_action("hum"),
		"InputMap must have 'hum' action after _ensure_input_actions")

func test_hum_action_has_keybind() -> void:
	GameState._ensure_input_actions()
	var events := InputMap.action_get_events("hum")
	TestHelper.is_true(events.size() >= 1, "hum action must have at least one event")

func test_hum_action_shares_z_and_enter() -> void:
	GameState._ensure_input_actions()
	var keys: Array = []
	for ev in InputMap.action_get_events("hum"):
		if ev is InputEventKey:
			keys.append((ev as InputEventKey).physical_keycode)
	TestHelper.is_true(KEY_Z in keys, "hum must bind Z")
	TestHelper.is_true(KEY_ENTER in keys, "hum must bind Enter")