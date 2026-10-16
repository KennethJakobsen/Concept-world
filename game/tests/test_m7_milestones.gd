extends TestCase
## T-105 (M7): milepæle, der låser forskningsgrene op – betingelser, belønninger, sandbox, backfill.


func _scen(extra: Dictionary = {}) -> ScenarioDef:
	var d: Dictionary = {
		"id": "ms_test", "name": "MS", "order": 99,
		"map": {"width": 40, "height": 40, "entrance": [20, 39]},
		"start": {"money": 50000, "reputation": 50, "paths": [[20, 39]], "attractions": [], "decor": [],
			"staff": [], "unlocked": [], "research_enabled": true, "entry_fee": 0},
		"objectives": [{"type": "money_min", "value": 99999999}], "deadline_days": 0, "lose": [],
	}
	d.merge(extra, true)
	return ScenarioDef.from_dict(d)


func _sim(extra: Dictionary = {}) -> ParkSim:
	var s := ParkSim.new_from_scenario(_scen(extra), 5)
	s.register_def(AttractionDef.from_dict({"id": "ms_ride", "kind": "ride", "footprint": [1, 1],
		"capacity": 2, "ride_ticks": 10, "ticket_price": 5, "excitement": 20}))
	s.research.unlocked["ms_ride"] = true
	for y in range(30, 39):
		s.cmd_place_path(Vector2i(20, y))
	return s


func _by_id(s: ParkSim, id: String) -> Dictionary:
	for m in s.milestones():
		if m["id"] == id:
			return m
	return {}


func test_defs_loaded_and_initial_locks() -> void:
	var s := _sim()
	assert_true(s.milestones_enabled())
	assert_eq(s.milestones().size(), 6)
	var m: Dictionary = _by_id(s, "first_thrill")
	assert_eq(m["achieved"], false)
	assert_eq(m["reward"]["unlock_topic"], "thrill_rides")
	assert_true(s.topic_available("gentle_rides"), "start-emne")
	assert_true(s.topic_available("shops"), "start-emne")
	for t: String in ["thrill_rides", "roller_coasters", "water_rides", "scenery", "sideshows"]:
		assert_true(not s.topic_available(t), t)
	assert_eq(s.topic_locked_by("thrill_rides"), "first_thrill")
	assert_true(not s.cmd_set_research_priority("thrill_rides"), "låst emne kan ikke prioriteres")
	assert_true(s.cmd_set_research_priority("shops"))
	# Forskningen vælger ikke items fra låste emner.
	var topic: String = str(s.research.def.item(s.research.current_item).get("topic", ""))
	assert_true(topic == "gentle_rides" or topic == "shops", topic)


func test_rides_open_unlocks_topic() -> void:
	var s := _sim()
	var got: Array = []
	s.milestone_achieved.connect(func(id: String) -> void: got.append(id))
	for x in range(14, 20):
		s.cmd_place_path(Vector2i(x, 31))
	for x: int in [15, 17]:
		assert_true(s.cmd_place_attraction("ms_ride", Vector2i(x, 30)) != null)
	assert_eq(s.milestone_measure("rides_open"), 2.0)
	assert_true(_by_id(s, "first_thrill")["progress"] > 0.6)
	for i in 21:
		s.update(SimClock.TICK_DELTA)
	assert_true(not got.has("first_thrill"))
	var a: Attraction = s.cmd_place_attraction("ms_ride", Vector2i(19, 30))
	s.cmd_set_open(a.id, false)
	assert_eq(s.milestone_measure("rides_open"), 2.0, "lukket tæller ikke")
	s.cmd_set_open(a.id, true)
	for i in 21:
		s.update(SimClock.TICK_DELTA)
	assert_true(got.has("first_thrill"))
	assert_true(s.topic_available("thrill_rides"))


func test_each_condition_measured() -> void:
	var s := _sim()
	# total_guests
	s._next_guest_id = 101
	assert_eq(s.milestone_measure("total_guests"), 100.0)
	# reputation
	s.reputation = 61.0
	assert_eq(s.milestone_measure("reputation"), 61.0)
	# total_revenue (historik + i dag; entré, billetter, gebyrer)
	s.economy.earn(15000, "tickets")
	s.economy.close_day(1)
	s.economy.earn(4000, "entry")
	s.economy.earn(1000, "atm_fees")
	s.economy.earn(999, "refund")
	assert_eq(s.milestone_measure("total_revenue"), 20000.0)
	# coaster_built kræver en færdig rutsjebane
	assert_eq(s.milestone_measure("coaster_built"), 0.0)
	# days_clean: sammenhængende rene dage
	s._milestones_day()
	s._milestones_day()
	assert_eq(s.milestone_measure("days_clean"), 2.0)
	s.world.set_litter(Vector2i(20, 35), 5)
	s.world.set_litter(Vector2i(20, 36), 5)
	s.world.set_litter(Vector2i(20, 37), 5)
	s._milestones_day()
	assert_eq(s.milestone_measure("days_clean"), 0.0)
	# Progress
	assert_eq(_by_id(s, "guests_100")["progress"], 1.0)


