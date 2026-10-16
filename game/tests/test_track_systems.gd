extends TestCase
## T-090: generaliseret spor (ADR-004) – systemer, validering, vandbane og minitog.

const FLUME: Array[String] = [
	"flume_lift_up", "flume_lift_up", "flume_straight", "flume_straight", "flume_straight",
	"flume_turn_right", "flume_turn_right",
	"flume_drop", "flume_straight", "flume_straight", "flume_straight", "flume_straight", "flume_straight",
	"flume_turn_right", "flume_turn_right",
]
const TRAIN: Array[String] = [
	"train_straight", "train_straight", "train_straight", "train_straight", "train_straight",
	"train_turn_right", "train_turn_right",
	"train_straight", "train_straight", "train_straight", "train_straight", "train_straight", "train_straight",
	"train_turn_right", "train_turn_right",
]


func _sim(seed_v: int = 5) -> ParkSim:
	var s := ParkSim.new(40, 40, seed_v)
	s.economy.money = 1000000
	return s


func _build(s: ParkSim, def_id: String, seq: Array[String], cell: Vector2i, heading: int = 1) -> int:
	var id: int = s.cmd_start_coaster(def_id, cell, heading)
	assert_true(id > 0, "start %s" % def_id)
	for p in seq:
		assert_true(s.cmd_place_track_piece(id, p), "place %s %s" % [p, s.preview_track_piece(id, p)])
	return id


## Park med sti fra indgangen til (10,9) og en bane med station i (10,10).
func _park(def_id: String, seq: Array[String], seed_v: int = 5) -> ParkSim:
	var s := _sim(seed_v)
	s.fixed_spawn = true
	s.spawn_interval_ticks = 10
	var e: Vector2i = s.world.entrance
	for y in range(9, e.y):
		s.cmd_place_path(Vector2i(e.x, y))
	for x in range(10, e.x):
		s.cmd_place_path(Vector2i(x, 9))
	var id: int = _build(s, def_id, seq, Vector2i(10, 10))
	assert_eq(s.cmd_finish_coaster(id), [] as Array[String])
	return s


func test_content_systems() -> void:
	var sys: Array[StringName] = CoasterContent.systems()
	for n: StringName in [&"coaster", &"flume", &"train", &"monorail"]:
		assert_true(sys.has(n), "system %s" % n)
	assert_eq((CoasterContent.pieces()["track_straight"] as TrackPieceDef).system, &"coaster")
	assert_true(not CoasterContent.pieces().has("flume_straight"))
	assert_eq(CoasterContent.piece("flume_drop").rise, -2)
	assert_true(CoasterContent.piece("flume_drop").splash)
	assert_eq(CoasterContent.piece("flume_drop").system, &"flume")
	assert_eq(int(CoasterContent.system_def(&"coaster")["clearance_levels"]), 2)
	assert_eq(int(CoasterContent.system_def(&"train")["clearance_levels"]), 1)
	assert_eq(CoasterContent.system_for_kind("transport"), &"monorail")
	assert_eq(CoasterContent.station_id(&"flume"), "flume_station")
	assert_eq(CoasterContent.station_id(&"monorail"), "monorail_station_start")
	assert_eq(CoasterContent.station_id(&"monorail", "end"), "monorail_station_end")


func test_is_tracked() -> void:
	var s := _sim()
	for k: String in ["coaster", "flume", "train", "transport"]:
		var d := AttractionDef.new()
		d.kind = k
		assert_true(Attraction.new(1, d, Vector2i.ZERO).is_tracked(), k)
	var r := AttractionDef.new()
	assert_true(not Attraction.new(1, r, Vector2i.ZERO).is_tracked())
	assert_true(s.cmd_place_attraction("log_flume", Vector2i(3, 3)) == null, "spor bygges ikke som bygning")


