extends TestCase

var _removed: Array = []


func _on_removed(gid: int) -> void:
	_removed.append(gid)


## 20x20, indgang (10,19). Sti op til karrusel med indgang (10,15).
func _make(seed_v: int) -> ParkSim:
	var s := ParkSim.new(20, 20, seed_v)
	for y in range(16, 19):
		s.cmd_place_path(Vector2i(10, y))
	assert_true(s.cmd_place_attraction("carousel", Vector2i(9, 12)) != null)
	s.spawn_interval_ticks = 10
	return s


func _run(s: ParkSim, seconds: float) -> void:
	for i in int(seconds * 20):
		s.update(SimClock.TICK_DELTA)


func test_guest_reaches_and_rides() -> void:
	var s := _make(1)
	s.max_guests = 1
	var rode: bool = false
	for i in 400:
		s.update(SimClock.TICK_DELTA)
		for g: Guest in s.guests.values():
			if g.state == Guest.State.RIDING:
				rode = true
				assert_eq(g.cell, Vector2i(10, 15))
	assert_true(rode)


func _snapshot(s: ParkSim) -> Array:
	var out: Array = []
	var ids: Array = s.guests.keys()
	ids.sort()
	for gid in ids:
		var g: Guest = s.guests[gid]
		out.append([gid, g.cell, g.next_cell, g.state, g.rides_left])
	return out


func test_deterministic() -> void:
	var a := _make(42)
	var b := _make(42)
	_run(a, 30.0)
	_run(b, 30.0)
	assert_eq(_snapshot(a), _snapshot(b))
	assert_true(not _snapshot(a).is_empty())


func test_guest_leaves() -> void:
	var s := _make(7)
	s.max_guests = 1
	s.rides_per_guest_max = 1
	s.guest_removed.connect(_on_removed)
	_run(s, 60.0)
	assert_true(_removed.has(1))


func test_no_spawn_without_path() -> void:
	var s := ParkSim.new(20, 20, 1)
	s.spawn_interval_ticks = 1
	_run(s, 5.0)
	assert_eq(s.guests.size(), 0)
	s.cmd_place_path(Vector2i(10, 18))
	_run(s, 1.0)
	assert_true(s.guests.size() > 0)
