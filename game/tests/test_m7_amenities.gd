extends TestCase
## T-104 (M7): gå hjem, hæveautomat, spande (fyld/overløb), bænke med pladser, lys og affald.

const RIDE: Dictionary = {"id": "r10", "kind": "ride", "footprint": [1, 1], "capacity": 4,
	"ride_ticks": 10, "ticket_price": 10, "excitement": 50}
const ATM: Dictionary = {"id": "atm_t", "kind": "atm", "footprint": [1, 1], "capacity": 1, "ride_ticks": 5,
	"ticket_price": 0, "withdraw": {"min": 20, "max": 50}, "fee": 1, "max_per_visit": 2, "range_cells": 30,
	"min_happiness": 40}


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func _sim(park_extra: Dictionary = {}) -> ParkSim:
	var park: Dictionary = {"max_guests_base": 0, "dark_path_penalty_per_tick": 0.5}
	park.merge(park_extra, true)
	var b := Balance.from_dicts(
		{"start_money": 100000, "entry_fee": 0, "path_cost": 0, "guest_money_min": 500,
			"guest_money_max": 500, "day_ticks": 100000},
		{"needs": {"energy": {"rate": 0.0, "threshold": 80}}, "happiness_start": 70, "leave_happiness": 20,
			"leave_energy": 90, "speed": 0.5},
		park, {"bin_radius": 4, "bin_capacity": 4, "litter_chance_after_shop": 0.0, "litter_chance_with_bin": 0.0,
			"bench_seek_energy": 70, "bench_rest_ticks": 50})
	var s := ParkSim.new(30, 30, 7, b)
	s.register_def(AttractionDef.from_dict(RIDE))
	s.register_def(AttractionDef.from_dict(ATM))
	s.register_decor_def(DecorDef.from_dict({"id": "bench", "kind": "bench", "on_path": true, "seats": 2}))
	s.register_decor_def(DecorDef.from_dict({"id": "bin", "kind": "bin", "on_path": true, "capacity": 4}))
	s.register_decor_def(DecorDef.from_dict({"id": "lamp", "kind": "lamp", "on_path": true,
		"happiness_aura": 0.5, "aura_radius": 2, "night_aura": 1.5}))
	for y in range(21, 29):
		s.cmd_place_path(Vector2i(15, y))
	for x in range(5, 15):
		s.cmd_place_path(Vector2i(x, 21))
	return s


func _guest(s: ParkSim, cell: Vector2i, money: int = 100) -> Guest:
	var g := Guest.new(500 + s.guests.size(), cell)
	g.money = money
	g.happiness = 70.0
	g.needs = {"energy": 0.0}
	s.guests[g.id] = g
	return g


func test_leave_reasons_and_leaving_guest_does_not_queue() -> void:
	var s := _sim()
	s.cmd_place_attraction("r10", Vector2i(12, 20))
	var g := _guest(s, Vector2i(10, 21))
	g.happiness = 10.0
	s._choose_goal(g)
	assert_eq(g.state, Guest.State.LEAVING)
	assert_true(g.leaving)
	assert_eq(g.leave_reason, "unhappy")
	var t := _guest(s, Vector2i(10, 21))
	t.needs["energy"] = 95.0
	s._choose_goal(t)
	assert_eq(t.leave_reason, "tired")
	var p := _guest(s, Vector2i(10, 21), 3)
	s._choose_goal(p)
	assert_eq(p.leave_reason, "no_money")
	assert_eq(s.guest_info(p.id)["leave_reason"], "no_money")
	# En gæst på vej hjem vælger ikke en forlystelse igen, selv om humøret stiger.
	g.happiness = 100.0
	s._choose_goal(g)
	assert_eq(g.state, Guest.State.LEAVING)
	assert_eq(g.target_attraction_id, -1)
	for i in 200:
		s.update(SimClock.TICK_DELTA)
		if s.guests.has(g.id):
			assert_true(g.state != Guest.State.QUEUING)
	assert_eq(s.attractions[0].total_visitors, 0)


func test_atm_withdraw_fee_and_max_per_visit() -> void:
	var s := _sim()
	s.cmd_place_attraction("r10", Vector2i(12, 20))
	var atm: Attraction = s.cmd_place_attraction("atm_t", Vector2i(8, 20))
	assert_true(atm != null and atm.is_atm())
	var used: Array = []
	s.atm_used.connect(func(gid: int, aid: int, amount: int) -> void: used.append([gid, aid, amount]))
	var g := _guest(s, Vector2i(11, 21), 2)
	s._choose_goal(g)
	assert_eq(g.target_attraction_id, atm.id, "går til hæveautomaten i stedet for hjem")
	assert_true(not g.leaving)
	for i in 100:
		s.update(SimClock.TICK_DELTA)
		if not used.is_empty():
			break
	assert_eq(used.size(), 1)
	var amount: int = used[0][2]
	assert_true(amount >= 20 and amount <= 50)
	assert_eq(g.atm_uses, 1)
	assert_eq(int(s.finance_report()["today"]["atm_fees"]), 1)
	assert_true(s.cheapest_open_price() == 10, "hæveautomaten tæller ikke som billigste pris")
	# Maks 2 pr. besøg.
	var h := _guest(s, Vector2i(11, 21), 2)
	h.atm_uses = 2
	s._choose_goal(h)
	assert_eq(h.leave_reason, "no_money")
	# Utilfreds gæst (under min_happiness) bruger den ikke.
	var u := _guest(s, Vector2i(11, 21), 2)
	u.happiness = 30.0
	s._choose_goal(u)
	assert_true(u.leaving)


