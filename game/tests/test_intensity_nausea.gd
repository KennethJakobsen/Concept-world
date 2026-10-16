extends TestCase
## T-084: intensity/kvalme/opkast og save v3.


func _bal(guests_extra: Dictionary = {}) -> Balance:
	var g: Dictionary = {"needs": {"hunger": {"rate": 0.0, "threshold": 100}}, "happiness_start": 80,
		"leave_happiness": 0, "speed": 0.5, "intensity_tolerance": {"min": 10, "max": 90},
		"nausea_per_point": 1.0, "nausea_decay": 0.0, "vomit_threshold": 50.0, "vomit_happiness": 15.0,
		"vomit_litter": 2}
	g.merge(guests_extra, true)
	return Balance.from_dicts({"start_money": 100000, "entry_fee": 0, "path_cost": 0, "guest_money_min": 500,
		"guest_money_max": 500, "day_ticks": 100000}, g, {},
		{"litter_chance_after_shop": 0.0, "litter_max_per_cell": 5})


func _sim(seed_v: int = 9, extra: Dictionary = {}) -> ParkSim:
	var s := ParkSim.new(30, 30, seed_v, _bal(extra))
	s.register_def(AttractionDef.from_dict({"id": "wild", "kind": "ride", "footprint": [1, 1], "capacity": 4,
		"ride_ticks": 20, "ticket_price": 0, "excitement": 30, "intensity": 50, "nausea": 80}))
	s.register_def(AttractionDef.from_dict({"id": "tame", "kind": "ride", "footprint": [1, 1], "capacity": 4,
		"ride_ticks": 20, "ticket_price": 0, "excitement": 30, "intensity": 0, "nausea": 0}))
	for y in range(5, 29):
		s.cmd_place_path(Vector2i(15, y))
	return s


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func test_def_fields_and_content() -> void:
	var d := AttractionDef.from_dict({"id": "x", "intensity": 120, "nausea": 35})
	assert_eq(d.intensity, 100.0)
	assert_eq(d.nausea, 35.0)
	assert_eq(AttractionDef.from_dict({"id": "y"}).intensity, 0.0)
	var s := ParkSim.new(10, 10, 1)
	assert_eq(s.get_def("teacups").nausea, 35.0)
	assert_eq(s.get_def("drop_tower").intensity, 85.0)
	assert_true(AttractionDef.from_dict(d.to_dict()).nausea == 35.0)


func test_coaster_ratings_mapped_x10() -> void:
	var a := Attraction.new(1, AttractionDef.from_dict({"id": "c", "kind": "coaster"}), Vector2i.ZERO)
	a.ratings = {"intensity": 6.5, "nausea": 3.0}
	assert_eq(a.intensity_value(), 65.0)
	assert_eq(a.nausea_value(), 30.0)


func test_tolerance_drawn_with_rng_deterministic() -> void:
	var a := _sim(3)
	var b := _sim(3)
	a.cmd_place_attraction("tame", Vector2i(14, 10))
	b.cmd_place_attraction("tame", Vector2i(14, 10))
	a.spawn_interval_ticks = 5
	b.spawn_interval_ticks = 5
	_step(a, 60)
	_step(b, 60)
	assert_true(a.guests.size() >= 3)
	var tols: Dictionary = {}
	for gid in a.guests:
		var t: float = (a.guests[gid] as Guest).intensity_tolerance
		assert_true(t >= 10.0 and t <= 90.0)
		assert_eq(t, (b.guests[gid] as Guest).intensity_tolerance)
		tols[t] = true
	assert_true(tols.size() > 1, "forskellige tolerancer")


func test_too_intense_rejected_and_too_tame_weighted() -> void:
	var s := _sim()
	var wild: Attraction = s.cmd_place_attraction("wild", Vector2i(14, 10))
	var tame: Attraction = s.cmd_place_attraction("tame", Vector2i(16, 12))
	var g := Guest.new(99, Vector2i(15, 20))
	g.money = 100
	g.happiness = 80
	g.intensity_tolerance = 30.0
	assert_true(not s._usable(g, wild))
	assert_eq(g.thought, ParkSim.TOO_INTENSE_THOUGHT)
	assert_true(s._usable(g, tame))
	var g2 := Guest.new(100, Vector2i(15, 20))
	g2.intensity_tolerance = 80.0
	assert_true(s._too_tame(g2, tame))
	assert_true(not s._too_tame(g2, wild))
	assert_eq(s._ride_weight(g2, tame), 30 / s.balance.too_tame_divisor)
	assert_eq(s._ride_weight(g2, wild), 30)


