extends TestCase
## T-130: lukket tømmerrende/minitog færdiggøres via palette → BuildTool → sim, også når
## værktøjet har mistet sin aktive bane (Esc, Vælg, nyt værktøjsvalg, indlæst save).

const FLUME: Array[String] = [
	"flume_lift_up", "flume_lift_up", "flume_straight", "flume_straight", "flume_straight",
	"flume_turn_right", "flume_turn_right",
	"flume_drop", "flume_straight", "flume_straight", "flume_straight", "flume_straight", "flume_straight",
	"flume_turn_right", "flume_turn_right",
]
const TRAIN: Array[String] = [
	"train_straight", "train_straight", "train_straight", "train_straight", "train_straight",
	"train_turn_right", "train_turn_right",
	"train_straight", "train_straight", "train_straight", "train_straight", "train_straight", "train_straight",
	"train_turn_right", "train_turn_right",
]


func _setup() -> Array:
	var view := ParkView.new()
	var s := ParkSim.new(40, 40, 5)
	s.economy.money = 1000000
	view.setup(s)
	var bt := BuildTool.new()
	bt._view = view
	var pal := CoasterPalette.new()
	pal.build()
	pal.tool = bt
	return [view, s, bt, pal]


func _build(bt: BuildTool, pal: CoasterPalette, def_id: String, seq: Array[String]) -> int:
	assert_true(bt.set_tool("coaster:" + def_id), "værktøj %s" % def_id)
	pal.set_system(bt.coaster_system())
	var id: int = bt.place_coaster_station(Vector2i(10, 10), 1)
	assert_true(id > 0, "station %s" % def_id)
	for p in seq:
		pal.choose_piece(p)
		assert_true(bt.place_coaster_piece(), "placér %s" % p)
	return id


func _finish_ok(s: ParkSim, bt: BuildTool, pal: CoasterPalette, id: int) -> void:
	var msgs: Array[String] = []
	pal.message.connect(func(t: String) -> void: msgs.append(t))
	var errs: Array = []
	bt.coaster_errors.connect(func(c: Array[String]) -> void: errs.append_array(c))
	pal.finish()
	assert_eq(errs.size(), 0, "ingen fejl: %s" % [errs])
	assert_true(not s.get_attraction(id).building, "færdig")
	assert_eq(msgs, ["Banen er åben!"] as Array[String])


func _run(def_id: String, seq: Array[String], lose: Callable) -> void:
	var r: Array = _setup()
	var view: ParkView = r[0]
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	var pal: CoasterPalette = r[3]
	var id: int = _build(bt, pal, def_id, seq)
	assert_true(s.get_attraction(id).track.is_closed(), "lukket")
	lose.call(bt, def_id)
	_finish_ok(s, bt, pal, id)
	pal.free()
	bt.free()
	view.free()


func test_flume_direct() -> void:
	_run("log_flume", FLUME, func(_bt: BuildTool, _d: String) -> void: pass)


func test_train_direct() -> void:
	_run("mini_train", TRAIN, func(_bt: BuildTool, _d: String) -> void: pass)


## Reproduktion: Esc/Vælg og derefter genvalg af byggeknappen nulstillede coaster_id → "no_station".
func test_flume_after_reselect_tool() -> void:
	_run("log_flume", FLUME, func(bt: BuildTool, d: String) -> void:
		bt.set_tool(BuildTool.TOOL_SELECT)
		bt.set_tool("coaster:" + d)
		assert_eq(bt.coaster_id, -1))


func test_train_after_escape() -> void:
	_run("mini_train", TRAIN, func(bt: BuildTool, _d: String) -> void:
		bt.coaster_id = -1)


func test_ambiguous_and_none() -> void:
	var r: Array = _setup()
	var view: ParkView = r[0]
	var bt: BuildTool = r[2]
	var pal: CoasterPalette = r[3]
	bt.set_tool("coaster:log_flume")
	assert_eq(bt.finish_coaster(), ["no_station"] as Array[String])
	var a: int = bt.place_coaster_station(Vector2i(10, 10), 1)
	bt.coaster_id = -1
	var b: int = bt.place_coaster_station(Vector2i(20, 20), 1)
	assert_true(a > 0 and b > 0)
	bt.coaster_id = -1
	assert_eq(bt.finish_coaster(), ["no_active_track"] as Array[String])
	assert_true(M6Texts.track_error("no_active_track") != "no_active_track")
	# Valgt i info-panelet → palette sender resume_id → banen genoptages (fejl = ikke lukket).
	pal.resume_id = a
	bt.coaster_id = -1
	pal.finish()
	assert_eq(bt.coaster_id, a)
	pal.free()
	bt.free()
	view.free()