func test_atm_low_money_withdraws_before_broke() -> void:
	# T-149: saldo ≥ billigste pris, men under atm_low_money → hæv før pengene slipper op.
	var s := _sim()
	assert_eq(s.balance.atm_low_money, 10, "default")
	assert_eq(Balance.from_dicts({}, {"atm_low_money": 25}).atm_low_money, 25, "læses fra guests.json")
	s.balance.atm_low_money = 15
	s.cmd_place_attraction("r10", Vector2i(12, 20))
	var atm: Attraction = s.cmd_place_attraction("atm_t", Vector2i(8, 20))
	var g := _guest(s, Vector2i(11, 21), 12)
	s._choose_goal(g)
	assert_eq(g.leave_reason, "")
	assert_eq(g.target_attraction_id, atm.id, "lav saldo → hæveautomat")
	_step(s, 100)
	assert_eq(g.atm_uses, 1)
	assert_true(g.money >= 12 + 20 - 1)
	# Over tærsklen: ingen hævning; max_per_visit og min_happiness gælder stadig.
	var rich := _guest(s, Vector2i(11, 21), 40)
	s._choose_goal(rich)
	assert_true(rich.target_attraction_id != atm.id)
	var maxed := _guest(s, Vector2i(11, 21), 12)
	maxed.atm_uses = 2
	s._choose_goal(maxed)
	assert_true(maxed.target_attraction_id != atm.id)
	var sad := _guest(s, Vector2i(11, 21), 12)
	sad.happiness = 30.0
	s._choose_goal(sad)
	assert_true(sad.target_attraction_id != atm.id)


func test_atm_deterministic() -> void:
	var r: Array = []
	for k in 2:
		var s := _sim()
		s.cmd_place_attraction("r10", Vector2i(12, 20))
		s.cmd_place_attraction("atm_t", Vector2i(8, 20))
		var g := _guest(s, Vector2i(11, 21), 2)
		s._choose_goal(g)
		_step(s, 100)
		r.append(g.money)
	assert_eq(r[0], r[1])


func test_bin_fill_levels_signal_and_overflow() -> void:
	var s := _sim()
	var bid: int = s.cmd_place_decor("bin", Vector2i(10, 21))
	var d: Decor = s.get_decor(bid)
	var levels: Array = []
	s.bin_state_changed.connect(func(id: int, lv: int) -> void: levels.append([id, lv]))
	s.set_bin_fill(d, 1)
	assert_eq(levels.size(), 0)
	s.set_bin_fill(d, 2)
	s.set_bin_fill(d, 4)
	assert_eq(levels, [[bid, 1], [bid, 2]])
	var info: Dictionary = s.decor_info(bid)
	assert_eq(info["fill_ratio"], 1.0)
	assert_eq(info["capacity"], 4)
	assert_eq(info["level"], 2)
	# Fuld spand tæller ikke; affaldet lægges ved spanden.
	var changed: Array = []
	s.litter_changed.connect(func(c: Vector2i) -> void: changed.append(c))
	var g := _guest(s, Vector2i(12, 21))
	s._drop_litter(g)
	assert_eq(d.fill, 4)
	assert_eq(s.world.get_litter(Vector2i(10, 21)), 1)
	assert_eq(changed, [Vector2i(10, 21)])
	assert_eq(s.litter_at(Vector2i(10, 21)), [{"kind": "litter", "index": 0}] as Array[Dictionary])
	# Tømt spand fyldes igen.
	s.set_bin_fill(d, 0)
	assert_eq(levels[levels.size() - 1], [bid, 0])
	s.balance.litter_chance_with_bin = 0.0
	s._drop_litter(g)
	assert_eq(d.fill, 1)


func test_litter_at_kinds() -> void:
	var s := _sim()
	var c := Vector2i(15, 25)
	s.world.set_litter(c, 2)
	s.world.add_vomit(c, 2, 5)
	var l: Array[Dictionary] = s.litter_at(c)
	assert_eq(l.size(), 4)
	assert_eq(l[0], {"kind": "litter", "index": 0})
	assert_eq(l[3], {"kind": "vomit", "index": 3})


