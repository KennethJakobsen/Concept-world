extends TestCase
## T-103 (M7, ADR-005 §1–3): køstier, tålmodighed, valg af ledig bygning, belægning og trængsel.

const RIDE: Dictionary = {"id": "slow_q", "kind": "ride", "footprint": [1, 1], "capacity": 2,
	"ride_ticks": 3000, "ticket_price": 1, "excitement": 20}


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func _balance(guests_extra: Dictionary = {}) -> Balance:
	var g: Dictionary = {"needs": {}, "happiness_start": 70, "leave_happiness": 20}
	g.merge(guests_extra, true)
	return Balance.from_dicts(
		{"start_money": 100000, "entry_fee": 0, "path_cost": 0, "guest_money_min": 500,
			"guest_money_max": 500, "day_ticks": 100000}, g, {"queue_slots_per_cell": 2,
			"queue_default_max": 4, "queue_path_cost": 15, "queue_path_refund": 7, "max_guests_base": 5,
			"queue_max_cycles": 3})


## Forlystelse ved (10,15), indgang (10,16). Køsti (10,17)..(10,20), sti y=21 x=10..15 og x=15 ned til porten.
func _queue_park(guests_extra: Dictionary = {}) -> ParkSim:
	var s := ParkSim.new(30, 30, 4, _balance(guests_extra))
	s.register_def(AttractionDef.from_dict(RIDE))
	for y in range(21, 29):
		s.cmd_place_path(Vector2i(15, y))
	for x in range(10, 15):
		s.cmd_place_path(Vector2i(x, 21))
	assert_true(s.cmd_place_attraction("slow_q", Vector2i(10, 15)) != null)
	for y in range(17, 21):
		assert_true(s.cmd_place_queue_path(Vector2i(10, y)))
	return s


func test_queue_cell_kind_cost_and_not_walkable() -> void:
	var s := ParkSim.new(20, 20, 1, _balance())
	var m0: int = s.economy.money
	assert_true(s.cmd_place_queue_path(Vector2i(5, 5)))
	assert_eq(s.economy.money, m0 - 15)
	assert_eq(s.world.get_tile(Vector2i(5, 5)), ParkWorld.CellKind.QUEUE)
	assert_eq(ParkWorld.CellKind.QUEUE, ParkWorld.Tile.QUEUE)
	assert_true(not s.world.is_walkable(Vector2i(5, 5)))
	assert_true(not s.cmd_place_queue_path(Vector2i(5, 5)), "optaget")
	assert_true(not s.cmd_place_path(Vector2i(5, 5)))
	# PathFinder følger ikke køstier.
	s.cmd_place_path(Vector2i(4, 5))
	s.cmd_place_path(Vector2i(6, 5))
	assert_eq(s.path_finder.find_path(Vector2i(4, 5), Vector2i(6, 5)).size(), 0)
	assert_true(s.cmd_remove_queue_path(Vector2i(5, 5)))
	assert_eq(s.economy.money, m0 - 15 + 7)
	assert_true(not s.cmd_remove_queue_path(Vector2i(5, 5)))


func test_queue_chain_capacity_and_approach() -> void:
	var s := _queue_park()
	var a: Attraction = s.attractions[0]
	assert_eq(s.queue_capacity(a), 8, "4 celler × 2")
	assert_eq(a.queue_cells, [Vector2i(10, 17), Vector2i(10, 18), Vector2i(10, 19), Vector2i(10, 20)] as Array[Vector2i])
	assert_eq(s.approach_cell(a), Vector2i(10, 21))
	assert_true(s.is_reachable(a), "nåbar via køens ende")
	assert_eq(s.queue_slot_cell(a, 0), Vector2i(10, 17))
	assert_eq(s.queue_slot_cell(a, 7), Vector2i(10, 20))
	# Uden køsti: virtuel kø som før M7 (max(default, kapacitet × cycles)).
	s.cmd_remove_queue_path(Vector2i(10, 17))
	assert_eq(a.queue_cells.size(), 0, "kæden starter ved indgangen")
	assert_eq(s.queue_capacity(a), 6)
	assert_eq(s.approach_cell(a), a.entrance_cell)


