extends TestCase
## T-092: spor-meshes pr. system, køretøjer og stationer.

const SYS := {
	"flume": ["flume_station", "flume_straight", "flume_turn_left", "flume_turn_right", "flume_lift_up", "flume_drop"],
	"train": ["train_station", "train_straight", "train_turn_left", "train_turn_right"],
	"monorail": ["monorail_station_start", "monorail_straight", "monorail_turn_left", "monorail_turn_right", "monorail_up", "monorail_down", "monorail_station_end"],
}


func _chain(ids: Array, defs: Dictionary, level: int) -> Array:
	var out: Array = []
	var cell := Vector2i.ZERO
	var heading := 1
	for id: String in ids:
		var d: Dictionary = defs[id]
		out.append({"def_id": id, "cell": cell, "heading": heading, "level": level})
		heading = posmod(heading + int(d.get("turn", 0)), 4)
		level += int(d.get("rise", 0))
		var dv := CoasterTrackMesh.heading_dir(heading)
		cell += Vector2i(int(dv.x), int(dv.z))
	return out


func test_defs_loaded_with_system() -> void:
	var defs := CoasterTrackMesh.load_defs()
	for sys: String in SYS:
		for id: String in SYS[sys]:
			assert_true(defs.has(id), id)
			if defs.has(id):
				assert_eq(String(defs[id].get("system", "")), sys, id)
	assert_eq(String(defs["track_straight"].get("system", "coaster")), "coaster")


func test_dispatch_and_budget() -> void:
	var defs := CoasterTrackMesh.load_defs()
	for sys: String in SYS:
		var ids: Array = []
		var pool: Array = SYS[sys]
		for i in 60:
			var id: String = pool[i % pool.size()]
			if id.ends_with("_down") or id == "flume_drop":
				id = pool[1]
			ids.append(id)
		var ps := _chain(ids, defs, 3 if sys == "monorail" else 0)
		assert_eq(CoasterTrackMesh.system_of(ps, defs), StringName(sys))
		var m := CoasterTrackMesh.new()
		m.build(ps, defs)
		var tris := m.triangle_count()
		assert_true(tris > 0 and tris <= 20000, "%s trekanter %d" % [sys, tris])
		if sys == "flume":
			var found := false
			for s in m.mesh.get_surface_count():
				found = found or m.mesh.surface_get_material(s) is ShaderMaterial
			assert_true(found, "vandoverflade")
		m.set_ghost(true)
		assert_true(m.material_override != null)
		m.free()


func test_train_styles() -> void:
	for sys: StringName in [&"coaster", &"flume", &"train", &"monorail"]:
		var t := CoasterTrain.new()
		t.set_cars(3)
		t.set_style(sys)
		assert_eq(t.car_count(), 3)
		assert_eq(t.style, sys)
		var smoke := t.find_children("*", "CPUParticles3D", true, false)
		assert_eq(smoke.size() > 0, sys == &"train", "røg kun på lokomotiv")
		t.set_broken(true)
		t.set_lights(1.0)
		t.free()


func test_stations() -> void:
	for s: String in ["flume", "train", "monorail"]:
		var n: Node3D = (load("res://scenes/props/%s_station.tscn" % s) as PackedScene).instantiate()
		assert_true(n.get_node_or_null("Theme") != null, s)
		assert_true(n.has_method("set_running") and n.has_method("set_broken") and n.has_method("set_lights"))
		for mi: Node in n.find_children("*", "MeshInstance3D", true, false):
			var sm := (mi as MeshInstance3D).material_override as StandardMaterial3D
			assert_true(sm != null and (sm.albedo_texture != null or sm.emission_enabled), "%s/%s tekstur" % [s, mi.name])
		n.free()
