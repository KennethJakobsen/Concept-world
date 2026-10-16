extends TestCase
## T-093: sporsystemer i scenen – stationer, tog-stil, plask og transportgæster.


func _sim() -> ParkSim:
	var s := ParkSim.new(40, 40, 5)
	s.economy.money = 1000000
	return s


func test_splash_signal_emits_fx() -> void:
	var view := ParkView.new()
	var s := _sim()
	view.setup(s)
	var kinds: Array[StringName] = []
	view.fx_event.connect(func(k: StringName, _p: Vector3) -> void: kinds.append(k))
	s.ride_splash.emit(1, Vector2i(5, 5))
	assert_true(kinds.has(&"splash"), "ride_splash → splash")
	view.free()


func test_monorail_station_and_end_station() -> void:
	var view := ParkView.new()
	var s := _sim()
	view.setup(s)
	var id: int = s.cmd_start_coaster("monorail", Vector2i(5, 5), 1)
	assert_true(id > 0)
	for i in 8:
		assert_true(s.cmd_place_track_piece(id, "monorail_straight"))
	assert_true(view.end_station_node(id) == null)
	assert_true(s.cmd_place_track_piece(id, "monorail_station_end"))
	var es: Node3D = view.end_station_node(id)
	assert_true(es is TrackStation, "endestation er en TrackStation")
	assert_eq((es as TrackStation).level, s.get_attraction(id).track.pieces[0].level)
	assert_true(s.cmd_remove_last_piece(id))
	assert_true(view.end_station_node(id) == null)
	view.free()


func test_guest_hidden_while_riding_transport() -> void:
	var view := ParkView.new()
	var s := _sim()
	view.setup(s)
	s.spawn_interval_ticks = 10
	s.max_guests = 1
	var e: Vector2i = s.world.entrance
	assert_true(s.cmd_place_path(Vector2i(e.x, e.y - 1)))
	for i in 40:
		s.update(SimClock.TICK_DELTA)
	assert_true(s.guests.size() > 0)
	var g: Guest = s.guests.values()[0]
	view.sync_guests()
	g.transport_id = 99
	g.state = Guest.State.RIDING
	view.sync_guests()
	assert_eq(s.guest_state_name(g), &"riding_transport")
	assert_eq(view.guest_near(view.cell_center(g.cell), 100.0), -1, "skjult under turen")
	view.free()


func _tool_setup() -> Array:
	var view := ParkView.new()
	var s := _sim()
	view.setup(s)
	var bt := BuildTool.new()
	bt._view = view
	var pal := CoasterPalette.new()
	pal.build()
	pal.tool = bt
	return [view, s, bt, pal]


## Kæden UI → BuildTool: palette (set_system/choose_piece) → set_coaster_piece → sim, inkl. endestation og systemskift.
func test_palette_to_build_tool_chain() -> void:
	var r: Array = _tool_setup()
	var view: ParkView = r[0]
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	var pal: CoasterPalette = r[3]
	# Tømmerrende: vælg stykke, skift så til svævebane → stykket fra det andet system ryddes.
	assert_true(bt.set_tool("coaster:log_flume"))
	pal.set_system(bt.coaster_system())
	pal.choose_piece("flume_straight")
	assert_eq(bt.coaster_piece, "flume_straight")
	assert_true(bt.set_tool("coaster:monorail"))
	assert_eq(bt.coaster_piece, "", "stykke fra andet system ryddes")
	pal.set_system(bt.coaster_system())
	assert_true(not pal.piece_ids().has("flume_straight"), "palette filtreret")
	var id: int = bt.place_coaster_station(Vector2i(5, 5), 1)
	assert_true(id > 0)
	pal.choose_piece("monorail_straight")
	for i in 8:
		assert_true(bt.place_coaster_piece())
	var end_id: String = CoasterPalette.end_station_id(&"monorail")
	assert_eq(end_id, bt.end_station_piece())
	pal.choose_piece(end_id)
	assert_eq(bt.coaster_piece, end_id)
	# Genvalg af samme værktøj (fx "Fortsæt byg") må ikke rydde endestationen.
	assert_true(bt.set_tool("coaster:monorail"))
	bt.coaster_id = id
	assert_eq(bt.coaster_piece, end_id)
	assert_true(bt.place_coaster_piece(), "endestation via palette")
	assert_true(s.get_attraction(id).track.is_complete())
	pal.finish()
	assert_true(not s.get_attraction(id).building, "banen åbnet")
	assert_true(view.end_station_node(id) is TrackStation)
	bt.free()
	pal.free()
	view.free()


## Svævebanens kabine kører pendul (start → ende, ende → start) i stedet for at hoppe.
func test_transport_cabin_pendulum() -> void:
	var r: Array = _tool_setup()
	var view: ParkView = r[0]
	var s: ParkSim = r[1]
	var id: int = s.cmd_start_coaster("monorail", Vector2i(5, 5), 1)
	for i in 8:
		assert_true(s.cmd_place_track_piece(id, "monorail_straight"))
	assert_true(s.cmd_place_track_piece(id, "monorail_station_end"))
	for c: Vector2i in [Vector2i(4, 5), Vector2i(4, 6), Vector2i(4, 4)]:
		s.cmd_place_path(c)
	var errs: Array[String] = s.cmd_finish_coaster(id)
	assert_eq(errs, [] as Array[String])
	var a: Attraction = s.get_attraction(id)
	assert_eq(view.transport_leg_t(id), 0.0)
	a.riders.append(1)
	a.ticks_left = a.ride_ticks() - a.load_ticks - 1  # turen kører
	view.update_coasters(0.0)
	assert_true(view.transport_leg_t(id) < 0.5, "første tur fra start")
	a.ticks_left = 0
	a.riders.clear()
	view.update_coasters(0.0)
	assert_eq(view.transport_leg_t(id), 1.0, "holder ved endestationen")
	a.riders.append(1)
	a.ticks_left = a.ride_ticks() - a.load_ticks - 1
	view.update_coasters(0.0)
	assert_true(view.transport_leg_t(id) > 0.5, "anden tur kører tilbage")
	a.ticks_left = 0
	a.riders.clear()
	view.update_coasters(0.0)
	assert_eq(view.transport_leg_t(id), 0.0, "tilbage ved start")
	r[2].free()
	r[3].free()
	view.free()
