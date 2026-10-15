extends TestCase
## T-033: trængsel – kø-loft, nåbarhed i tiltrækning, utilfredse gæster opgiver køen.

const PARK: Dictionary = {"weight_ride": 1.0, "weight_facility": 5.0, "reputation_start": 50,
	"reputation_learn_rate": 0.02, "spawn_per_score": 100.0, "spawn_min_per_day": 10,
	"spawn_max_per_day": 2000, "max_guests_base": 5, "max_guests_per_capacity": 1.0, "queue_max_cycles": 3}


func _sim(park: Dictionary = PARK) -> ParkSim:
	var b := Balance.from_dicts(
		{"start_money": 100000, "entry_fee": 0, "path_cost": 0, "guest_money_min": 500,
			"guest_money_max": 500, "day_ticks": 100000},
		{"needs": {}, "happiness_start": 70, "leave_happiness": 20}, park)
	var s := ParkSim.new(30, 30, 4, b)
	s.register_def(AttractionDef.from_dict({"id": "slow", "kind": "ride", "footprint": [1, 1],
		"capacity": 2, "ride_ticks": 2000, "ticket_price": 1, "excitement": 16}))
	for y in range(20, 29):
		s.cmd_place_path(Vector2i(15, y))
	return s


func test_queue_capped_with_thought() -> void:
	var s := _sim()
	var a: Attraction = s.cmd_place_attraction("slow", Vector2i(14, 25))
	s.spawn_interval_ticks = 5
	s.max_guests = 40
	s.rides_per_guest_min = 3
	s.rides_per_guest_max = 3
	var saw: bool = false
	var max_q: int = 0
	for i in 1500:
		s.update(SimClock.TICK_DELTA)
		max_q = maxi(max_q, a.queue.size())
		for g: Guest in s.guests.values():
			saw = saw or g.thought == ParkSim.QUEUE_FULL_THOUGHT
	assert_eq(max_q, 6, "kø = capacity × 3")
	assert_true(s.is_queue_full(a))
	assert_true(saw, "tanke om lang kø")


func test_queue_cap_disabled() -> void:
	var p: Dictionary = PARK.duplicate()
	p["queue_max_cycles"] = 0
	var s := _sim(p)
	var a: Attraction = s.cmd_place_attraction("slow", Vector2i(14, 25))
	for i in 50:
		a.enqueue(1000 + i)
	assert_true(not s.is_queue_full(a))


func test_unreachable_not_counted() -> void:
	var s := _sim()
	var a: Attraction = s.cmd_place_attraction("slow", Vector2i(5, 5))  # ingen sti til (5,6)
	assert_true(not s.is_reachable(a))
	assert_eq(s.attraction_score(), 0.0)
	assert_eq(s.current_max_guests(), 5)
	assert_eq(s.expected_guests_per_day(), 0.0)
	for y in range(7, 21):
		s.cmd_place_path(Vector2i(5, y))
	for x in range(6, 15):
		s.cmd_place_path(Vector2i(x, 20))
	assert_true(s.is_reachable(a))
	assert_eq(s.attraction_score(), 4.0)
	assert_eq(s.current_max_guests(), 7)
	s.cmd_remove_path(Vector2i(10, 20))
	assert_true(not s.is_reachable(a))


func test_unhappy_guest_leaves_queue() -> void:
	var s := _sim()
	var a: Attraction = s.cmd_place_attraction("slow", Vector2i(14, 25))
	s.spawn_interval_ticks = 5
	s.max_guests = 8
	var g: Guest = null
	for i in 1000:
		s.update(SimClock.TICK_DELTA)
		if a.is_running() and a.queue.size() >= 2:
			g = s.guests[a.queue.back()]
			break
	assert_true(g != null, "nogen står i kø")
	g.happiness = 5.0
	s.update(SimClock.TICK_DELTA)
	assert_true(not a.queue.has(g.id))
	assert_true(not s.guests.has(g.id) or g.state == Guest.State.LEAVING, str(g.state))


## Regression: QA's fulde park (T-032) med rigtigt content – glæden må ikke kollapse.
func test_full_park_does_not_collapse() -> void:
	var s := ParkSim.new(64, 64, 12345)
	s.economy.money += 10000
	var e: Vector2i = s.world.entrance
	for y in range(e.y - 1, 49, -1):
		s.cmd_place_path(Vector2i(e.x, y))
	for x in range(e.x - 10, e.x + 11):
		if x != e.x:
			s.cmd_place_path(Vector2i(x, 50))
	for p: Array in [["carousel", -2, 46], ["burger_stand", 2, 49], ["drinks_stand", 4, 49],
			["toilet", -4, 49], ["ice_cream_stand", 6, 49], ["ferris_wheel", 4, 51], ["bumper_cars", -8, 51]]:
		assert_true(s.cmd_place_attraction(p[0], Vector2i(e.x + p[1], p[2])) != null, p[0])
	var rep0: float = s.reputation
	var hap_sum: float = 0.0
	var n: int = 0
	for i in s.balance.day_ticks * 3:
		s.update(SimClock.TICK_DELTA)
		if i % 100 == 0 and i > s.balance.day_ticks and not s.guests.is_empty():
			hap_sum += s.get_stats().avg_happiness
			n += 1
		for a: Attraction in s.attractions:
			assert_true(a.queue.size() <= ceili(a.def.capacity * s.balance.queue_max_cycles))
	assert_true(n > 0)
	assert_true(hap_sum / n > 65.0, "glæde %.1f" % (hap_sum / n))
	assert_true(s.reputation >= rep0, "omdømme %.1f" % s.reputation)
