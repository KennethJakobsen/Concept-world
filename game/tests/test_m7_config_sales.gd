extends TestCase
## T-102 (M7): config pr. bygning, opskrifter, prisvirkninger, salgssignal, statistik og save v4.


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func _park(seed_v: int = 11) -> ParkSim:
	var s := ParkSim.new(40, 40, seed_v)
	s.economy.money += 20000
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


func _by_def(s: ParkSim, def_id: String) -> Attraction:
	for a in s.attractions:
		if a.def.id == def_id:
			return a
	return null


func test_def_parses_config_recipes_effects() -> void:
	var s := ParkSim.new(10, 10, 1)
	var c: AttractionDef = s.get_def("carousel")
	assert_eq(float(c.config["capacity"]["default"]), 8.0)
	assert_true(c.config.has("speed"))
	var b: AttractionDef = s.get_def("burger_stand")
	assert_eq(b.recipes.size(), 2)
	assert_eq(str(b.recipe("salt")["name"]), "Ekstra salt")
	assert_eq(b.price_effects.size(), 1)
	var rt: AttractionDef = AttractionDef.from_dict(b.to_dict())
	assert_eq(rt.recipes, b.recipes, "snapshot bevarer opskrifter")
	assert_eq(rt.config, b.config)


func test_set_config_clamps_and_formulas() -> void:
	var s := _park()
	var a: Attraction = _by_def(s, "carousel")
	var base: Dictionary = s.effective_config(a.id)
	assert_eq(base["capacity"], 8)
	assert_eq(base["upkeep_per_day"], 180)
	assert_eq(base["excitement"], 25)
	assert_false(s.cmd_set_config(a.id, "nope", 1.0))
	assert_true(s.cmd_set_config(a.id, "capacity", 99.0))
	assert_eq(s.effective_config(a.id)["capacity"], 12, "clamp til max")
	assert_eq(s.effective_config(a.id)["upkeep_per_day"], int(round(180 * (0.7 + 0.3 * 12.0 / 8.0))))
	assert_true(s.cmd_set_config(a.id, "ride_ticks", 320.0))
	assert_eq(s.effective_config(a.id)["excitement"], int(round(25 * (0.85 + 0.15 * 320.0 / 200.0))))
	assert_true(s.cmd_set_config(a.id, "speed", 1.2))
	var ec: Dictionary = s.effective_config(a.id)
	assert_near(float(ec["intensity"]), 10.0 * 1.44, 1e-4)
	assert_near(float(ec["nausea"]), 5.0 * 1.44, 1e-4)
	assert_near(a.effective_reliability(), 1.0 - (1.0 - 0.985) * 1.2, 1e-6)
	assert_true(s.cmd_set_config(a.id, "capacity", 8.0))
	assert_false(a.config.has("capacity"), "default = ingen ændring gemt")
	var shop: Attraction = _by_def(s, "burger_stand")
	assert_false(s.cmd_set_config(shop.id, "capacity", 3.0), "shop har ingen config")


func test_config_applies_from_next_ride() -> void:
	var s := _park()
	var a: Attraction = _by_def(s, "carousel")
	for i in 10:
		a.enqueue(1000 + i)
	a.tick()
	assert_eq(a.riders.size(), 8)
	var left: int = a.ticks_left
	s.cmd_set_config(a.id, "ride_ticks", 120.0)
	s.cmd_set_config(a.id, "capacity", 4.0)
	assert_eq(a.ticks_left, left, "turen er låst")
	assert_eq(a.cfg("capacity"), 8.0, "låst under turen")
	while a.is_running():
		a.tick()
	a.tick()
	assert_eq(a.riders.size(), 2, "næste tur: kun 2 tilbage i kø (kapacitet 4)")
	assert_eq(a.ticks_left, 120)


func test_upkeep_scales_with_capacity_at_day_end() -> void:
	var s := _park()
	var a: Attraction = _by_def(s, "carousel")
	s.cmd_set_config(a.id, "capacity", 12.0)
	s._end_day()
	assert_eq(a.upkeep_total, a.upkeep_per_day())
	assert_eq(a.upkeep_total, 207)


