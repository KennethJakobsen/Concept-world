extends TestCase
## T-037: personale, nedbrud, affald, dekoration (stub-data).

const RULES: Dictionary = {"litter_chance_after_shop": 1.0, "litter_chance_with_bin": 0.0, "bin_radius": 4,
	"bin_capacity": 20, "litter_max_per_cell": 5, "dirty_threshold": 2, "happiness_penalty_dirty_per_tick": 0.05,
	"cleaner_sweep_ticks": 5, "cleaner_empty_bin_ticks": 5, "bench_energy_restore": -30, "bench_rest_ticks": 20,
	"bench_seek_energy": 70, "decor_aura_max_per_tick": 0.03, "aura_scale_per_tick": 0.01,
	"entertainer_happiness_per_tick": 0.03, "mechanic_inspect_interval_ticks": 100000,
	"inspection_reliability_bonus": 0.01, "inspection_ticks": 5}


func _sim(rules: Dictionary = {}, reliability: float = 1.0, needs: Dictionary = {}) -> ParkSim:
	var r: Dictionary = RULES.duplicate()
	r.merge(rules, true)
	var b := Balance.from_dicts(
		{"start_money": 100000, "entry_fee": 0, "path_cost": 0, "guest_money_min": 500,
			"guest_money_max": 500, "day_ticks": 100000},
		{"needs": needs, "happiness_start": 50, "leave_happiness": 0, "speed": 0.5}, {}, r)
	var s := ParkSim.new(30, 30, 11, b)
	s.register_def(AttractionDef.from_dict({"id": "r", "kind": "ride", "footprint": [1, 1], "capacity": 1,
		"ride_ticks": 10, "ticket_price": 0, "excitement": 10, "reliability": reliability, "repair_ticks": 10}))
	s.register_def(AttractionDef.from_dict({"id": "shop", "kind": "shop", "footprint": [1, 1], "capacity": 2,
		"ride_ticks": 5, "ticket_price": 0, "satisfies": {"hunger": -70}}))
	for st: Array in [["mechanic", 0], ["cleaner", 12], ["entertainer", 3]]:
		s.register_staff_def(StaffDef.from_dict({"id": st[0], "wage_per_day": 50, "speed": 0.5, "work_radius": st[1]}))
	for dd: Array in [["bench", "bench", true, 0.0, 0], ["bin", "bin", true, 0.0, 0], ["tree", "tree", false, 1.0, 2]]:
		s.register_decor_def(DecorDef.from_dict({"id": dd[0], "kind": dd[1], "build_cost": 10, "on_path": dd[2],
			"happiness_aura": dd[3], "aura_radius": dd[4]}))
	for y in range(10, 29):
		s.cmd_place_path(Vector2i(15, y))
	return s


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


## Gæst der står stille (QUEUING uden kø-objekt) på cellen.
func _idle_guest(s: ParkSim, cell: Vector2i, happiness: float = 50.0) -> Guest:
	var g := Guest.new(900 + s.guests.size(), cell)
	g.state = Guest.State.QUEUING
	g.happiness = happiness
	s.guests[g.id] = g
	return g


func test_breakdown_and_repair() -> void:
	var s := _sim({}, 0.0)
	var a: Attraction = s.cmd_place_attraction("r", Vector2i(15, 8))
	var events: Array = []
	s.attraction_broken.connect(func(x: Attraction) -> void: events.append(["broken", x.id]))
	s.attraction_repaired.connect(func(x: Attraction) -> void: events.append(["repaired", x.id]))
	s.spawn_interval_ticks = 5
	s.max_guests = 10
	s.rides_per_guest_min = 5
	s.rides_per_guest_max = 5
	_step(s, 400)
	assert_true(a.broken)
	assert_eq(a.status, Attraction.Status.BROKEN)
	assert_eq(events, [["broken", a.id]])
	assert_true(a.queue.is_empty(), "kø opløst")
	_step(s, 400)
	assert_true(a.broken, "uden mekaniker forbliver den i stykker")
	var mid: int = s.cmd_hire_staff("mechanic", Vector2i(15, 20))
	assert_true(mid > 0)
	_step(s, 200)
	assert_true(events.has(["repaired", a.id]), str(events))


func test_broken_dissolves_queue_with_thought() -> void:
	var s := _sim({}, 0.0)
	var a: Attraction = s.cmd_place_attraction("r", Vector2i(15, 8))
	for i in 4:
		var g := Guest.new(100 + i, a.entrance_cell)
		g.money = 100
		g.rides_left = 3
		s.guests[g.id] = g
		g.state = Guest.State.QUEUING
		g.target_attraction_id = a.id
		a.enqueue(g.id)
	var thoughts: Array = []
	var gs: Dictionary = s.guests  # undgå at lambdaen fanger s (referencecykel)
	s.attraction_broken.connect(func(_x: Attraction) -> void:
		for g: Guest in gs.values():
			thoughts.append(g.thought))
	_step(s, 30)
	assert_true(a.broken)
	assert_eq(thoughts.count("Den er i stykker!"), 3, str(thoughts))


