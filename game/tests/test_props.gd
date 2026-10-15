extends TestCase

const PROPS := ["carousel", "ferris_wheel", "bumper_cars", "burger_stand",
	"drinks_stand", "ice_cream_stand", "toilet", "thought_bubble",
	"mechanic", "cleaner", "entertainer", "bin", "bench", "tree_round", "tree_pine",
	"tree_blossom", "flowers", "lamp", "litter", "swing_ride", "haunted_house", "go_karts",
	"guest", "entrance"]


func test_all_props_instantiate() -> void:
	for id in PROPS:
		var scene: PackedScene = load("res://scenes/props/%s.tscn" % id)
		assert_true(scene != null, id)
		var n := scene.instantiate()
		assert_true(n is Node3D, id)
		n.free()


func test_thought_bubble_api() -> void:
	var b: Node3D = (load("res://scenes/props/thought_bubble.tscn") as PackedScene).instantiate()
	assert_true(b.has_method("show_text"))
	assert_true(b.has_method("hide_bubble"))
	b.free()


func test_breakdown_smoke_instantiates() -> void:
	var n: Node = (load("res://scenes/effects/breakdown_smoke.tscn") as PackedScene).instantiate()
	assert_true(n.get_node("Smoke") is CPUParticles3D)
	n.free()


func test_staff_api() -> void:
	for id in ["mechanic", "cleaner", "entertainer"]:
		var n: Node = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		assert_true(n.has_method("set_color") and n.has_method("set_walking") and n.has_method("hop"), id)
		n.free()


func test_litter_levels() -> void:
	var n: Node3D = (load("res://scenes/props/litter.tscn") as PackedScene).instantiate()
	n.set_level(0)
	assert_true(not n.visible)
	n.set_level(2)
	assert_true(n.visible and n.get_node("L2").visible and not n.get_node("L3").visible)
	n.free()


func test_lamp_off_by_default() -> void:
	var n: Node3D = (load("res://scenes/props/lamp.tscn") as PackedScene).instantiate()
	assert_true(not n.get_node("Light").visible)
	n.set_on(true)
	assert_true(n.get_node("Light").visible)
	n.free()


const RIDES := ["carousel", "ferris_wheel", "bumper_cars", "swing_ride", "haunted_house", "go_karts"]
const FX := ["breakdown_smoke", "repair_sparks", "coins", "confetti", "build_dust", "sweep_dust"]


func test_day_night_rig_api() -> void:
	var rig: Node3D = (load("res://scenes/rendering/day_night_rig.tscn") as PackedScene).instantiate()
	assert_true(rig is DayNightRig)
	assert_true(rig.get_node("Sun") is DirectionalLight3D)
	assert_true(rig.get_node("WorldEnvironment") is WorldEnvironment)
	var got: Array[float] = []
	rig.night_factor_changed.connect(func(f: float) -> void: got.append(f))
	rig.set_time_of_day(0.5)
	assert_true(rig.night_factor() < 0.05, "middag er dag")
	rig.set_time_of_day(0.0)
	assert_true(rig.night_factor() > 0.95, "midnat er nat")
	rig.set_time_of_day(0.0)
	assert_true(got.size() == 2, "kun signal ved aendring")
	var noon_e: float = 0.0
	rig.set_time_of_day(0.5)
	noon_e = (rig.get_node("Sun") as DirectionalLight3D).light_energy
	rig.set_time_of_day(0.0)
	assert_true((rig.get_node("Sun") as DirectionalLight3D).light_energy < noon_e)
	rig.free()


func test_lamp_intensity() -> void:
	var n: Node3D = (load("res://scenes/props/lamp.tscn") as PackedScene).instantiate()
	n.set_intensity(0.5)
	assert_true(n.get_node("Light").visible)
	assert_true(not (n.get_node("Light") as OmniLight3D).shadow_enabled)
	n.set_intensity(0.0)
	assert_true(not n.get_node("Light").visible)
	n.free()


func test_ride_visual_api() -> void:
	for id in RIDES:
		var n: Node3D = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		for m in ["set_running", "set_broken", "set_lights"]:
			assert_true(n.has_method(m), "%s.%s" % [id, m])
		n.set_running(false)
		n.set_broken(true)
		n.set_lights(1.0)
		n.set_broken(false)
		n.set_running(true)
		n.free()


