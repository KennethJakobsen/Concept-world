extends TestCase
## T-091: svævebane – transportkanter i stigrafen (ADR-004 §4).

const START: Vector2i = Vector2i(5, 5)


func _ride_def() -> AttractionDef:
	var d := AttractionDef.new()
	d.id = "island_ride"
	d.kind = "ride"
	d.capacity = 4
	d.ride_ticks = 40
	d.ticket_price = 1
	d.excitement = 30
	d.reliability = 1.0
	return d


## Hovedsti: indgang → (20,9) → (4,9) → (4,4). Svævebane (5,5)→(14,5), øen: (14,4),(14,3),(15,3) + forlystelse (15,2).
func _park(seed_v: int = 5, finish: bool = true) -> ParkSim:
	var s := ParkSim.new(40, 40, seed_v)
	s.economy.money = 1000000
	s.fixed_spawn = true
	s.spawn_interval_ticks = 10
	s.register_def(_ride_def())
	var e: Vector2i = s.world.entrance
	for y in range(9, e.y):
		assert_true(s.cmd_place_path(Vector2i(e.x, y)))
	for x in range(4, e.x):
		assert_true(s.cmd_place_path(Vector2i(x, 9)))
	for y in range(4, 9):
		assert_true(s.cmd_place_path(Vector2i(4, y)))
	var id: int = s.cmd_start_coaster("monorail", START, 1)
	assert_eq(id, 1)
	for i in 8:
		assert_true(s.cmd_place_track_piece(id, "monorail_straight"), str(s.preview_track_piece(id, "monorail_straight")))
	if not finish:
		return s
	assert_true(s.cmd_place_track_piece(id, "monorail_station_end"))
	assert_eq(s.preview_track_piece(id, "monorail_straight")["reason"], "closed")
	assert_eq(s.cmd_finish_coaster(id), [] as Array[String])
	assert_true(s.cmd_place_path(Vector2i(14, 3)))
	assert_true(s.cmd_place_attraction("island_ride", Vector2i(15, 2)) != null)
	return s


func test_world_links() -> void:
	var w := ParkWorld.new(10, 10)
	w.add_link(Vector2i(1, 1), Vector2i(5, 5), 3.0, 7)
	w.add_link(Vector2i(1, 1), Vector2i(8, 8), 2.0, 2)
	var l: Array[Dictionary] = w.links_from(Vector2i(1, 1))
	assert_eq(l.size(), 2)
	assert_eq(l[0]["owner_id"], 2, "sorteret efter owner_id")
	assert_eq(w.links_from(Vector2i(5, 5))[0]["to"], Vector2i(1, 1), "tovejs")
	w.remove_links(2)
	assert_eq(w.links_from(Vector2i(1, 1)).size(), 1)
	assert_eq(w.links_from(Vector2i(8, 8)).size(), 0)
	w.remove_links(7)
	assert_true(not w.has_links())


func test_pathfinder_links() -> void:
	var w := ParkWorld.new(12, 3)
	for x in [0, 1, 2, 8, 9, 10]:
		w.place_path(Vector2i(x, 1))
	var pf := PathFinder.new(w)
	var ok: Array = [true]
	pf.link_usable = func(_o: int) -> bool: return ok[0]
	pf.link_price = func(_o: int) -> int: return 5
	w.add_link(Vector2i(2, 1), Vector2i(8, 1), 4.0, 1)
	assert_true(pf.find_path(Vector2i(0, 1), Vector2i(10, 1)).is_empty(), "uden budget: ingen kant")
	var p: Array[Vector2i] = pf.find_path(Vector2i(0, 1), Vector2i(10, 1), 10)
	assert_eq(p, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1)] as Array[Vector2i])
	assert_true(pf.find_path(Vector2i(0, 1), Vector2i(10, 1), 4).is_empty(), "har ikke råd")
	ok[0] = false
	pf.invalidate()
	assert_true(pf.find_path(Vector2i(0, 1), Vector2i(10, 1), 10).is_empty(), "lukket/brudt")


func test_monorail_requires_end_station() -> void:
	var s := _park(5, false)
	assert_eq(s.cmd_finish_coaster(1), ["incomplete"] as Array[String])
	assert_true(not s.world.has_links())


