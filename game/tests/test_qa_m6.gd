extends TestCase
## T-096: M6-verifikation – alle 18 nye bygninger i én park, mekanik B/D/E/A/C, saves v1/v2 → v3
## og determinisme efter N ticks.

const BUILDINGS: Array[String] = [
	"bouncy_castle", "teacups", "trampoline", "sky_rings", "pirate_ship", "space_rocket", "drop_tower",
	"fries_stand", "coffee_stand", "balloon_stand", "souvenir_shop",
	"coconut_shy", "shooting_gallery", "hook_a_duck", "strength_tester",
]
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
const STREET_Y: int = 30


func _track(s: ParkSim, def_id: String, seq: Array[String], cell: Vector2i) -> int:
	var id: int = s.cmd_start_coaster(def_id, cell, 1)
	assert_true(id > 0, "start %s" % def_id)
	for p in seq:
		assert_true(s.cmd_place_track_piece(id, p), "%s: %s %s" % [def_id, p, s.preview_track_piece(id, p)])
	return id


## Park med alle 15 bygninger nord for en gade og vandbane, minitog og svævebane syd for den.
func _full_park(seed_v: int) -> ParkSim:
	var s := ParkSim.new(64, 64, seed_v)
	s.economy.money = 10000000
	s.fixed_spawn = true
	s.spawn_interval_ticks = 10
	var e: Vector2i = s.world.entrance
	for y in range(STREET_Y + 1, e.y):
		s.cmd_place_path(Vector2i(e.x, y))
	for x in range(1, 63):
		s.cmd_place_path(Vector2i(x, STREET_Y))
	var x: int = 2
	for b in BUILDINGS:
		var size: Vector2i = s.get_def(b).footprint
		var a: Attraction = s.cmd_place_attraction(b, Vector2i(x, STREET_Y - size.y))
		assert_true(a != null, "placér %s" % b)
		x += size.x + 1
	var ids: Array[int] = [_track(s, "log_flume", FLUME, Vector2i(2, STREET_Y + 1)),
		_track(s, "mini_train", TRAIN, Vector2i(16, STREET_Y + 1))]
	var mono: int = s.cmd_start_coaster("monorail", Vector2i(50, STREET_Y + 1), 1)
	assert_true(mono > 0, "start monorail")
	for i in 8:
		assert_true(s.cmd_place_track_piece(mono, "monorail_straight"), str(s.preview_track_piece(mono, "monorail_straight")))
	assert_true(s.cmd_place_track_piece(mono, "monorail_station_end"))
	ids.append(mono)
	for id in ids:
		assert_eq(s.cmd_finish_coaster(id), [] as Array[String], "finish %d" % id)
	s.cmd_hire_staff("mechanic", Vector2i(30, STREET_Y))
	s.cmd_hire_staff("handyman", Vector2i(20, STREET_Y))
	return s


func _step(s: ParkSim, ticks: int) -> void:
	for i in ticks:
		s.update(SimClock.TICK_DELTA)


func _snap(s: ParkSim) -> String:
	return SaveCodec.stringify(s.to_save()["park"])


func test_all_18_buildings_and_mechanics() -> void:
	var s := _full_park(4)
	assert_eq(s.attractions.size(), 18, "15 bygninger + 3 sporbaner")
	_step(s, 20 * 60 * 8)
	var visits: Dictionary = {}
	var prizes: int = 0
	for a: Attraction in s.attractions:
		visits[a.def.id] = a.total_visitors
		prizes += a.prizes_won
	var nausea_seen: bool = false
	var items_seen: bool = false
	for g: Guest in s.guests.values():
		nausea_seen = nausea_seen or g.nausea > 0.0
		items_seen = items_seen or not g.items.is_empty()
	assert_true(s.guests.size() > 0, "gæster i parken")
	assert_true(nausea_seen or s.world.total_vomit() > 0, "B: kvalme/opkast")
	assert_true(prizes > 0, "D: præmier vundet")
	assert_true(items_seen, "E: gæster bærer ting")
	assert_true(int(visits["log_flume"]) > 0, "A: vandbane bruges")
	assert_true(int(visits["mini_train"]) > 0, "minitog bruges")
	assert_eq(s.world.has_links(), true, "C: svævebanen giver transportkanter")
	print("T-096 besøg: ", visits, " præmier=", prizes, " opkast=", s.world.total_vomit())


func test_determinism_full_park() -> void:
	var a := _full_park(9)
	var b := _full_park(9)
	_step(a, 4000)
	_step(b, 4000)
	assert_eq(_snap(a), _snap(b), "samme seed → samme park")
	var l := ParkSim.from_save(SaveCodec.parse(SaveCodec.stringify(a.to_save())))
	assert_eq(_snap(l), _snap(a), "round-trip")
	_step(a, 2000)
	_step(l, 2000)
	assert_eq(_snap(l), _snap(a), "deterministisk efter load")


func test_v1_fixture_loads_as_v3() -> void:
	var d: Dictionary = SaveCodec.parse(FileAccess.get_file_as_string("res://tests/fixtures/save_v1.json"))
	assert_eq(int(d["save_version"]), 1)
	var s := ParkSim.from_save(d)
	assert_true(s != null)
	_step(s, 200)
	assert_eq(int(s.to_save()["save_version"]), 3)


func test_v2_save_loads_as_v3() -> void:
	var src := _full_park(2)
	_step(src, 1000)
	var d: Dictionary = SaveCodec.parse(SaveCodec.stringify(src.to_save()))
	d["save_version"] = 2
	var park: Dictionary = d["park"]
	for g: Dictionary in park.get("guests", []):
		g.erase("intensity_tolerance")
		g.erase("nausea")
		g.erase("items")
	for at: Dictionary in park.get("attractions", []):
		at.erase("prizes_won")
	if park.has("world"):
		(park["world"] as Dictionary).erase("vomit")
	var s := ParkSim.from_save(d)
	assert_true(s != null)
	assert_eq(s.attractions.size(), 18)
	_step(s, 500)
	assert_eq(int(s.to_save()["save_version"]), 3)
