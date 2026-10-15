extends TestCase
## T-030: tiltrækning, omdømme og gæstestrøm (stub park-konfiguration).

const PARK: Dictionary = {"weight_ride": 1.0, "weight_facility": 5.0, "reputation_start": 50,
	"reputation_learn_rate": 0.1, "expected_entry_fee_per_score": 1.0, "price_penalty_factor": 1.0,
	"price_penalty_max": 0.9, "spawn_per_score": 100.0, "reputation_mult_base": 0.5,
	"spawn_min_per_day": 10, "spawn_max_per_day": 2000, "max_guests_base": 5, "max_guests_per_capacity": 1.0}


func _sim(fee: int = 0, park: Dictionary = PARK) -> ParkSim:
	var b := Balance.from_dicts(
		{"start_money": 100000, "entry_fee": fee, "path_cost": 0, "guest_money_min": 50,
			"guest_money_max": 50, "day_ticks": 1000},
		{"needs": {}, "happiness_start": 70}, park)
	var s := ParkSim.new(30, 30, 9, b)
	s.register_def(AttractionDef.from_dict({"id": "ride", "kind": "ride", "footprint": [1, 1],
		"capacity": 4, "ride_ticks": 20, "ticket_price": 1, "excitement": 16}))
	s.register_def(AttractionDef.from_dict({"id": "shop", "kind": "shop", "footprint": [1, 1],
		"capacity": 2, "ride_ticks": 10, "ticket_price": 1}))
	for y in range(20, 29):
		s.cmd_place_path(Vector2i(15, y))
	return s


func _count_spawns(s: ParkSim, ticks: int) -> int:
	var n: Array = [0]
	s.guest_spawned.connect(func(_g: Guest) -> void: n[0] += 1)
	for i in ticks:
		s.update(SimClock.TICK_DELTA)
	return n[0]


func test_balance_reads_park() -> void:
	assert_true(Balance.load_default().has_park, "park.json findes")
	assert_true(not Balance.from_dicts({}, {}).has_park)
	assert_true(not _sim().fixed_spawn)


func test_no_rides_no_guests() -> void:
	var s := _sim()
	s.cmd_place_attraction("shop", Vector2i(14, 25))  # kun bod
	assert_eq(s.expected_guests_per_day(), 0.0)
	assert_eq(_count_spawns(s, 2000), 0)


func test_more_attractions_higher_rate() -> void:
	var s := _sim()
	s.cmd_place_attraction("ride", Vector2i(14, 25))
	var r1: float = s.expected_guests_per_day()
	assert_eq(s.attraction_score(), 4.0)
	assert_eq(r1, 400.0)  # 100 * 4 * 1.0
	s.cmd_place_attraction("ride", Vector2i(16, 25))
	s.cmd_place_attraction("shop", Vector2i(14, 23))
	assert_true(s.expected_guests_per_day() > r1)
	assert_eq(s.attraction_score(), sqrt(37.0))
	# lukket tæller ikke
	s.cmd_set_open(s.attractions[2].id, false)
	assert_eq(s.attraction_score(), sqrt(32.0))


func test_rate_realized_stochastically() -> void:
	var low := _sim()
	low.cmd_place_attraction("ride", Vector2i(14, 25))
	var high := _sim()
	for x in [14, 16]:
		for y in [21, 23, 25]:
			high.cmd_place_attraction("ride", Vector2i(x, y))
	var nl: int = _count_spawns(low, 1000)
	var nh: int = _count_spawns(high, 1000)
	assert_true(nl > 0)
	assert_true(nh > nl, "%d > %d" % [nh, nl])


func test_min_rate_and_no_path() -> void:
	var p: Dictionary = PARK.duplicate()
	p["spawn_per_score"] = 0.001
	var s := _sim(0, p)
	s.cmd_place_attraction("ride", Vector2i(14, 25))
	assert_eq(s.expected_guests_per_day(), 10.0)
	s.cmd_remove_path(Vector2i(15, 28))
	assert_eq(s.expected_guests_per_day(), 0.0)


func test_happy_guests_raise_reputation() -> void:
	var s := _sim()
	s.cmd_place_attraction("ride", Vector2i(14, 25))
	var events: Array = []
	s.reputation_changed.connect(func(v: float) -> void: events.append(v))
	var g := Guest.new(500, s.world.entrance)
	g.happiness = 100.0
	s.guests[g.id] = g
	s._remove_guest(g)
	assert_eq(s.reputation, 55.0)
	assert_eq(events, [55.0])
	var sad := Guest.new(501, s.world.entrance)
	sad.happiness = 0.0
	s.guests[sad.id] = sad
	s._remove_guest(sad)
	assert_eq(s.reputation, 49.5)
	# højere omdømme → højere rate
	var r: float = s.expected_guests_per_day()
	s.reputation = 90.0
	assert_true(s.expected_guests_per_day() > r)


func test_high_entry_fee_lowers_rate() -> void:
	var cheap := _sim(4)
	cheap.cmd_place_attraction("ride", Vector2i(14, 25))
	var dear := _sim(6)  # forventet 4 → straf 0.5
	dear.cmd_place_attraction("ride", Vector2i(14, 25))
	assert_eq(cheap.price_penalty(), 0.0)
	assert_eq(dear.price_penalty(), 0.5)
	assert_eq(dear.expected_guests_per_day(), cheap.expected_guests_per_day() * 0.5)
	dear.cmd_set_entry_fee(1000)
	assert_eq(dear.price_penalty(), 0.9)


func test_max_guests_grows_with_capacity() -> void:
	var s := _sim()
	assert_eq(s.current_max_guests(), 5)
	s.cmd_place_attraction("ride", Vector2i(14, 25))
	assert_eq(s.current_max_guests(), 9)
	s.cmd_place_attraction("shop", Vector2i(16, 25))
	assert_eq(s.current_max_guests(), 11)
	var n: int = 0
	for i in 3000:
		s.update(SimClock.TICK_DELTA)
		assert_true(s.guests.size() <= s.current_max_guests())
		n = maxi(n, s.guests.size())
	assert_true(n > 0)


func test_stats_and_determinism() -> void:
	var a := _sim()
	var b := _sim()
	for s: ParkSim in [a, b]:
		s.cmd_place_attraction("ride", Vector2i(14, 25))
		s.cmd_place_attraction("shop", Vector2i(16, 25))
		for i in 3000:
			s.update(SimClock.TICK_DELTA)
	assert_eq(a._next_guest_id, b._next_guest_id)
	assert_eq(a.reputation, b.reputation)
	assert_eq(a.get_stats(), b.get_stats())
	var st: Dictionary = a.get_stats()
	for k in ["reputation", "attraction_score", "guests_per_day", "max_guests"]:
		assert_true(st.has(k), k)
