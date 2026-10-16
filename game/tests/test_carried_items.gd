extends TestCase
## T-086: bærbare ting.


func _sim(seed_v: int = 3) -> ParkSim:
	var b := Balance.from_dicts({"start_money": 100000, "entry_fee": 0, "path_cost": 0, "day_ticks": 2400},
		{"needs": {"hunger": {"rate": 0.0, "threshold": 100}}, "happiness_start": 50, "leave_happiness": 0},
		{}, {})
	return ParkSim.new(30, 30, seed_v, b)


func _add(s: ParkSim, id: int, cell: Vector2i) -> Guest:
	var g := Guest.new(id, cell)
	g.happiness = 50.0
	s.guests[id] = g
	return g


func test_item_defs_loaded() -> void:
	var s := _sim()
	var d: ItemDef = s.item_def(&"balloon")
	assert_true(d != null)
	assert_eq(d.aura_radius, 2)
	assert_true(s.item_def(&"nope") == null)
	assert_eq(s.get_def("balloon_stand").carry_item, "balloon")


func test_give_item_unique_and_signal() -> void:
	var s := _sim()
	var g := _add(s, 1, Vector2i(5, 5))
	var got: Array = []
	s.item_gained.connect(func(gid: int, it: StringName) -> void: got.append([gid, it]))
	assert_true(s._give_item(g, &"souvenir"))
	assert_true(not s._give_item(g, &"souvenir"))
	assert_eq(g.items.size(), 1)
	assert_eq(got, [[1, &"souvenir"]])


func test_hourly_happiness_and_aura() -> void:
	var s := _sim()
	var a := _add(s, 1, Vector2i(5, 5))
	var near := _add(s, 2, Vector2i(6, 6))  # manhattan 2
	var far := _add(s, 3, Vector2i(9, 5))   # manhattan 4
	a.items.append(&"prize_bear")
	s._tick_items_hour()
	assert_eq(a.happiness, 52.0)
	assert_eq(near.happiness, 50.5)
	assert_eq(far.happiness, 50.0)


func test_balloon_lost_seeded() -> void:
	var lost_a: Array = _run_loss(7)
	var lost_b: Array = _run_loss(7)
	assert_eq(lost_a, lost_b)
	assert_true(lost_a.size() > 0)


func _run_loss(seed_v: int) -> Array:
	var s := _sim(seed_v)
	var out: Array = []
	s.item_lost.connect(func(gid: int, it: StringName, c: Vector2i) -> void: out.append([gid, it, c]))
	for i in 50:
		_add(s, i + 1, Vector2i(i % 30, 1)).items.append(&"balloon")
	for h in 10:
		s._tick_items_hour()
	for e: Array in out:
		var g: Guest = s.guests[e[0]]
		assert_true(not g.items.has(&"balloon"))
		assert_eq(g.thought, ParkSim.ITEM_LOST_THOUGHT)
	return out


func test_guest_info_and_save() -> void:
	var s := _sim()
	var g := _add(s, 1, Vector2i(5, 5))
	g.items.append(&"balloon")
	g.nausea = 12.0
	var info: Dictionary = s.guest_info(1)
	assert_eq(info["items"], ["balloon"])
	assert_eq(info["nausea"], 12.0)
	assert_true(info.has("intensity_tolerance"))
	assert_eq(s.guest_info(99), {})
	var g2: Guest = Guest.from_save(g.to_save())
	assert_eq(g2.items, g.items)
