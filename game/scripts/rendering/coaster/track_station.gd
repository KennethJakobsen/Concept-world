class_name TrackStation
extends Node3D
## T-092: Stationer med tema til sporsystemerne (ADR-004). 1x1 celle, origin i
## cellemidten på jorden, sporet løber langs lokal -Z gennem midten (samme
## konvention som coaster_station.tscn). Bygges proceduralt af primitiver med
## teksturerede materialer (Compatibility-sikkert).
##   flume    – perron + tag med en kæmpe træstamme og en økse i
##   train    – perron med skorsten med ur
##   monorail – tandhjulsformet perron på søjle i højde `level`

@export var style: StringName = &"":
	set(v):
		style = v
		_rebuild()
@export var level: int = 2:  ## kun monorail: banens niveau (m)
	set(v):
		level = v
		_rebuild()

var running: bool = true
var broken: bool = false
var lights: float = 0.0
var _lamp_mat: StandardMaterial3D
var _into: Node3D = null  ## forælder for nye dele (null = self)


func _mat(col: Color, tex: String = "plaster") -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.albedo_texture = load("res://assets/textures/%s.png" % tex)
	m.uv1_triplanar = true
	m.roughness = 0.85
	return m


func _box(size: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO, nm: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	if nm != "":
		mi.name = nm
	(_into if _into else self).add_child(mi)
	return mi


func _cyl(r_top: float, r_bot: float, h: float, pos: Vector3, rot_deg: Vector3, mat: Material, segs: int = 12, nm: String = "") -> MeshInstance3D:
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
	if nm != "":
		mi.name = nm
	(_into if _into else self).add_child(mi)
	return mi


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.free()
	_lamp_mat = StandardMaterial3D.new()
	_lamp_mat.albedo_color = Color(1.0, 0.9, 0.6)
	_lamp_mat.emission_enabled = true
	_lamp_mat.emission = Color(1.0, 0.85, 0.5)
	_into = null
	match style:
		&"flume":
			_build_flume()
		&"train":
			_build_train()
		&"monorail":
			_build_monorail()
	set_lights(lights)


func _build_flume() -> void:
	var wood: Material = load("res://assets/materials/wood.tres")
	var dark: Material = load("res://assets/materials/wood_dark.tres")
	var bark := _mat(Color(0.42, 0.28, 0.17), "planks")
	var cut := _mat(Color(0.88, 0.72, 0.46), "planks")
	var steel: Material = load("res://assets/materials/steel.tres")
	for sx: float in [-1.0, 1.0]:
		_box(Vector3(0.18, 0.2, 1.0), Vector3(sx * 0.4, 0.1, 0), wood, Vector3.ZERO, "Platform%s" % ("L" if sx < 0 else "R"))
		for sz: float in [-0.42, 0.42]:
			_box(Vector3(0.06, 0.95, 0.06), Vector3(sx * 0.46, 0.67, sz), dark)
	_box(Vector3(1.04, 0.05, 1.04), Vector3(0, 1.16, 0), dark, Vector3.ZERO, "Roof")
	# Theme: kæmpe træstamme på taget + økse hugget i den.
	var theme := Node3D.new()
	theme.name = "Theme"
	add_child(theme)
	_into = theme
	var log_mi := _cyl(0.24, 0.24, 1.2, Vector3(0, 1.43, 0), Vector3(90, 0, 0), bark, 14, "Log")
	for sz: float in [-1.0, 1.0]:
		_cyl(0.22, 0.22, 0.02, Vector3(0, 1.43, sz * 0.6), Vector3(90, 0, 0), cut, 14, "LogEnd")
	_cyl(0.025, 0.025, 0.55, Vector3(0.12, 1.83, 0.15), Vector3(0, 0, -25), wood, 6, "AxeHandle")
	_box(Vector3(0.16, 0.1, 0.03), Vector3(0.0, 1.62, 0.15), steel, Vector3(0, 0, -25), "AxeHead")


func _build_train() -> void:
	var stone: Material = load("res://assets/materials/path_stone.tres")
	var wood: Material = load("res://assets/materials/wood.tres")
	var roof: Material = load("res://assets/materials/roof_tiles.tres")
	var brick := _mat(Color(0.7, 0.32, 0.25), "brick")
	var face := _mat(Color(0.97, 0.95, 0.88))
	var hand := _mat(Color(0.1, 0.1, 0.12))
	# Perron på højre side, bænk og tag.
	_box(Vector3(0.3, 0.12, 1.0), Vector3(0.37, 0.06, 0), stone, Vector3.ZERO, "Platform")
	for sz: float in [-0.4, 0.4]:
		_box(Vector3(0.05, 0.75, 0.05), Vector3(0.45, 0.49, sz), wood)
	_box(Vector3(0.42, 0.05, 1.04), Vector3(0.36, 0.88, 0), roof, Vector3(0, 0, 10), "Roof")
	_box(Vector3(0.1, 0.05, 0.4), Vector3(0.42, 0.22, 0), wood, Vector3.ZERO, "Bench")
	# Theme: skorsten med ur.
	var theme := Node3D.new()
	theme.name = "Theme"
	add_child(theme)
	_into = theme
	_box(Vector3(0.2, 1.3, 0.2), Vector3(0.38, 0.77, -0.38), brick, Vector3.ZERO, "Chimney")
	_box(Vector3(0.26, 0.06, 0.26), Vector3(0.38, 1.45, -0.38), brick, Vector3.ZERO, "ChimneyCap")
	_cyl(0.13, 0.13, 0.03, Vector3(0.38, 1.15, -0.27), Vector3(90, 0, 0), face, 16, "ClockFace")
	_box(Vector3(0.015, 0.09, 0.01), Vector3(0.38, 1.19, -0.25), hand, Vector3.ZERO, "HandHour")
	_box(Vector3(0.012, 0.11, 0.01), Vector3(0.42, 1.15, -0.25), hand, Vector3(0, 0, -90), "HandMinute")
	_box(Vector3(0.08, 0.05, 0.03), Vector3(0.38, 0.95, -0.26), _lamp_mat, Vector3.ZERO, "Lamp")


func _build_monorail() -> void:
	var metal: Material = load("res://assets/materials/metal.tres")
	var conc := _mat(Color(0.72, 0.71, 0.68))
	var gear_mat := _mat(Color(0.85, 0.62, 0.2), "metal")
	var y := float(level) - 0.32
	_cyl(0.12, 0.14, y, Vector3(0, y * 0.5, 0), Vector3.ZERO, conc, 10, "Column")
	# Tandhjulsperron: skive + 12 tænder.
	var theme := Node3D.new()
	theme.name = "Theme"
	add_child(theme)
	_into = theme
	_cyl(0.42, 0.42, 0.08, Vector3(0, y - 0.04, 0), Vector3.ZERO, gear_mat, 24, "GearDeck")
	for k in 12:
		var a := TAU * k / 12.0
		_box(Vector3(0.1, 0.08, 0.1), Vector3(sin(a) * 0.46, y - 0.04, cos(a) * 0.46), gear_mat, Vector3(0, rad_to_deg(a), 0), "Tooth%d" % k)
	_cyl(0.1, 0.1, 0.1, Vector3(0, y + 0.01, 0), Vector3.ZERO, metal, 10, "Hub")
	# Stående pyntetandhjul ved siden af + rækværk.
	_cyl(0.22, 0.22, 0.04, Vector3(0.44, y + 0.32, 0.3), Vector3(0, 0, 90), gear_mat, 16, "SideGear")
	for k in 8:
		var a := TAU * k / 8.0
		_box(Vector3(0.05, 0.07, 0.07), Vector3(0.44, y + 0.32 + cos(a) * 0.25, 0.3 + sin(a) * 0.25), gear_mat, Vector3(rad_to_deg(-a), 0, 0), "SideTooth%d" % k)
	for sx: float in [-0.38, 0.38]:
		_box(Vector3(0.03, 0.2, 0.7), Vector3(sx, y + 0.1, 0), metal, Vector3.ZERO, "Railing")
	_box(Vector3(0.08, 0.05, 0.03), Vector3(0, y + 0.02, 0.44), _lamp_mat, Vector3.ZERO, "Lamp")


func set_running(on: bool) -> void:
	running = on


func set_broken(on: bool) -> void:
	broken = on


func set_lights(f: float) -> void:
	lights = clampf(f, 0.0, 1.0)
	if _lamp_mat:
		_lamp_mat.emission_energy_multiplier = 2.5 * lights