func test_recipes_supplies_and_needs() -> void:
	var s := _park()
	var a: Attraction = _by_def(s, "burger_stand")
	assert_false(s.cmd_set_recipe(a.id, "unknown", true))
	assert_true(s.cmd_set_recipe(a.id, "salt", true))
	assert_true(s.cmd_set_recipe(a.id, "big", true))
	assert_eq(a.recipes, ["big", "salt"] as Array[String])
	var g := Guest.new(999, a.entrance_cell)
	g.needs = {"hunger": 80.0, "thirst": 10.0}
	g.happiness = 50.0
	# Forventninger læses fra bodens data (ikke hardcodet), så balancering ikke bryder testen.
	var salt: Dictionary = a.def.recipe("salt")
	var big: Dictionary = a.def.recipe("big")
	var exp_thirst: float = clampf(10.0 + float(salt["satisfies"].get("thirst", 0.0)) + float(big["satisfies"].get("thirst", 0.0)), 0.0, 100.0)
	var exp_hunger: float = clampf(80.0 + float(salt["satisfies"].get("hunger", 0.0)) + float(big["satisfies"].get("hunger", 0.0)), 0.0, 100.0)
	var exp_hap: float = 50.0 + float(salt.get("happiness", 0.0)) + float(big.get("happiness", 0.0))
	s._apply_recipes(g, a)
	assert_near(float(g.needs["thirst"]), exp_thirst, 1e-6)
	assert_near(float(g.needs["hunger"]), exp_hunger, 1e-6)
	assert_near(g.happiness, exp_hap, 1e-6)
	for i in 4:
		s._apply_recipes(g, a)
	var exp_sup: int = int(floor(5.0 * (float(salt["cost_per_sale"]) + float(big["cost_per_sale"])) + 1e-9))
	assert_eq(a.supplies_total, exp_sup)
	assert_eq(int(s.finance_report()["today"]["supplies"]), -exp_sup)
	assert_true(Economy.CATEGORIES.has("supplies"))
	var v_off: float = 0.0
	s.cmd_set_recipe(a.id, "big", false)
	v_off = s.price_value(a)
	s.cmd_set_recipe(a.id, "big", true)
	assert_near(s.price_value(a), v_off * 1.15, 1e-4, "price_tolerance")


func test_price_effects_extra_purchase() -> void:
	var s := _park()
	var a: Attraction = _by_def(s, "burger_stand")
	s.cmd_set_price(a.id, 1)  # 1/4 < 0.6
	var extra: int = 0
	var thought: int = 0
	for i in 200:
		var g := Guest.new(5000 + i, a.entrance_cell)
		g.money = 100
		g.nausea = 0.0
		s._price_effects(g, a)
		if g.money < 100:
			extra += 1
			assert_near(g.nausea, 15.0, 1e-6)
		if g.thought == ParkSim.TOO_MUCH_THOUGHT:
			thought += 1
	assert_true(extra > 40 and extra < 100, "ca. 35 %% ekstra køb (fik %d)" % extra)
	assert_eq(thought, extra)
	s.cmd_set_price(a.id, 4)
	var g2 := Guest.new(1, a.entrance_cell)
	g2.money = 100
	for i in 50:
		s._price_effects(g2, a)
	assert_eq(g2.money, 100, "normal pris: ingen ekstra køb")


func test_sales_tick_once_per_tick_and_stats() -> void:
	var s := _park(3)
	var ticks: Array = [0, 0]
	s.sales_tick.connect(func(sales: Dictionary) -> void:
		ticks[0] += 1
		for k: Variant in sales:
			ticks[1] += int(sales[k]))
	var purchases: Array = [0]
	s.purchase_made.connect(func(_g: int, _b: int, amount: int) -> void: purchases[0] += amount)
	_step(s, 2000)
	assert_true(ticks[0] > 0, "salg udsendt")
	assert_eq(ticks[1], purchases[0], "sum af sales_tick = sum af køb")
	var a: Attraction = _by_def(s, "carousel")
	var st: Dictionary = s.attraction_stats(a.id)
	for k in ["revenue_today", "revenue_yesterday", "revenue_total", "upkeep_total", "net_total",
			"customers_today", "revenue_days", "payback_day", "queue_length", "queue_capacity",
			"wait_ticks_estimate"]:
		assert_true(st.has(k), k)
	assert_eq(st["revenue_today"], a.total_revenue)
	assert_eq(st["payback_day"], -1)


