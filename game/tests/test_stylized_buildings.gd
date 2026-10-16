extends TestCase
## T-074: hver bygning har et tema-element (Theme-undertræ), uden strakte kugler,
## uden spejlede rotationer og inden for et rimeligt trekantbudget.

const BUILDINGS := ["ice_cream_stand", "burger_stand", "drinks_stand", "toilet", "coaster_station",
	"entrance", "haunted_house", "carousel", "ferris_wheel", "swing_ride", "bumper_cars", "go_karts",
	# T-083 (M6)
	"bouncy_castle", "teacups", "trampoline", "sky_rings", "pirate_ship", "space_rocket", "drop_tower",
	"fries_stand", "coffee_stand", "balloon_stand", "souvenir_shop", "coconut_shy", "shooting_gallery",
	"hook_a_duck", "strength_tester"]
const M6_ANIMATED := ["bouncy_castle", "teacups", "trampoline", "sky_rings", "pirate_ship", "space_rocket", "drop_tower"]
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


## T-083: alle transforms i M6-props er rene rotationer (ingen skala/spejling), footprint ligger som
## metadata og modellen holder sig inden for footprintet (med lille margin til tema-overhæng).
func _all_nodes(n: Node, out: Array[Node3D]) -> void:
	for c in n.get_children():
		if c is Node3D:
			out.append(c)
		_all_nodes(c, out)


func test_m6_transforms_and_footprint() -> void:
	for id: String in BUILDINGS.slice(12):
		var b: Node3D = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		assert_true(b is RideVisual, id + ": RideVisual")
		assert_true(b.has_meta(&"footprint"), id + ": footprint-metadata")
		var fp: Vector2i = b.get_meta(&"footprint", Vector2i.ONE)
		var nodes: Array[Node3D] = []
		_all_nodes(b, nodes)
		var box := AABB()
		var first := true
		for n in nodes:
			var basis := n.transform.basis
			assert_true(basis.determinant() > 0.0, id + "/" + n.name + ": ingen spejling")
			assert_true((basis.get_scale() - Vector3.ONE).length() < 0.002, id + "/" + n.name + ": ingen skalering")
			if n is MeshInstance3D and (n as MeshInstance3D).mesh:
				var xf := Transform3D.IDENTITY
				var c: Node = n
				while c != b:
					xf = (c as Node3D).transform * xf
					c = c.get_parent()
				var bb: AABB = xf * (n as MeshInstance3D).mesh.get_aabb()
				box = bb if first else box.merge(bb)
				first = false
		assert_true(absf(box.position.x) <= fp.x * 0.5 + 0.15 and box.end.x <= fp.x * 0.5 + 0.15, "%s: x inden for footprint %s" % [id, box])
		assert_true(absf(box.position.z) <= fp.y * 0.5 + 0.15 and box.end.z <= fp.y * 0.5 + 0.15, "%s: z inden for footprint %s" % [id, box])
		b.free()


func test_m6_rides_animate() -> void:
	for id: String in M6_ANIMATED:
		var b: RideVisual = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		b._ready()
		assert_true(b._spinners.size() >= 1, id + ": har driftsanimation")
		var before: Array[Transform3D] = []
		for s in b._spinners:
			before.append(s.transform)
		for i in 20:
			for s in b._spinners:
				s._process(0.05)
		var moved := false
		for k in b._spinners.size():
			if not b._spinners[k].transform.is_equal_approx(before[k]):
				moved = true
		assert_true(moved, id + ": bevæger sig, når den kører")
		b.free()


func _xf_to(n: Node, root: Node) -> Transform3D:
	var x := Transform3D.IDENTITY
	while n != root:
		x = (n as Node3D).transform * x
		n = n.get_parent()
	return x


## T-099: piratskibet går fri af stel, afstivning og platform i alle gyngefaser.
func test_pirate_ship_swing_clearance() -> void:
	var b: Node3D = (load("res://scenes/props/pirate_ship.tscn") as PackedScene).instantiate()
	var sw: Node3D = b.get_node("Swing")
	var statics: Array = []
	for mi: MeshInstance3D in b.find_children("*", "MeshInstance3D", true, false):
		if not sw.is_ancestor_of(mi) and not String(mi.name) in ["Base", "Axle", "HubF", "HubB"]:
			statics.append([String(mi.name), _xf_to(mi, b) * mi.mesh.get_aabb()])
	var amp := rad_to_deg(float(sw.get("amplitude")))
	for k in 9:
		var deg := lerpf(-amp, amp, float(k) / 8.0)
		sw.rotation = Vector3(0, 0, deg_to_rad(deg))
		for mi: MeshInstance3D in sw.find_children("*", "MeshInstance3D", true, false):
			if String(mi.name).begins_with("Arm"):
				continue
			var xf := _xf_to(mi, b)
			for v: Vector3 in mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
				var p := xf * v
				for s: Array in statics:
					assert_true(not (s[1] as AABB).grow(0.03).has_point(p), "%.0f°: %s rammer %s" % [deg, mi.name, s[0]])
	b.free()


## T-099: kastebolden ligger på kokosnøddebodens tag, ikke ude over kanten.
func test_coconut_ball_on_roof() -> void:
	var b: Node3D = (load("res://scenes/props/coconut_shy.tscn") as PackedScene).instantiate()
	var ball: MeshInstance3D = b.get_node("Theme/Ball")
	var roof: MeshInstance3D = b.get_node("Roof")
	var bb := _xf_to(ball, b) * ball.mesh.get_aabb()
	var rb := _xf_to(roof, b) * roof.mesh.get_aabb()
	assert_true(bb.position.x >= rb.position.x and bb.end.x <= rb.end.x, "bold inden for taget i x")
	assert_true(bb.position.z >= rb.position.z and bb.end.z <= rb.end.z, "bold inden for taget i z")
	b.free()
