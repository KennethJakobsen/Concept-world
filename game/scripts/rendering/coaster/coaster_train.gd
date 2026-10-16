class_name CoasterTrain
extends Node3D
## T-069: Rutsjebanetog (M5-kontrakt §5). Vognene bygges af simple primitiver i
## samme stil som de øvrige forlystelser (panel-tekstur, mættede farver).
## Bridge placerer vognene med set_path_pose (én transform pr. vogn, lokal -Z fremad,
## origin = centerlinjen). Implementerer RideVisual-API'et: set_running/set_broken/set_lights.

const CAR_LEN := 0.62
const CAR_SPACING := 0.72   ## anbefalet afstand mellem vognes centre langs banen
const CAR_COLORS: Array[Color] = [Color(0.85, 0.22, 0.2), Color(0.95, 0.75, 0.2), Color(0.25, 0.5, 0.85), Color(0.35, 0.7, 0.4)]

var style: StringName = &"coaster"  ## T-092: coaster | flume | train | monorail
var running: bool = true
var broken: bool = false
var lights: float = 0.0
var _cars: Array[Node3D] = []
var _lamp_mat: StandardMaterial3D
var _body_mats: Array[StandardMaterial3D] = []
var _tex: Texture2D
var _smoke: Array[CPUParticles3D] = []


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


## T-092 (ADR-004 §5): vælger køretøj efter sporsystem og bygger vognene om
## med samme antal. coaster = vogn, flume = træstamme-båd, train = lokomotiv +
## åbne vogne (røg fra skorstenen), monorail = kabine.
func set_style(system: StringName) -> void:
	style = system if system in [&"flume", &"train", &"monorail"] else &"coaster"
	set_cars(maxi(_cars.size(), 1))


func set_cars(n: int) -> void:
	for c in _cars:
		remove_child(c)
		c.queue_free()
	_cars.clear()
	_body_mats.clear()
	_smoke.clear()
	for i in maxi(n, 1):
		var car: Node3D
		match style:
			&"flume":
				car = _make_log(i)
			&"train":
				car = _make_loco(i) if i == 0 else _make_wagon(i)
			&"monorail":
				car = _make_cabin(i, i == 0, i == maxi(n, 1) - 1)
			_:
				car = _make_car(i, i == 0)
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
	_update_smoke()


func set_broken(on: bool) -> void:
	broken = on
	_update_smoke()
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


func _update_smoke() -> void:
	for p in _smoke:
		p.emitting = running and not broken


func _cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, rot_deg: Vector3, mat: Material, segs: int = 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = segs
	cm.rings = 1
	mi.mesh = cm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _body(col: Color) -> StandardMaterial3D:
	var m := _mat(col)
	m.set_meta(&"base", col)
	_body_mats.append(m)
	return m


## Udhulet træstamme (vandoverfladen ligger ~0.09 over centerlinjen).
func _make_log(i: int) -> Node3D:
	var car := Node3D.new()
	car.name = "Log%d" % i
	var bark := _body(Color(0.45, 0.3, 0.18))
	var cut := _mat(Color(0.85, 0.7, 0.45))
	var seat := _mat(Color(0.3, 0.2, 0.12))
	_cyl(car, 0.17, 0.17, CAR_LEN, Vector3(0, 0.17, 0), Vector3(90, 0, 0), bark)
	for sz: float in [-1.0, 1.0]:
		_cyl(car, 0.15, 0.15, 0.02, Vector3(0, 0.17, sz * CAR_LEN * 0.5), Vector3(90, 0, 0), cut)
	# Hulningen: mørk "indside" og to bænke.
	_part(car, Vector3(0.22, 0.03, CAR_LEN * 0.8), Vector3(0, 0.3, 0), seat)
	for sz: float in [-0.12, 0.14]:
		_part(car, Vector3(0.22, 0.05, 0.08), Vector3(0, 0.33, sz), cut)
	if i == 0:
		# Grenstump som "galionsfigur" og lygte.
		_cyl(car, 0.03, 0.05, 0.18, Vector3(0, 0.36, -CAR_LEN * 0.42), Vector3(-30, 0, 0), bark, 6)
		_part(car, Vector3(0.08, 0.05, 0.03), Vector3(0, 0.25, -CAR_LEN * 0.5 - 0.02), _lamp_mat)
	return car


