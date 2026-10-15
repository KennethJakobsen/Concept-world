extends TestCase
## T-068: rutsjebane – bane, validering, fysik, ratings, gæster og save.

const ST: Vector2i = Vector2i(10, 10)
const OVAL: Array[String] = [
	"track_lift_up", "track_lift_up", "track_lift_up", "track_straight", "track_straight",
	"track_turn_right", "track_turn_right",
	"track_down", "track_down", "track_down", "track_straight", "track_straight", "track_straight",
	"track_turn_right", "track_turn_right",
]


func _sim(seed_v: int = 5) -> ParkSim:
	var s := ParkSim.new(40, 40, seed_v)
	s.economy.money = 100000
	return s


func _build(s: ParkSim, seq: Array[String], cell: Vector2i = ST, heading: int = 1) -> int:
	var id: int = s.cmd_start_coaster("wooden_coaster", cell, heading)
	assert_true(id > 0, "start")
	for p in seq:
		assert_true(s.cmd_place_track_piece(id, p), "place %s %s" % [p, s.preview_track_piece(id, p)])
	return id


func _oval_profile() -> CoasterProfile:
	var s := _sim()
	var id: int = _build(s, OVAL)
	var a: Attraction = s.get_attraction(id)
	return CoasterPhysics.simulate(a.track, CoasterContent.train("basic_train"), CoasterContent.pieces())


func test_next_entry_and_closed() -> void:
	var s := _sim()
	var id: int = s.cmd_start_coaster("wooden_coaster", ST, 1)
	var t: CoasterTrack = s.get_attraction(id).track
	assert_eq(t.next_entry(), {"cell": ST + Vector2i(1, 0), "heading": 1, "level": 0})
	s.cmd_place_track_piece(id, "track_lift_up")
	assert_eq(t.next_entry(), {"cell": ST + Vector2i(2, 0), "heading": 1, "level": 1})
	s.cmd_place_track_piece(id, "track_turn_right")
	assert_eq(t.next_entry(), {"cell": ST + Vector2i(2, 1), "heading": 2, "level": 1})
	s.cmd_place_track_piece(id, "track_turn_left")
	assert_eq(t.next_entry(), {"cell": ST + Vector2i(3, 1), "heading": 1, "level": 1})
	assert_true(not t.is_closed())
	var id2: int = _build(s, OVAL, Vector2i(10, 20))
	assert_true(s.get_attraction(id2).track.is_closed())


func test_validate_codes() -> void:
	var s := _sim()
	var id: int = _build(s, ["track_straight"] as Array[String])
	var a: Attraction = s.get_attraction(id)
	assert_true(s.cmd_finish_coaster(id).has("not_closed"))
	assert_true(not a.is_open)
	var t := CoasterTrack.new()
	t.pieces.append(TrackPiece.new("track_straight", Vector2i(1, 1), 1, 0))
	assert_true(t.validate().has("no_station"))
	t.pieces.append(TrackPiece.new("coaster_station", Vector2i(2, 1), 1, 0))
	t.pieces.append(TrackPiece.new("coaster_station", Vector2i(3, 1), 1, 0))
	assert_true(t.validate().has("multiple_stations"))
	var t2 := CoasterTrack.new({}, 1)
	t2.pieces.append(TrackPiece.new("track_up", Vector2i(1, 1), 1, 1))
	t2.pieces.append(TrackPiece.new("track_down", Vector2i(2, 1), 1, 0))
	var e: Array[String] = t2.validate()
	assert_true(e.has("too_high") and e.has("below_ground"))
	var t3 := CoasterTrack.new()
	t3.pieces.append(TrackPiece.new("track_straight", Vector2i(1, 1), 1, 0))
	t3.pieces.append(TrackPiece.new("track_straight", Vector2i(1, 1), 2, 1))
	assert_true(t3.validate().has("collision"))


func test_place_rules_and_refund() -> void:
	var s := _sim()
	var m0: int = s.economy.money
	var id: int = s.cmd_start_coaster("wooden_coaster", ST, 1)
	var a: Attraction = s.get_attraction(id)
	assert_eq(m0 - s.economy.money, 1000 + 300)
	assert_eq(a.entrance_cell, ST + Vector2i(0, -1))
	assert_eq(s.world.get_tile(a.entrance_cell), ParkWorld.Tile.PATH)
	assert_true(not a.is_open and a.building)
	# sti foran banen blokerer på lavt niveau
	s.cmd_place_path(ST + Vector2i(1, 0))
	assert_eq(s.preview_track_piece(id, "track_straight")["reason"], "collision")
	s.cmd_remove_path(ST + Vector2i(1, 0))
	var m1: int = s.economy.money
	assert_true(s.cmd_place_track_piece(id, "track_lift_up"))
	assert_true(s.cmd_place_track_piece(id, "track_lift_up"))
	assert_eq(s.world.occupied_by_track(ST + Vector2i(2, 0)), [1] as Array[int])
	# kan ikke lægge sti/bygning under lav bane
	assert_true(not s.world.can_place_path(ST + Vector2i(1, 0)))
	assert_true(not s.world.can_place_attraction(s.get_def("carousel"), ST + Vector2i(1, -1)))
	assert_true(s.cmd_remove_last_piece(id))
	assert_true(s.cmd_remove_last_piece(id))
	assert_true(not s.cmd_remove_last_piece(id))  # stationen bliver
	assert_eq(s.economy.money, m1)
	assert_eq(s.world.occupied_by_track(ST + Vector2i(1, 0)), [] as Array[int])
	assert_true(not s.cmd_place_track_piece(id, "nope"))
	s.economy.money = 0
	assert_eq(s.preview_track_piece(id, "track_straight")["reason"], "no_money")


