extends TestCase
## T-057: spøgelseshusets sadeltag skal have rygning i midten (langs x) og flugte med væggene.


func _corners(mi: MeshInstance3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var a: AABB = mi.mesh.get_aabb()
	for i: int in 8:
		out.append(mi.transform * a.get_endpoint(i))
	return out


func test_roof_is_gable_not_valley() -> void:
	var h: Node3D = (load("res://scenes/props/haunted_house.tscn") as PackedScene).instantiate()
	var walls: MeshInstance3D = h.get_node("Walls")
	var wall_top: float = walls.position.y + (walls.mesh as BoxMesh).size.y * 0.5
	var wall_half_x: float = (walls.mesh as BoxMesh).size.x * 0.5
	for n: String in ["Roof0", "Roof2"]:
		var r: MeshInstance3D = h.get_node(n)
		var top := -INF
		var top_z := 0.0
		var bottom := INF
		var bottom_z := 0.0
		for c: Vector3 in _corners(r):
			if c.y > top:
				top = c.y
				top_z = c.z
			if c.y < bottom:
				bottom = c.y
				bottom_z = c.z
			assert_true(absf(c.x) <= wall_half_x + 0.2, n + ": flugter med væggene i x")
		assert_true(absf(top_z) < absf(bottom_z), n + ": rygning nærmest midten")
		assert_true(absf(top_z) < 0.2, n + ": rygning ved z~0")
		assert_true(bottom <= wall_top + 0.05 and bottom > wall_top - 0.3, n + ": tagfod ved vægtop")
	h.free()
