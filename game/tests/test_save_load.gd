extends TestCase
## T-036: save/load, determinisme, migration.


func _startpark(seed_v: int = 777) -> ParkSim:
	var s := ParkSim.new(40, 40, seed_v)
	s.economy.money += 5000
	var e: Vector2i = s.world.entrance
	for y in range(e.y - 1, 29, -1):
		s.cmd_place_path(Vector2i(e.x, y))
	for x in range(e.x - 6, e.x + 7):
		if x != e.x:
			s.cmd_place_path(Vector2i(x, 30))
	assert_true(s.cmd_place_attraction("carousel", Vector2i(e.x - 2, 26)) != null)
	assert_true(s.cmd_place_attraction("burger_stand", Vector2i(e.x + 2, 29)) != null)
	assert_true(s.cmd_place_attraction("drinks_stand", Vector2i(e.x + 4, 29)) != null)
	assert_true(s.cmd_place_attraction("toilet", Vector2i(e.x - 4, 29)) != null)
	return s


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func _json_roundtrip(d: Dictionary) -> Dictionary:
	return SaveCodec.parse(SaveCodec.stringify(d))


func _park_str(s: ParkSim) -> String:
	return SaveCodec.stringify(s.to_save()["park"])


func test_envelope() -> void:
	var d: Dictionary = _startpark().to_save()
	assert_eq(d["save_version"], SaveMigrations.CURRENT)
	assert_true(d.has("game_version") and d.has("created") and d.has("park"))


func test_roundtrip_identical() -> void:
	var a := _startpark()
	_step(a, 3000)
	assert_true(not a.guests.is_empty())
	var b := ParkSim.from_save(_json_roundtrip(a.to_save()))
	assert_true(b != null)
	assert_eq(_park_str(b), _park_str(a))
	assert_eq(b.attractions.size(), 4)
	assert_true(b.world.attractions[0] == b.attractions[0], "samme objekt i world og sim")
	assert_eq(b.world.get_tile(b.attractions[0].origin), ParkWorld.Tile.ATTRACTION)


func test_determinism_after_load() -> void:
	var a := _startpark()
	_step(a, 1500)  # midt i dag 1 med gæster i kø/tur – dagsskift sker efter load
	var b := ParkSim.from_save(_json_roundtrip(a.to_save()))
	var days: Array = [0]
	b.day_passed.connect(func(_d: int) -> void: days[0] += 1)
	_step(a, 2000)
	_step(b, 2000)
	assert_eq(_park_str(b), _park_str(a))
	assert_true(days[0] >= 1, "signaler genskabt (day_passed)")
	assert_eq(a.economy.money, b.economy.money)
	assert_eq(a.rng.state, b.rng.state)


func test_stub_def_snapshot_and_fixed_spawn() -> void:
	var bal := Balance.from_dicts({"start_money": 10000, "day_ticks": 500}, {"needs": {"hunger": {"rate": 0.1, "threshold": 50}}})
	var a := ParkSim.new(20, 20, 3, bal)
	a.register_def(AttractionDef.from_dict({"id": "stub", "kind": "ride", "footprint": [1, 1],
		"capacity": 2, "ride_ticks": 30, "ticket_price": 2, "excitement": 9}))
	for y in range(15, 19):
		a.cmd_place_path(Vector2i(10, y))
	a.cmd_place_attraction("stub", Vector2i(10, 13))
	a.spawn_interval_ticks = 7
	a.max_guests = 6
	_step(a, 400)
	var b := ParkSim.from_save(_json_roundtrip(a.to_save()), bal)
	assert_eq(b.attractions[0].def.excitement, 9)
	assert_true(b.fixed_spawn)
	assert_eq(b.spawn_interval_ticks, 7)
	_step(a, 2000)
	_step(b, 2000)
	assert_eq(_park_str(b), _park_str(a))


func test_rng_state_large_values() -> void:
	var a := ParkSim.new(10, 10, 9223372036854775000)
	for i in 50:
		a.rng.randi()
	var b := ParkSim.from_save(_json_roundtrip(a.to_save()))
	assert_eq(b.rng.seed, a.rng.seed)
	assert_eq(b.rng.state, a.rng.state)
	assert_eq(b.rng.randi(), a.rng.randi())


func test_migration_v0_to_v1() -> void:
	var a := _startpark()
	_step(a, 2000)
	var park: Dictionary = _json_roundtrip(a.to_save())["park"]
	# byg en v0-save: ingen envelope, flade needs_* felter
	var v0: Dictionary = park.duplicate(true)
	v0["save_version"] = 0
	for g: Dictionary in v0["guests"]:
		for k: String in g["needs"]:
			g["needs_" + k] = g["needs"][k]
		g.erase("needs")
	var m: Dictionary = SaveMigrations.migrate(v0)
	assert_eq(m["save_version"], SaveMigrations.CURRENT)
	assert_true(m.has("park"))
	var b := ParkSim.from_save(v0)
	assert_true(b != null)
	assert_eq(_park_str(b), _park_str(a))


func test_newer_version_rejected() -> void:
	var d: Dictionary = _startpark().to_save()
	d["save_version"] = SaveMigrations.CURRENT + 1
	assert_true(ParkSim.from_save(d) == null)
	assert_true(ParkSim.from_save({}) == null)


func test_float_codec_exact() -> void:
	for x: float in [0.0, 0.1, 93.72000000000025, 1.0 / 3.0, -2.5e-300, 1e300]:
		var back: Variant = JSON.parse_string(JSON.stringify({"v": SaveCodec.f(x)}, "", false, true))["v"]
		assert_eq(SaveCodec.to_f(back), x)
	assert_eq(SaveCodec.to_f(12), 12.0)  # håndskrevne tal accepteres
