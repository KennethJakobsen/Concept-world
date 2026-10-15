extends TestCase


func _bound(action: StringName, key: Key) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and (e as InputEventKey).physical_keycode == key:
			return true
	return false


func test_actions_exist() -> void:
	for a in [&"cam_left", &"cam_right", &"cam_forward", &"cam_back", &"cam_rotate_left", &"cam_rotate_right"]:
		assert_true(InputMap.has_action(a))


func test_wasd_bound() -> void:
	assert_true(_bound(&"cam_forward", KEY_W))
	assert_true(_bound(&"cam_left", KEY_A))
	assert_true(_bound(&"cam_back", KEY_S))
	assert_true(_bound(&"cam_right", KEY_D))
	assert_true(_bound(&"cam_forward", KEY_UP))
	assert_true(_bound(&"cam_rotate_left", KEY_Q))
	assert_true(_bound(&"cam_rotate_right", KEY_E))
