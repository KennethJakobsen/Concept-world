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
