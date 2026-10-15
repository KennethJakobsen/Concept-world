extends TestCase
## T-073: stationens sadeltag skal have rygning i midten (langs z = sporet) og hvile på søjlerne.


func _corners(mi: MeshInstance3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var a: AABB = mi.mesh.get_aabb()
	for i: int in 8:
		out.append(mi.transform * a.get_endpoint(i))
	return out


func test_roof_is_gable_not_valley() -> void:
	var s: Node3D = (load("res://scenes/props/coaster_station.tscn") as PackedScene).instantiate()
	var post: MeshInstance3D = s.get_node("Post1")
	var post_top: float = post.position.y + (post.mesh as BoxMesh).size.y * 0.5
	for n: String in ["RoofL", "RoofR"]:
		var r: MeshInstance3D = s.get_node(n)
		var top := -INF
		var top_x := 0.0
		var bottom := INF
		var bottom_x := 0.0
		for c: Vector3 in _corners(r):
			if c.y > top:
				top = c.y
				top_x = c.x
			if c.y < bottom:
				bottom = c.y
				bottom_x = c.x
		assert_true(absf(top_x) < absf(bottom_x), n + ": rygning nærmest midten")
		assert_true(absf(top_x) < 0.1, n + ": rygning ved x~0 (langs sporet)")
		assert_true(bottom < post_top, n + ": tagfod når ned til søjletop (svæver ikke)")
		assert_true(bottom > post_top - 0.15, n + ": tagfod ikke for lavt")
	s.free()
