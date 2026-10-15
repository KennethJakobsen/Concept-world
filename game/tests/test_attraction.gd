extends TestCase

var _started: int = 0
var _finished: Array = []


func _def() -> AttractionDef:
	return AttractionDef.from_json("res://content/attractions/carousel.json")


func test_load_json() -> void:
	var d := _def()
	assert_eq(d.id, "carousel")
	assert_eq(d.footprint, Vector2i(3, 3))
	assert_true(d.capacity > 0 and d.ride_ticks > 0)


func test_placement_and_collision() -> void:
	var w := ParkWorld.new(20, 20)
	var d := _def()
	assert_true(not w.can_place_attraction(d, Vector2i(18, 5)))  # udenfor
	assert_true(not w.can_place_attraction(d, Vector2i(5, 17)))  # indgang udenfor
	var a := w.place_attraction(d, Vector2i(5, 5))
	assert_true(a != null)
	assert_eq(a.entrance_cell, Vector2i(6, 8))
	assert_eq(w.get_tile(a.entrance_cell), ParkWorld.Tile.PATH)
	assert_eq(w.get_tile(Vector2i(7, 7)), ParkWorld.Tile.ATTRACTION)
	assert_true(w.place_attraction(d, Vector2i(6, 6)) == null)  # overlap
	assert_true(not w.can_place_attraction(d, Vector2i(5, 8)))  # oven på indgangscelle
	assert_true(not w.remove_path(a.entrance_cell))
	w.place_path(Vector2i(12, 8))
	assert_true(w.place_attraction(d, Vector2i(11, 5)) != null)  # indgang på eksisterende sti


func _on_started() -> void:
	_started += 1


func _on_finished(ids: Array) -> void:
	_finished.append(ids)


func test_cycle_and_capacity() -> void:
	var d := AttractionDef.from_dict({"id": "t", "footprint": [1, 1], "capacity": 2, "ride_ticks": 3})
	var a := Attraction.new(1, d, Vector2i.ZERO)
	a.ride_started.connect(_on_started)
	a.ride_finished.connect(_on_finished)
	for i in 3:
		a.enqueue(i + 10)
	a.tick()
	assert_eq(_started, 1)
	assert_eq(a.riders, [10, 11])
	assert_eq(a.queue, [12])
	a.tick()
	a.tick()
	assert_true(_finished.is_empty())
	a.tick()
	assert_eq(_finished, [[10, 11]])
	a.tick()
	assert_eq(_started, 2)
	assert_eq(a.riders, [12])