func test_rewards_points_money_and_signal() -> void:
	var s := _sim()
	var got: Array = []
	s.milestone_achieved.connect(func(id: String) -> void: got.append(id))
	var m0: int = s.economy.money
	s._next_guest_id = 101
	s.reputation = 61.0
	var p0: float = s.research.progress
	s._evaluate_milestones()
	assert_true(got.has("guests_100"))
	assert_true(got.has("stars_3"))
	assert_true(s.research.progress != p0 or s.research.unlocked.size() > 0, "50 forskningspoint")
	assert_true(s.topic_available("roller_coasters"))
	assert_true(s.cmd_set_research_priority("roller_coasters"))
	# Penge-belønning (first_coaster) bogføres som "rewards".
	var fc: MilestoneDef = s.milestones_state.get_def("first_coaster")
	s._achieve(fc)
	assert_eq(s.economy.money, m0 + 1000)
	assert_eq(int(s.finance_report()["today"]["rewards"]), 1000)
	assert_true(s.topic_available("water_rides"))
	# Opnås kun én gang.
	got.clear()
	s._evaluate_milestones()
	assert_true(not got.has("guests_100"))


func test_research_points_unlock_item() -> void:
	var s := _sim()
	s.research.current_item = "ice_cream_stand"
	s.research.progress = 40.0
	var unl: Array = []
	s.research_unlocked.connect(func(id: String) -> void: unl.append(id))
	s._next_guest_id = 101
	s._evaluate_milestones()
	assert_true(unl.has("ice_cream_stand"), "40 + 50 >= 80")


func test_sandbox_and_disabled() -> void:
	var sb := ParkSim.new(30, 30, 1)
	assert_true(not sb.milestones_enabled())
	assert_true(sb.topic_available("thrill_rides"))
	var got: Array = []
	sb.milestone_achieved.connect(func(id: String) -> void: got.append(id))
	sb.reputation = 99.0
	for i in 40:
		sb.update(SimClock.TICK_DELTA)
	assert_eq(got.size(), 0, "sandbox giver ingen belønning")
	var off := _sim({"milestones": false})
	assert_true(not off.milestones_enabled())
	assert_true(off.topic_available("sideshows"))
	assert_true(off.cmd_set_research_priority("sideshows"))
	var no_research := _sim({"start": {"money": 50000, "paths": [[20, 39]], "research_enabled": false}})
	assert_true(not no_research.milestones_enabled())


func test_save_roundtrip() -> void:
	var s := _sim()
	s._next_guest_id = 101
	s._evaluate_milestones()
	s._milestones_day()
	var save: Dictionary = s.to_save()
	assert_eq(save["park"]["milestones_backfill"], false, "nye saves")
	var s2 := ParkSim.from_save(save, null, [s.scenario.def, s.get_def("ms_ride")])
	assert_true(s2.milestones_state.is_achieved("guests_100"))
	assert_eq(s2.milestones_state.days_clean, 1)
	assert_eq(s2.to_save()["park"], save["park"])


func test_backfill_on_migrated_save() -> void:
	var s := _sim()
	s._next_guest_id = 150
	s.reputation = 70.0
	s.economy.earn(25000, "tickets")
	var save: Dictionary = s.to_save()
	save["save_version"] = 3
	var park: Dictionary = save["park"]
	park.erase("milestones")
	park.erase("milestones_backfill")
	park.erase("milestones_days_clean")
	var s2 := ParkSim.from_save(save, null, [s.scenario.def, s.get_def("ms_ride")])
	assert_true(s2.milestones_state.backfill)
	var toasts: Array = []
	var back: Array = []
	s2.milestone_achieved.connect(func(id: String) -> void: toasts.append(id))
	s2.milestones_backfilled.connect(func(ids: Array) -> void: back.append(ids))
	var money0: int = s2.economy.money
	var prog0: float = s2.research.progress
	s2.update(SimClock.TICK_DELTA)
	assert_eq(back.size(), 1)
	var ids: Array = back[0]
	assert_true(ids.has("guests_100") and ids.has("stars_3") and ids.has("sideshow_ready"), str(ids))
	assert_true(not ids.has("clean_park"), "days_clean kan ikke beregnes")
	assert_true(not ids.has("first_coaster"))
	assert_eq(toasts.size(), 0, "ingen toast")
	assert_eq(s2.economy.money, money0, "ingen penge")
	assert_eq(s2.research.progress, prog0, "ingen point")
	assert_true(s2.topic_available("roller_coasters") and s2.topic_available("sideshows"))
	assert_true(not s2.topic_available("water_rides"))
	assert_true(not s2.milestones_state.backfill)
	# Kun én gang.
	s2.update(SimClock.TICK_DELTA)
	assert_eq(back.size(), 1)
