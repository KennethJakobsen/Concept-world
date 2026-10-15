extends TestCase
## Bridge-test uden SceneTree: ParkView spejler sim via signaler.


func test_guest_nodes_created_and_removed() -> void:
	var view := ParkView.new()
	var s := ParkSim.new(20, 20, 3)
	view.setup(s)
	s.spawn_interval_ticks = 10
	s.max_guests = 5
	for y in range(16, 19):
		assert_true(s.cmd_place_path(Vector2i(10, y)))
	assert_eq(view.path_node_count(), 3)
	assert_true(s.cmd_place_attraction("carousel", Vector2i(9, 12)) != null)
	var max_nodes: int = 0
	var spawned: Array = [0]
	var removed: Array = [0]
	s.guest_spawned.connect(func(_g: Guest) -> void: spawned[0] += 1)
	s.guest_removed.connect(func(_id: int) -> void: removed[0] += 1)
	for i in 4000:
		s.update(SimClock.TICK_DELTA)
		view.sync_guests()
		assert_eq(view.guest_node_count(), s.guests.size())
		max_nodes = maxi(max_nodes, view.guest_node_count())
	assert_true(max_nodes > 0, "gæst-noder oprettet")
	assert_true(removed[0] > 0, "gæster fjernet")
	var before: int = view.path_node_count()
	assert_true(s.cmd_remove_path(Vector2i(10, 18)))
	assert_eq(view.path_node_count(), before - 1)
	view.free()


func test_build_and_remove_all_buildings() -> void:
	var view := ParkView.new()
	var s := ParkSim.new(64, 64, 1)
	s.economy.earn(1000000, "test")
	view.setup(s)
	var ids: Array[String] = ["carousel", "ferris_wheel", "bumper_cars", "burger_stand",
		"drinks_stand", "ice_cream_stand", "toilet"]
	var placed: Array[int] = []
	var x: int = 2
	for id in ids:
		var a: Attraction = s.cmd_place_attraction(id, Vector2i(x, 10))
		assert_true(a != null, "kan bygge %s" % id)
		if a == null:
			continue
		assert_true(view.has_attraction_node(a.id), "node for %s" % id)
		placed.append(a.id)
		x += a.def.footprint.x + 1
	assert_eq(view.attraction_node_count(), ids.size())
	for aid in placed:
		assert_true(s.cmd_remove_attraction(aid))
		assert_true(not view.has_attraction_node(aid))
	assert_eq(view.attraction_node_count(), 0)
	view.free()


func test_thought_bubbles_capped() -> void:
	var view := ParkView.new()
	var s := ParkSim.new(20, 20, 3)
	view.setup(s)
	s.spawn_interval_ticks = 1
	s.max_guests = 30
	assert_true(s.cmd_place_path(Vector2i(10, 18)))
	for i in 200:
		s.update(SimClock.TICK_DELTA)
		view.sync_guests()
		for g: Guest in s.guests.values():
			g.thought = "Tanke %d" % i
		view.update_bubbles(SimClock.TICK_DELTA)
		assert_true(view.bubble_count() <= ParkView.MAX_BUBBLES)
	view.free()
