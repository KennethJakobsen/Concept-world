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


func _busy_sim() -> ParkSim:
	var s := ParkSim.new(30, 30, 5)
	s.economy.earn(1000000, "test")
	var e: Vector2i = s.world.entrance
	for i in range(1, 12):
		s.cmd_place_path(e + Vector2i(0, -i))
	s.cmd_place_attraction("burger_stand", e + Vector2i(1, -6) - Vector2i(0, 1))
	s.cmd_place_decor("bench", e + Vector2i(0, -3))
	s.cmd_place_decor("tree_round", e + Vector2i(3, -2))
	s.cmd_hire_staff("cleaner", e + Vector2i(0, -2))
	s.cmd_hire_staff("mechanic", e + Vector2i(0, -4))
	s.world.set_litter(e + Vector2i(0, -5), 2)
	return s


func test_rebuild_from_save_same_node_counts() -> void:
	var s := _busy_sim()
	var view := ParkView.new()
	view.setup(s)
	for i in 600:
		s.update(SimClock.TICK_DELTA)
	view.sync_guests()
	var before: Dictionary = view.node_counts()
	assert_true(int(before["staff"]) == 2 and int(before["decor"]) == 2, str(before))
	var loaded: ParkSim = ParkSim.from_save(JSON.parse_string(JSON.stringify(s.to_save())))
	assert_true(loaded != null)
	var view2 := ParkView.new()
	view2.setup(loaded)
	assert_eq(view2.node_counts(), before)
	# Genbrug af samme ParkView: setup på ny sim river gammel scene ned.
	view.setup(loaded)
	assert_eq(view.node_counts(), before)
	view.free()
	view2.free()


func test_place_remove_all_decor() -> void:
	var s := ParkSim.new(30, 30, 1)
	s.economy.earn(1000000, "test")
	var view := ParkView.new()
	view.setup(s)
	var ids: Array[String] = ["bench", "bin", "flowers", "lamp", "tree_blossom", "tree_pine", "tree_round"]
	var placed: Array[int] = []
	var x: int = 2
	for id in ids:
		var cell := Vector2i(x, 5)
		if s.get_decor_def(id).on_path:
			s.cmd_place_path(cell)
		var did: int = s.cmd_place_decor(id, cell)
		assert_true(did >= 0, "kan placere %s" % id)
		assert_eq(view.decor_at(cell), did)
		placed.append(did)
		x += 2
	assert_eq(view.decor_node_count(), ids.size())
	for did in placed:
		assert_true(s.cmd_remove_decor(did))
	assert_eq(view.decor_node_count(), 0)
	view.free()


func test_hire_move_fire_staff() -> void:
	var s := ParkSim.new(30, 30, 1)
	var view := ParkView.new()
	view.setup(s)
	var e: Vector2i = s.world.entrance
	s.cmd_place_path(e + Vector2i(0, -1))
	s.cmd_place_path(e + Vector2i(0, -2))
	var ids: Array[int] = []
	for t in ["mechanic", "cleaner", "entertainer"]:
		var sid: int = s.cmd_hire_staff(t, e + Vector2i(0, -1))
		assert_true(sid >= 0, t)
		ids.append(sid)
	assert_eq(view.staff_node_count(), 3)
	assert_true(s.cmd_move_staff(ids[0], e + Vector2i(0, -2)))
	view.sync_staff()
	assert_eq(view.staff_near(ParkView.cell_center(e + Vector2i(0, -2)), 0.5), ids[0])
	for sid in ids:
		assert_true(s.cmd_fire_staff(sid))
	assert_eq(view.staff_node_count(), 0)
	view.free()


func test_litter_pool_and_smoke() -> void:
	var s := ParkSim.new(30, 30, 1)
	s.economy.earn(1000000, "test")
	var view := ParkView.new()
	view.setup(s)
	var c := Vector2i(4, 4)
	s.cmd_place_path(c)
	s.world.set_litter(c, 2)
	assert_eq(view.litter_node_count(), 1)
	s.world.set_litter(c, 0)
	assert_eq(view.litter_node_count(), 0)
	s.cmd_place_path(c + Vector2i(1, 0))
	s.world.set_litter(c + Vector2i(1, 0), 1)
	assert_eq(view.litter_node_count(), 1)
	var a: Attraction = s.cmd_place_attraction("carousel", Vector2i(10, 10))
	assert_true(a != null)
	s.attraction_broken.emit(a)
	assert_eq(view.smoke_node_count(), 1)
	s.attraction_repaired.emit(a)
	assert_eq(view.smoke_node_count(), 0)
	view.free()
