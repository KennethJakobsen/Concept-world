extends TestCase
## T-074: hver bygning har et tema-element (Theme-undertræ), uden strakte kugler,
## uden spejlede rotationer og inden for et rimeligt trekantbudget.

const BUILDINGS := ["ice_cream_stand", "burger_stand", "drinks_stand", "toilet", "coaster_station",
	"entrance", "haunted_house", "carousel", "ferris_wheel", "swing_ride", "bumper_cars", "go_karts"]
const THEME_TRI_BUDGET := 3000


func _theme_meshes(n: Node, out: Array[MeshInstance3D]) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		_theme_meshes(c, out)


func _tris(m: Mesh) -> int:
	var t := 0
	for s in m.get_surface_count():
		var a := m.surface_get_arrays(s)
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		t += (idx.size() if idx.size() > 0 else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return t


func test_every_building_has_theme() -> void:
	for id in BUILDINGS:
		var b: Node3D = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		var meshes: Array[MeshInstance3D] = []
		for n in b.find_children("Theme", "Node3D", true, false):
			_theme_meshes(n, meshes)
		assert_true(meshes.size() >= 5, id + ": har tema-element")
		var tris := 0
		for mi in meshes:
			var basis := mi.transform.basis
			assert_true(basis.determinant() > 0.0, id + "/" + mi.name + ": ingen spejling")
			assert_true((basis.get_scale() - Vector3.ONE).length() < 0.002, id + "/" + mi.name + ": ingen skalering")
			if mi.mesh is SphereMesh:
				var s := mi.mesh as SphereMesh
				var want := s.radius if s.is_hemisphere else s.radius * 2.0
				assert_true(is_equal_approx(s.height, want), id + "/" + mi.name + ": kugle ikke strakt")
			tris += _tris(mi.mesh)
		assert_true(tris < THEME_TRI_BUDGET, "%s: %d trekanter i tema" % [id, tris])
		b.free()


func test_api_preserved() -> void:
	for id in ["carousel", "ferris_wheel", "bumper_cars", "swing_ride", "haunted_house", "go_karts"]:
		var b: Node3D = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		for m in ["set_running", "set_broken", "set_lights"]:
			assert_true(b.has_method(m), id + "." + m)
		b.free()