func test_queue_chain_stops_at_branch_and_other_queue() -> void:
	var s := _queue_park()
	var a: Attraction = s.attractions[0]
	s.cmd_place_queue_path(Vector2i(11, 18))  # forgrening ved (10,18)
	assert_eq(a.queue_cells, [Vector2i(10, 17), Vector2i(10, 18)] as Array[Vector2i])


func test_guests_get_distinct_slots_along_queue() -> void:
	var s := _queue_park()
	var a: Attraction = s.attractions[0]
	s.spawn_interval_ticks = 3
	s.max_guests = 14
	s.rides_per_guest_min = 5
	s.rides_per_guest_max = 5
	var changed: Array = [0]
	s.queue_changed.connect(func(id: int) -> void:
		if id == a.id:
			changed[0] += 1)
	_step(s, 900)
	assert_true(changed[0] > 0, "queue_changed")
	assert_eq(a.queue.size(), 8, "køen er fuld (8 pladser)")
	var seen_pos: Dictionary = {}
	for i in a.queue.size():
		var g: Guest = s.guests[a.queue[i]]
		assert_eq(g.queue_index, i)
		var p: Vector2 = s.guest_position(g.id)
		assert_true(not seen_pos.has(p), "unik plads")
		seen_pos[p] = true
		var c: Vector2i = Vector2i(int(floor(p.x)), int(floor(p.y)))
		assert_true(a.queue_cells.has(c), "plads ligger på køstien: %s" % c)
		assert_eq(c, s.queue_slot_cell(a, i))
	var st: Dictionary = s.attraction_stats(a.id)
	assert_eq(st["queue_length"], 8)
	assert_eq(st["queue_capacity"], 8)
	assert_true(int(st["wait_ticks_estimate"]) > 3000)
	# Forreste plads ligger nærmest indgangen.
	var p0: Vector2 = s.queue_slot_position(a, 0)
	var p1: Vector2 = s.queue_slot_position(a, 1)
	assert_true(p0.y < p1.y)


func test_patience_and_abandon() -> void:
	var s := _queue_park({"queue_patience_ticks": {"min": 10, "max": 10}, "queue_impatient_decay": 1.0,
		"queue_abandon_happiness": 5})
	var a: Attraction = s.attractions[0]
	var g := Guest.new(500, s.approach_cell(a))
	g.happiness = 80.0
	g.money = 100
	g.rides_left = 0
	s.guests[g.id] = g
	g.target_attraction_id = a.id
	g.state = Guest.State.QUEUING
	s._join_queue(g, a)
	a.riders = [1, 2]  # forlystelsen kører – køen står stille
	a.ticks_left = 99999
	assert_eq(g.patience, 10.0)
	for i in 10:
		s._tick_guest(g)
	assert_eq(g.patience, 0.0)
	assert_eq(g.thought, ParkSim.M7_THOUGHTS["queue_bored"])
	assert_eq(g.state, Guest.State.QUEUING)
	for i in 5:
		s._tick_guest(g)
	assert_true(g.state != Guest.State.QUEUING, "opgav køen")
	assert_true(not a.queue.has(g.id))
	assert_eq(g.queue_index, -1)
	assert_true(g.rejected_ids.has(a.id))
	assert_true(g.happiness <= 76.0)


func test_entertainer_halves_patience_loss() -> void:
	var s := _queue_park()
	var a: Attraction = s.attractions[0]
	var g := Guest.new(500, s.approach_cell(a))
	s.guests[g.id] = g
	g.target_attraction_id = a.id
	g.state = Guest.State.QUEUING
	s._join_queue(g, a)
	var p0: float = g.patience
	for i in 10:
		s._tick_guest(g)
	assert_eq(g.patience, p0 - 10.0)
	assert_true(s.cmd_hire_staff("entertainer", Vector2i(11, 21)) > 0)
	for i in 10:
		s._tick_guest(g)
	assert_eq(g.patience, p0 - 15.0, "halvt tab med underholdning")


