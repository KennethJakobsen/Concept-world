class_name CarriedItemsVisual
extends Node3D
## T-087: Baerbare ting paa en gaest (ballon paa snor, souvenirpose, praemie-bamse/and).
## Bygges dovent af GuestVisual.set_items(); meshes er primitiver (Compatibility-sikre).
## Ballonen svajer i _process; processing kun aktiv, naar der er en ballon.

const BALLOON_COLORS: Array[Color] = [
	Color(0.95, 0.25, 0.3), Color(0.25, 0.55, 0.95), Color(0.98, 0.8, 0.2), Color(0.4, 0.8, 0.35)]

var _balloon: Node3D
var _t: float = 0.0
var _items: Array[StringName] = []


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	return m


static func _sphere(r: float, c: Color) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 8
	s.rings = 4
	s.material = _mat(c)
	var mi := MeshInstance3D.new()
	mi.mesh = s
	return mi


func items() -> Array[StringName]:
	return _items.duplicate()


func set_items(items: Array[StringName]) -> void:
	_items = items.duplicate()
	for c in get_children():
		remove_child(c)
		c.free()
	_balloon = null
	for id in _items:
		match String(id):
			"balloon":
				_build_balloon()
			"souvenir":
				_build_bag()
			"prize_bear":
				_build_bear()
			"prize_duck":
				_build_duck()
			_:
				if String(id).begins_with("prize_"):
					_build_bear()
	set_process(_balloon != null)


func _build_balloon() -> void:
	_balloon = Node3D.new()
	_balloon.name = "Balloon"
	_balloon.position = Vector3(0.14, 0.32, 0.0)  # haand
	add_child(_balloon)
	var string := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.004
	cyl.bottom_radius = 0.004
	cyl.height = 0.45
	cyl.radial_segments = 4
	cyl.rings = 1
	cyl.material = _mat(Color(0.95, 0.95, 0.95))
	string.mesh = cyl
	string.position = Vector3(0, 0.225, 0)
	_balloon.add_child(string)
	var col := BALLOON_COLORS[absi(get_instance_id()) % BALLOON_COLORS.size()]
	var b := _sphere(0.1, col)
	b.position = Vector3(0, 0.53, 0)
	_balloon.add_child(b)


func _build_bag() -> void:
	var bag := MeshInstance3D.new()
	bag.name = "Bag"
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 0.12, 0.05)
	box.material = _mat(Color(0.85, 0.3, 0.55))
	bag.mesh = box
	bag.position = Vector3(-0.15, 0.2, 0.0)
	add_child(bag)


func _build_bear() -> void:
	var bear := Node3D.new()
	bear.name = "Bear"
	bear.position = Vector3(0.0, 0.22, 0.13)  # i favnen
	add_child(bear)
	var brown := Color(0.6, 0.4, 0.22)
	var body := _sphere(0.055, brown)
	bear.add_child(body)
	var head := _sphere(0.04, brown)
	head.position = Vector3(0, 0.08, 0)
	bear.add_child(head)
	for x in [-0.03, 0.03]:
		var ear := _sphere(0.015, brown)
		ear.position = Vector3(x, 0.115, 0)
		bear.add_child(ear)


func _build_duck() -> void:
	var duck := Node3D.new()
	duck.name = "Duck"
	duck.position = Vector3(0.0, 0.22, 0.13)
	add_child(duck)
	var y := Color(1.0, 0.85, 0.15)
	duck.add_child(_sphere(0.05, y))
	var head := _sphere(0.032, y)
	head.position = Vector3(0, 0.065, 0.02)
	duck.add_child(head)
	var beak := _sphere(0.014, Color(1.0, 0.5, 0.1))
	beak.position = Vector3(0, 0.06, 0.055)
	duck.add_child(beak)


func _process(delta: float) -> void:
	if _balloon == null:
		set_process(false)
		return
	_t += delta
	_balloon.rotation = Vector3(sin(_t * 1.7) * 0.12, 0.0, sin(_t * 1.3) * 0.15)