## Lokomotiv med overdreven skorsten og røg (CPUParticles3D).
func _make_loco(i: int) -> Node3D:
	var car := Node3D.new()
	car.name = "Loco%d" % i
	var red := _body(Color(0.8, 0.18, 0.15))
	var black := _mat(Color(0.12, 0.12, 0.14))
	var brass := _mat(Color(0.9, 0.7, 0.25))
	_part(car, Vector3(0.3, 0.06, CAR_LEN), Vector3(0, 0.11, 0), black)
	for sx: float in [-0.13, 0.13]:
		for sz: float in [-0.2, 0.0, 0.2]:
			_cyl(car, 0.07, 0.07, 0.04, Vector3(sx, 0.1, sz), Vector3(0, 0, 90), red, 8)
	# Kedel, førerhus, skorsten (kæmpe tragt), dom og lygte.
	_cyl(car, 0.13, 0.13, CAR_LEN * 0.62, Vector3(0, 0.27, -0.08), Vector3(90, 0, 0), red)
	_part(car, Vector3(0.32, 0.3, 0.2), Vector3(0, 0.3, CAR_LEN * 0.4), red)
	_part(car, Vector3(0.36, 0.04, 0.26), Vector3(0, 0.47, CAR_LEN * 0.4), black)
	_cyl(car, 0.05, 0.05, 0.14, Vector3(0, 0.45, -0.25), Vector3.ZERO, black, 8)
	_cyl(car, 0.13, 0.05, 0.16, Vector3(0, 0.6, -0.25), Vector3.ZERO, black, 10)
	_cyl(car, 0.06, 0.06, 0.08, Vector3(0, 0.42, 0.02), Vector3.ZERO, brass, 8)
	_part(car, Vector3(0.08, 0.06, 0.03), Vector3(0, 0.3, -CAR_LEN * 0.5 - 0.02), _lamp_mat)
	var smoke := CPUParticles3D.new()
	smoke.name = "Smoke"
	smoke.position = Vector3(0, 0.7, -0.25)
	smoke.amount = 14
	smoke.lifetime = 1.6
	smoke.local_coords = false
	smoke.direction = Vector3.UP
	smoke.spread = 15.0
	smoke.initial_velocity_min = 0.4
	smoke.initial_velocity_max = 0.6
	smoke.gravity = Vector3(0, 0.15, 0)
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.6))
	smoke.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(0.95, 0.95, 0.95, 0.85))
	grad.set_color(1, Color(0.8, 0.8, 0.82, 0.0))
	smoke.color_ramp = grad
	var puff := SphereMesh.new()
	puff.radius = 0.08
	puff.height = 0.16
	puff.radial_segments = 8
	puff.rings = 4
	var pm := StandardMaterial3D.new()
	pm.vertex_color_use_as_albedo = true
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = pm
	smoke.mesh = puff
	smoke.emitting = running and not broken
	car.add_child(smoke)
	_smoke.append(smoke)
	return car


## Åben vogn med bænk til minitoget.
func _make_wagon(i: int) -> Node3D:
	var car := Node3D.new()
	car.name = "Wagon%d" % i
	var col := CAR_COLORS[i % CAR_COLORS.size()]
	var body := _body(col)
	var black := _mat(Color(0.12, 0.12, 0.14))
	var seat := _mat(Color(0.4, 0.26, 0.15))
	_part(car, Vector3(0.3, 0.05, CAR_LEN * 0.9), Vector3(0, 0.1, 0), black)
	for sx: float in [-0.13, 0.13]:
		for sz: float in [-0.18, 0.18]:
			_cyl(car, 0.05, 0.05, 0.04, Vector3(sx, 0.08, sz), Vector3(0, 0, 90), black, 8)
	_part(car, Vector3(0.34, 0.04, CAR_LEN * 0.9), Vector3(0, 0.15, 0), body)
	for sx: float in [-0.155, 0.155]:
		_part(car, Vector3(0.03, 0.1, CAR_LEN * 0.9), Vector3(sx, 0.22, 0), body)
	for sz: float in [-1.0, 1.0]:
		_part(car, Vector3(0.34, 0.1, 0.03), Vector3(0, 0.22, sz * CAR_LEN * 0.44), body)
	_part(car, Vector3(0.26, 0.05, 0.14), Vector3(0, 0.2, 0), seat)
	# Baldakin på fire stænger.
	for sx: float in [-0.14, 0.14]:
		for sz: float in [-0.22, 0.22]:
			_part(car, Vector3(0.025, 0.28, 0.025), Vector3(sx, 0.31, sz), black)
	_part(car, Vector3(0.38, 0.03, CAR_LEN * 0.95), Vector3(0, 0.46, 0), _mat(Color(0.95, 0.92, 0.85)))
	return car


## Monorail-kabine, der sidder over betonbjælken (centerlinje = bjælkens top).
func _make_cabin(i: int, front: bool, back: bool) -> Node3D:
	var car := Node3D.new()
	car.name = "Cabin%d" % i
	var body := _body(Color(0.2, 0.55, 0.75))
	var trim := _mat(Color(0.95, 0.95, 0.92))
	var dark := _mat(Color(0.15, 0.15, 0.18))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.6, 0.8, 0.95, 0.55)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.1
	# Skørter, der griber om bjælken.
	for sx: float in [-0.13, 0.13]:
		_part(car, Vector3(0.04, 0.16, CAR_LEN * 0.9), Vector3(sx, -0.04, 0), dark)
	_part(car, Vector3(0.36, 0.08, CAR_LEN), Vector3(0, 0.08, 0), body)
	for sx: float in [-0.165, 0.165]:
		_part(car, Vector3(0.03, 0.16, CAR_LEN * 0.92), Vector3(sx, 0.2, 0), glass).name = "Window%d" % int(sx > 0)
	_part(car, Vector3(0.36, 0.05, CAR_LEN), Vector3(0, 0.3, 0), trim)
	_part(car, Vector3(0.3, 0.04, CAR_LEN * 0.8), Vector3(0, 0.34, 0), body)
	for sz: float in [-1.0, 1.0]:
		var is_end := (front and sz < 0.0) or (back and sz > 0.0)
		if is_end:
			var nose := _part(car, Vector3(0.36, 0.24, 0.12), Vector3(0, 0.18, sz * (CAR_LEN * 0.5 + 0.04)), body)
			nose.rotation_degrees.x = 20.0 * sz
			_part(car, Vector3(0.1, 0.05, 0.03), Vector3(0, 0.12, sz * (CAR_LEN * 0.5 + 0.1)), _lamp_mat)
		else:
			_part(car, Vector3(0.3, 0.2, 0.03), Vector3(0, 0.19, sz * CAR_LEN * 0.5), dark)
	return car