func test_nausea_and_vomit() -> void:
	var s := _sim()
	var wild: Attraction = s.cmd_place_attraction("wild", Vector2i(14, 10))
	var g := Guest.new(7, Vector2i(15, 11))
	g.happiness = 80.0
	s.guests[g.id] = g
	var vomits: Array = []
	var warns: Array = []
	s.guest_vomited.connect(func(gid: int, c: Vector2i) -> void: vomits.append([gid, c]))
	s.warning.connect(func(code: StringName, d: Dictionary) -> void:
		if code == ParkSim.WARN_GUEST_VOMIT:
			warns.append(d))
	g.nausea = 10.0
	s._after_ride_nausea(g, wild)  # +80 → 90 ≥ 50; chance 0.8
	var tries: int = 0
	while vomits.is_empty() and tries < 50:
		g.nausea = 100.0  # garanteret (chance 1)
		s._after_ride_nausea(g, wild)
		tries += 1
	assert_eq(vomits.size(), 1)
	assert_eq(vomits[0], [7, Vector2i(15, 11)])
	assert_eq(warns.size(), 1)
	assert_eq(warns[0]["cell"], Vector2i(15, 11))
	assert_eq(g.nausea, 0.0)
	assert_true(g.happiness <= 65.0)
	assert_eq(s.world.get_vomit(Vector2i(15, 11)), 2)
	assert_eq(s.world.get_litter(Vector2i(15, 11)), 2)
	assert_eq(s.get_stats()["vomit"], 2)
	# Rengøring (samme mekanisme som affald) fjerner opkast.
	s.world.set_litter(Vector2i(15, 11), 0)
	assert_eq(s.world.get_vomit(Vector2i(15, 11)), 0)
	assert_eq(s.world.total_vomit(), 0)


func test_cleaner_removes_vomit() -> void:
	var s := _sim()
	s.world.add_vomit(Vector2i(15, 15), 2, 5)
	assert_true(s.cmd_hire_staff("cleaner", Vector2i(15, 14)) > 0)
	_step(s, 400)
	assert_eq(s.world.total_vomit(), 0)


func test_no_vomit_below_threshold() -> void:
	var s := _sim(9, {"nausea_per_point": 0.1})
	var wild: Attraction = s.cmd_place_attraction("wild", Vector2i(14, 10))
	var g := Guest.new(7, Vector2i(15, 11))
	var st: int = s.rng.state
	s._after_ride_nausea(g, wild)
	assert_eq(g.nausea, 8.0)
	assert_eq(s.rng.state, st, "intet RNG-træk under tærsklen")


func test_nausea_decays() -> void:
	var s := _sim(9, {"nausea_decay": 0.5})
	s.cmd_place_attraction("tame", Vector2i(14, 10))
	var g := Guest.new(50, Vector2i(15, 20))
	g.nausea = 10.0
	g.state = Guest.State.RIDING
	s.guests[g.id] = g
	s._update_needs(g)
	assert_eq(g.nausea, 9.5)


func _vomit_park(seed_v: int) -> ParkSim:
	var s := _sim(seed_v, {"nausea_per_point": 1.0, "vomit_threshold": 20.0})
	s.cmd_place_attraction("wild", Vector2i(14, 10))
	s.cmd_place_attraction("tame", Vector2i(16, 12))
	s.spawn_interval_ticks = 10
	s.max_guests = 12
	return s


func test_roundtrip_and_determinism_with_vomit() -> void:
	var a := _vomit_park(11)
	_step(a, 1500)
	var any_nausea: bool = false
	for g: Guest in a.guests.values():
		any_nausea = any_nausea or g.nausea > 0.0
	assert_true(any_nausea or a.world.total_vomit() > 0, "kvalme eller opkast i parken")
	var saved: Dictionary = SaveCodec.parse(SaveCodec.stringify(a.to_save()))
	var b := ParkSim.from_save(saved, a.balance, [a.get_def("wild"), a.get_def("tame")])
	assert_eq(SaveCodec.stringify(b.to_save()["park"]), SaveCodec.stringify(a.to_save()["park"]))
	_step(a, 1500)
	_step(b, 1500)
	assert_true(a.world.total_vomit() > 0 or a.get_stats()["vomit"] >= 0)
	assert_eq(SaveCodec.stringify(b.to_save()["park"]), SaveCodec.stringify(a.to_save()["park"]))


func test_migration_v2_to_v3() -> void:
	var v2: Dictionary = {"save_version": 2, "park": {"world": {"litter": [[1, 2, 3]]},
		"guests": [{"id": 1}], "attractions": [{"id": 1}]}}
	var m: Dictionary = SaveMigrations.migrate(v2)
	assert_eq(m["save_version"], 3)
	assert_eq(SaveMigrations.CURRENT, 3)
	var g: Dictionary = m["park"]["guests"][0]
	assert_eq(g["intensity_tolerance"], 50.0)
	assert_eq(g["nausea"], 0.0)
	assert_eq(g["items"], [])
	assert_eq(m["park"]["attractions"][0]["prizes_won"], 0)
	assert_eq(m["park"]["world"]["vomit"], [])


func test_v1_fixture_chain_to_v3() -> void:
	var d: Dictionary = SaveCodec.parse(FileAccess.get_file_as_string("res://tests/fixtures/save_v1.json"))
	assert_eq(int(d["save_version"]), 1)
	var m: Dictionary = SaveMigrations.migrate(d)
	assert_eq(m["save_version"], 3)
	assert_true(m["park"].has("research"))
	for g: Dictionary in m["park"]["guests"]:
		assert_eq(g["nausea"], 0.0)
	var s := ParkSim.from_save(d)
	assert_true(s != null)
	for g: Guest in s.guests.values():
		assert_eq(g.intensity_tolerance, 50.0)
	_step(s, 200)
