extends TestCase
## T-067: scenarier, mål, sejr/nederlag.


func _def(extra: Dictionary = {}) -> ScenarioDef:
	var d: Dictionary = {
		"id": "t_scn", "name": "Test", "order": 5,
		"map": {"width": 30, "height": 30, "entrance": [15, 29]},
		"start": {"money": 5000, "reputation": 40, "paths": [[15, 29], [15, 28], [15, 27], [15, 26]],
			"attractions": [{"def": "carousel", "origin": [16, 24]}], "decor": [{"def": "bench", "cell": [15, 27]}],
			"staff": [], "unlocked": ["ferris_wheel"], "research_enabled": true, "entry_fee": 7},
		"objectives": [{"type": "money_min", "value": 6000}],
		"deadline_days": 0, "lose": [],
	}
	d.merge(extra, true)
	return ScenarioDef.from_dict(d)


func _end_days(s: ParkSim, n: int) -> void:
	for i in n:
		s._end_day()


func test_list_all_sorted() -> void:
	var all: Array[ScenarioDef] = ScenarioDef.list_all()
	assert_true(all.size() >= 4)
	for i in range(1, all.size()):
		assert_true(all[i - 1].order <= all[i].order)
	assert_eq(all[0].id, "sandbox")
	assert_true(all[0].is_sandbox())


func test_from_json_real() -> void:
	var d: ScenarioDef = ScenarioDef.from_json("res://content/scenarios/green_meadow.json")
	assert_true(d != null)
	assert_eq(d.id, "green_meadow")
	assert_eq(d.map_size, Vector2i(48, 48))
	assert_eq(d.decor[0]["def"], "bench")
	assert_eq(d.objectives.size(), 2)
	assert_true(ScenarioDef.from_json("res://nope.json") == null)


func test_all_real_scenarios_setup() -> void:
	for d in ScenarioDef.list_all():
		var s := ParkSim.new_from_scenario(d, 1)
		assert_eq(s.attractions.size(), d.attractions.size())
		assert_eq(s.decor.size(), d.decor.size())
		assert_eq(s.economy.money, d.start_money)
		assert_eq(s.world.width, d.map_size.x)
		assert_eq(s.research.enabled, d.research_enabled)
		assert_eq(s.scenario == null, d.is_sandbox())


func test_new_from_scenario() -> void:
	var s := ParkSim.new_from_scenario(_def(), 3)
	assert_eq(s.world.width, 30)
	assert_eq(s.world.entrance, Vector2i(15, 29))
	assert_eq(s.economy.money, 5000)
	assert_eq(s.reputation, 40.0)
	assert_eq(s.entry_fee, 7)
	assert_eq(s.attractions.size(), 1)
	assert_eq(s.decor.size(), 1)
	assert_true(s.research.enabled)
	assert_true(s.is_unlocked("ferris_wheel"))
	assert_true(s.is_unlocked("carousel"))
	assert_true(not s.is_unlocked("go_karts"))
	assert_eq(s.scenario.state, Scenario.RUNNING)


func test_custom_entrance() -> void:
	var s := ParkSim.new_from_scenario(_def({"map": {"width": 30, "height": 30, "entrance": [0, 10]}}), 1)
	assert_eq(s.world.get_tile(Vector2i(0, 10)), ParkWorld.Tile.ENTRANCE)
	assert_eq(s.world.get_tile(Vector2i(15, 29)), ParkWorld.Tile.PATH)


func test_park_value() -> void:
	var s := ParkSim.new_from_scenario(_def(), 1)
	var built: int = s.get_def("carousel").build_cost + s.get_decor_def("bench").build_cost
	assert_eq(s.park_value(), int(floor(built * 0.8)) + 5000)


func _won_by(type: String, value: float, setup: Callable) -> void:
	var s := ParkSim.new_from_scenario(_def({"objectives": [{"type": type, "value": value}]}), 1)
	var got: Array = []
	s.scenario_finished.connect(func(w: bool, r: String) -> void: got.append([w, r]))
	s.research.setup(false)
	s.economy.money = 0
	s.reputation = 0.0
	_end_days(s, 1)
	assert_eq(s.scenario.state, Scenario.RUNNING)
	setup.call(s)
	_end_days(s, 1)
	assert_eq(s.scenario.state, Scenario.WON)
	assert_eq(got, [[true, "objectives"]])
	assert_eq(s.scenario_status()["objectives"][0]["met"], true)


func test_obj_guests() -> void:
	_won_by("guests_in_park", 2, func(s: ParkSim) -> void:
		s.guests[900] = Guest.new(900, Vector2i(15, 28))
		s.guests[901] = Guest.new(901, Vector2i(15, 28)))


func test_obj_reputation() -> void:
	_won_by("reputation_min", 70, func(s: ParkSim) -> void: s.reputation = 71.0)


func test_obj_money() -> void:
	_won_by("money_min", 6000, func(s: ParkSim) -> void: s.economy.money = 1000000)


func test_obj_park_value() -> void:
	_won_by("park_value_min", 50000, func(s: ParkSim) -> void: s.economy.money = 1000000)


func test_obj_rides_count() -> void:
	_won_by("rides_count_min", 2, func(s: ParkSim) -> void:
		s.economy.money = 100000
		assert_true(s.cmd_place_attraction("ferris_wheel", Vector2i(3, 3)) != null)
		s.economy.money = 0)


