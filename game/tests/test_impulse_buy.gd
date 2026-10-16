extends TestCase
## T-119: impulskøb i butikker uden behov.


func _bal(impulse: Dictionary = {}) -> Balance:
	var g: Dictionary = {"needs": {"hunger": {"rate": 0.0, "threshold": 100}}, "happiness_start": 80,
		"leave_happiness": 0, "spawn_interval_ticks": 10, "max_guests": 20, "speed": 0.2, "need_start_max": 0}
	if not impulse.is_empty():
		g["impulse"] = impulse
	return Balance.from_dicts({"start_money": 10000, "entry_fee": 0, "path_cost": 0,
		"guest_money_min": 100, "guest_money_max": 100, "day_ticks": 100000}, g)


## Indgang (10,19). Sti (10,16..18). Ballonbod på (10,15) → indgang (10,16).
func _sim(seed_v: int, b: Balance = null) -> ParkSim:
	var s := ParkSim.new(20, 20, seed_v, b if b != null else _bal())
	s.register_def(AttractionDef.from_dict({"id": "bal", "kind": "shop", "footprint": [1, 1],
		"capacity": 2, "ride_ticks": 10, "ticket_price": 2, "satisfies": {}, "carry_item": "balloon"}))
	for y in range(16, 19):
		s.cmd_place_path(Vector2i(10, y))
	assert_true(s.cmd_place_attraction("bal", Vector2i(10, 15)) != null)
	return s


func _guest(s: ParkSim, id: int, happiness: float = 80.0, money: int = 100) -> Guest:
	var g := Guest.new(id, Vector2i(10, 18))
	g.happiness = happiness
	g.money = money
	s.guests[id] = g
	return g


func _count(seed_v: int, n: int) -> Array:
	var s := _sim(seed_v)
	var out: Array = []
	for i in n:
		var g := _guest(s, i + 1)
		out.append(s._try_impulse(g))
	return out


func test_params_default_and_from_data() -> void:
	var d := _bal()
	assert_eq(d.impulse_base_chance, 0.35)
	assert_eq(d.impulse_radius, 12)
	var b := _bal({"base_chance": 0.5, "radius": 3, "min_happiness": 10, "price_sensitivity": 2})
	assert_eq(b.impulse_base_chance, 0.5)
	assert_eq(b.impulse_radius, 3)
	assert_eq(b.impulse_min_happiness, 10.0)
	assert_eq(b.impulse_price_sensitivity, 2.0)


func test_frequency_and_determinism() -> void:
	var a: Array = _count(11, 400)
	assert_eq(a, _count(11, 400))
	var hits: int = a.count(true)
	# forventet 0.35 × 0.8 × (1 - 2/100) ≈ 0.274 → ~110 af 400
	assert_true(hits > 80 and hits < 140, "hits=%d" % hits)


func test_no_repeat_unhappy_far_or_poor() -> void:
	var s := _sim(3, _bal({"base_chance": 1.0}))
	var has := _guest(s, 1)
	has.items.append(&"balloon")
	assert_true(not s._try_impulse(has))
	assert_true(not s._try_impulse(_guest(s, 2, 10.0)))
	assert_true(not s._try_impulse(_guest(s, 3, 80.0, 1)))
	var ok := _guest(s, 4)
	assert_true(s._try_impulse(ok))
	assert_eq(ok.target_attraction_id, s.attractions[0].id)
	var far := _sim(3, _bal({"base_chance": 1.0, "radius": 1}))
	assert_true(not far._try_impulse(_guest(far, 1)))


func test_shop_without_need_gets_visits_no_double_buy() -> void:
	var s := _sim(9)
	for i in 6000:
		s.update(SimClock.TICK_DELTA)
	assert_true(s.attractions[0].total_visitors > 0)
	for gid in s.guests:
		var g: Guest = s.guests[gid]
		assert_true(g.items.count(&"balloon") <= 1)
