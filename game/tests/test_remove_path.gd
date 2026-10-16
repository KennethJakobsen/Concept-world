extends TestCase
## T-132: Stier kan fjernes via BuildTool (fjern-værktøj + sti-værktøj), indgange giver besked.


func _setup() -> Array:
	var view := ParkView.new()
	var s := ParkSim.new(40, 40, 5)
	s.economy.earn(100000, "test")
	view.setup(s)
	var bt := BuildTool.new()
	bt._view = view
	return [view, s, bt]


func test_remove_tool_removes_path() -> void:
	var r: Array = _setup()
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	var c := Vector2i(12, 12)
	assert_true(s.cmd_place_path(c))
	var before: int = s.economy.money
	assert_true(bt.remove_building_at(c), "fjern-værktøjet fjerner sti")
	assert_eq(s.world.get_tile(c), ParkWorld.Tile.GRASS)
	assert_eq(s.economy.money, before + s.balance.path_refund)
	assert_true(not bt.remove_path_at(c), "græs kan ikke fjernes")


func test_entrance_gives_message() -> void:
	var r: Array = _setup()
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	var a: Attraction = s.cmd_place_attraction("carousel", Vector2i(10, 10))
	assert_true(a != null)
	var ent := Vector2i(10 + a.def.footprint.x / 2, 10 + a.def.footprint.y)
	assert_true(s.cmd_place_path(ent) or s.world.get_tile(ent) == ParkWorld.Tile.PATH)
	var msgs: Array[String] = []
	bt.remove_blocked.connect(func(m: String) -> void: msgs.append(m))
	assert_true(not bt.remove_path_at(ent))
	assert_eq(msgs.size(), 1)
	assert_eq(s.world.get_tile(ent), ParkWorld.Tile.PATH)
