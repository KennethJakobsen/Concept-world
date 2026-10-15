extends TestCase
## T-070: Rutsjebane-byggeværktøj og bridge headless (BuildTool-API'et uden input).

const OVAL: Array[String] = [
	"track_lift_up", "track_lift_up", "track_lift_up", "track_straight", "track_straight",
	"track_turn_right", "track_turn_right",
	"track_down", "track_down", "track_down", "track_straight", "track_straight", "track_straight",
	"track_turn_right", "track_turn_right",
]


func _setup() -> Array:
	var view := ParkView.new()
	var s := ParkSim.new(40, 40, 5)
	s.economy.earn(1000000, "test")
	view.setup(s)
	var bt := BuildTool.new()
	bt._view = view
	return [view, s, bt]


func test_build_closed_oval_via_build_tool() -> void:
	var r: Array = _setup()
	var view: ParkView = r[0]
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	assert_true(bt.set_tool("coaster:wooden_coaster"))
	assert_eq(bt.finish_coaster(), ["no_station"] as Array[String])
	var id: int = bt.place_coaster_station(Vector2i(10, 20), 1)
	assert_true(id >= 0, "station placeret")
	assert_true(bt.is_building_coaster())
	assert_eq(view.coaster_count(), 1)
	assert_true(view.coaster_train(id) == null, "intet tog under bygning")
	for p in OVAL:
		bt.set_coaster_piece(p)
		assert_true(bt.place_coaster_piece(), "placér %s" % p)
	# Backspace + genplacering
	var n: int = s.get_attraction(id).track.pieces.size()
	assert_true(bt.remove_last_coaster_piece())
	assert_eq(s.get_attraction(id).track.pieces.size(), n - 1)
	assert_true(bt.place_coaster_piece())
	var errs: Array = [null]
	bt.coaster_errors.connect(func(c: Array[String]) -> void: errs[0] = c)
	assert_true(bt.finish_coaster().is_empty())
	assert_true(errs[0] == null, "ingen fejl-signal ved succes")
	var a: Attraction = s.get_attraction(id)
	assert_true(a.is_open and not a.building)
	assert_eq(bt.tool, BuildTool.TOOL_SELECT)
	assert_true(view.coaster_train(id) != null, "tog oprettet")
	assert_true(view.coaster_mesh(id).triangle_count() > 0)
	view.update_coasters(0.1)
	bt.free()
	view.free()


func test_unfinished_errors_and_resume() -> void:
	var r: Array = _setup()
	var view: ParkView = r[0]
	var bt: BuildTool = r[2]
	bt.set_tool("coaster:wooden_coaster")
	var id: int = bt.place_coaster_station(Vector2i(10, 20), 1)
	bt.set_coaster_piece("track_straight")
	assert_true(bt.place_coaster_piece())
	var errs: Array = [[]]
	bt.coaster_errors.connect(func(c: Array[String]) -> void: errs[0] = c)
	bt.finish_coaster()
	assert_true((errs[0] as Array).has("not_closed"))
	bt.handle_escape()
	assert_eq(bt.coaster_id, -1)
	assert_eq(bt.tool, BuildTool.TOOL_SELECT)
	assert_true(view.sim.get_attraction(id).building, "banen står ufærdig")
	assert_true(bt.resume_coaster(id))
	assert_eq(bt.coaster_id, id)
	assert_true(bt.place_coaster_piece())
	bt.free()
	view.free()


func test_locked_ids_refused() -> void:
	var r: Array = _setup()
	var view: ParkView = r[0]
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	s.research.setup(true, [] as Array[String])
	if s.is_unlocked("wooden_coaster"):
		bt.free()
		view.free()
		return  # data låser ikke rutsjebanen op fra start; intet at teste
	assert_true(not bt.set_tool("coaster:wooden_coaster"))
	assert_eq(bt.tool, BuildTool.TOOL_SELECT)
	bt.free()
	view.free()


func test_coaster_restored_after_load() -> void:
	var r: Array = _setup()
	var view: ParkView = r[0]
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	bt.set_tool("coaster:wooden_coaster")
	var id: int = bt.place_coaster_station(Vector2i(10, 20), 1)
	for p in OVAL:
		bt.set_coaster_piece(p)
		bt.place_coaster_piece()
	assert_true(bt.finish_coaster().is_empty())
	var s2: ParkSim = ParkSim.from_save(s.to_save())
	view.setup(s2)
	assert_eq(view.coaster_count(), 1)
	assert_true(view.coaster_train(id) != null)
	s2.cmd_remove_attraction(id)
	assert_eq(view.coaster_count(), 0)
	bt.free()
	view.free()
