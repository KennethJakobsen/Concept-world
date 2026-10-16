extends TestCase
## T-134: sporbane-kort låst, indtil alle required_pieces er forsket.


func _sim() -> ParkSim:
	return ParkSim.new_from_scenario(ScenarioDef.find("green_meadow"), 1)


func test_wooden_coaster_card_locked_until_turns_researched() -> void:
	var hud := Hud.new()
	hud.sim = _sim()
	hud._build_ui()
	hud.refresh()
	var id: String = "coaster:wooden_coaster"
	assert_true(hud._build_buttons.has(id))
	var b: Button = hud._build_buttons[id]
	assert_true(not hud.sim.can_complete("wooden_coaster"))
	var txt: String = hud.build_lock_text(id)
	assert_true(txt.begins_with("Kræver forskning: Rutsjebaner – "), txt)
	assert_true(LockOverlay.is_locked(b))
	assert_true(b.disabled)
	assert_eq(b.tooltip_text, txt)
	for pid: String in hud.sim.missing_pieces("wooden_coaster"):
		hud.sim.research.unlocked[pid] = true
	hud.refresh()
	assert_eq(hud.build_lock_text(id), "")
	assert_true(not LockOverlay.is_locked(b))
	assert_true(b.tooltip_text != txt)
	hud.free()


func test_non_tracked_has_no_track_lock() -> void:
	var sim := _sim()
	assert_eq(LockOverlay.track_lock_text(sim, "carousel"), "")
