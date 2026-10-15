extends TestCase

var _events: Array = []


func _on_changed(cell: Vector2i, tile: int) -> void:
	_events.append([cell, tile])


func test_bounds_and_entrance() -> void:
	var w := ParkWorld.new(10, 8)
	assert_true(w.in_bounds(Vector2i(0, 0)))
	assert_true(w.in_bounds(Vector2i(9, 7)))
	assert_true(not w.in_bounds(Vector2i(10, 0)))
	assert_true(not w.in_bounds(Vector2i(0, -1)))
	assert_eq(w.entrance, Vector2i(5, 7))
	assert_eq(w.get_tile(w.entrance), ParkWorld.Tile.ENTRANCE)
	assert_eq(w.get_tile(Vector2i(1, 1)), ParkWorld.Tile.GRASS)
	assert_true(not w.place_path(Vector2i(-1, 0)))


func test_place_remove_path_and_signal() -> void:
	var w := ParkWorld.new(10, 8)
	w.tile_changed.connect(_on_changed)
	assert_true(w.place_path(Vector2i(2, 2)))
	assert_eq(w.get_tile(Vector2i(2, 2)), ParkWorld.Tile.PATH)
	assert_true(not w.place_path(Vector2i(2, 2)))
	assert_true(w.remove_path(Vector2i(2, 2)))
	assert_true(not w.remove_path(Vector2i(2, 2)))
	assert_eq(_events, [[Vector2i(2, 2), ParkWorld.Tile.PATH], [Vector2i(2, 2), ParkWorld.Tile.GRASS]])


func test_cannot_place_on_entrance_or_attraction() -> void:
	var w := ParkWorld.new(10, 8)
	assert_true(not w.can_place_path(w.entrance))
	assert_true(not w.remove_path(w.entrance))
	var def := AttractionDef.from_dict({"id": "x", "footprint": [2, 2], "capacity": 1, "ride_ticks": 1})
	assert_true(w.place_attraction(def, Vector2i(1, 1)) != null)
	assert_true(not w.place_path(Vector2i(1, 1)))
	assert_eq(w.get_tile(Vector2i(2, 2)), ParkWorld.Tile.ATTRACTION)
