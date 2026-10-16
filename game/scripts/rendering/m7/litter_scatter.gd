class_name LitterScatter
extends Node3D
## T-107: Skrald-props pr. celle. set_items(items) med items = Array[Dictionary] {kind, index}
## (fra sim.litter_at). Position/rotation = hash(cell, index), dvs. deterministisk.
## Kinds: "wrapper", "cup", "can", "food", "vomit" (ukendt -> wrapper). Maks 5 vises.

const MAX_ITEMS := 5
static var _meshes: Dictionary = {}

var cell: Vector2i = Vector2i.ZERO


static func _mesh(kind: String) -> Mesh:
	if _meshes.is_empty():
		var mk := func(c: Color) -> StandardMaterial3D:
			var m := StandardMaterial3D.new()
			m.albedo_color = c
			m.roughness = 0.8
			return m
		var w := BoxMesh.new(); w.size = Vector3(0.12, 0.015, 0.08); w.material = mk.call(Color(0.95, 0.85, 0.3))
		var c := CylinderMesh.new(); c.top_radius = 0.035; c.bottom_radius = 0.028; c.height = 0.1; c.radial_segments = 6; c.rings = 1; c.material = mk.call(Color(0.95, 0.95, 0.95))
		var k := CylinderMesh.new(); k.top_radius = 0.028; k.bottom_radius = 0.028; k.height = 0.08; k.radial_segments = 6; k.rings = 1; k.material = mk.call(Color(0.85, 0.2, 0.2))
		var f := BoxMesh.new(); f.size = Vector3(0.1, 0.03, 0.06); f.material = mk.call(Color(0.6, 0.4, 0.2))
		var v := CylinderMesh.new(); v.top_radius = 0.14; v.bottom_radius = 0.16; v.height = 0.01; v.radial_segments = 8; v.rings = 1; v.material = mk.call(Color(0.55, 0.7, 0.25))
		_meshes = {"wrapper": w, "cup": c, "can": k, "food": f, "vomit": v}
	return _meshes.get(kind, _meshes["wrapper"])


static func item_transform(c: Vector2i, index: int) -> Transform3D:
	var h := hash([c.x, c.y, index])
	var x := float(h & 1023) / 1023.0 * 0.7 - 0.35
	var z := float((h >> 10) & 1023) / 1023.0 * 0.7 - 0.35
	var a := float((h >> 20) & 1023) / 1023.0 * TAU
	return Transform3D(Basis(Vector3.UP, a), Vector3(x, 0.07, z))


func set_items(items: Array) -> void:
	for ch in get_children():
		remove_child(ch)
		ch.queue_free()
	for i in mini(items.size(), MAX_ITEMS):
		var it: Dictionary = items[i]
		var kind := String(it.get("kind", "wrapper"))
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh(kind)
		var t := item_transform(cell, int(it.get("index", i)))
		if kind == "cup" or kind == "can":
			t.basis = t.basis * Basis(Vector3.RIGHT, PI * 0.5)  # væltet
		mi.transform = t
		mi.visibility_range_end = 40.0
		add_child(mi)
	visible = get_child_count() > 0