func test_choice_prefers_shorter_queue() -> void:
	var b := Balance.from_dicts({"start_money": 100000, "entry_fee": 0, "path_cost": 0, "day_ticks": 100000},
		{"needs": {"toilet": {"rate": 0.0, "threshold": 50}}, "queue_weight_cells": 3}, {"queue_max_cycles": 10})
	var s := ParkSim.new(30, 30, 2, b)
	s.register_def(AttractionDef.from_dict({"id": "wc", "kind": "toilet", "footprint": [1, 1], "capacity": 1,
		"ride_ticks": 50, "ticket_price": 0, "satisfies": {"toilet": -80}}))
	for x in range(5, 25):
		s.cmd_place_path(Vector2i(x, 20))
	for y in range(21, 29):
		s.cmd_place_path(Vector2i(15, y))
	var near: Attraction = s.cmd_place_attraction("wc", Vector2i(13, 18))  # indgang (13,19)? footprint 1 → (13,19)
	var far: Attraction = s.cmd_place_attraction("wc", Vector2i(20, 18))
	s.cmd_place_path(Vector2i(13, 19))
	s.cmd_place_path(Vector2i(20, 19))
	var g := Guest.new(900, Vector2i(15, 20))
	g.money = 100
	g.needs = {"toilet": 90.0}
	s.guests[g.id] = g
	s._choose_goal(g)
	assert_eq(g.target_attraction_id, near.id, "tom kø: nærmeste")
	for i in 4:
		near.enqueue(7000 + i)  # 4 × 3 = 12 > afstandsforskel
	s._choose_goal(g)
	assert_eq(g.target_attraction_id, far.id, "lang kø: den ledige")


func test_blocked_by_full_cell_then_pushes_through() -> void:
	var s := _queue_park()
	var g := Guest.new(42, Vector2i(15, 25))
	g.money = 100
	s.guests[g.id] = g
	g.next_cell = Vector2i(15, 24)
	g.path = [Vector2i(15, 23)] as Array[Vector2i]
	g.target_attraction_id = s.attractions[0].id
	s.world.occupancy_add(Vector2i(15, 24), 6)
	for i in 30:
		s._tick_guest(g)
	assert_eq(g.cell, Vector2i(15, 25), "venter ved fuld celle")
	assert_true(g.blocked_ticks > 0)
	for i in 60:
		s._tick_guest(g)
	assert_true(g.cell != Vector2i(15, 25), "presser sig igennem efter 3 × reroute (ingen fastlåsning)")


func test_reroute_around_full_cell() -> void:
	var s := ParkSim.new(20, 20, 3, _balance())
	# Ring: (5..9, 5) og (5..9, 9) forbundet af x=5 og x=9.
	for x in range(5, 10):
		s.cmd_place_path(Vector2i(x, 5))
		s.cmd_place_path(Vector2i(x, 9))
	for y in range(6, 9):
		s.cmd_place_path(Vector2i(5, y))
		s.cmd_place_path(Vector2i(9, y))
	var g := Guest.new(1, Vector2i(5, 5))
	g.money = 10
	s.guests[g.id] = g
	s._set_route(g, s.path_finder.find_path(Vector2i(5, 5), Vector2i(9, 9)))
	var first: Vector2i = g.next_cell
	s.world.occupancy_add(first, 6)
	for i in s.balance.crowd_reroute_ticks + 12:
		s._tick_guest(g)
	assert_true(g.next_cell != first, "ny rute uden om den fulde celle")
	assert_eq(g.path[g.path.size() - 1], Vector2i(9, 9))


func test_crowding_counter_and_thought() -> void:
	var s := _queue_park()
	var c := Vector2i(15, 25)
	for i in s.balance.crowd_ticks + 1:
		s.world.occupancy_reset()
		s.world.occupancy_add(c, 6)
		s.world.update_crowd(6)
	assert_true(s.crowded_cells().has(c))
	assert_eq(s.occupancy(c), 6)
	var g := Guest.new(77, c)
	g.happiness = 50.0
	s.guests[g.id] = g
	s._apply_surroundings(g)
	assert_true(g.happiness < 50.0)
	assert_eq(g.thought, ParkSim.M7_THOUGHTS["crowded"])
	s.world.occupancy_reset()
	s.world.update_crowd(6)
	assert_true(not s.crowded_cells().has(c), "nulstilles når cellen ikke er fuld")


func test_occupancy_never_above_max_in_corridor() -> void:
	var s := _queue_park()
	s.spawn_interval_ticks = 1
	s.max_guests = 80
	s.rides_per_guest_min = 3
	s.rides_per_guest_max = 3
	var worst: int = 0
	for i in 1500:
		s.update(SimClock.TICK_DELTA)
		for y in range(21, 28):
			if s.occupancy(Vector2i(15, y)) > worst:
				worst = s.occupancy(Vector2i(15, y))
	assert_true(worst <= s.balance.max_guests_per_cell + 1, "belægning ≤ 6 (+1 ved gennempresning), fik %d" % worst)


