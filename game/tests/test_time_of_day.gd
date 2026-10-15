extends TestCase
## T-047: tid på dagen, selv-reparation, warning og nye signaler.


func _sim(day_ticks: int = 1000, daynight: Dictionary = {}, rules: Dictionary = {}, reliability: float = 1.0) -> ParkSim:
	var b := Balance.from_dicts(
		{"start_money": 100000, "entry_fee": 0, "path_cost": 0, "guest_money_min": 500,
			"guest_money_max": 500, "day_ticks": day_ticks},
		{"needs": {}, "happiness_start": 50, "leave_happiness": 0, "speed": 0.5}, {}, rules, daynight)
	var s := ParkSim.new(30, 30, 7, b)
	s.register_def(AttractionDef.from_dict({"id": "r", "kind": "ride", "footprint": [1, 1], "capacity": 1,
		"ride_ticks": 10, "ticket_price": 3, "excitement": 10, "reliability": reliability, "repair_ticks": 10}))
	s.register_staff_def(StaffDef.from_dict({"id": "mechanic", "wage_per_day": 0, "speed": 0.5, "work_radius": 0}))
	s.register_staff_def(StaffDef.from_dict({"id": "cleaner", "wage_per_day": 0, "speed": 0.5, "work_radius": 0}))
	for y in range(10, 29):
		s.cmd_place_path(Vector2i(15, y))
	return s


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func test_defaults_without_data() -> void:
	var b := Balance.from_dicts({}, {})
	assert_eq(b.day_start_time, 0.25)
	assert_eq(b.dawn, 0.22)
	assert_eq(b.day_phase, 0.30)
	assert_eq(b.dusk, 0.78)
	assert_eq(b.night, 0.86)
	assert_eq(b.self_repair_ticks, 2400)
	assert_eq(b.self_repair_cost, 200)


func test_time_of_day_and_clock() -> void:
	var s := _sim(1000)
	assert_eq(s.time_of_day(), 0.25)
	assert_eq(s.clock_text(), "06:00")
	assert_eq(s.phase(), &"dawn")
	assert_true(not s.is_night())
	s.day_tick = 250
	assert_eq(s.clock_text(), "12:00")
	assert_eq(s.phase(), &"day")
	s.day_tick = 999  # 0.249 → 05:58
	assert_true(s.time_of_day() < 0.25 and s.time_of_day() >= 0.0)
	assert_eq(s.clock_text(), "05:58")
	assert_eq(s.phase(), &"dawn")
	s.day_tick = 760  # 0.01 – efter midnat-wrap
	assert_eq(s.clock_text(), "00:14")
	assert_true(s.is_night())
	assert_eq(s.phase(), &"night")


func test_phase_boundaries() -> void:
	var s := _sim(1000, {"day_start_time": 0.0})
	var cases: Array = [[219, &"night", true], [220, &"dawn", false], [299, &"dawn", false],
		[300, &"day", false], [779, &"day", false], [780, &"dusk", true], [859, &"dusk", true],
		[860, &"night", true], [999, &"night", true], [0, &"night", true]]
	for c: Array in cases:
		s.day_tick = c[0]
		assert_eq(s.phase(), c[1], "tick %d" % c[0])
		assert_eq(s.is_night(), c[2], "is_night tick %d" % c[0])


func test_phase_changed_only_on_transition_and_wraps() -> void:
	var s := _sim(100)  # start 0.25 = dawn
	var phases: Array = []
	s.phase_changed.connect(func(p: StringName) -> void: phases.append(p))
	_step(s, 100)  # hel dag → dawn igen via wrap
	assert_eq(phases, [&"day", &"dusk", &"night", &"dawn"])
	_step(s, 3)
	assert_eq(phases.size(), 4, "ingen signal uden overgang")


func test_clock_text_ascii() -> void:
	var s := _sim(97)
	for t in 97:
		s.day_tick = t
		var txt: String = s.clock_text()
		assert_eq(txt.length(), 5)
		for ch in txt:
			assert_true("0123456789:".contains(ch), txt)


