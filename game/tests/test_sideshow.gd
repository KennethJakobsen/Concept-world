extends TestCase
## T-085: sideshows og præmier.


func _sim(seed_v: int = 5, win: float = 0.25) -> ParkSim:
	var b := Balance.from_dicts({"start_money": 100000, "entry_fee": 0, "path_cost": 0, "guest_money_min": 500,
		"guest_money_max": 500, "day_ticks": 100000},
		{"needs": {"hunger": {"rate": 0.0, "threshold": 100}}, "happiness_start": 60, "leave_happiness": 0,
			"speed": 0.5}, {}, {"litter_chance_after_shop": 0.0})
	var s := ParkSim.new(30, 30, seed_v, b)
	s.register_def(AttractionDef.from_dict({"id": "shy", "kind": "sideshow", "footprint": [1, 1],
		"capacity": 3, "ride_ticks": 10, "ticket_price": 2, "excitement": 4, "satisfies": {},
		"win_chance": win, "prize_cost": 5, "prize_happiness": 10.0, "prize_item": "prize_bear"}))
	for y in range(5, 29):
		s.cmd_place_path(Vector2i(15, y))
	return s


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func test_def_fields_from_content() -> void:
	var s := ParkSim.new(10, 10, 1)
	var d: AttractionDef = s.get_def("coconut_shy")
	assert_eq(d.kind, "sideshow")
	assert_eq(d.win_chance, 0.25)
	assert_eq(d.prize_cost, 5)
	assert_eq(d.prize_item, "prize_bear")
	assert_eq(AttractionDef.from_dict(d.to_dict()).prize_happiness, 10.0)


func test_win_frequency_seeded() -> void:
	var s := _sim(5, 0.25)
	var a: Attraction = s.cmd_place_attraction("shy", Vector2i(14, 10))
	var wins: Array = []
	s.prize_won.connect(func(gid: int, aid: int, item: String) -> void: wins.append([gid, aid, item]))
	var n: int = 2000
	for i in n:
		var g := Guest.new(1000 + i, a.entrance_cell)
		g.happiness = 50.0
		s._sideshow_result(g, a)
	assert_eq(a.prizes_won, wins.size())
	var rate: float = float(a.prizes_won) / n
	assert_true(rate > 0.21 and rate < 0.29, "gevinstrate %f" % rate)
	assert_eq(wins[0][1], a.id)
	assert_eq(wins[0][2], "prize_bear")
	# Samme seed → samme antal gevinster.
	var s2 := _sim(5, 0.25)
	var a2: Attraction = s2.cmd_place_attraction("shy", Vector2i(14, 10))
	for i in n:
		s2._sideshow_result(Guest.new(1000 + i, a2.entrance_cell), a2)
	assert_eq(a2.prizes_won, a.prizes_won)


func test_win_and_loss_effects() -> void:
	var s := _sim(5, 1.0)
	var a: Attraction = s.cmd_place_attraction("shy", Vector2i(14, 10))
	var g := Guest.new(1, a.entrance_cell)
	g.happiness = 50.0
	var m: int = s.economy.money
	s._sideshow_result(g, a)
	assert_eq(g.happiness, 60.0)
	assert_true(g.items.has(&"prize_bear"))
	assert_eq(s.economy.money, m - 5)
	assert_eq(s.economy.get_today_total("prizes"), -5)
	assert_eq(a.prize_cost_total, 5)
	var lose := _sim(5, 0.0)
	var b: Attraction = lose.cmd_place_attraction("shy", Vector2i(14, 10))
	var g2 := Guest.new(2, b.entrance_cell)
	g2.happiness = 50.0
	lose._sideshow_result(g2, b)
	assert_eq(g2.happiness, 54.0)
	assert_eq(b.prizes_won, 0)
	assert_true(g2.items.is_empty())


func test_guests_visit_pay_and_stats() -> void:
	var s := _sim(7, 0.5)
	var a: Attraction = s.cmd_place_attraction("shy", Vector2i(14, 10))
	s.spawn_interval_ticks = 10
	s.max_guests = 10
	_step(s, 2000)
	assert_true(a.total_visitors > 0, "besøg")
	assert_true(a.total_revenue >= a.total_visitors * 2)
	assert_true(a.prizes_won > 0)
	var st: Dictionary = s.attraction_stats(a.id)
	assert_eq(st["prizes_won"], a.prizes_won)
	assert_eq(st["prize_cost_total"], a.prizes_won * 5)
	var fr: Dictionary = s.finance_report()
	assert_true((fr["categories"] as Array).has("prizes"))
	assert_eq(fr["today"]["prizes"], -a.prizes_won * 5)
	assert_eq(s.attraction_stats(999), {})


func test_save_roundtrip_prizes() -> void:
	var s := _sim(7, 0.5)
	var a: Attraction = s.cmd_place_attraction("shy", Vector2i(14, 10))
	s.spawn_interval_ticks = 10
	s.max_guests = 10
	_step(s, 1500)
	assert_true(a.prizes_won > 0)
	var b := ParkSim.from_save(SaveCodec.parse(SaveCodec.stringify(s.to_save())), s.balance, [s.get_def("shy")])
	assert_eq(b.get_attraction(a.id).prizes_won, a.prizes_won)
	assert_eq(SaveCodec.stringify(b.to_save()["park"]), SaveCodec.stringify(s.to_save()["park"]))
	_step(s, 800)
	_step(b, 800)
	assert_eq(SaveCodec.stringify(b.to_save()["park"]), SaveCodec.stringify(s.to_save()["park"]))
	var m: Dictionary = SaveMigrations.migrate({"save_version": 2, "park": {"attractions": [{"id": 1}]}})
	assert_eq(m["park"]["attractions"][0]["prize_cost_total"], 0)
