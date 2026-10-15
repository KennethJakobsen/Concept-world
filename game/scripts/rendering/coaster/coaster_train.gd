class_name CoasterTrain
extends Node3D
## T-069: Rutsjebanetog (M5-kontrakt §5). Vognene bygges af simple primitiver i
## samme stil som de øvrige forlystelser (panel-tekstur, mættede farver).
## Bridge placerer vognene med set_path_pose (én transform pr. vogn, lokal -Z fremad,
## origin = centerlinjen). Implementerer RideVisual-API'et: set_running/set_broken/set_lights.

const CAR_LEN := 0.62
const CAR_SPACING := 0.72   ## anbefalet afstand mellem vognes centre langs banen
const CAR_COLORS: Array[Color] = [Color(0.85, 0.22, 0.2), Color(0.95, 0.75, 0.2), Color(0.25, 0.5, 0.85), Color(0.35, 0.7, 0.4)]

var running: bool = true
var broken: bool = false
var lights: float = 0.0
var _cars: Array[Node3D] = []
var _lamp_mat: StandardMaterial3D
var _body_mats: Array[StandardMaterial3D] = []
var _tex: Texture2D


func _init() -> void:
	_tex = load("res://assets/textures/panel.png")
	_lamp_mat = StandardMaterial3D.new()
	_lamp_mat.albedo_color = Color(1.0, 0.9, 0.6)
	_lamp_mat.emission_enabled = true
	_lamp_mat.emission = Color(1.0, 0.85, 0.5)
	_lamp_mat.emission_energy_multiplier = 0.0


func _ready() -> void:
	if _cars.is_empty():
		set_cars(3)


func car_count() -> int:
	return _cars.size()


func set_cars(n: int) -> void:
	for c in _cars:
		c.queue_free() if c.is_inside_tree() else c.free()
	_cars.clear()
	_body_mats.clear()
	for i in maxi(n, 1):
		var car := _make_car(i, i == 0)
		add_child(car)
		_cars.append(car)
		car.position = Vector3(0, 0, CAR_SPACING * i)  # standard: på række bag forreste vogn


## Én transform pr. vogn (overskydende ignoreres; manglende vogne skjules).
func set_path_pose(points: Array[Transform3D]) -> void:
	for i in _cars.size():
		if i < points.size():
			_cars[i].transform = points[i]
			_cars[i].visible = true
		else:
			_cars[i].visible = false


func set_running(on: bool) -> void:
	running = on


func set_broken(on: bool) -> void:
	broken = on
	for m in _body_mats:
		m.albedo_color = m.get_meta(&"base").darkened(0.45) if on else m.get_meta(&"base")


func set_lights(f: float) -> void:
	lights = clampf(f, 0.0, 1.0)
	_lamp_mat.emission_energy_multiplier = 2.5 * lights


func _mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.albedo_texture = _tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(2, 2, 2)
	m.roughness = 0.7
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m


func _part(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _make_car(i: int, lead: bool) -> Node3D:
	var car := Node3D.new()
	car.name = "Car%d" % i
	var base := CAR_COLORS[i % CAR_COLORS.size()]
	var body := _mat(base)
	body.set_meta(&"base", base)
	_body_mats.append(body)
	var dark := _mat(Color(0.18, 0.18, 0.22))
	var seat := _mat(Color(0.3, 0.2, 0.15))
	# Chassis + hjul (over skinnerne, centerlinje i y=0, skinnetop ~0.1).
	_part(car, Vector3(0.3, 0.06, CAR_LEN * 0.9), Vector3(0, 0.15, 0), dark)
	for sx: float in [-0.17, 0.17]:
		for sz: float in [-0.22, 0.22]:
			_part(car, Vector3(0.04, 0.08, 0.08), Vector3(sx, 0.12, sz), dark)
	# Karrosseri: bund + sider + front/bag.
	_part(car, Vector3(0.42, 0.06, CAR_LEN), Vector3(0, 0.21, 0), body)
	for sx: float in [-0.19, 0.19]:
		_part(car, Vector3(0.04, 0.16, CAR_LEN), Vector3(sx, 0.31, 0), body)
	_part(car, Vector3(0.42, 0.18, 0.05), Vector3(0, 0.32, CAR_LEN * 0.5), body)
	# To sæderækker med ryglæn.
	for sz: float in [-0.12, 0.16]:
		_part(car, Vector3(0.32, 0.05, 0.16), Vector3(0, 0.27, sz), seat)
		_part(car, Vector3(0.32, 0.14, 0.04), Vector3(0, 0.34, sz + 0.09), seat)
	if lead:
		# Spids næse med lygte.
		var nose := _part(car, Vector3(0.42, 0.22, 0.12), Vector3(0, 0.3, -CAR_LEN * 0.5 - 0.04), body)
		nose.rotation_degrees.x = -18.0
		_part(car, Vector3(0.12, 0.06, 0.03), Vector3(0, 0.32, -CAR_LEN * 0.5 - 0.11), _lamp_mat)
	else:
		_part(car, Vector3(0.42, 0.18, 0.05), Vector3(0, 0.32, -CAR_LEN * 0.5), body)
	return car