func test_obj_coaster_excitement() -> void:
	_won_by("coaster_excitement_min", 5.0, func(s: ParkSim) -> void:
		var cd := AttractionDef.from_dict({"id": "fake_coaster", "kind": "coaster", "footprint": [1, 1], "build_cost": 0})
		s.register_def(cd)
		s.economy.money = 0
		var a: Attraction = s.world.place_coaster(cd, Vector2i(3, 3), Vector2i(3, 4))
		a.ratings = {"excitement": 5.5})


func test_deadline_lost() -> void:
	var s := ParkSim.new_from_scenario(_def({"deadline_days": 3, "objectives": [{"type": "money_min", "value": 1e9}]}), 1)
	var got: Array = []
	s.scenario_finished.connect(func(w: bool, r: String) -> void: got.append([w, r]))
	_end_days(s, 2)
	assert_eq(s.scenario.state, Scenario.RUNNING)
	_end_days(s, 1)
	assert_eq(s.scenario.state, Scenario.LOST)
	assert_eq(got, [[false, "deadline"]])
	_end_days(s, 3)  # ingen videre evaluering
	assert_eq(got.size(), 1)
	assert_eq(s.scenario.days_elapsed, 3)


func test_win_beats_deadline_same_day() -> void:
	var s := ParkSim.new_from_scenario(_def({"deadline_days": 1, "objectives": [{"type": "money_min", "value": 10}]}), 1)
	s.economy.money = 1000000
	_end_days(s, 1)
	assert_eq(s.scenario.state, Scenario.WON)


func test_win_beats_lose_same_day() -> void:
	var s := ParkSim.new_from_scenario(_def({"objectives": [{"type": "reputation_min", "value": 10}],
		"lose": [{"type": "money_below", "value": 0, "days": 1}]}), 1)
	s.economy.money = -100
	s.reputation = 50.0
	_end_days(s, 1)
	assert_eq(s.scenario.state, Scenario.WON)


func test_lose_streak_resets() -> void:
	var s := ParkSim.new_from_scenario(_def({"objectives": [{"type": "money_min", "value": 1e9}],
		"lose": [{"type": "reputation_below", "value": 20, "days": 3}]}), 1)
	var got: Array = []
	s.scenario_finished.connect(func(w: bool, r: String) -> void: got.append([w, r]))
	s.reputation = 10.0
	_end_days(s, 2)
	assert_eq(s.scenario.lose_streaks["0"], 2)
	s.reputation = 30.0
	_end_days(s, 1)
	assert_eq(s.scenario.lose_streaks["0"], 0)
	s.reputation = 10.0
	_end_days(s, 2)
	assert_eq(s.scenario.state, Scenario.RUNNING)
	_end_days(s, 1)
	assert_eq(s.scenario.state, Scenario.LOST)
	assert_eq(got, [[false, "reputation_below"]])


func test_money_below_streak() -> void:
	var s := ParkSim.new_from_scenario(_def({"objectives": [{"type": "money_min", "value": 1e9}],
		"lose": [{"type": "money_below", "value": -5000, "days": 2}]}), 1)
	s.economy.money = -6000
	_end_days(s, 2)
	assert_eq(s.scenario.state, Scenario.LOST)
	assert_eq(s.scenario.reason, "money_below")


func test_sim_continues_after_finish() -> void:
	var s := ParkSim.new_from_scenario(_def({"deadline_days": 1, "objectives": [{"type": "money_min", "value": 1e9}]}), 1)
	_end_days(s, 1)
	var d: int = s.day
	_end_days(s, 2)
	assert_eq(s.day, d + 2)


func test_sandbox_and_old_saves() -> void:
	var sb: ScenarioDef = ScenarioDef.find("sandbox")
	var s := ParkSim.new_from_scenario(sb, 1)
	assert_true(s.scenario == null)
	assert_eq(s.scenario_status(), {})
	assert_true(s.is_unlocked("go_karts"))
	var plain := ParkSim.new(20, 20, 1)
	var save: Dictionary = plain.to_save()
	assert_true(save["park"]["scenario"] == null)
	save["park"].erase("scenario")
	var l: ParkSim = ParkSim.from_save(save)
	assert_true(l.scenario == null)
	_end_days(l, 2)  # ingen fejl


func test_save_load_mid_scenario() -> void:
	var def := _def({"objectives": [{"type": "money_min", "value": 1e9}], "deadline_days": 10,
		"lose": [{"type": "reputation_below", "value": 20, "days": 3}]})
	var s := ParkSim.new_from_scenario(def, 7)
	s.reputation = 10.0
	_end_days(s, 2)
	var save: Dictionary = SaveCodec.parse(SaveCodec.stringify(s.to_save()))
	var l: ParkSim = ParkSim.from_save(save, null, [def])
	assert_eq(l.scenario.days_elapsed, 2)
	assert_eq(l.scenario.lose_streaks["0"], 2)
	assert_eq(l.scenario.def.id, "t_scn")
	for x: ParkSim in [s, l]:
		for i in 400:
			x.update(SimClock.TICK_DELTA)
	assert_eq(SaveCodec.stringify(l.to_save()["park"]), SaveCodec.stringify(s.to_save()["park"]))
	l.reputation = 10.0
	_end_days(l, 1)
	assert_eq(l.scenario.state, Scenario.LOST)


func test_save_load_real_scenario_finds_def() -> void:
	var s := ParkSim.new_from_scenario(ScenarioDef.find("green_meadow"), 2)
	_end_days(s, 1)
	var l: ParkSim = ParkSim.from_save(SaveCodec.parse(SaveCodec.stringify(s.to_save())))
	assert_eq(l.scenario.def.id, "green_meadow")
	assert_eq(l.scenario_status()["deadline_days"], 40)
