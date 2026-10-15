extends TestCase
## T-053: fuld spildag med rigtige data; faser i rækkefølge; save om natten → samme ur.


func _park() -> ParkSim:
	var s := ParkSim.new(40, 40, 4242)
	var e: Vector2i = s.world.entrance
	for y in range(e.y - 1, 29, -1):
		s.cmd_place_path(Vector2i(e.x, y))
	return s


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func test_full_day_phase_order_and_night_save() -> void:
	var s := _park()
	var day_ticks: int = s.balance.day_ticks
	var phases: Array = []
	s.phase_changed.connect(func(p: StringName) -> void: phases.append(p))
	var saved: Dictionary = {}
	var saved_clock: String = ""
	for i in day_ticks:
		s.update(SimClock.TICK_DELTA)
		if saved.is_empty() and s.phase() == &"night":
			saved = SaveCodec.parse(SaveCodec.stringify(s.to_save()))
			saved_clock = s.clock_text()
	assert_eq(phases, [&"day", &"dusk", &"night", &"dawn"])
	assert_true(not saved.is_empty(), "nat nået i løbet af en spildag")
	var b := ParkSim.from_save(saved)
	assert_true(b != null)
	assert_eq(b.clock_text(), saved_clock)
	assert_eq(b.phase(), &"night")
	assert_true(b.is_night())