func test_bench_two_seats() -> void:
	var s := _sim()
	var bid: int = s.cmd_place_decor("bench", Vector2i(10, 21))
	var d: Decor = s.get_decor(bid)
	var sat: Array = []
	var stood: Array = []
	s.guest_sat.connect(func(gid: int, did: int, seat: int) -> void: sat.append([gid, did, seat]))
	s.guest_stood.connect(func(gid: int) -> void: stood.append(gid))
	var gs: Array[Guest] = []
	for i in 3:
		var g := _guest(s, Vector2i(12, 21))
		g.needs["energy"] = 75.0
		s._choose_goal(g)
		gs.append(g)
	assert_eq(gs[0].target_decor_id, bid)
	_step(s, 40)
	assert_eq(s.bench_occupants(d).size(), 2)
	assert_eq(s.bench_free_seats(d), 0)
	assert_eq(sat.size(), 2)
	assert_eq([sat[0][2], sat[1][2]], [0, 1])
	assert_eq(s.decor_info(bid)["occupants"].size(), 2)
	# Den tredje fandt ingen plads og sidder ikke.
	var third_resting: int = 0
	for g in gs:
		if g.resting_on == bid:
			assert_eq(g.state, Guest.State.RESTING)
		else:
			third_resting += 1
	assert_eq(third_resting, 1)
	_step(s, 60)
	assert_true(stood.size() >= 2, "rejser sig efter hvilet")
	# Fjernet bænk: siddende rejser sig.
	var g2 := _guest(s, Vector2i(10, 21))
	s._sit_down(g2, d)
	s.cmd_remove_decor(bid)
	assert_eq(g2.resting_on, -1)
	assert_true(stood.has(g2.id))


func test_light_levels_and_dark_penalty() -> void:
	var s := _sim()
	s.day_tick = 0
	s._update_light()
	var c := Vector2i(15, 25)
	s.day_tick = int(s.balance.day_ticks * 0.3)  # midt på dagen
	s._update_light()
	assert_eq(s.light_level(c), 1.0)
	# Nat: tid 0.0 = (day_start_time + t) => t = 0.75
	s.day_tick = int(s.balance.day_ticks * 0.75)
	s._update_light()
	assert_eq(s.phase(), ParkSim.PHASE_NIGHT)
	assert_eq(s.light_level(c), 0.0)
	var g := _guest(s, c)
	var h0: float = g.happiness
	s._apply_surroundings(g)
	assert_true(g.happiness < h0, "mørk sti koster glæde")
	s.cmd_place_decor("lamp", Vector2i(15, 26))
	s._update_light()
	assert_eq(s.light_level(c), 1.0)
	assert_eq(s.world.light_level(Vector2i(15, 22)), 0.0, "uden for lygtens radius")
	var h1: float = g.happiness
	s._apply_surroundings(g)
	assert_true(g.happiness > h1, "oplyst: ingen straf, og lygtens natte-aura")


func test_save_roundtrip_and_v3_migration() -> void:
	var s := _sim()
	var bid: int = s.cmd_place_decor("bench", Vector2i(10, 21))
	var g := _guest(s, Vector2i(10, 21))
	s._sit_down(g, s.get_decor(bid))
	g.atm_uses = 1
	var l := _guest(s, Vector2i(12, 21))
	l.happiness = 5.0
	s._choose_goal(l)
	var save: Dictionary = s.to_save()
	var defs: Array = [AttractionDef.from_dict(RIDE), AttractionDef.from_dict(ATM), s.get_decor_def("bench")]
	var s2 := ParkSim.from_save(save, s.balance, defs)
	var g2: Guest = s2.guests[g.id]
	assert_eq(g2.resting_on, bid)
	assert_eq(g2.atm_uses, 1)
	assert_eq(s2.bench_seat(g.id), 0)
	assert_true((s2.guests[l.id] as Guest).leaving)
	assert_eq((s2.guests[l.id] as Guest).leave_reason, "unhappy")
	assert_eq(s2.to_save()["park"], save["park"])
	# v3 uden nye felter.
	var old: Dictionary = save.duplicate(true)
	old["save_version"] = 3
	for gd: Dictionary in old["park"]["guests"]:
		for k: String in ["leaving", "leave_reason", "atm_uses", "resting_on"]:
			gd.erase(k)
	for dd: Dictionary in old["park"]["decor"]:
		dd.erase("fill")
	var m: Dictionary = SaveMigrations.migrate(old)
	for gd: Dictionary in m["park"]["guests"]:
		assert_true(gd.has("leaving") and gd.has("atm_uses") and gd.has("resting_on"))
		if int(gd["id"]) == g.id:
			assert_eq(gd["resting_on"], bid, "hvilende gæst beholder bænken")
		if int(gd["id"]) == l.id:
			assert_eq(gd["leaving"], true)
	assert_eq(m["park"]["decor"][0]["fill"], 0)
