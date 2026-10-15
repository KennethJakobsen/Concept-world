extends TestCase
## T-019: Economy + økonomi-kommandoer i ParkSim (stub-balance, uafhængig af content-tal).

var _days: Array = []


func _bal(extra: Dictionary = {}) -> Balance:
	var e: Dictionary = {"start_money": 1000, "entry_fee": 5, "path_cost": 10, "path_refund": 4,
		"guest_money_min": 50, "guest_money_max": 50, "day_ticks": 100}
	e.merge(extra, true)
	return Balance.from_dicts(e, {"needs": {}, "spawn_interval_ticks": 10, "max_guests": 1})


func _stub_def(cost: int = 400, running: int = 30) -> AttractionDef:
	return AttractionDef.from_dict({"id": "stub_ride", "kind": "ride", "footprint": [3, 3],
		"build_cost": cost, "running_cost_per_day": running, "capacity": 4, "ride_ticks": 20,
		"ticket_price": 3, "excitement": 20})


func _sim(extra: Dictionary = {}) -> ParkSim:
	var s := ParkSim.new(20, 20, 1, _bal(extra))
	s.register_def(_stub_def())
	return s


func test_economy_basics() -> void:
	var e := Economy.new(100)
	assert_true(e.can_afford(100))
	assert_true(not e.can_afford(101))
	assert_true(not e.spend(150, "build"))
	assert_eq(e.money, 100)
	assert_true(e.spend(40, "build"))
	e.earn(15, "tickets")
	e.charge(200, "running")
	assert_eq(e.money, -125)
	assert_eq(e.get_today_total("build"), -40)
	assert_eq(e.get_today_total("tickets"), 15)
	var d: Dictionary = e.close_day(1)
	assert_eq(d["net"], -225)
	assert_eq(e.history.size(), 1)
	assert_true(e.today.is_empty())


func test_path_cost_and_refund() -> void:
	var s := _sim({"start_money": 25})
	assert_true(s.cmd_place_path(Vector2i(10, 18)))
	assert_true(s.cmd_place_path(Vector2i(10, 17)))
	assert_eq(s.economy.money, 5)
	assert_true(not s.cmd_place_path(Vector2i(10, 16)), "ikke råd")
	assert_eq(s.world.get_tile(Vector2i(10, 16)), ParkWorld.Tile.GRASS)
	assert_true(s.cmd_remove_path(Vector2i(10, 17)))
	assert_eq(s.economy.money, 9)


func test_build_cost_and_remove_refund() -> void:
	var s := _sim({"start_money": 500})
	var a: Attraction = s.cmd_place_attraction("stub_ride", Vector2i(9, 12))
	assert_true(a != null)
	assert_eq(s.economy.money, 100)
	assert_eq(a.price, 3)
	assert_true(s.cmd_place_attraction("stub_ride", Vector2i(2, 2)) == null, "ikke råd")
	assert_true(s.cmd_remove_attraction(a.id))
	assert_eq(s.economy.money, 300)
	assert_true(s.get_attraction(a.id) == null)
	assert_eq(s.world.get_tile(Vector2i(10, 13)), ParkWorld.Tile.GRASS)
	assert_true(not s.cmd_remove_attraction(a.id))


func test_set_price_open_entry() -> void:
	var s := _sim()
	var a: Attraction = s.cmd_place_attraction("stub_ride", Vector2i(9, 12))
	assert_true(s.cmd_set_price(a.id, 9))
	assert_eq(a.price, 9)
	assert_true(not s.cmd_set_price(a.id, -1))
	assert_true(not s.cmd_set_price(999, 1))
	assert_true(s.cmd_set_open(a.id, false))
	assert_true(not a.is_open)
	s.cmd_set_entry_fee(12)
	assert_eq(s.entry_fee, 12)


func _on_day(d: int) -> void:
	_days.append(d)


func test_day_passes_and_running_costs() -> void:
	var s := _sim()
	s.day_passed.connect(_on_day)
	s.cmd_place_attraction("stub_ride", Vector2i(2, 2))
	var before: int = s.economy.money
	for i in 100:
		s.update(SimClock.TICK_DELTA)
	assert_eq(_days, [2])
	assert_eq(s.day, 2)
	assert_eq(s.economy.money, before - 30)
	assert_eq(int(s.economy.history[0]["totals"]["running"]), -30)


func test_entry_fee_and_ticket_revenue() -> void:
	var s := _sim({"day_ticks": 100000})
	for y in range(16, 19):
		s.cmd_place_path(Vector2i(10, y))
	var a: Attraction = s.cmd_place_attraction("stub_ride", Vector2i(9, 12))
	var before: int = s.economy.money
	var spawned: Array = [0]
	s.guest_spawned.connect(func(_g: Guest) -> void: spawned[0] += 1)
	for i in 200:
		s.update(SimClock.TICK_DELTA)
	assert_true(spawned[0] >= 1)
	assert_eq(s.economy.get_today_total("entry"), 5 * spawned[0])
	assert_true(a.total_visitors >= 1)
	assert_eq(a.total_revenue, a.total_visitors * 3)
	assert_eq(s.economy.money, before + 5 * spawned[0] + a.total_revenue)


func test_real_content_parses() -> void:
	var b := Balance.load_default()
	assert_true(b.day_ticks > 0 and b.start_money > 0)
	assert_true(not b.needs.is_empty())
	var dir := DirAccess.open("res://content/attractions/")
	var n: int = 0
	for f in dir.get_files():
		if f.ends_with(".json"):
			var d := AttractionDef.from_json("res://content/attractions/" + f)
			assert_true(d != null and d.id != "", f)
			assert_true(d.kind in ["ride", "shop", "toilet", "coaster"], f)
			n += 1
	assert_true(n > 0)
	var s := ParkSim.new(30, 30, 1)
	var c: Attraction = s.cmd_place_attraction("carousel", Vector2i(2, 2))
	var g := Guest.new(1, Vector2i.ZERO)
	g.happiness = 50.0
	assert_eq(s.price_value(c, g), 7.0)  # GDD: karrusel 7 ved neutral glæde