func test_wrong_system() -> void:
	var s := _sim()
	var id: int = s.cmd_start_coaster("log_flume", Vector2i(10, 10), 1)
	assert_true(id > 0)
	assert_eq(s.preview_track_piece(id, "track_straight")["reason"], "wrong_system")
	assert_true(not s.cmd_place_track_piece(id, "track_straight"))
	assert_eq(s.preview_track_piece(id, "nope")["reason"], "unknown_piece")
	var t: CoasterTrack = s.get_attraction(id).track
	assert_eq(t.system, &"flume")
	t.pieces.append(TrackPiece.new("track_straight", Vector2i(11, 10), 1, 0))
	t.defs = t.defs.duplicate()
	t.defs["track_straight"] = CoasterContent.piece("track_straight")
	assert_true(t.validate().has("wrong_system"))


func test_train_rules_and_too_high() -> void:
	var s := _sim()
	var id: int = s.cmd_start_coaster("mini_train", Vector2i(10, 10), 1)
	assert_eq(s.get_attraction(id).track.clearance_levels, 1)
	assert_eq(s.preview_track_piece(id, "flume_lift_up")["reason"], "wrong_system")
	assert_true(s.cmd_place_track_piece(id, "train_straight"))
	assert_true(s.cmd_finish_coaster(id).has("not_closed"))
	var t := CoasterTrack.new({}, 8, &"train")
	t.pieces.append(TrackPiece.new("train_station", Vector2i(1, 1), 1, 1))
	assert_true(t.validate().has("too_high"), "max_level 0")


func test_too_low_and_incomplete_monorail() -> void:
	var t := CoasterTrack.new({}, 8, &"monorail")
	assert_true(not t.closed_loop)
	assert_eq(t.clearance_levels, 3)
	t.pieces.append(TrackPiece.new("monorail_station_start", Vector2i(1, 1), 1, 0))
	t.pieces.append(TrackPiece.new("monorail_straight", Vector2i(2, 1), 1, 0))
	var errs: Array[String] = t.validate()
	assert_true(errs.has("too_low"), str(errs))
	assert_true(errs.has("incomplete"), str(errs))
	assert_true(not errs.has("not_closed"))
	var s := _sim()
	var id: int = s.cmd_start_coaster("monorail", Vector2i(10, 10), 1)
	assert_true(id > 0)
	assert_eq(s.get_attraction(id).track.pieces[0].level, 2, "station på min_level")
	assert_eq(s.preview_track_piece(id, "monorail_down")["reason"], "too_low")


func test_flume_profile_splash_and_wet() -> void:
	var s := _park("log_flume", FLUME)
	var a: Attraction = s.get_attraction(1)
	assert_true(a.is_ride() and a.is_tracked() and not a.is_coaster())
	assert_true(a.profile.ok, "fysik ok")
	assert_eq(a.profile.splashes, 1)
	assert_eq(a.excitement_value(), a.def.excitement, "ratings fra data")
	assert_eq(a.intensity_value(), a.def.intensity)
	a.ratings["intensity"] = 0.0
	var splashes: Array = []
	s.ride_splash.connect(func(aid: int, c: Vector2i) -> void: splashes.append([aid, c]))
	var wet: Array = [false]
	for i in 4000:
		s.update(SimClock.TICK_DELTA)
		for g: Guest in s.guests.values():
			if g.wet_ticks > 0:
				wet[0] = true
	assert_true(a.total_visitors > 0)
	assert_true(not splashes.is_empty(), "plask udsendt")
	assert_eq(splashes[0][0], a.id)
	assert_eq(splashes[0][1], a.track.pieces[a.profile.splash_pieces[0]].cell)
	assert_true(wet[0], "gæster bliver våde")


func test_wet_thirst() -> void:
	var s := _park("log_flume", FLUME)
	var a: Attraction = s.get_attraction(1)
	var g := Guest.new(99, s.world.entrance)
	g.needs["thirst"] = 50.0
	s._get_wet(g, a)
	assert_eq(g.needs["thirst"], 40.0)
	assert_eq(g.wet_ticks, s.balance.wet_ticks)


