extends TestCase
## T-106 (M7, ADR-005 §4–5): flyt (også sporbaner), sælg-refusion og fortryd.

const OVAL: Array[String] = [
	"track_lift_up", "track_lift_up", "track_lift_up", "track_straight", "track_straight",
	"track_turn_right", "track_turn_right",
	"track_down", "track_down", "track_down", "track_straight", "track_straight", "track_straight",
	"track_turn_right", "track_turn_right", "track_straight",
]


func _step(s: ParkSim, n: int) -> void:
	for i in n:
		s.update(SimClock.TICK_DELTA)


func _sim() -> ParkSim:
	var s := ParkSim.new(60, 60, 3)
	s.economy.money = 1000000
	return s


func _oval(s: ParkSim, station: Vector2i) -> int:
	var id: int = s.cmd_start_coaster("wooden_coaster", station, 1)
	assert_true(id >= 0, "station")
	for p in OVAL:
		if s.get_attraction(id).track.is_closed():
			break
		assert_true(s.cmd_place_track_piece(id, p), "%s %s" % [p, s.preview_track_piece(id, p)])
	assert_eq(s.cmd_finish_coaster(id), [] as Array[String])
	return id


func test_path_and_queue_path_undo_redo_exact_money() -> void:
	var s := _sim()
	var m0: int = s.economy.money
	assert_true(not s.can_undo())
	assert_true(s.cmd_place_path(Vector2i(5, 5)))
	assert_true(s.cmd_place_queue_path(Vector2i(6, 5)))
	assert_true(s.can_undo())
	assert_eq(s.undo_label(), "Byg køsti")
	assert_true(s.cmd_undo()["ok"])
	assert_eq(s.world.get_tile(Vector2i(6, 5)), ParkWorld.Tile.GRASS)
	assert_true(s.cmd_undo()["ok"])
	assert_eq(s.world.get_tile(Vector2i(5, 5)), ParkWorld.Tile.GRASS)
	assert_eq(s.economy.money, m0, "præcis tilbage")
	assert_true(s.can_redo())
	assert_eq(s.cmd_redo()["kind"], "path")
	assert_eq(s.world.get_tile(Vector2i(5, 5)), ParkWorld.Tile.PATH)
	assert_true(s.cmd_remove_path(Vector2i(5, 5)))
	assert_true(not s.can_redo(), "ny handling rydder redo")
	var m1: int = s.economy.money
	assert_true(s.cmd_undo()["ok"])
	assert_eq(s.world.get_tile(Vector2i(5, 5)), ParkWorld.Tile.PATH)
	assert_eq(s.economy.money, m1 - s.balance.path_refund)
	assert_eq(s.cmd_undo()["reason"], "", "fjern sti igen")
	assert_eq(s.economy.money, m0)


func test_build_sell_refund_and_undo() -> void:
	var s := _sim()
	var m0: int = s.economy.money
	var a: Attraction = s.cmd_place_attraction("carousel", Vector2i(10, 10))
	var cost: int = a.def.build_cost
	assert_eq(s.sell_refund(a.id), cost, "100 % lige efter opførelse")
	_step(s, s.balance.sell_full_refund_ticks + 1)
	assert_eq(s.sell_refund(a.id), cost / 2, "50 % efter vinduet")
	var b: Attraction = s.cmd_place_attraction("carousel", Vector2i(20, 10))
	b.total_visitors = 1
	assert_eq(s.sell_refund(b.id), cost / 2, "50 % med kunder")
	b.total_visitors = 0
	var m1: int = s.economy.money
	assert_true(s.cmd_remove_attraction(b.id))
	assert_eq(s.economy.money, m1 + cost)
	assert_true(s.cmd_undo()["ok"], "fortryd salg")
	assert_eq(s.get_attraction(b.id), b, "samme instans tilbage")
	assert_eq(s.economy.money, m1)
	assert_true(s.cmd_undo()["ok"], "fortryd byg")
	assert_true(s.get_attraction(b.id) == null)
	assert_eq(s.world.get_tile(Vector2i(20, 10)), ParkWorld.Tile.GRASS)
	assert_eq(s.economy.money, m0 - cost)
	assert_true(s.cmd_redo()["ok"])
	assert_eq(s.get_attraction(b.id), b)


