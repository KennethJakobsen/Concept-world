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