func _break_now(s: ParkSim) -> Attraction:
	var a: Attraction = s.cmd_place_attraction("r", Vector2i(15, 8))
	s._break(a)
	return a


func test_self_repair_without_mechanic() -> void:
	var s := _sim(100000, {}, {"self_repair_ticks": 50, "self_repair_cost": 200})
	var warns: Array = []
	var repaired: Array = []
	s.warning.connect(func(c: StringName, d: Dictionary) -> void: warns.append([c, d]))
	s.attraction_repaired.connect(func(x: Attraction) -> void: repaired.append(x.id))
	var a := _break_now(s)
	assert_eq(warns, [[&"broken_no_mechanic", {"attraction_id": a.id}]])
	var money: int = s.economy.money
	_step(s, 49)
	assert_true(a.broken)
	_step(s, 1)
	assert_true(not a.broken)
	assert_eq(repaired, [a.id])
	assert_eq(s.economy.money, money - 200)
	assert_eq(int(s.economy.today.get("repairs", 0)), -200)
	assert_eq(warns.size(), 1, "kun én advarsel pr. nedbrud")
	s._break(a)
	assert_eq(warns.size(), 2)


func test_self_repair_disabled() -> void:
	var s := _sim(100000, {}, {"self_repair_ticks": 0})
	var a := _break_now(s)
	_step(s, 3000)
	assert_true(a.broken)


func test_no_self_repair_or_warning_with_mechanic() -> void:
	var s := _sim(100000, {}, {"self_repair_ticks": 5})
	var warns: Array = []
	s.warning.connect(func(c: StringName, d: Dictionary) -> void: warns.append(c))
	s.cmd_hire_staff("mechanic", Vector2i(15, 28))
	var a := _break_now(s)
	_step(s, 20)
	assert_true(a.broken, "mekaniker ansat → ingen ekstern service")
	assert_eq(a.self_repair_elapsed, 0)
	assert_eq(int(s.economy.today.get("repairs", 0)), 0)
	assert_eq(warns, [])


func test_self_repair_counter_saved() -> void:
	var s := _sim(100000, {}, {"self_repair_ticks": 50})
	var a := _break_now(s)
	_step(s, 30)
	assert_eq(a.self_repair_elapsed, 30)
	var s2 := ParkSim.from_save(s.to_save(), s.balance)
	assert_eq(s2.get_attraction(a.id).self_repair_elapsed, 30)
	_step(s2, 20)
	assert_true(not s2.get_attraction(a.id).broken)
	var d: Dictionary = a.to_save()
	d.erase("self_repair_elapsed")
	assert_eq(Attraction.from_save(d, a.def).self_repair_elapsed, 0, "default 0")


func test_purchase_and_ride_cycle_signals() -> void:
	var s := _sim(100000)
	var a: Attraction = s.cmd_place_attraction("r", Vector2i(15, 8))
	var buys: Array = []
	var cycles: Array = []
	s.purchase_made.connect(func(gid: int, bid: int, amt: int) -> void: buys.append([gid, bid, amt]))
	s.ride_cycle_started.connect(func(aid: int) -> void: cycles.append(aid))
	var g := Guest.new(500, a.entrance_cell)
	g.money = 100
	g.rides_left = 1
	s.guests[g.id] = g
	assert_eq(s._try_enter(g, a), "")
	assert_eq(buys, [[500, a.id, 3]])
	_step(s, 1)
	assert_eq(cycles, [a.id])


func test_litter_swept_signal() -> void:
	var s := _sim(100000)
	var swept: Array = []
	s.litter_swept.connect(func(c: Vector2i) -> void: swept.append(c))
	s.world.set_litter(Vector2i(15, 20), 3)
	s.cmd_hire_staff("cleaner", Vector2i(15, 20))
	_step(s, 200)
	assert_eq(swept, [Vector2i(15, 20)])
	assert_eq(s.world.get_litter(Vector2i(15, 20)), 0)