func test_ferris_cabs_hang_upright() -> void:
	var n: RideVisual = (load("res://scenes/props/ferris_wheel.tscn") as PackedScene).instantiate()
	n._ready()
	var wheel: Node3D = n.get_node("Wheel")
	wheel.rotate_object_local(Vector3.BACK, 1.1)
	n._process(0.016)
	var cab: Node3D = wheel.get_node("Cab3")
	var b := wheel.transform.basis * cab.transform.basis
	assert_true(b.y.is_equal_approx(Vector3.UP), "kabine lodret")
	n.free()


func test_person_anim_api() -> void:
	for id in ["guest", "mechanic", "cleaner", "entertainer"]:
		var n: Node3D = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		n._ready()
		assert_true(n.has_method("set_walking") and n.has_method("play_emote"), id)
		n.set_walking(true)
		for k in [&"happy", &"angry", &"sick", &"sweep", &"repair"]:
			n.play_emote(k)
			n._process(0.1)
		n.set_walking(false)
		n.free()


func test_effect_scenes() -> void:
	for id in FX:
		var n: Node = (load("res://scenes/effects/%s.tscn" % id) as PackedScene).instantiate()
		assert_true(n.has_method("play"), id)
		var has_p := false
		for c in n.get_children():
			if c is CPUParticles3D:
				has_p = true
		assert_true(has_p, id)
		n.free()


## T-054: Primitive meshes maa ikke vaere strakte (SphereMesh height = 8 gav "spyd").
func _check_meshes(n: Node, id: String) -> void:
	if n is MeshInstance3D:
		var m: Mesh = (n as MeshInstance3D).mesh
		if m is SphereMesh:
			var s := m as SphereMesh
			assert_true(s.height <= s.radius * 2.0 + 0.001, "%s/%s sphere strakt" % [id, n.name])
		if m != null:
			var sz := m.get_aabb().size
			var hi := maxf(sz.x, maxf(sz.y, sz.z))
			assert_true(hi <= 6.0, "%s/%s mesh for stor (%s)" % [id, n.name, sz])
	for c in n.get_children():
		_check_meshes(c, id)


func test_no_stretched_meshes() -> void:
	for id in PROPS:
		var n: Node = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		_check_meshes(n, id)
		n.free()


## T-054: Efter mange frames med running/broken-skift skal transforms forblive ortonormale.
func test_ride_transforms_stay_sane() -> void:
	for id in RIDES:
		var n: RideVisual = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		n._ready()
		for i in 600:
			if i % 97 == 0:
				n.set_broken(i % 194 == 0)
				n.set_running(i % 3 != 0)
			n._process(0.05)
			for s in n._spinners:
				s._process(0.05)
		n.set_broken(false)
		_check_basis(n, id)
		n.free()


func _check_basis(n: Node, id: String) -> void:
	if n is Node3D:
		var sc := (n as Node3D).transform.basis.get_scale()
		assert_true(sc.x < 3.0 and sc.y < 3.0 and sc.z < 3.0 and sc.x > 0.05, "%s/%s skala %s" % [id, n.name, sc])
	for c in n.get_children():
		_check_basis(c, id)


## T-058: Gaesten skal forblive billig (200+ i parken).
const GUEST_MESH_CAP: int = 5


func _count_meshes(n: Node) -> int:
	var c := 1 if n is MeshInstance3D else 0
	for ch in n.get_children():
		c += _count_meshes(ch)
	return c


func test_guest_mesh_budget() -> void:
	var n: Node = (load("res://scenes/props/guest.tscn") as PackedScene).instantiate()
	var c := _count_meshes(n)
	assert_true(c <= GUEST_MESH_CAP, "guest har %d meshes (loft %d)" % [c, GUEST_MESH_CAP])
	n.free()


## T-058: Detaljer maa ikke flytte noder, som scripts er afhaengige af.
func test_detail_keeps_api_nodes() -> void:
	var need := {"carousel": ["Top/Horse0/Head"], "ferris_wheel": ["Wheel/Cab0/Roof"],
		"swing_ride": ["Top/Arm0/Seat/Back"], "bumper_cars": ["Cars/Car0/Seat"],
		"go_karts": ["Karts/Kart0/Driver/Helmet"], "haunted_house": ["Ghost"],
		"lamp": ["Light", "Bulb"], "guest": ["Body/Pants", "Head/Hair"]}
	for id in need:
		var n: Node = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		for p in need[id]:
			assert_true(n.get_node_or_null(p) != null, "%s/%s" % [id, p])
		n.free()