func test_finish_registers_link_and_reachability() -> void:
	var s := _park()
	var a: Attraction = s.get_attraction(1)
	assert_true(a.is_transport() and not a.is_ride())
	assert_eq(a.entrance_cell, Vector2i(5, 4))
	assert_eq(s.transport_exit_cell(a), Vector2i(14, 4))
	assert_eq(s.world.get_tile(Vector2i(14, 4)), ParkWorld.Tile.PATH)
	var l: Array[Dictionary] = s.world.links_from(Vector2i(5, 4))
	assert_eq(l.size(), 1)
	assert_eq(l[0]["to"], Vector2i(14, 4))
	assert_eq(l[0]["cost"], a.def.transport_cost)
	var ride: Attraction = s.get_attraction(2)
	assert_true(s.is_reachable(ride), "øen nås via svævebanen")
	s.cmd_set_open(1, false)
	s._reachable_dirty = true
	assert_true(not s.is_reachable(ride), "lukket bane")
	s.cmd_set_open(1, true)
	s._break(a)
	s._reachable_dirty = true
	assert_true(not s.is_reachable(ride), "brudt bane")
	var g := Guest.new(99, Vector2i(5, 4))
	g.money = 100
	assert_true(s._route(g, ride.entrance_cell).is_empty(), "brudt: ingen rute")
	s._repair(a)
	assert_true(not s._route(g, ride.entrance_cell).is_empty(), "repareret")
	assert_true(s.path_finder.find_path(Vector2i(5, 4), ride.entrance_cell).is_empty(), "personale bruger ikke kanter")


func test_poor_guest_avoids_link() -> void:
	var s := _park()
	var ride: Attraction = s.get_attraction(2)
	s.cmd_set_price(1, 30)
	var g := Guest.new(99, Vector2i(5, 4))
	g.money = 29
	assert_true(s._route(g, ride.entrance_cell).is_empty())
	g.money = 30
	var r: Array[Vector2i] = s._route(g, ride.entrance_cell)
	assert_true(r.has(Vector2i(14, 4)))


func test_guests_ride_transport() -> void:
	var s := _park()
	var mono: Attraction = s.get_attraction(1)
	var ride: Attraction = s.get_attraction(2)
	var seen: Array = [false]
	for i in 6000:
		s.update(SimClock.TICK_DELTA)
		if not seen[0]:
			for g: Guest in s.guests.values():
				if s.guest_info(g.id)["state"] == &"riding_transport":
					seen[0] = true
	assert_true(mono.total_visitors > 0, "passagerer")
	assert_true(mono.total_revenue > 0, "billet")
	assert_true(ride.total_visitors > 0, "gæster nåede øen")
	assert_true(seen[0], "riding_transport set")
	assert_eq(s.attraction_stats(1)["riders_today"], mono.riders_today)


func test_save_load_rebuilds_links_and_determinism() -> void:
	var s := _park(13)
	for i in 3000:
		s.update(SimClock.TICK_DELTA)
	var l: ParkSim = ParkSim.from_save(SaveCodec.parse(SaveCodec.stringify(s.to_save())), s.balance, [_ride_def()])
	assert_true(l != null)
	assert_eq(l.world.links_from(Vector2i(5, 4)).size(), 1, "links genopbygget")
	for i in 2000:
		s.update(SimClock.TICK_DELTA)
		l.update(SimClock.TICK_DELTA)
	assert_eq(SaveCodec.stringify(l.to_save()["park"]), SaveCodec.stringify(s.to_save()["park"]))


func test_remove_transport_removes_links_and_refunds() -> void:
	var s := _park()
	var mono: Attraction = s.get_attraction(1)
	var g := Guest.new(500, Vector2i(5, 4))
	g.money = 100
	s.guests[g.id] = g
	g.next_cell = Vector2i(14, 4)
	s._board_transport(g)
	assert_eq(g.transport_id, 1)
	assert_eq(g.money, 100 - mono.price)
	assert_true(s.cmd_remove_attraction(1))
	assert_true(not s.world.has_links())
	assert_eq(g.transport_id, -1)
	assert_eq(g.money, 100)


## T-145: svævebanen er også en forlystelse – gæster kører i den uden genvejsfordel.
func test_guests_ride_transport_as_attraction() -> void:
	var s := _park(7, false)
	assert_true(s.cmd_place_track_piece(1, "monorail_station_end"))
	assert_eq(s.cmd_finish_coaster(1), [] as Array[String])
	# Sti til endestationen, så banen ikke er en genvej (parallel sti fra (4,4)).
	for x in range(5, 15):
		assert_true(s.cmd_place_path(Vector2i(x, 3)))
	assert_true(s.cmd_place_path(Vector2i(4, 3)))
	var mono: Attraction = s.get_attraction(1)
	var arrived: Array = [false]
	var riding: Dictionary = {}
	for i in 6000:
		s.update(SimClock.TICK_DELTA)
		for gg: Guest in s.guests.values():
			if gg.state == Guest.State.RIDING and gg.transport_id < 0 and gg.target_attraction_id == 1:
				riding[gg.id] = true
			elif riding.has(gg.id) and gg.state != Guest.State.RIDING:
				riding.erase(gg.id)
				if gg.cell == s.transport_exit_cell(mono):
					arrived[0] = true
	assert_true(mono.total_visitors > 0, "gæster valgte svævebanen som forlystelse")
	assert_true(mono.total_revenue > 0, "billet")
	assert_true(arrived[0], "gæst steg af ved den anden station")