func test_revenue_history_and_payback() -> void:
	var s := _park(5)
	var a: Attraction = _by_def(s, "drinks_stand")
	for d in 9:
		a.revenue_today = 100
		a.total_revenue += 100
		a.customers_today = 3
		s._end_day()
	assert_eq(a.revenue_days.size(), 7, "kun 7 dage")
	assert_eq(a.revenue_today, 0)
	assert_eq(a.customers_today, 0)
	assert_eq(s.attraction_stats(a.id)["revenue_yesterday"], 100)
	assert_true(a.payback_day > 0, "tjent hjem")
	var net: int = a.total_revenue - a.upkeep_total
	assert_eq(s.attraction_stats(a.id)["net_total"], net)


func test_migration_v3_to_v4() -> void:
	var v3: Dictionary = {"save_version": 3, "park": {"world": {}, "guests": [{"id": 1}],
		"attractions": [{"id": 1}]}}
	var m: Dictionary = SaveMigrations.migrate(v3)
	assert_eq(SaveMigrations.CURRENT, 4)
	assert_eq(m["save_version"], 4)
	var ad: Dictionary = m["park"]["attractions"][0]
	assert_eq(ad["config"], {})
	assert_eq(ad["recipes"], [])
	assert_eq(ad["customers_today"], 0)
	assert_eq(ad["revenue_days"], [])
	assert_eq(ad["payback_day"], -1)
	var gd: Dictionary = m["park"]["guests"][0]
	assert_eq(gd["patience"], 1050.0)
	assert_eq(gd["queue_index"], -1)
	assert_eq(gd["blocked_ticks"], 0)


func test_migration_v2_and_v1_to_v4() -> void:
	var v2: Dictionary = {"save_version": 2, "park": {"world": {}, "guests": [{"id": 1}],
		"attractions": [{"id": 1}]}}
	var m: Dictionary = SaveMigrations.migrate(v2)
	assert_eq(m["save_version"], 4)
	assert_eq(m["park"]["attractions"][0]["prizes_won"], 0, "v3-trin kørt")
	assert_eq(m["park"]["attractions"][0]["payback_day"], -1, "v4-trin kørt")
	var d: Dictionary = SaveCodec.parse(FileAccess.get_file_as_string("res://tests/fixtures/save_v1.json"))
	var m1: Dictionary = SaveMigrations.migrate(d)
	assert_eq(m1["save_version"], 4)
	var s := ParkSim.from_save(d)
	assert_true(s != null)
	_step(s, 100)
	assert_eq(int(s.to_save()["save_version"]), 4)


func test_roundtrip_with_config_and_recipes() -> void:
	var a := _park(21)
	var car: Attraction = _by_def(a, "carousel")
	var shop: Attraction = _by_def(a, "burger_stand")
	a.cmd_set_config(car.id, "speed", 1.2)
	a.cmd_set_config(car.id, "capacity", 10.0)
	a.cmd_set_recipe(shop.id, "salt", true)
	a.cmd_set_price(shop.id, 2)
	_step(a, 1700)
	a.cmd_set_config(car.id, "ride_ticks", 150.0)  # evt. midt i en tur
	var b := ParkSim.from_save(SaveCodec.parse(SaveCodec.stringify(a.to_save())))
	assert_true(b != null)
	var pa: String = SaveCodec.stringify(a.to_save()["park"])
	assert_eq(SaveCodec.stringify(b.to_save()["park"]), pa)
	_step(a, 2500)
	_step(b, 2500)
	assert_eq(SaveCodec.stringify(b.to_save()["park"]), SaveCodec.stringify(a.to_save()["park"]))


func assert_false(cond: bool, msg: String = "") -> void:
	assert_true(not cond, msg)


func assert_near(actual: float, expected: float, eps: float, msg: String = "") -> void:
	assert_true(absf(actual - expected) <= eps, "expected %s ≈ %s. %s" % [actual, expected, msg])