## T-060: Gokarts følger banens midterlinje og vender i kørselsretningen.
func test_go_karts_follow_track() -> void:
	var n: RideVisual = (load("res://scenes/props/go_karts.tscn") as PackedScene).instantiate()
	n._ready()
	var track: KartTrack = n.get_node("Karts")
	assert_true(n._spinners.has(track), "RideVisual styrer banen")
	for frame in 300:
		n._process(0.05)
		track._process(0.05)
		if frame % 50 != 49:
			continue
		var karts := track._karts()
		assert_eq(karts.size(), 3)
		for k in karts:
			var best := INF
			var best_t := Vector3.ZERO
			var L := track.length()
			for i in 400:
				var s := L * i / 400.0
				var d := Vector2(k.position.x, k.position.z).distance_to(Vector2(track.point_at(s).x, track.point_at(s).z))
				if d < best:
					best = d
					best_t = track.tangent_at(s)
			assert_true(best < 0.05, "%s %.3f fra midterlinjen" % [k.name, best])
			assert_true(k.transform.basis.z.normalized().dot(best_t) > 0.95, "%s vender i kørselsretningen" % k.name)
			# inde på asfalten: mellem Infield (1.15 x 0.65) og Track-kant (1.75 x 1.25)
			var p: Vector3 = k.position
			assert_true(absf(p.x) < 1.6 and absf(p.z) < 1.1, "%s på banen" % k.name)
			assert_true(absf(p.x) > 1.25 or absf(p.z) > 0.75, "%s ikke i infield" % k.name)
	# blødt stop
	n.set_running(false)
	var before := track._s
	for i in 100:
		n._process(0.05)
		track._process(0.05)
	var mid := track._s
	for i in 20:
		n._process(0.05)
		track._process(0.05)
	assert_true(is_equal_approx(mid, track._s), "står stille efter stop")
	assert_true(not is_equal_approx(before, mid), "decelererer blødt (kører lidt videre)")
	n.free()


## T-061: Ingen synlig flade på forlystelserne er en flad farve uden tekstur
## (undtagen hud, glas og emissive pærer).
func test_rides_fully_textured() -> void:
	for id in RIDES:
		var n: Node3D = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		_check_textured(n, id)
		n.free()


func _check_textured(n: Node, id: String) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mat: Material = mi.material_override
		if mat == null and mi.mesh:
			mat = mi.mesh.surface_get_material(0)
		var sm := mat as StandardMaterial3D
		assert_true(sm != null, "%s/%s har materiale" % [id, mi.name])
		if sm:
			var c := sm.albedo_color
			var skin := c.r > 0.9 and c.g > 0.75 and c.g < 0.85 and c.b > 0.6 and c.b < 0.7
			var exempt := sm.emission_enabled or skin or c.a < 1.0 or String(mi.name).contains("Window")
			assert_true(exempt or sm.albedo_texture != null, "%s/%s uden tekstur" % [id, n.get_parent().name + "/" + mi.name])
	for c in n.get_children():
		_check_textured(c, id)


func _root_xf(n: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var c: Node = n
	while c != root and c is Node3D:
		xf = (c as Node3D).transform * xf
		c = c.get_parent()
	return xf


func _mesh_boxes(n: Node, root: Node3D, out: Array[AABB]) -> void:
	for c in n.get_children():
		if String(c.name) == "Bulbs":
			continue
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			out.append(_root_xf(c, root) * (c as MeshInstance3D).mesh.get_aabb())
		_mesh_boxes(c, root, out)


func _bulb_nodes(n: Node, out: Array[MeshInstance3D]) -> void:
	for c in n.get_children():
		if String(c.name) == "Bulbs":
			for b in c.get_children():
				out.append(b)
		else:
			_bulb_nodes(c, out)


func test_ride_bulbs_sit_on_model() -> void:
	## T-062: hver lyskæde-pære skal ligge på (tæt ved) en mesh i forlystelsen.
	for id: String in ["carousel", "ferris_wheel", "bumper_cars", "swing_ride", "haunted_house", "go_karts"]:
		var n: RideVisual = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		n._ready()
		var boxes: Array[AABB] = []
		_mesh_boxes(n, n, boxes)
		var bulbs: Array[MeshInstance3D] = []
		_bulb_nodes(n, bulbs)
		assert_true(bulbs.size() >= 8, id + ": har lyskæde")
		for b in bulbs:
			var p := _root_xf(b, n).origin
			var best := INF
			for bb in boxes:
				var q := Vector3(clampf(p.x, bb.position.x, bb.end.x), clampf(p.y, bb.position.y, bb.end.y), clampf(p.z, bb.position.z, bb.end.z))
				best = minf(best, p.distance_to(q))
			assert_true(best <= 0.06, "%s: pære %s svæver %.2f m fra modellen" % [id, p, best])
		n.free()