func test_high_track_over_path_and_track_crossing() -> void:
	var s := _sim()
	s.cmd_place_path(Vector2i(14, 10))
	s.cmd_place_path(Vector2i(14, 11))
	var id: int = _build(s, ["track_lift_up", "track_lift_up", "track_straight"] as Array[String])
	# næste stykke ligger på niveau 2 over stien (14,10)
	assert_true(s.cmd_place_track_piece(id, "track_straight"))
	var id2: int = s.cmd_start_coaster("wooden_coaster", Vector2i(14, 13), 0)
	assert_true(id2 > 0)
	assert_true(s.cmd_place_track_piece(id2, "track_straight"))  # (14,12)
	# (14,11) er sti → kollision; (13,?)
	assert_eq(s.preview_track_piece(id2, "track_straight")["reason"], "collision")


func test_locked_pieces_rejected() -> void:
	var s := _sim()
	s.research.setup(true, ["wooden_coaster"])
	assert_eq(s.cmd_start_coaster("wooden_coaster", ST, 1) > 0, s.is_unlocked("coaster_station"))
	s.research.setup(true, ["wooden_coaster", "coaster_station", "track_straight"])
	var id: int = s.cmd_start_coaster("wooden_coaster", ST + Vector2i(0, 5), 1)
	assert_true(id > 0)
	assert_eq(s.preview_track_piece(id, "track_lift_up")["reason"], "locked")
	assert_true(not s.cmd_place_track_piece(id, "track_lift_up"))
	assert_true(s.cmd_place_track_piece(id, "track_straight"))


func test_oval_physics_and_ratings() -> void:
	var p := _oval_profile()
	assert_true(p.ok)
	assert_eq(p.drops, 1)
	assert_eq(p.turns, 4)
	assert_eq(p.max_height, 3)
	assert_true(absf(p.length - (1.0 + 3 * 1.414 + 2 + 4 * 0.785 + 3 * 1.414 + 3)) < 1e-3)
	# fart i bunden af faldet ≈ sqrt(lift² + 2·g·3) minus lidt friktion
	var ideal: float = sqrt(2.5 * 2.5 + 2.0 * 9.81 * 3.0)
	assert_true(p.max_speed < ideal and p.max_speed > ideal * 0.85, "max_speed %f" % p.max_speed)
	assert_true(p.duration_s > 3.0 and p.duration_s < 20.0, "dur %f" % p.duration_s)
	assert_true(absf(p.samples_s[p.samples_s.size() - 1] - p.length) < 1e-3)
	# determinisme
	var q := _oval_profile()
	assert_eq(q.samples_v, p.samples_v)
	assert_eq(q.duration_s, p.duration_s)
	var r: Dictionary = CoasterRatings.rate(p, CoasterContent.ratings())
	for k in ["excitement", "intensity", "nausea"]:
		assert_true(float(r[k]) >= 0.0 and float(r[k]) <= 10.0)
	print("T-068 oval: len=%.2f dur=%.2fs vmax=%.2f g=%.2f lat=%.2f drops=%d -> %s" % [p.length, p.duration_s,
		p.max_speed, p.max_g, p.max_lat, p.drops, r])
	# position/speed
	assert_eq(p.position_at(0.0), 0.0)
	assert_true(absf(p.position_at(1.0) - p.length) < 1e-4)
	assert_true(p.position_at(0.5) > 0.0 and p.position_at(0.5) < p.length)
	assert_true(absf(p.speed_at(0.0) - 2.0) < 1e-4)


func test_too_slow() -> void:
	var seq: Array[String] = OVAL.duplicate()
	for i in 3:
		seq[i] = "track_up"
	var s := _sim()
	var id: int = _build(s, seq)
	var errs: Array[String] = s.cmd_finish_coaster(id)
	assert_eq(errs, ["too_slow"] as Array[String])
	assert_true(not s.get_attraction(id).is_open)


