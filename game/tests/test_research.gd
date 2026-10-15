extends TestCase
## T-066: forskning + save v2.

const FIXTURE_V1: String = "res://tests/fixtures/save_v1.json"


func _def() -> ResearchDef:
	return ResearchDef.from_dict({
		"points_per_day_base": 10, "cost_per_level": [0, 500, 1000, 2000],
		"topics": [
			{"id": "gentle_rides", "name": "Rolige", "unlocks": ["ferris_wheel"]},
			{"id": "thrill_rides", "name": "Vilde", "unlocks": ["swing_ride", "go_karts"]},
			{"id": "scenery", "name": "Pynt", "unlocks": ["flowers"]},
		],
		"items": [
			{"id": "ferris_wheel", "topic": "gentle_rides", "points": 25},
			{"id": "flowers", "topic": "scenery", "points": 15},
			{"id": "swing_ride", "topic": "thrill_rides", "points": 30},
			{"id": "go_karts", "topic": "thrill_rides", "points": 30},
		],
		"start_unlocked": ["carousel", "burger_stand", "toilet", "bench"],
	})


func _sim(seed_v: int = 99) -> ParkSim:
	var s := ParkSim.new(40, 40, seed_v)
	s.research = Research.new(_def())
	s.research.setup(true)
	s.economy.money += 20000
	return s


func _end_days(s: ParkSim, n: int) -> void:
	for i in n:
		s._end_day()


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func _rt(d: Dictionary) -> Dictionary:
	return SaveCodec.parse(SaveCodec.stringify(d))


func _park_str(s: ParkSim) -> String:
	return SaveCodec.stringify(s.to_save()["park"])


func test_default_disabled_all_unlocked() -> void:
	var s := ParkSim.new(20, 20, 1)
	assert_true(not s.research.enabled)
	assert_true(s.is_unlocked("go_karts"))
	assert_true(s.is_unlocked("anything"))
	assert_eq(s.research_status()["enabled"], false)


func test_def_defaults_without_file() -> void:
	var d := ResearchDef.new()
	assert_eq(d.points_per_day_base, 10.0)
	assert_eq(d.cost_per_level, [0, 500, 1000, 2000] as Array[int])
	assert_true(d.start_unlocked.has("carousel") and d.start_unlocked.has("track_straight"))


func test_locked_placement_rejected() -> void:
	var s := _sim()
	assert_true(not s.is_unlocked("ferris_wheel"))
	assert_true(s.is_unlocked("carousel"))
	var money: int = s.economy.money
	assert_true(s.cmd_place_attraction("ferris_wheel", Vector2i(5, 5)) == null)
	assert_true(s.cmd_place_attraction("carousel", Vector2i(5, 5)) != null)
	assert_eq(s.cmd_place_decor("flowers", Vector2i(15, 15)), -1)
	assert_true(s.economy.money < money)


func test_funding_and_priority_validation() -> void:
	var s := _sim()
	assert_true(not s.cmd_set_research_funding(4))
	assert_true(not s.cmd_set_research_funding(-1))
	assert_true(s.cmd_set_research_funding(3))
	assert_true(not s.cmd_set_research_priority("nope"))
	assert_true(s.cmd_set_research_priority(""))
	assert_eq(s.research_status()["funding_level"], 3)


func test_progress_cost_and_unlock() -> void:
	var s := _sim()
	var got: Array = []
	var warns: Array = []
	s.research_unlocked.connect(func(id: String) -> void: got.append(id))
	s.warning.connect(func(c: StringName, d: Dictionary) -> void: warns.append([c, d]))
	assert_eq(s.research_status()["current_item"], "ferris_wheel")
	s.cmd_set_research_funding(1)
	var m0: int = s.economy.money
	_end_days(s, 1)
	assert_eq(m0 - s.economy.money, 500)
	assert_eq(int(s.economy.history[-1]["totals"].get("research", 0)), -500)
	assert_eq(s.research_status()["progress"], 10.0)
	_end_days(s, 2)  # 30 >= 25
	assert_eq(got, ["ferris_wheel"])
	assert_eq(warns.size(), 1)
	assert_eq(warns[0][0], &"research_done")
	assert_eq(warns[0][1], {"item_id": "ferris_wheel"})
	assert_true(s.is_unlocked("ferris_wheel"))
	assert_eq(s.research_status()["current_item"], "flowers")
	assert_eq(s.research_status()["progress"], 5.0)
	assert_eq(s.research_status()["points_needed"], 15.0)


func test_funding_zero_no_progress_no_cost() -> void:
	var s := _sim()
	var m0: int = s.economy.money
	_end_days(s, 3)
	assert_eq(s.economy.money, m0)
	assert_eq(s.research_status()["progress"], 0.0)