func test_invalid_inverse_keeps_entry() -> void:
	var s := _sim()
	var a: Attraction = s.cmd_place_attraction("carousel", Vector2i(10, 10))
	assert_true(s.cmd_remove_attraction(a.id))
	s.economy.money = 0
	var r: Dictionary = s.cmd_undo()
	assert_true(not r["ok"])
	assert_eq(r["reason"], "no_money")
	assert_true(s.can_undo(), "posten bliver liggende")
	s.economy.money = 1000000
	assert_true(s.cmd_place_path(Vector2i(10, 10)))
	assert_true(s.cmd_undo()["ok"])  # fjerner stien
	assert_true(s.cmd_place_attraction("carousel", Vector2i(10, 10)) != null)
	assert_eq(s.cmd_undo()["kind"], "build")
	# Cellen blokeres → fortryd salg fejler med occupied og bliver liggende
	assert_true(s.cmd_place_path(Vector2i(30, 30)))
	assert_true(s.cmd_undo()["ok"])
	assert_true(s.world.place_path(Vector2i(10, 10)))  # uden om stakken
	var r2: Dictionary = s.cmd_undo()
	assert_eq(r2["kind"], "sell")
	assert_eq(r2["reason"], "occupied")
	s.world.remove_path(Vector2i(10, 10))
	assert_true(s.cmd_undo()["ok"], "nu lykkes det")


func test_stack_limit() -> void:
	var s := _sim()
	for i in 25:
		assert_true(s.cmd_place_path(Vector2i(i, 3)))
	assert_eq(s.undo_stack.undo_size(), 20)
	var n: int = 0
	while s.cmd_undo()["ok"]:
		n += 1
	assert_eq(n, 20)
	assert_eq(s.world.get_tile(Vector2i(4, 3)), ParkWorld.Tile.PATH, "de ældste 5 kan ikke fortrydes")


func test_move_flat_with_rotation_and_undo() -> void:
	var s := _sim()
	var a: Attraction = s.cmd_place_attraction("carousel", Vector2i(10, 10))
	var fp: Vector2i = a.def.footprint
	var old_ent: Vector2i = a.entrance_cell
	var pv: Dictionary = s.preview_move(a.id, Vector2i(30, 30), 1)
	assert_true(pv["ok"], str(pv))
	assert_eq(pv["entrance"], Vector2i(29, 30 + Attraction.rotated_size(a.def, 1).y / 2))
	var sigs: Array = []
	s.attraction_moved.connect(func(id: int) -> void: sigs.append(id))
	var m0: int = s.economy.money
	assert_true(s.cmd_move_attraction(a.id, Vector2i(30, 30), 1)["ok"])
	assert_eq(s.economy.money, m0, "flyt er gratis")
	assert_eq(sigs, [a.id])
	assert_eq(a.rotation, 1)
	assert_eq(s.world.get_tile(Vector2i(10, 10)), ParkWorld.Tile.GRASS)
	assert_eq(s.world.get_tile(Vector2i(30, 30)), ParkWorld.Tile.ATTRACTION)
	assert_eq(s.world.get_tile(a.entrance_cell), ParkWorld.Tile.PATH)
	assert_eq(s.world.get_tile(old_ent), ParkWorld.Tile.PATH, "gammel indgang bliver sti")
	# Overlap med eget fodaftryk er tilladt
	assert_true(s.preview_move(a.id, Vector2i(31, 30), 1)["ok"])
	# Ugyldigt: oven på en anden bygning
	s.cmd_place_attraction("carousel", Vector2i(40, 10))
	var bad: Dictionary = s.cmd_move_attraction(a.id, Vector2i(40, 10), 0)
	assert_true(not bad["ok"])
	assert_eq(bad["reason"], "occupied")
	s.cmd_undo()  # byg nr. 2
	assert_eq(s.cmd_undo()["kind"], "move")
	assert_eq(a.origin, Vector2i(10, 10))
	assert_eq(a.rotation, 0)
	assert_eq(a.entrance_cell, Vector2i(10 + fp.x / 2, 10 + fp.y))