func _park_with_coaster(seed_v: int = 5, tame: bool = true) -> ParkSim:
	var s := _sim(seed_v)
	s.fixed_spawn = true
	s.spawn_interval_ticks = 10
	var e: Vector2i = s.world.entrance
	for y in range(9, e.y):
		s.cmd_place_path(Vector2i(e.x, y))
	for x in range(10, e.x):
		s.cmd_place_path(Vector2i(x, 9))
	var id: int = _build(s, OVAL, Vector2i(10, 10), 1)  # indgang (10,9)
	assert_eq(s.cmd_finish_coaster(id), [] as Array[String])
	if tame:
		s.get_attraction(id).ratings["intensity"] = 1.0  # alle gæster tåler den
	return s


func test_finish_and_attraction_behaviour() -> void:
	var s := _park_with_coaster()
	var a: Attraction = s.get_attraction(1)
	assert_true(a.is_open and not a.building)
	assert_true(not a.ratings.is_empty())
	assert_eq(a.ride_ticks(), int(ceil(a.profile.duration_s * 20)) + a.load_ticks)
	assert_eq(a.cells.size(), 16)
	assert_true(s.world.get_attraction_at(Vector2i(13, 10)) == a)
	assert_true(s.is_reachable(a))
	assert_true(s.attraction_score() > 0.0)
	var seen_progress: bool = false
	var started: Array = []
	s.ride_cycle_started.connect(func(aid: int) -> void: started.append(aid))
	for i in 4000:
		s.update(SimClock.TICK_DELTA)
		var pr: float = a.ride_progress()
		assert_true(pr >= 0.0 and pr <= 1.0)
		if pr > 0.0 and pr < 1.0:
			seen_progress = true
	assert_true(a.total_visitors > 0, "visitors")
	assert_true(seen_progress)
	assert_true(started.has(a.id))


func test_too_intense_and_sick() -> void:
	var s := _park_with_coaster()
	var a: Attraction = s.get_attraction(1)
	var g := Guest.new(1, s.world.entrance)
	g.money = 100
	g.happiness = 80
	a.ratings["intensity"] = 10.0
	assert_true(not s._usable(g, a))
	assert_eq(g.thought, ParkSim.TOO_INTENSE_THOUGHT)
	var g2 := Guest.new(2, s.world.entrance)
	g2.happiness = 80
	a.ratings["nausea"] = 10.0
	var before: float = g2.happiness
	var sick: int = 0
	var old: float = float(CoasterContent.ratings().get("sick_chance_per_nausea", 0.0))
	CoasterContent.ratings()["sick_chance_per_nausea"] = 0.1  # 100 %
	s._maybe_sick(g2, a)
	CoasterContent.ratings()["sick_chance_per_nausea"] = old
	assert_eq(g2.thought, ParkSim.SICK_THOUGHT)
	assert_true(g2.happiness < before)


func test_remove_coaster_clears_track() -> void:
	var s := _park_with_coaster()
	var m: int = s.economy.money
	var a: Attraction = s.get_attraction(1)
	var val: int = a.build_value()
	assert_true(s.cmd_remove_attraction(1))
	assert_eq(s.economy.money, m + val / 2)
	assert_eq(s.world.occupied_by_track(Vector2i(11, 10)), [] as Array[int])
	assert_true(s.world.can_place_path(Vector2i(11, 10)))


func test_save_roundtrip_building_and_running() -> void:
	var tol: Dictionary = CoasterContent.ratings()["guest_tolerance"]
	var old: Dictionary = tol.duplicate()
	tol["intensity_pref_min"] = 10.0  # alle tåler banen, så toget kører
	tol["intensity_pref_max"] = 10.0
	var s := _park_with_coaster(9, false)
	var bid: int = _build(s, ["track_straight", "track_lift_up"] as Array[String], Vector2i(25, 3), 1)
	for i in 3000:
		s.update(SimClock.TICK_DELTA)
	assert_true(s.get_attraction(1).total_visitors > 0, "toget har kørt")
	var d: Dictionary = SaveCodec.parse(SaveCodec.stringify(s.to_save()))
	var l: ParkSim = ParkSim.from_save(d)
	assert_true(l != null)
	assert_eq(SaveCodec.stringify(l.to_save()["park"]), SaveCodec.stringify(s.to_save()["park"]))
	var b: Attraction = l.get_attraction(bid)
	assert_true(b.building and b.track.pieces.size() == 3)
	assert_eq(l.world.occupied_by_track(Vector2i(27, 3)), [0] as Array[int])
	var a0: Attraction = s.get_attraction(1)
	var a1: Attraction = l.get_attraction(1)
	assert_eq(a1.profile.samples_v, a0.profile.samples_v)
	assert_eq(a1.ratings, a0.ratings)
	assert_eq(a1.ride_ticks(), a0.ride_ticks())
	assert_true(l.cmd_place_track_piece(bid, "track_straight"))
	for i in 600:
		s.update(SimClock.TICK_DELTA)
		l.update(SimClock.TICK_DELTA)
	s.cmd_place_track_piece(bid, "track_straight")
	assert_eq(SaveCodec.stringify(l.to_save()["park"]), SaveCodec.stringify(s.to_save()["park"]))
	tol.merge(old, true)
