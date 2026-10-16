extends TestCase
## T-133 (M7): required_pieces – en sporbane kan kun startes, når de påkrævede stykker er låst op,
## og en minimal lukket bane (station + lige + 4 sving) kan færdiggøres i hvert scenarie.


func _tracked_defs(s: ParkSim) -> Array[AttractionDef]:
	var out: Array[AttractionDef] = []
	for f in DirAccess.get_files_at(ParkSim.ATTRACTION_DIR):
		if not f.ends_with(".json"):
			continue
		var d: AttractionDef = s.get_def(f.get_basename())
		if d != null and d.is_tracked():
			out.append(d)
	return out


func _piece_with_turn(d: AttractionDef, turn: int) -> String:
	for pid in d.required_pieces:
		var p: TrackPieceDef = CoasterContent.piece(pid)
		if p != null and p.kind != "station" and p.turn == turn and p.rise == 0:
			return pid
	return ""


func test_required_pieces_parsed_with_default() -> void:
	var d := AttractionDef.from_dict({"id": "x", "kind": "coaster"})
	assert_eq(d.required_pieces.size(), 0)
	var s := ParkSim.new(20, 20, 1)
	var wc: AttractionDef = s.get_def("wooden_coaster")
	assert_true(wc.required_pieces.has("track_turn_right"))
	assert_eq(AttractionDef.from_dict(wc.to_dict()).required_pieces, wc.required_pieces)


func test_start_rejected_until_pieces_unlocked() -> void:
	var s := ParkSim.new(40, 40, 1)
	s.research.setup(true)
	assert_true(s.is_unlocked("wooden_coaster"))
	assert_true(not s.is_unlocked("track_turn_right"))
	assert_true(not s.can_complete("wooden_coaster"))
	assert_true(s.missing_pieces("wooden_coaster").has("track_turn_left"))
	var m0: int = s.economy.money
	assert_eq(s.cmd_start_coaster("wooden_coaster", Vector2i(20, 20), 1), -1)
	assert_eq(s.economy.money, m0, "intet trukket")
	s.research.unlocked["track_turn_left"] = true
	s.research.unlocked["track_turn_right"] = true
	assert_true(s.can_complete("wooden_coaster"))
	assert_eq(s.missing_pieces("wooden_coaster").size(), 0)
	assert_true(s.cmd_start_coaster("wooden_coaster", Vector2i(20, 20), 1) > 0)
	assert_true(not s.can_complete("carousel"), "ikke en sporbane")


## Pr. scenarie: hver oplåst sporbane, der kan startes, skal kunne lukkes med en minimal flad bane,
## som består validate() (inkl. too_slow).
func test_minimal_loop_per_scenario() -> void:
	var checked: int = 0
	for sd in ScenarioDef.list_all():
		var s := ParkSim.new_from_scenario(sd, 1)
		s.economy.money = 1 << 30
		var slot: int = 0
		for d in _tracked_defs(s):
			if not s.is_unlocked(d.id) or not s.can_complete(d.id):
				continue
			if not bool(CoasterContent.system_def(d.track_system()).get("closed_loop", true)):
				continue  # transport (to stationer) lukkes ikke som ring
			var right: String = _piece_with_turn(d, 1)
			var straight: String = _piece_with_turn(d, 0)
			assert_true(right != "" and straight != "", "%s: sving og lige i required_pieces" % d.id)
			var station := Vector2i(4 + slot * 8, 6)
			slot += 1
			var id: int = s.cmd_start_coaster(d.id, station, 1)
			assert_true(id > 0, "%s/%s: start" % [sd.id, d.id])
			if id <= 0:
				continue
			for pid: String in [right, right, straight, right, right]:
				assert_true(s.cmd_place_track_piece(id, pid), "%s/%s: %s" % [sd.id, d.id, pid])
			var errs: Array[String] = s.cmd_finish_coaster(id)
			assert_eq(errs, [] as Array[String], "%s/%s: minimal lukket bane" % [sd.id, d.id])
			checked += 1
	assert_true(checked >= 3, "sandbox: træbane, tømmerrende og minitog")