func test_move_ejects_queue_with_refund() -> void:
	var s := _sim()
	var a: Attraction = s.cmd_place_attraction("carousel", Vector2i(10, 10))
	var g := Guest.new(99, a.entrance_cell)
	g.money = 10
	g.paid = 5
	g.state = Guest.State.QUEUING
	s.guests[99] = g
	a.enqueue(99)
	assert_true(s.cmd_move_attraction(a.id, Vector2i(30, 30), 0)["ok"])
	assert_true(a.queue.is_empty())
	assert_eq(g.money, 15)


func test_move_coaster_rigid_with_rotation_keeps_ratings() -> void:
	var s := _sim()
	var id: int = _oval(s, Vector2i(10, 20))
	var a: Attraction = s.get_attraction(id)
	var ratings: Dictionary = a.ratings.duplicate()
	var n: int = a.track.pieces.size()
	var pv: Dictionary = s.preview_move(id, Vector2i(30, 40), 1)
	assert_true(pv["ok"], str(pv))
	assert_true(s.cmd_move_attraction(id, Vector2i(30, 40), 1)["ok"])
	assert_eq(a.track.pieces.size(), n)
	assert_eq(a.track.pieces[0].cell, Vector2i(30, 40))
	assert_eq(a.track.pieces[0].heading, 2, "drejet 90° med uret")
	assert_true(a.track.is_closed())
	assert_eq(a.ratings, ratings, "ratings uændrede")
	assert_eq(a.cells, pv["cells"])
	for c in a.cells:
		assert_eq(s.world.track_levels_except(c, -1).size() > 0, true)
	assert_eq(s.world.track_levels_except(Vector2i(10, 20), -1).size(), 0, "gammel bane ryddet")
	assert_eq(a.entrance_cell, Vector2i(30, 40) + Vector2i(1, 0), "indgang til venstre for kørselsretningen")
	assert_eq(s.world.get_tile(a.entrance_cell), ParkWorld.Tile.PATH)
	# Flyt i stedet ved kun at dreje (om stationen)
	assert_true(s.cmd_move_attraction(id, Vector2i(30, 40), 2)["ok"])
	assert_true(s.cmd_undo()["ok"])
	assert_true(s.cmd_undo()["ok"])
	assert_eq(a.track.pieces[0].cell, Vector2i(10, 20))
	assert_eq(a.track.pieces[0].heading, 1)
	assert_eq(a.rotation, 0)
	assert_eq(a.ratings, ratings)


func test_coaster_move_collision_and_undo_build() -> void:
	var s := _sim()
	var id: int = _oval(s, Vector2i(10, 20))
	var a: Attraction = s.get_attraction(id)
	s.cmd_place_attraction("carousel", Vector2i(32, 18))
	var r: Dictionary = s.cmd_move_attraction(id, Vector2i(30, 20), 0)
	assert_true(not r["ok"], "kolliderer med bygning")
	s.cmd_undo()  # carousel
	var m0: int = s.economy.money
	var value: int = a.build_value()
	assert_eq(s.undo_label(), "Byg " + a.def.name)
	assert_true(s.cmd_undo()["ok"], "hele banen fortrydes")
	assert_true(s.get_attraction(id) == null)
	assert_eq(s.economy.money, m0 + value)
	assert_true(s.cmd_redo()["ok"])
	assert_eq(s.get_attraction(id), a)
	assert_eq(s.economy.money, m0)
	assert_true(s.world.track_levels_except(Vector2i(10, 20), -1).size() > 0)


