extends TestCase
## T-072: M5-verifikation – scenarie til sejr med bot, nederlag, forskning → byg, lukket rutsjebane med
## gæster og deterministisk save/load midt i det hele.

const OVAL: Array[String] = [
	"track_lift_up", "track_lift_up", "track_lift_up", "track_straight", "track_straight",
	"track_turn_right", "track_turn_right",
	"track_down", "track_down", "track_down", "track_straight", "track_straight", "track_straight",
	"track_turn_right", "track_turn_right",
]


func _def(extra: Dictionary = {}) -> ScenarioDef:
	var d: Dictionary = {
		"id": "qa_m5", "name": "QA", "order": 99,
		"map": {"width": 64, "height": 64, "entrance": [32, 63]},
		"start": {"money": 30000, "reputation": 50, "paths": [[32, 63]], "attractions": [], "decor": [],
			"staff": [], "unlocked": [], "research_enabled": true, "entry_fee": 8},
		"objectives": [{"type": "rides_count_min", "value": 2}, {"type": "coaster_excitement_min", "value": 4.0}],
		"deadline_days": 0, "lose": [],
	}
	d.merge(extra, true)
	return ScenarioDef.from_dict(d)


## Bot-layout: sti op til en gade (y=50) og rutsjebane-station syd for gaden.
func _layout(s: ParkSim) -> void:
	for y in range(62, 49, -1):
		s.cmd_place_path(Vector2i(32, y))
	for x in range(14, 50):
		s.cmd_place_path(Vector2i(x, 50))
	s.cmd_hire_staff("mechanic", Vector2i(32, 52))


func _build_oval(s: ParkSim) -> int:
	var id: int = s.cmd_start_coaster("wooden_coaster", Vector2i(16, 51), 1)
	assert_true(id > 0, "start coaster")
	for p in OVAL:
		assert_true(s.cmd_place_track_piece(id, p), "place %s" % p)
	return id


func _days(s: ParkSim, n: int) -> void:
	var day_s: float = s.balance.day_ticks * SimClock.TICK_DELTA
	for i in n:
		var t: float = 0.0
		while t < day_s - 1e-3:
			s.update(5.0)
			t += 5.0


func _snap(s: ParkSim) -> String:
	return SaveCodec.stringify(s.to_save()["park"])


func test_research_unlocks_then_build() -> void:
	var s := ParkSim.new_from_scenario(_def(), 3)
	_layout(s)
	var item: String = "track_turn_right"
	assert_true(not s.is_unlocked(item))
	var a: int = s.cmd_start_coaster("wooden_coaster", Vector2i(40, 51), 1)
	assert_true(a > 0)
	assert_true(not s.can_place_track_piece(a, item), "låst stykke afvist")
	assert_true(s.cmd_set_research_funding(3))
	assert_true(s.cmd_set_research_priority("roller_coasters"))
	var got: Array[String] = []
	s.research_unlocked.connect(func(id: String) -> void: got.append(id))
	for i in 20:
		s._end_day()
		if s.is_unlocked(item):
			break
	assert_true(s.is_unlocked(item), "forsket frem")
	assert_true(got.has(item))
	assert_true(s.cmd_place_track_piece(a, item), "kan bygges efter forskning")


func test_scenario_won_by_bot_with_coaster_and_save_midway() -> void:
	var s := ParkSim.new_from_scenario(_def(), 7)
	for p in OVAL:
		s.research.unlocked[p] = true
	_layout(s)
	var finished: Array = []
	s.scenario_finished.connect(func(won: bool, reason: String) -> void: finished.append([won, reason]))
	var id: int = _build_oval(s)
	assert_true(s.cmd_finish_coaster(id).is_empty(), "lukket bane")
	var c: Attraction = s.get_attraction(id)
	assert_true(c.is_open)
	assert_true(c.track.is_closed())
	assert_true(float(c.ratings.get("excitement", 0.0)) >= 4.0)
	s.cmd_place_attraction("carousel", Vector2i(20, 47))
	_days(s, 1)
	# save/load midt i: scenarie kører, tog i bevægelse, forskning i gang
	s.cmd_set_research_funding(1)
	s.update(3.0)
	var l: ParkSim = ParkSim.from_save(SaveCodec.parse(SaveCodec.stringify(s.to_save())))
	assert_eq(_snap(l), _snap(s), "round-trip")
	for i in 400:
		s.update(SimClock.TICK_DELTA)
		l.update(SimClock.TICK_DELTA)
	assert_eq(_snap(l), _snap(s), "determinisme efter load")
	# bot: byg en bod mere, kør til sejr
	s.cmd_place_attraction("burger_stand", Vector2i(26, 49))
	for d in 10:
		_days(s, 1)
		if not s.scenario.is_running():
			break
	assert_eq(s.scenario.state, &"won")
	assert_true(c.total_visitors > 0, "rutsjebanen har haft gæster")
	assert_eq(finished.size(), 1)
	assert_true(finished.size() == 1 and finished[0][0])


func test_lose_condition() -> void:
	var s := ParkSim.new_from_scenario(_def({"start": {"money": -100, "reputation": 50, "paths": [[32, 63]],
		"attractions": [], "decor": [], "staff": [], "unlocked": [], "research_enabled": false, "entry_fee": 0},
		"lose": [{"type": "money_below", "value": 0, "days": 2}]}), 1)
	var res: Array = []
	s.scenario_finished.connect(func(won: bool, reason: String) -> void: res.append([won, reason]))
	s._end_day()
	assert_eq(s.scenario.state, &"running")
	s._end_day()
	assert_eq(s.scenario.state, &"lost")
	assert_eq(res.size(), 1)
	assert_true(not res[0][0])


func test_v1_fixture_loads_in_v2() -> void:
	var d: Dictionary = SaveCodec.parse(FileAccess.get_file_as_string("res://tests/fixtures/save_v1.json"))
	var l: ParkSim = ParkSim.from_save(d)
	assert_true(l != null)
	assert_true(not l.research.enabled)
	assert_true(l.is_unlocked("go_karts"))
	assert_true(l.scenario == null)


func test_simulation_layer_has_no_nodes() -> void:
	var bad: Array[String] = []
	var re := RegEx.create_from_string("\\b(Node|Node2D|Node3D|SceneTree|Control|get_tree|MeshInstance3D|Camera3D)\\b")
	var stack: Array[String] = ["res://simulation"]
	while not stack.is_empty():
		var dir: String = stack.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			stack.append(dir + "/" + sub)
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				var src: String = FileAccess.get_file_as_string(dir + "/" + f)
				for line in src.split("\n"):
					if not line.strip_edges().begins_with("#") and re.search(line) != null:
						bad.append("%s: %s" % [f, line.strip_edges()])
	assert_eq(bad, [] as Array[String])
