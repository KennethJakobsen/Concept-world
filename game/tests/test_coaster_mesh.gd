extends TestCase
## T-069: CoasterTrackMesh / CoasterTrain / station.

const IDS: Array[String] = ["track_straight", "track_turn_left", "track_turn_right",
	"track_up", "track_down", "track_lift_up", "coaster_station"]


func _chain(ids: Array, defs: Dictionary, cell: Vector2i, heading: int, level: int) -> Array:
	var out: Array = []
	for id: String in ids:
		var d: Dictionary = defs[id]
		out.append({"def_id": id, "cell": cell, "heading": heading, "level": level})
		heading = posmod(heading + int(d.get("turn", 0)), 4)
		level += int(d.get("rise", 0))
		var dv := CoasterTrackMesh.heading_dir(heading)
		cell += Vector2i(int(dv.x), int(dv.z))
	return out


func test_defs_have_all_types() -> void:
	var defs := CoasterTrackMesh.load_defs()
	for id in IDS:
		assert_true(defs.has(id), id)


func test_consecutive_endpoints_match() -> void:
	var defs := CoasterTrackMesh.load_defs()
	for h in 4:
		for a in IDS:
			for b in IDS:
				var ps := _chain([a, b], defs, Vector2i(3, 4), h, 2)
				var la := CoasterTrackMesh.centerline(ps[0], defs[a])
				var lb := CoasterTrackMesh.centerline(ps[1], defs[b])
				assert_true(la[la.size() - 1].distance_to(lb[0]) <= 1e-3, "%s->%s h%d" % [a, b, h])


func test_centerline_convention() -> void:
	var defs := CoasterTrackMesh.load_defs()
	var l := CoasterTrackMesh.centerline({"def_id": "track_straight", "cell": Vector2i(2, 5), "heading": 0, "level": 1}, defs["track_straight"])
	assert_true(l[0].is_equal_approx(Vector3(2.5, 1.0, 6.0)), str(l[0]))
	assert_true(l[l.size() - 1].is_equal_approx(Vector3(2.5, 1.0, 5.0)), str(l[l.size() - 1]))
	var u := CoasterTrackMesh.centerline({"def_id": "track_up", "cell": Vector2i(0, 0), "heading": 1, "level": 0}, defs["track_up"])
	assert_true(is_equal_approx(u[u.size() - 1].y, 1.0))
	var t := CoasterTrackMesh.centerline({"def_id": "track_turn_right", "cell": Vector2i(0, 0), "heading": 0, "level": 0}, defs["track_turn_right"])
	assert_true(t[t.size() - 1].is_equal_approx(Vector3(1.0, 0.0, 0.5)), str(t[t.size() - 1]))


func test_full_centerline_closed_loop_continuous() -> void:
	var defs := CoasterTrackMesh.load_defs()
	var ps := _chain(["coaster_station", "track_lift_up", "track_straight", "track_turn_right", "track_turn_right",
		"track_down", "track_straight", "track_straight", "track_turn_right", "track_turn_right"], defs, Vector2i(0, 0), 1, 0)
	var line := CoasterTrackMesh.full_centerline(ps, defs)
	assert_true(line[0].distance_to(line[line.size() - 1]) <= 1e-3, "lukket")
	for i in range(1, line.size()):
		assert_true(line[i].distance_to(line[i - 1]) < 0.3, "spring ved %d" % i)


func test_budget_60_pieces() -> void:
	var defs := CoasterTrackMesh.load_defs()
	var ids: Array = []
	for i in 60:
		ids.append(IDS[i % 6] if i % 6 != 4 else "track_lift_up")
	var ps := _chain(ids, defs, Vector2i(0, 0), 1, 3)
	var m := CoasterTrackMesh.new()
	m.build(ps, defs)
	var tris := m.triangle_count()
	assert_true(tris > 0 and tris <= 20000, "trekanter %d" % tris)
	m.free()


func test_ghost() -> void:
	var defs := CoasterTrackMesh.load_defs()
	var m := CoasterTrackMesh.new()
	m.build([{"def_id": "track_up", "cell": Vector2i(0, 0), "heading": 1, "level": 0}], defs)
	m.set_ghost(true)
	var mat := m.material_override as StandardMaterial3D
	assert_true(mat != null and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and mat.albedo_color.g > mat.albedo_color.r)
	m.set_ghost(false)
	mat = m.material_override as StandardMaterial3D
	assert_true(mat.albedo_color.r > mat.albedo_color.g)
	m.free()


func test_train_api() -> void:
	var t: CoasterTrain = (load("res://scenes/props/coaster_train.tscn") as PackedScene).instantiate()
	t.set_cars(4)
	assert_eq(t.car_count(), 4)
	var poses: Array[Transform3D] = [Transform3D(Basis(), Vector3(1, 2, 3))]
	t.set_path_pose(poses)
	for m in ["set_running", "set_broken", "set_lights"]:
		assert_true(t.has_method(m), m)
	t.set_broken(true)
	t.set_lights(1.0)
	t.set_running(false)
	t.free()


func test_station_and_demo_instantiate() -> void:
	for p in ["res://scenes/props/coaster_station.tscn", "res://scenes/rendering/coaster_demo.tscn"]:
		var n := (load(p) as PackedScene).instantiate()
		assert_true(n is Node3D, p)
		n.free()