func test_queue_index_survives_save() -> void:
	var s := _queue_park()
	s.spawn_interval_ticks = 3
	s.max_guests = 14
	s.rides_per_guest_min = 5
	s.rides_per_guest_max = 5
	_step(s, 600)
	var l := ParkSim.from_save(SaveCodec.parse(SaveCodec.stringify(s.to_save())), s.balance)
	assert_eq(SaveCodec.stringify(l.to_save()["park"]), SaveCodec.stringify(s.to_save()["park"]))
	assert_eq(l.attractions[0].queue_cells, s.attractions[0].queue_cells, "køstien genberegnes")
	_step(s, 800)
	_step(l, 800)
	assert_eq(SaveCodec.stringify(l.to_save()["park"]), SaveCodec.stringify(s.to_save()["park"]))


## 64×64-park med 500 gæster (ADR-005 §7).
static func mass_park(seed_v: int) -> ParkSim:
	var s := ParkSim.new(64, 64, seed_v)
	s.economy.money = 1 << 30
	s.balance.guest_money_min = 2000
	s.balance.guest_money_max = 3000
	var e: Vector2i = s.world.entrance
	# Bred hovedgade (3 celler) fra porten, så porten ikke er flaskehals.
	s.cmd_place_path(e + Vector2i(-1, 0))
	s.cmd_place_path(e + Vector2i(1, 0))
	for y in range(10, e.y):
		for dx in [-1, 0, 1]:
			s.cmd_place_path(Vector2i(e.x + dx, y))
	for row in [50, 40, 30, 20, 10]:
		for x in range(8, 57):
			s.cmd_place_path(Vector2i(x, row))
	for y in range(10, 51):
		s.cmd_place_path(Vector2i(8, y))
		s.cmd_place_path(Vector2i(56, y))
	var rides: Array = ["carousel", "teacups", "swing_ride", "ferris_wheel", "bumper_cars", "pirate_ship"]
	var shops: Array = ["burger_stand", "drinks_stand", "toilet", "ice_cream_stand", "fries_stand", "coffee_stand"]
	var i: int = 0
	for row in [50, 40, 30, 20]:
		for x in [12, 22, 40, 48]:
			s.cmd_place_attraction(rides[i % rides.size()], Vector2i(x - 1, row - 4))
			i += 1
		for x in [17, 27, 37, 44, 52]:
			s.cmd_place_attraction(shops[i % shops.size()], Vector2i(x, row - 1))
			i += 1
	# Køstier til den første forlystelse i hver række (fra indgangen nedad mod stien under).
	s.spawn_interval_ticks = 1
	s.max_guests = 500  # 1 pr. tick (spillet: ≤ 400/dag)
	s.rides_per_guest_min = 20
	s.rides_per_guest_max = 30
	return s


func test_determinism_500_guests_and_budget() -> void:
	var a := mass_park(99)
	var b := mass_park(99)
	_step(a, 700)
	_step(b, 700)
	assert_true(a.guests.size() >= 450, "~500 gæster (fik %d)" % a.guests.size())
	var t0: int = Time.get_ticks_usec()
	_step(a, 200)
	var per_tick_ms: float = float(Time.get_ticks_usec() - t0) / 200.0 / 1000.0
	print("T-103 benchmark: %.2f ms/tick med %d gæster" % [per_tick_ms, a.guests.size()])
	_step(b, 200)
	assert_eq(SaveCodec.stringify(b.to_save()["park"]), SaveCodec.stringify(a.to_save()["park"]), "deterministisk")
	assert_true(per_tick_ms <= 8.0, "budget (headless debug ≤ 8 ms; balance.sh --perf måler 4 ms): %.2f" % per_tick_ms)
	var worst: int = 0
	for y in a.world.height:
		for x in a.world.width:
			var c := Vector2i(x, y)
			if c != a.world.entrance and a.occupancy(c) > worst:
				worst = a.occupancy(c)
	assert_true(worst <= a.balance.max_guests_per_cell + 1, "maks 6 pr. celle (fik %d)" % worst)