func test_move_transport_rebuilds_links() -> void:
	var s := _sim()
	var id: int = s.cmd_start_coaster("monorail", Vector2i(5, 5), 1)
	assert_true(id >= 0)
	for i in 8:
		assert_true(s.cmd_place_track_piece(id, "monorail_straight"))
	assert_true(s.cmd_place_track_piece(id, "monorail_station_end"))
	assert_eq(s.cmd_finish_coaster(id), [] as Array[String])
	var a: Attraction = s.get_attraction(id)
	assert_eq(s.world.links_from(a.entrance_cell).size(), 1)
	var old_ent: Vector2i = a.entrance_cell
	assert_true(s.cmd_move_attraction(id, Vector2i(10, 30), 1)["ok"])
	assert_eq(s.world.links_from(old_ent).size(), 0, "gamle kanter væk")
	var l: Array[Dictionary] = s.world.links_from(a.entrance_cell)
	assert_eq(l.size(), 1)
	assert_eq(l[0]["to"], s.transport_exit_cell(a))
	assert_eq(s.world.get_tile(s.transport_exit_cell(a)), ParkWorld.Tile.PATH)
	assert_true(s.cmd_undo()["ok"])
	assert_eq(s.world.links_from(old_ent).size(), 1, "links genopbygget ved fortryd")
	# Sælg og fortryd → links igen
	assert_true(s.cmd_remove_attraction(id))
	assert_true(not s.world.has_links())
	assert_true(s.cmd_undo()["ok"])
	assert_eq(s.world.links_from(old_ent).size(), 1)


func test_decor_place_remove_move_undo() -> void:
	var s := _sim()
	var m0: int = s.economy.money
	var id: int = s.cmd_place_decor("tree_round", Vector2i(3, 3))
	assert_true(id >= 0)
	assert_true(s.cmd_move_decor(id, Vector2i(4, 4)))
	assert_eq(s.world.get_tile(Vector2i(3, 3)), ParkWorld.Tile.GRASS)
	assert_eq(s.world.get_tile(Vector2i(4, 4)), ParkWorld.Tile.DECOR)
	assert_true(s.cmd_remove_decor(id))
	assert_true(s.cmd_undo()["ok"])
	assert_eq(s.get_decor(id).cell, Vector2i(4, 4))
	assert_true(s.cmd_undo()["ok"])
	assert_eq(s.get_decor(id).cell, Vector2i(3, 3))
	assert_true(s.cmd_undo()["ok"])
	assert_true(s.get_decor(id) == null)
	assert_eq(s.economy.money, m0)


func test_price_config_recipe_undo_and_merge() -> void:
	var s := _sim()
	var c: Attraction = s.cmd_place_attraction("carousel", Vector2i(10, 10))
	var b: Attraction = s.cmd_place_attraction("burger_stand", Vector2i(20, 10))
	var p0: int = c.price
	assert_true(s.cmd_set_price(c.id, p0 + 1))
	assert_true(s.cmd_set_price(c.id, p0 + 2))
	assert_true(s.cmd_set_config(c.id, "capacity", 10))
	assert_true(s.cmd_set_recipe(b.id, "salt", true))
	assert_eq(s.undo_stack.undo_size(), 5, "2 byg + pris (samlet) + config + opskrift")
	assert_eq(s.cmd_undo()["kind"], "recipe")
	assert_true(not b.recipes.has("salt"))
	assert_eq(s.cmd_undo()["kind"], "config")
	assert_true(not c.config.has("capacity"))
	assert_eq(s.cmd_undo()["kind"], "price")
	assert_eq(c.price, p0)
	assert_eq(s.cmd_redo()["kind"], "price")
	assert_eq(c.price, p0 + 2)


func test_built_tick_saved_and_migrated() -> void:
	var s := _sim()
	_step(s, 5)
	var a: Attraction = s.cmd_place_attraction("carousel", Vector2i(10, 10))
	assert_eq(a.built_tick, 5)
	assert_true(s.cmd_move_attraction(a.id, Vector2i(20, 20), 3)["ok"])
	var s2: ParkSim = ParkSim.from_save(s.to_save())
	var a2: Attraction = s2.get_attraction(a.id)
	assert_eq(a2.built_tick, 5)
	assert_eq(a2.rotation, 3)
	assert_eq(a2.entrance_cell, a.entrance_cell)
	assert_true(not s2.can_undo(), "stakken gemmes ikke")
	var m: Dictionary = SaveMigrations.migrate({"save_version": 3, "park": {"attractions": [{"id": 1}]}})
	assert_eq(m["park"]["attractions"][0]["built_tick"], 0)
	assert_eq(m["park"]["attractions"][0]["rotation"], 0)
