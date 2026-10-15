extends TestCase


func _line(w: ParkWorld, a: Vector2i, b: Vector2i) -> void:
	var c := a
	w.place_path(c)
	while c != b:
		c += Vector2i(signi(b.x - c.x), 0) if c.x != b.x else Vector2i(0, signi(b.y - c.y))
		w.place_path(c)


func test_straight() -> void:
	var w := ParkWorld.new(10, 10)
	_line(w, Vector2i(1, 1), Vector2i(5, 1))
	var p := PathFinder.new(w).find_path(Vector2i(1, 1), Vector2i(5, 1))
	assert_eq(p.size(), 5)
	assert_eq(p[0], Vector2i(1, 1))
	assert_eq(p[4], Vector2i(5, 1))


func test_detour() -> void:
	var w := ParkWorld.new(10, 10)
	_line(w, Vector2i(1, 1), Vector2i(1, 5))
	_line(w, Vector2i(1, 5), Vector2i(5, 5))
	_line(w, Vector2i(5, 5), Vector2i(5, 1))
	var p := PathFinder.new(w).find_path(Vector2i(1, 1), Vector2i(5, 1))
	assert_eq(p.size(), 13)
	for i in range(1, p.size()):
		assert_eq(absi(p[i].x - p[i - 1].x) + absi(p[i].y - p[i - 1].y), 1)


func test_no_path() -> void:
	var w := ParkWorld.new(10, 10)
	w.place_path(Vector2i(1, 1))
	w.place_path(Vector2i(3, 1))
	assert_true(PathFinder.new(w).find_path(Vector2i(1, 1), Vector2i(3, 1)).is_empty())
	assert_true(PathFinder.new(w).find_path(Vector2i(0, 0), Vector2i(3, 1)).is_empty())


func test_invalidated_after_removal() -> void:
	var w := ParkWorld.new(10, 10)
	_line(w, Vector2i(1, 1), Vector2i(5, 1))
	var pf := PathFinder.new(w)
	assert_eq(pf.find_path(Vector2i(1, 1), Vector2i(5, 1)).size(), 5)
	w.remove_path(Vector2i(3, 1))
	assert_true(pf.find_path(Vector2i(1, 1), Vector2i(5, 1)).is_empty())
	w.place_path(Vector2i(3, 1))
	assert_eq(pf.find_path(Vector2i(1, 1), Vector2i(5, 1)).size(), 5)
