extends TestCase
## T-135: ParkView bygger omgivelser med scenariets tema, og der er kun én indgang.


func test_scenario_theme_and_single_entrance() -> void:
	for pair: Array in [["river_valley", "river"], ["mountain_peak", "mountain"], ["green_meadow", "countryside"]]:
		var def := ScenarioDef.find(pair[0])
		var sim := ParkSim.new_from_scenario(def, 1)
		var pv := ParkView.new()
		pv.setup(sim)
		assert_eq(pv.scenario_theme(), pair[1], pair[0])
		var s: Node = pv.find_child("Surroundings", true, false)
		assert_true(s is SurroundingsRenderer, pair[0] + ": omgivelser")
		assert_eq(str((s as SurroundingsRenderer).config["theme"]), pair[1])
		var n: int = 0
		for c: Node in pv.find_children("*", "", true, false):
			if c.scene_file_path.ends_with("entrance.tscn"):
				n += 1
		assert_eq(n, 0, "ingen gammel entrance.tscn ved siden af porten")
		pv.free()
