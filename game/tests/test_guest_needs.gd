extends TestCase
## T-020: behov, butikker, toiletter, glæde, tanker (stub-data).

var _removed: Array = []


func _on_removed(gid: int) -> void:
	_removed.append(gid)


func _bal(money: int = 100, hunger_rate: float = 0.0) -> Balance:
	return Balance.from_dicts(
		{"start_money": 10000, "entry_fee": 0, "path_cost": 0, "guest_money_min": money,
			"guest_money_max": money, "day_ticks": 100000},
		{"needs": {"hunger": {"rate": hunger_rate, "threshold": 60}, "energy": {"rate": 0.0, "threshold": 80}},
			"happiness_start": 70, "happiness_decay_when_need_over_threshold": 0.0, "leave_happiness": 20,
			"spawn_interval_ticks": 10, "max_guests": 1, "speed": 0.2, "need_start_max": 0})


## Indgang (10,19). Sti (10,16..18). Burgerbod 1x1 på (10,15) → indgang (10,16).
func _sim(b: Balance) -> ParkSim:
	var s := ParkSim.new(20, 20, 5, b)
	s.register_def(AttractionDef.from_dict({"id": "burger", "kind": "shop", "footprint": [1, 1],
		"capacity": 2, "ride_ticks": 10, "ticket_price": 4, "satisfies": {"hunger": -70}}))
	for y in range(16, 19):
		s.cmd_place_path(Vector2i(10, y))
	s.cmd_place_path(Vector2i(11, 17))
	s.cmd_place_path(Vector2i(9, 17))
	assert_true(s.cmd_place_attraction("burger", Vector2i(10, 15)) != null)
	s.guest_removed.connect(_on_removed)
	return s


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func test_hungry_guest_eats() -> void:
	var s := _sim(_bal(100, 0.5))
	var shop: Attraction = s.attractions[0]
	var max_drop: float = 0.0
	var prev: Dictionary = {}
	var saw_thought: bool = false
	for i in 600:
		s.update(SimClock.TICK_DELTA)
		for g: Guest in s.guests.values():
			if g.thought == "Jeg er sulten!":
				saw_thought = true
			if prev.has(g.id):
				max_drop = maxf(max_drop, prev[g.id] - g.needs["hunger"])
			prev[g.id] = g.needs["hunger"]
	assert_true(saw_thought, "tanke om sult")
	assert_true(shop.total_visitors >= 1, "besøgte burgerbod")
	assert_true(max_drop > 50.0, "sult faldt")
	assert_eq(shop.total_revenue, shop.total_visitors * 4)


func test_too_expensive_rejected() -> void:
	var s := _sim(_bal(1000, 0.5))
	var shop: Attraction = s.attractions[0]
	assert_true(s.cmd_set_price(shop.id, 50))
	var saw: bool = false
	for i in 600:
		s.update(SimClock.TICK_DELTA)
		for g: Guest in s.guests.values():
			if g.thought == "For dyrt!":
				saw = true
				assert_eq(g.money, 1000)
	assert_true(saw, "afvist med tanke")
	assert_eq(shop.total_visitors, 0)


func test_no_money_leaves() -> void:
	var s := _sim(_bal(0, 0.5))
	var seen: Array = []
	s.guest_spawned.connect(func(g: Guest) -> void: seen.append([g.state, g.thought]))
	_step(s, 200)
	assert_true(not seen.is_empty())
	assert_eq(seen[0], [Guest.State.LEAVING, "Jeg vil hjem."])
	assert_true(_removed.has(1))
	assert_eq(s.attractions[0].total_visitors, 0)


func test_low_happiness_leaves() -> void:
	var s := _sim(_bal(100, 0.0))
	s.rides_per_guest_min = 5
	s.rides_per_guest_max = 5
	_step(s, 10)
	var g: Guest = s.guests[1]
	g.happiness = 10.0
	_step(s, 200)
	assert_true(_removed.has(1))


func test_closed_not_used() -> void:
	var s := _sim(_bal(100, 0.5))
	var shop: Attraction = s.attractions[0]
	assert_true(s.cmd_set_open(shop.id, false))
	_step(s, 600)
	assert_eq(shop.total_visitors, 0)


func _snap(s: ParkSim) -> Array:
	var out: Array = []
	var ids: Array = s.guests.keys()
	ids.sort()
	for gid in ids:
		var g: Guest = s.guests[gid]
		out.append([gid, g.cell, g.state, g.money, g.happiness, g.needs.duplicate(), g.thought])
	return out