func test_inspection_raises_reliability() -> void:
	var s := _sim({"mechanic_inspect_interval_ticks": 10}, 0.5)
	var a: Attraction = s.cmd_place_attraction("r", Vector2i(15, 8))
	s.cmd_hire_staff("mechanic", Vector2i(15, 12))
	_step(s, 100)
	assert_true(a.reliability_bonus > 0.0)
	assert_true(a.last_inspect_tick > 0)
	assert_true(a.effective_reliability() <= 1.0)


func test_litter_dropped_and_swept() -> void:
	var s := _sim({}, 1.0, {"hunger": {"rate": 1.0, "threshold": 50}})
	s.cmd_place_attraction("shop", Vector2i(14, 20))
	s.spawn_interval_ticks = 20
	s.max_guests = 3
	_step(s, 400)
	assert_true(s.world.total_litter() > 0, "affald efter bod")
	s.max_guests = 0
	for g: Guest in s.guests.values():
		g.happiness = 0.0
	var cid: int = s.cmd_hire_staff("cleaner", Vector2i(15, 25))
	_step(s, 1500)
	assert_eq(s.world.total_litter(), 0)
	assert_true(s.get_staff(cid) != null)


func test_bin_reduces_litter() -> void:
	var totals: Array = []
	for with_bin in [false, true]:
		var s := _sim({}, 1.0, {"hunger": {"rate": 1.0, "threshold": 50}})
		s.cmd_place_attraction("shop", Vector2i(14, 20))
		if with_bin:
			assert_true(s.cmd_place_decor("bin", Vector2i(15, 22)) > 0)
		s.spawn_interval_ticks = 20
		s.max_guests = 3
		_step(s, 400)
		totals.append(s.world.total_litter())
		if with_bin:
			var bin: Decor = s.decor.values()[0]
			assert_true(bin.fill > 0)
	assert_true(totals[0] > 0)
	assert_eq(totals[1], 0)


func test_full_bin_emptied_by_cleaner() -> void:
	var s := _sim()
	var bid: int = s.cmd_place_decor("bin", Vector2i(15, 22))
	s.decor[bid].fill = 20
	s.cmd_hire_staff("cleaner", Vector2i(15, 26))
	_step(s, 100)
	assert_eq(s.decor[bid].fill, 0)


func test_dirty_path_penalty() -> void:
	var s := _sim()
	s.world.set_litter(Vector2i(15, 15), 3)
	var g := _idle_guest(s, Vector2i(15, 15))
	g.state = Guest.State.WALKING
	g.next_cell = g.cell
	s._update_needs(g)
	assert_true(g.happiness < 50.0)
	assert_eq(g.thought, "Her er beskidt!")


func test_bench_lowers_energy() -> void:
	var s := _sim({}, 1.0, {"energy": {"rate": 0.0, "threshold": 80}})
	var bid: int = s.cmd_place_decor("bench", Vector2i(15, 14))
	assert_true(bid > 0)
	var g := Guest.new(500, Vector2i(15, 20))
	g.needs = {"energy": 85.0}
	g.money = 100
	s.guests[g.id] = g
	s._choose_goal(g)
	assert_eq(g.target_decor_id, bid)
	var rested: bool = false
	for i in 200:
		s.update(SimClock.TICK_DELTA)
		rested = rested or g.state == Guest.State.RESTING
	assert_true(rested)
	assert_eq(g.needs["energy"], 55.0)


func test_entertainer_raises_happiness() -> void:
	var s := _sim()
	var g := _idle_guest(s, Vector2i(15, 20))
	var s2 := _sim()
	var g2 := _idle_guest(s2, Vector2i(15, 20))
	s.cmd_hire_staff("entertainer", Vector2i(15, 20))
	_step(s, 100)
	_step(s2, 100)
	assert_eq(g2.happiness, 50.0)
	assert_true(g.happiness > 51.0, str(g.happiness))


func test_decor_aura_capped() -> void:
	var s := _sim()
	var g := _idle_guest(s, Vector2i(15, 20))
	for c in [Vector2i(14, 20), Vector2i(16, 20), Vector2i(14, 19), Vector2i(16, 19)]:
		assert_true(s.cmd_place_decor("tree", c) > 0)
	assert_eq(s.aura_at(Vector2i(15, 20)), 0.03)
	_step(s, 100)
	assert_true(absf(g.happiness - 53.0) < 1e-6, str(g.happiness))


