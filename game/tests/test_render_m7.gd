extends TestCase
## T-107: M7-visuals (køsti, crowd, svævetal, skrald, spand).


func test_queue_path_connections() -> void:
	var q := QueuePathVisual.new()
	var open := q.get_node("Rails").get_child_count()
	q.set_connections(QueuePathVisual.N | QueuePathVisual.S)
	var straight := q.get_node("Rails").get_child_count()
	assert_true(straight < open, "forbundne sider har ingen kæde")
	var m := QueuePathVisual.mask_from(Vector2i(5, 5), func(c: Vector2i) -> bool: return c == Vector2i(5, 4))
	assert_eq(m, QueuePathVisual.N)
	q.free()


func test_crowd_limits_individuals() -> void:
	var r := GuestCrowdRenderer.new()
	var entries: Array = []
	for i in 500:
		entries.append({"id": i, "pos": Vector3(float(i % 25) * 0.5, 0, float(i / 25) * 0.5), "color": Color.RED})
	var ids := r.update(entries, Vector3.ZERO)
	assert_eq(ids.size(), GuestCrowdRenderer.MAX_INDIVIDUAL)
	assert_eq(ids.size() + r.instanced_count(), 500)
	r.free()


## T-148: MultiMesh-instanser står oprejst, uskaleret, med samme dele/offsets som guest.tscn.
func test_crowd_instances_upright_and_match_guest_visual() -> void:
	var r := GuestCrowdRenderer.new()
	var entries: Array = []
	for i in 300:
		entries.append({"id": i, "pos": Vector3(float(i % 30) * 0.4, 0.1, float(i / 30) * 0.4), "color": Color(0.2, 0.9, 0.3)})
	r.update(entries, Vector3.ZERO)
	var body := r.part_multimesh("Lod0Body")
	assert_true(body.visible_instance_count > 0, "LOD0 i brug")
	for name: String in ["Lod0Body", "Lod0Pants", "Lod0Head", "Lod0Hair"]:
		var mm := r.part_multimesh(name)
		assert_eq(mm.visible_instance_count, body.visible_instance_count, name)
	var scene: Node3D = load("res://scenes/props/guest.tscn").instantiate()
	var t := GuestCrowdRenderer.part_transform(Vector3(1, 0.1, 2), GuestCrowdRenderer.OFF_HEAD)
	assert_eq(t.basis, Basis.IDENTITY, "oprejst/uskaleret")
	assert_true(t.origin.is_equal_approx(Vector3(1, 0.1, 2) + (scene.get_node("Head") as Node3D).position))
	assert_true(GuestCrowdRenderer.OFF_BODY.is_equal_approx((scene.get_node("Body") as Node3D).position))
	var pants := scene.get_node("Body/Pants") as Node3D
	assert_true(GuestCrowdRenderer.OFF_PANTS.is_equal_approx(pants.position + (scene.get_node("Body") as Node3D).position))
	assert_eq((body.mesh as CapsuleMesh).height, ((scene.get_node("Body") as MeshInstance3D).mesh as CapsuleMesh).height)
	assert_true(body.use_colors, "krop farves pr. gæst")
	scene.free()
	# Færre gæster næste frame: kapacitet bevares, kun synlige tælles.
	r.update(entries.slice(0, 10), Vector3(100, 0, 100))
	assert_true(r.part_multimesh("Lod0Body").visible_instance_count <= 10)
	r.free()


func test_lane_offset_deterministic_and_spread() -> void:
	var seen := {}
	for i in 60:
		var o := GuestCrowdRenderer.lane_offset(i)
		assert_true(absf(o) <= 0.3001)
		seen[o] = true
	assert_eq(seen.size(), 6)
	assert_eq(GuestCrowdRenderer.lane_offset(17), GuestCrowdRenderer.lane_offset(17))


func test_litter_deterministic() -> void:
	var a := LitterScatter.item_transform(Vector2i(3, 4), 2)
	var b := LitterScatter.item_transform(Vector2i(3, 4), 2)
	assert_eq(a, b)
	var l := LitterScatter.new()
	l.set_items([{"kind": "cup", "index": 0}, {"kind": "can", "index": 1}, {"kind": "x", "index": 2}])
	assert_eq(l.get_child_count(), 3)
	l.free()


func test_bin_level_and_floating_text() -> void:
	var bin: Node3D = (load("res://scenes/props/bin.tscn") as PackedScene).instantiate()
	AmenityVisuals.set_bin_level(bin, 2)
	assert_true((bin.get_node("FullIcon") as Node3D).visible)
	AmenityVisuals.set_bin_level(bin, 0)
	assert_true(not (bin.get_node("Fill") as Node3D).visible)
	bin.free()
	var ft := FloatingText3D.new()
	ft.show_amount(Vector3.ZERO, 12)
	assert_eq(ft.active_count(), 1)
	ft.free()


func test_atm_prop_loads() -> void:
	var n: Node3D = (load("res://scenes/props/atm.tscn") as PackedScene).instantiate()
	assert_true(n.get_node_or_null("Theme") != null)
	n.free()