func test_flume_friction_used() -> void:
	var s := _park("log_flume", FLUME)
	var a: Attraction = s.get_attraction(1)
	var defs: Dictionary = a.track.defs.duplicate()
	var slow: Dictionary = {}
	for k: String in defs:
		var d: TrackPieceDef = (defs[k] as TrackPieceDef).duplicate()
		if d.kind != "lift" and d.kind != "station":
			d.friction = 0.5
		slow[k] = d
	var p2: CoasterProfile = CoasterPhysics.simulate(a.track, s._train_of(a), slow)
	assert_true(p2.max_speed < a.profile.max_speed or not p2.ok, "friktion fra stykkerne")


func test_train_constant_profile() -> void:
	var s := _park("mini_train", TRAIN)
	var a: Attraction = s.get_attraction(1)
	assert_true(a.profile.ok)
	var cruise: float = float(CoasterContent.train("mini_loco")["cruise_speed"])
	assert_true(absf(a.profile.max_speed - cruise) < 1e-4)
	for v in a.profile.samples_v:
		assert_true(absf(v - cruise) < 1e-4)
	assert_eq(a.profile.max_g, 1.0)
	assert_true(absf(a.profile.duration_s - a.profile.length / cruise) < 0.01)
	assert_eq(a.ratings["excitement"], a.def.excitement / 10.0)
	assert_eq(a.excitement_value(), a.def.excitement)
	assert_eq(s.rides_count(), 1)


func _run_hash(def_id: String, seq: Array[String], n: int) -> String:
	var s := _park(def_id, seq, 11)
	s.get_attraction(1).ratings["intensity"] = 0.0
	for i in n:
		s.update(SimClock.TICK_DELTA)
	return SaveCodec.stringify(s.to_save()["park"])


func test_determinism_all_systems() -> void:
	for pair: Array in [["log_flume", FLUME], ["mini_train", TRAIN], ["wooden_coaster", [
			"track_lift_up", "track_lift_up", "track_lift_up", "track_straight", "track_straight",
			"track_turn_right", "track_turn_right",
			"track_down", "track_down", "track_down", "track_straight", "track_straight", "track_straight",
			"track_turn_right", "track_turn_right"] as Array[String]]]:
		var seq: Array[String] = []
		seq.assign(pair[1])
		assert_eq(_run_hash(pair[0], seq, 1500), _run_hash(pair[0], seq, 1500), "deterministisk %s" % pair[0])


func test_save_roundtrip_flume_and_train() -> void:
	var s := _park("log_flume", FLUME, 7)
	var tid: int = _build(s, "mini_train", TRAIN, Vector2i(25, 20))
	var errs: Array[String] = s.cmd_finish_coaster(tid)
	assert_eq(errs, [] as Array[String])
	for i in 1500:
		s.update(SimClock.TICK_DELTA)
	var l: ParkSim = ParkSim.from_save(SaveCodec.parse(SaveCodec.stringify(s.to_save())))
	assert_true(l != null)
	assert_eq(l.get_attraction(1).track.system, &"flume")
	assert_eq(l.get_attraction(tid).track.system, &"train")
	assert_eq(l.get_attraction(1).profile.splashes, 1)
	for i in 600:
		s.update(SimClock.TICK_DELTA)
		l.update(SimClock.TICK_DELTA)
	assert_eq(SaveCodec.stringify(l.to_save()["park"]), SaveCodec.stringify(s.to_save()["park"]))


func test_migration_defaults() -> void:
	var d: Dictionary = {"save_version": 2, "park": {"guests": [{"id": 1}], "attractions": [{"id": 1}]}}
	var m: Dictionary = SaveMigrations.migrate(d)
	assert_eq(m["park"]["guests"][0]["wet_ticks"], 0)
	assert_eq(m["park"]["guests"][0]["transport_id"], -1)
	assert_eq(m["park"]["attractions"][0]["riders_today"], 0)