func test_decor_rules() -> void:
	var s := _sim()
	var m0: int = s.economy.money
	assert_eq(s.cmd_place_decor("bench", Vector2i(3, 3)), -1, "bænk kræver sti")
	var tree: int = s.cmd_place_decor("tree", Vector2i(3, 3))
	assert_true(tree > 0)
	assert_eq(s.world.get_tile(Vector2i(3, 3)), ParkWorld.Tile.DECOR)
	assert_true(not s.cmd_place_path(Vector2i(3, 3)))
	assert_eq(s.cmd_place_decor("tree", Vector2i(15, 15)), -1, "træ ikke på sti")
	var bench: int = s.cmd_place_decor("bench", Vector2i(15, 15))
	assert_eq(s.cmd_place_decor("bin", Vector2i(15, 15)), -1, "én på-sti-dekoration pr. celle")
	assert_eq(s.economy.money, m0 - 20)
	var removed: Array = []
	s.decor_removed.connect(func(id: int) -> void: removed.append(id))
	assert_true(s.cmd_remove_path(Vector2i(15, 15)))
	assert_eq(removed, [bench])
	assert_true(s.cmd_remove_decor(tree))
	assert_eq(s.world.get_tile(Vector2i(3, 3)), ParkWorld.Tile.GRASS)
	assert_true(not s.cmd_remove_decor(tree))


func test_hire_fire_move_and_wages() -> void:
	var s := _sim()
	s.balance.day_ticks = 100
	assert_eq(s.cmd_hire_staff("mechanic", Vector2i(3, 3)), -1, "kun på sti")
	assert_eq(s.cmd_hire_staff("nope", Vector2i(15, 15)), -1)
	var fired: Array = []
	s.staff_fired.connect(func(id: int) -> void: fired.append(id))
	var a: int = s.cmd_hire_staff("mechanic", Vector2i(15, 15))
	var b: int = s.cmd_hire_staff("cleaner", Vector2i(15, 16))
	assert_true(s.cmd_move_staff(b, Vector2i(15, 20)))
	assert_eq(s.get_staff(b).home_cell, Vector2i(15, 20))
	assert_true(not s.cmd_move_staff(b, Vector2i(3, 3)))
	_step(s, 100)
	assert_eq(int(s.economy.history.back()["totals"]["wages"]), -100)
	assert_true(s.cmd_fire_staff(a))
	assert_true(not s.cmd_fire_staff(a))
	assert_eq(fired, [a])
	_step(s, 100)
	assert_eq(int(s.economy.history.back()["totals"]["wages"]), -50)
	assert_eq(s.get_stats()["staff"], 1)


func _park_str(s: ParkSim) -> String:
	return SaveCodec.stringify(s.to_save()["park"])


func test_save_roundtrip_with_staff_decor_litter() -> void:
	var s := _sim({"litter_chance_after_shop": 0.5, "mechanic_inspect_interval_ticks": 50}, 0.3,
		{"hunger": {"rate": 0.5, "threshold": 50}, "energy": {"rate": 0.3, "threshold": 80}})
	s.cmd_place_attraction("r", Vector2i(15, 8))
	s.cmd_place_attraction("shop", Vector2i(14, 20))
	s.cmd_place_decor("bench", Vector2i(15, 18))
	s.cmd_place_decor("bin", Vector2i(15, 24))
	s.cmd_place_decor("tree", Vector2i(16, 12))
	s.cmd_hire_staff("mechanic", Vector2i(15, 26))
	s.cmd_hire_staff("cleaner", Vector2i(15, 27))
	s.cmd_hire_staff("entertainer", Vector2i(15, 15))
	s.spawn_interval_ticks = 15
	s.max_guests = 12
	s.balance.day_ticks = 700
	_step(s, 900)
	var defs: Array = []
	for t in ["mechanic", "cleaner", "entertainer"]:
		defs.append(s.get_staff_def(t))
	for t in ["bench", "bin", "tree"]:
		defs.append(s.get_decor_def(t))
	var b := ParkSim.from_save(SaveCodec.parse(SaveCodec.stringify(s.to_save())), s.balance, defs)
	assert_eq(_park_str(b), _park_str(s))
	assert_eq(b.staff.size(), 3)
	assert_eq(b.decor.size(), 3)
	_step(s, 2000)
	_step(b, 2000)
	assert_eq(_park_str(b), _park_str(s))
	var p: Dictionary = s.to_save()["park"]
	assert_true(not (p["staff"] as Array).is_empty() and not (p["decor"] as Array).is_empty())

