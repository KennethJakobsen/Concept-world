extends TestCase
## T-043: båret affald spredes langs ruten; ødelagte forlystelser tæller ikke i tiltrækning.


func _sim(rules: Dictionary = {}) -> ParkSim:
	var r: Dictionary = {"litter_chance_after_shop": 1.0, "litter_chance_with_bin": 0.0, "bin_radius": 4,
		"bin_capacity": 1000, "litter_max_per_cell": 5, "litter_carry_cells": 8}
	r.merge(rules, true)
	var b := Balance.from_dicts(
		{"start_money": 100000, "entry_fee": 0, "path_cost": 0, "guest_money_min": 500,
			"guest_money_max": 500, "day_ticks": 100000},
		{"needs": {"hunger": {"rate": 1.0, "threshold": 50}}, "happiness_start": 80, "leave_happiness": 0,
			"speed": 0.5}, {}, r)
	var s := ParkSim.new(30, 30, 21, b)
	s.register_def(AttractionDef.from_dict({"id": "shop", "kind": "shop", "footprint": [1, 1], "capacity": 2,
		"ride_ticks": 5, "ticket_price": 0, "satisfies": {"hunger": -70}}))
	s.register_def(AttractionDef.from_dict({"id": "r", "kind": "ride", "footprint": [1, 1], "capacity": 1,
		"ride_ticks": 10, "ticket_price": 0, "excitement": 16, "reliability": 0.5}))
	s.register_decor_def(DecorDef.from_dict({"id": "bin", "kind": "bin", "on_path": true}))
	for y in range(5, 29):
		s.cmd_place_path(Vector2i(15, y))
	s.cmd_place_attraction("shop", Vector2i(14, 20))
	s.spawn_interval_ticks = 15
	s.max_guests = 6
	return s


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func test_litter_spread_over_cells() -> void:
	var s := _sim()
	_step(s, 1500)
	assert_true(s.world.litter.size() >= 4, "celler med affald: %d" % s.world.litter.size())
	assert_true(s.world.total_litter() > 5, "mere end én celles loft: %d" % s.world.total_litter())
	assert_true(not s.world.litter.has(Vector2i(14, 21)) or s.world.litter.size() > 1)


func test_bin_collects_carried_litter() -> void:
	var s := _sim({"bin_radius": 30})
	var bid: int = s.cmd_place_decor("bin", Vector2i(15, 10))
	_step(s, 1500)
	assert_eq(s.world.total_litter(), 0)
	assert_true(s.decor[bid].fill > 0)


func test_save_roundtrip_with_carried_litter() -> void:
	var s := _sim()
	var carrying: Guest = null
	for i in 3000:
		s.update(SimClock.TICK_DELTA)
		for g: Guest in s.guests.values():
			if g.litter_steps_left > 0:
				carrying = g
		if carrying != null:
			break
	assert_true(carrying != null)
	var b := ParkSim.from_save(SaveCodec.parse(SaveCodec.stringify(s.to_save())), s.balance,
		[s.get_def("shop"), s.get_def("r"), s.get_decor_def("bin")])
	assert_eq((b.guests[carrying.id] as Guest).litter_steps_left, carrying.litter_steps_left)
	_step(s, 1000)
	_step(b, 1000)
	assert_eq(SaveCodec.stringify(b.to_save()["park"]), SaveCodec.stringify(s.to_save()["park"]))


func test_broken_not_in_score_but_in_max_guests() -> void:
	var s := _sim()
	s.fixed_spawn = false
	var a: Attraction = s.cmd_place_attraction("r", Vector2i(15, 3))
	var score: float = s.attraction_score()
	var maxg: int = s.current_max_guests()
	a.broken = true
	assert_true(s.attraction_score() < score)
	assert_eq(s.current_max_guests(), maxg)