func test_priority_selects_topic() -> void:
	var s := _sim()
	assert_true(s.cmd_set_research_priority("thrill_rides"))
	assert_eq(s.research_status()["current_item"], "swing_ride")
	s.cmd_set_research_funding(3)
	_end_days(s, 1)  # 30 → swing_ride
	assert_true(s.is_unlocked("swing_ride"))
	assert_eq(s.research_status()["current_item"], "go_karts")
	_end_days(s, 1)
	assert_eq(s.research_status()["current_item"], "ferris_wheel")  # emnet er tømt → første ulåste
	_end_days(s, 5)
	assert_eq(s.research_status()["current_item"], "")
	assert_true(s.is_unlocked("flowers"))


func test_disabled_no_cost() -> void:
	var s := ParkSim.new(20, 20, 1)
	s.cmd_set_research_funding(3)
	var m0: int = s.economy.money
	s._end_day()
	assert_eq(s.economy.money, m0)


func test_save_roundtrip_with_research() -> void:
	var s := _sim()
	s.cmd_set_research_priority("scenery")
	s.cmd_set_research_funding(1)
	_end_days(s, 1)
	var b := ParkSim.from_save(_rt(s.to_save()))
	b.research.def = s.research.def
	assert_eq(b.research_status(), s.research_status())
	assert_eq(_park_str(b), _park_str(s))


func test_determinism_with_research() -> void:
	var s := ParkSim.new(40, 40, 555)
	s.research = Research.new(_def())
	s.research.setup(true)
	s.economy.money += 50000
	var e: Vector2i = s.world.entrance
	for y in range(e.y - 1, 29, -1):
		s.cmd_place_path(Vector2i(e.x, y))
	for x in range(e.x - 6, e.x + 7):
		if x != e.x:
			s.cmd_place_path(Vector2i(x, 30))
	assert_true(s.cmd_place_attraction("carousel", Vector2i(e.x - 2, 26)) != null)
	assert_true(s.cmd_place_attraction("burger_stand", Vector2i(e.x + 2, 29)) != null)
	s.cmd_set_research_funding(2)
	_step(s, s.balance.day_ticks + 300)
	var b := ParkSim.from_save(_rt(s.to_save()))
	b.research.def = s.research.def
	_step(s, s.balance.day_ticks * 2)
	_step(b, b.balance.day_ticks * 2)
	assert_true(s.research.unlocked.has("ferris_wheel"))
	assert_eq(_park_str(b), _park_str(s))


func test_migration_v1_adds_m5_keys() -> void:
	var v1: Dictionary = {"save_version": 1, "park": {"attractions": [{"id": 1}]}}
	var m: Dictionary = SaveMigrations.migrate(v1)
	assert_eq(m["save_version"], 2)
	assert_eq(m["park"]["research"], {})
	assert_true(m["park"].has("scenario") and m["park"]["scenario"] == null)
	assert_eq(m["park"]["attractions"][0]["cells"], [])
	assert_true(m["park"]["attractions"][0]["track"] == null)
	assert_eq(m["park"]["attractions"][0]["ratings"], {})


func test_v1_fixture_loads() -> void:
	assert_true(FileAccess.file_exists(FIXTURE_V1))
	var d: Dictionary = SaveCodec.parse(FileAccess.get_file_as_string(FIXTURE_V1))
	assert_eq(int(d["save_version"]), 1)
	var s := ParkSim.from_save(d)
	assert_true(s != null)
	var p: Dictionary = d["park"]
	assert_eq(s.attractions.size(), (p["attractions"] as Array).size())
	assert_eq(s.guests.size(), (p["guests"] as Array).size())
	assert_eq(s.economy.money, int(p["economy"]["money"]))
	assert_eq(s.day, int(p["day"]))
	assert_true(not s.research.enabled)
	assert_true(s.is_unlocked("ferris_wheel") and s.is_unlocked("go_karts"))
	_step(s, 200)  # kører videre uden fejl
	var again := ParkSim.from_save(_rt(s.to_save()))
	assert_eq(_park_str(again), _park_str(s))


func test_research_ids_exist_in_catalog() -> void:
	if not FileAccess.file_exists(ResearchDef.PATH):
		print("  NOTE: content/research.json mangler – katalog-test sprunget over")
		return
	var d := ResearchDef.load_default()
	var s := ParkSim.new(10, 10, 1)
	var missing: Array = []
	for id in d.all_ids():
		var ok: bool = s.get_def(id) != null or s.get_decor_def(id) != null
		if not ok and (id.begins_with("track_") or id == "coaster_station"):
			ok = FileAccess.file_exists("res://content/coaster/pieces.json") \
					and FileAccess.get_file_as_string("res://content/coaster/pieces.json").contains("\"%s\"" % id)
			if not FileAccess.file_exists("res://content/coaster/pieces.json"):
				ok = true  # stykkerne lander med T-065; tjekkes når filen findes
		if not ok:
			missing.append(id)
	assert_eq(missing, [], "ukendte id'er i research.json")
	for it in d.items:
		assert_true(d.has_topic(it["topic"]), "ukendt emne for %s" % it["id"])
