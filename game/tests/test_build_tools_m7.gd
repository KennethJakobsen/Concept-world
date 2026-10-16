extends TestCase
## T-110: flyt/rotér/fortryd-værktøjer og salgsrefusion via BuildTool-API'et (uden input).


func _setup() -> Array:
	var view := ParkView.new()
	var s := ParkSim.new(30, 30, 3)
	s.economy.earn(100000, "test")
	view.setup(s)
	var bt := BuildTool.new()
	bt._view = view
	return [view, s, bt]


func _free(r: Array) -> void:
	(r[2] as Node).free()
	(r[0] as Node).free()


func test_move_and_rotate_attraction() -> void:
	var r: Array = _setup()
	var view: ParkView = r[0]
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	var a: Attraction = bt.place_building("burger_stand", Vector2i(5, 5))
	assert_true(a != null)
	assert_true(bt.set_tool(BuildTool.TOOL_MOVE))
	assert_true(bt.pick_up_at(a.origin))
	assert_eq(bt.move_kind, "attraction")
	bt.rotate_move()
	assert_eq(bt.move_rotation, 1)
	var target: Vector2i = Vector2i(15, 15)
	assert_true(bt.drop_move(bt.move_origin_for(target)))
	assert_eq(a.rotation, 1)
	assert_eq(bt.move_kind, "", "sluppet efter flyt")
	var n: Node3D = view._attractions[a.id]
	assert_true(absf(n.rotation.y + PI * 0.5) < 0.001, "visual drejet")
	var fp: Vector2i = a.footprint_size()
	assert_true(n.position.is_equal_approx(Vector3(a.origin.x + fp.x * 0.5, 0, a.origin.y + fp.y * 0.5)))
	# fortryd -> tilbage
	assert_true(bool(bt.undo().get("ok", false)))
	assert_eq(a.origin, Vector2i(5, 5))
	assert_eq(a.rotation, 0)
	assert_true(bool(bt.undo(true).get("ok", false)), "gentag")
	assert_eq(a.rotation, 1)
	_free(r)


func test_move_decor_and_cancel() -> void:
	var r: Array = _setup()
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	var did: int = bt.place_decor("tree_round", Vector2i(3, 3))
	assert_true(did >= 0)
	bt.set_tool(BuildTool.TOOL_MOVE)
	assert_true(bt.pick_up_at(Vector2i(3, 3)))
	assert_eq(bt.move_kind, "decor")
	bt.cancel_move()
	assert_eq(bt.move_id, -1)
	assert_true(bt.pick_up_at(Vector2i(3, 3)))
	assert_true(bt.drop_move(Vector2i(8, 8)))
	assert_eq((s.get_decor(did) as Decor).cell, Vector2i(8, 8))
	assert_true(not bt.pick_up_at(Vector2i(20, 20)), "intet at løfte")
	bt.set_tool(BuildTool.TOOL_SELECT)
	_free(r)


func test_sell_preview_matches_refund() -> void:
	var r: Array = _setup()
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	var a: Attraction = bt.place_building("burger_stand", Vector2i(5, 5))
	assert_eq(bt.sell_preview(a.origin), s.sell_refund(a.id))
	assert_eq(bt.sell_preview(a.origin), a.build_value(), "fuld refusion lige efter byg")
	assert_eq(bt.sell_preview(Vector2i(25, 25)), -1)
	var before: int = s.economy.money
	assert_true(bt.remove_building_at(a.origin))
	assert_eq(s.economy.money - before, a.build_value())
	assert_true(bool(bt.undo().get("ok", false)), "salg fortrydes")
	assert_true(s.get_attraction(a.id) != null or s.world.get_attraction_at(Vector2i(5, 5)) != null)
	_free(r)


func test_undo_empty_emits_failure() -> void:
	var r: Array = _setup()
	var bt: BuildTool = r[2]
	var got: Array = []
	bt.undo_performed.connect(func(redo: bool, ok: bool, _l: String) -> void: got.append([redo, ok]))
	bt.undo()
	assert_eq(got, [[false, false]])
	_free(r)


func test_disconnected_paths_marked() -> void:
	var r: Array = _setup()
	var s: ParkSim = r[1]
	var w: ParkWorld = s.world
	var start: Vector2i = w.entrance + Vector2i(0, -1)
	if not w.in_bounds(start) or not w.can_place_path(start):
		start = w.entrance + Vector2i(1, 0)
	assert_true(s.cmd_place_path(start))
	assert_true(s.cmd_place_path(Vector2i(2, 2)))
	var dis: Array[Vector2i] = BuildTool.disconnected_paths(w)
	assert_true(dis.has(Vector2i(2, 2)), "isoleret sti er afbrudt")
	assert_true(not dis.has(start), "sti ved porten er forbundet")
	_free(r)


func test_tool_id_and_lock() -> void:
	assert_eq(BuildTool.tool_content_id(BuildTool.TOOL_MOVE), "")
	assert_eq(BuildTool.KEY_TOOLS[KEY_M], "move")
