extends TestCase
## T-131: i hvert scenarie skal enhver bane, der kan startes, også kunne lukkes med oplåste stykker.

const LAYOUTS: Dictionary = {
	# Start-oplåst: station, lige, sving, lift og ned -> oval med ét drop (track_up forskes).
	&"coaster": [
		"track_lift_up", "track_lift_up", "track_lift_up", "track_straight", "track_straight",
		"track_turn_right", "track_turn_right",
		"track_down", "track_down", "track_down", "track_straight", "track_straight", "track_straight",
		"track_turn_right", "track_turn_right",
	],
	&"flume": [
		"flume_lift_up", "flume_lift_up", "flume_straight", "flume_straight", "flume_straight",
		"flume_turn_right", "flume_turn_right",
		"flume_drop", "flume_straight", "flume_straight", "flume_straight", "flume_straight", "flume_straight",
		"flume_turn_right", "flume_turn_right",
	],
	&"train": [
		"train_straight", "train_straight", "train_straight", "train_straight", "train_straight",
		"train_turn_right", "train_turn_right",
		"train_straight", "train_straight", "train_straight", "train_straight", "train_straight", "train_straight",
		"train_turn_right", "train_turn_right",
	],
}


func _try_build(s: ParkSim, def_id: String, seq: Array, cell: Vector2i) -> bool:
	var id: int = s.cmd_start_coaster(def_id, cell, 1)
	if id < 0:
		return false
	for p: String in seq:
		if not s.cmd_place_track_piece(id, p):
			s.cmd_remove_attraction(id)
			return false
	if not s.cmd_finish_coaster(id).is_empty():
		s.cmd_remove_attraction(id)
		return false
	return true


func test_startable_tracks_can_be_closed_in_all_scenarios() -> void:
	var checked: int = 0
	for sd in ScenarioDef.list_all():
		var s := ParkSim.new_from_scenario(sd, 1)
		s.economy.money = 100000000
		var ids: Array = s.research.unlocked.keys()
		ids.sort()
		for uid: String in ids:
			var d: AttractionDef = s.get_def(uid)
			if d == null or not d.is_tracked():
				continue
			var sys: StringName = d.track_system()
			# Stykkerne i en eventuel testbane skal være oplåste.
			for p: String in LAYOUTS.get(sys, []):
				assert_true(s.is_unlocked(p), "%s/%s: %s låst" % [sd.id, uid, p])
			if not LAYOUTS.has(sys):
				for t in ["%s_turn_left" % sys, "%s_turn_right" % sys]:
					if CoasterContent.piece(t) != null:
						assert_true(s.is_unlocked(t), "%s/%s: %s låst" % [sd.id, uid, t])
				continue
			var ok: bool = false
			for y in range(2, sd.map_size.y - 8):
				for x in range(2, sd.map_size.x - 12):
					if _try_build(s, uid, LAYOUTS[sys], Vector2i(x, y)):
						ok = true
						break
				if ok:
					break
			assert_true(ok, "%s: %s kunne ikke bygges som lukket bane" % [sd.id, uid])
			checked += 1
	assert_true(checked >= 3, "mindst én bane pr. scenarie tjekket (%d)" % checked)