func test_deterministic_with_needs() -> void:
	var b := Balance.from_dicts({"guest_money_min": 10, "guest_money_max": 90, "day_ticks": 300},
		{"needs": {"hunger": {"rate": 0.2, "threshold": 60}, "thirst": {"rate": 0.3, "threshold": 50}},
			"spawn_interval_ticks": 5, "max_guests": 10})
	var x := _sim(b)
	var y := _sim(b)
	_step(x, 1000)
	_step(y, 1000)
	assert_eq(_snap(x), _snap(y))
	assert_eq(x.economy.money, y.economy.money)
	assert_true(not _snap(x).is_empty())


func test_get_stats() -> void:
	var s := _sim(_bal(100, 0.0))
	var st: Dictionary = s.get_stats()
	assert_eq(st["guests"], 0)
	assert_eq(st["day"], 1)
	assert_eq(st["money"], s.economy.money)
	_step(s, 20)
	st = s.get_stats()
	assert_eq(st["guests"], 1)
	assert_eq(st["avg_happiness"], 70.0)


# --- T-025: GDD-afstemning ---

func _ride(id: String, exc: int) -> AttractionDef:
	return AttractionDef.from_dict({"id": id, "kind": "ride", "footprint": [1, 1], "capacity": 1,
		"ride_ticks": 5, "ticket_price": 1, "excitement": exc})


func test_price_value_formulas() -> void:
	var s := _sim(_bal())
	s.register_def(_ride("r", 25))
	var ride: Attraction = s.cmd_place_attraction("r", Vector2i(2, 2))
	var shop: Attraction = s.attractions[0]
	var g := Guest.new(99, Vector2i.ZERO)
	g.needs = {"hunger": 80.0}
	g.happiness = 100.0
	assert_eq(s.price_value(ride, g), 7.0 * 1.25)
	assert_eq(s.price_value(shop, g), 4.0 * 1.8 * 1.25)
	g.happiness = 0.0
	g.needs = {"hunger": 0.0}
	assert_eq(s.price_value(shop, g), 4.0 * 0.75)


func test_reject_penalty_is_two() -> void:
	var s := _sim(_bal(1000, 0.5))
	assert_true(s.cmd_set_price(s.attractions[0].id, 50))
	var seen: Dictionary = {}
	for i in 600:
		var before: Dictionary = {}
		for g: Guest in s.guests.values():
			before[g.id] = [g.happiness, g.rejected_ids.size()]
		s.update(SimClock.TICK_DELTA)
		for g: Guest in s.guests.values():
			if before.has(g.id) and g.rejected_ids.size() > before[g.id][1]:
				seen[g.id] = before[g.id][0] - g.happiness
	assert_true(not seen.is_empty())
	for d: float in seen.values():
		assert_true(absf(d - 2.0) < 1e-4, "glæde -2")


func test_start_needs_in_range_and_energy_leave() -> void:
	var b := Balance.from_dicts({"guest_money_min": 50, "guest_money_max": 50},
		{"needs": {"energy": {"rate": 0.0, "threshold": 80}}, "spawn_interval_ticks": 1, "max_guests": 20})
	assert_eq(b.need_start_max, 30.0)
	var s := _sim(b)
	var starts: Array = []
	s.guest_spawned.connect(func(g: Guest) -> void: starts.append(g.needs["energy"]))
	_step(s, 30)
	for v: float in starts:
		assert_true(v >= 0.0 and v <= 30.0)
	var g: Guest = s.guests.values()[0]
	g.needs["energy"] = 90.0  # over threshold, men < 100: bliver
	s._choose_goal(g)
	assert_true(g.state != Guest.State.LEAVING)
	g.needs["energy"] = 100.0
	s._choose_goal(g)
	assert_eq(g.state, Guest.State.LEAVING)
	assert_eq(g.thought, "Jeg vil hjem.")


func test_leaves_when_money_below_cheapest() -> void:
	var s := _sim(_bal(3, 0.0))  # burger koster 4
	var seen: Array = []
	s.guest_spawned.connect(func(g: Guest) -> void: seen.append(g.state))
	_step(s, 20)
	assert_eq(seen[0], Guest.State.LEAVING)


func test_ride_choice_weighted_by_excitement() -> void:
	var s := _sim(_bal(1000, 0.0))
	s.register_def(_ride("dull", 1))
	s.register_def(_ride("wild", 50))
	var dull: Attraction = s.cmd_place_attraction("dull", Vector2i(9, 16))
	var wild: Attraction = s.cmd_place_attraction("wild", Vector2i(11, 16))
	s.cmd_set_price(dull.id, 0)
	s.cmd_set_price(wild.id, 0)
	var g := Guest.new(99, Vector2i(10, 17))
	g.money = 1000
	g.needs = {}
	g.rides_left = 1
	s.guests[g.id] = g
	var counts: Dictionary = {dull.id: 0, wild.id: 0}
	for i in 300:
		g.cell = Vector2i(10, 17)
		s._choose_goal(g)
		counts[g.target_attraction_id] += 1
	assert_true(counts[wild.id] > counts[dull.id] * 10, str(counts))
