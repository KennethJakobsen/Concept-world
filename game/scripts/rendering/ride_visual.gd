class_name RideVisual
extends Node3D
## Faelles visuel adfaerd for forlystelser (duck-typed API jf. M4-kontrakt §3):
## set_running(bool), set_broken(bool), set_lights(f).
## Spinnere (Spinner-noder) accelererer/decelererer blødt. Pariserhjulets kabiner
## (Wheel/Cab*) kontra-roteres, saa de altid haenger lodret.

const ACCEL: float = 0.6  ## andel af fuld fart pr. sekund
const BROKEN_TILT_DEG: float = 4.0  ## synlig, men ikke absurd haeldning ved nedbrud
const BULB_COUNT: int = 12
const BULB_COLORS: Array[Color] = [Color(1.0, 0.85, 0.4), Color(1.0, 0.45, 0.35), Color(0.5, 0.8, 1.0)]

var running: bool = true
var broken: bool = false
var lights: float = 0.0
var _speed: float = 1.0
var _spinners: Array[Spinner] = []
var _cabs: Array[Node3D] = []
var _wheel: Node3D = null
var _bulb_mats: Array[StandardMaterial3D] = []
var _bulbs: Node3D = null
var _blink_t: float = 0.0
var _bob_node: Node3D = null
var _bob_base: float = 0.0


func _ready() -> void:
	_collect(self)
	_wheel = get_node_or_null("Wheel") as Node3D
	if _wheel:
		for c in _wheel.get_children():
			if c is Node3D and String(c.name).begins_with("Cab"):
				_cabs.append(c)
	_bob_node = get_node_or_null("Ghost") as Node3D
	if _bob_node:
		_bob_base = _bob_node.position.y
	_build_bulbs()
	_apply_speed()
	set_lights(lights)


func _collect(n: Node) -> void:
	for c in n.get_children():
		if c is Spinner:
			_spinners.append(c)
		_collect(c)


func set_running(on: bool) -> void:
	running = on


func set_broken(on: bool) -> void:
	broken = on
	if on:
		_speed = 0.0
		_apply_speed()
	rotation.z = deg_to_rad(BROKEN_TILT_DEG) if on else 0.0
	set_lights(lights)


func set_lights(f: float) -> void:
	lights = clampf(f, 0.0, 1.0)
	for i in _bulb_mats.size():
		var m := _bulb_mats[i]
		var e := lights
		if broken:
			e *= 0.15
		m.emission_energy_multiplier = 0.05 + e * 2.5
		m.albedo_color = BULB_COLORS[i % BULB_COLORS.size()].darkened(0.5 * (1.0 - e))


func _process(delta: float) -> void:
	var target := 1.0 if running and not broken else 0.0
	if not is_equal_approx(_speed, target):
		_speed = move_toward(_speed, target, ACCEL * delta)
		_apply_speed()
	if _wheel:
		var inv := _wheel.transform.basis.orthonormalized().inverse()
		for c in _cabs:
			c.transform.basis = inv
	if _bob_node:
		_blink_t += delta * _speed
		_bob_node.position.y = _bob_base + sin(_blink_t * 2.0) * 0.15
	if broken and not _bulb_mats.is_empty():
		_blink_t += delta
		var on := fmod(_blink_t, 0.8) < 0.4
		for m in _bulb_mats:
			m.emission_energy_multiplier = 1.5 if on else 0.05
			m.albedo_color = Color(1.0, 0.3, 0.2) if on else Color(0.3, 0.1, 0.1)


func _apply_speed() -> void:
	for s in _spinners:
		s.speed_scale = _speed


## Proceduralt lyskæde-ring rundt om forlystelsens top (emissive, ingen lys-noder).
func _build_bulbs() -> void:
	var box := _local_aabb(self, Transform3D.IDENTITY)
	if box.size == Vector3.ZERO:
		return
	_bulbs = Node3D.new()
	_bulbs.name = "Bulbs"
	add_child(_bulbs)
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	mesh.radial_segments = 6
	mesh.rings = 3
	for k in BULB_COLORS.size():
		var m := StandardMaterial3D.new()
		m.emission_enabled = true
		m.emission = BULB_COLORS[k]
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_bulb_mats.append(m)
	var y := box.end.y * 0.6 if box.end.y > 1.5 else box.end.y + 0.05
	var cx := box.get_center().x
	var cz := box.get_center().z
	var rx := box.size.x * 0.5 + 0.05
	var rz := box.size.z * 0.5 + 0.05
	for i in BULB_COUNT:
		var a := TAU * float(i) / float(BULB_COUNT)
		var b := MeshInstance3D.new()
		b.mesh = mesh
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		b.material_override = _bulb_mats[i % _bulb_mats.size()]
		b.position = Vector3(cx + cos(a) * rx, y, cz + sin(a) * rz)
		_bulbs.add_child(b)


func _local_aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	for c in n.get_children():
		if not c is Node3D:
			continue
		var cxf: Transform3D = xf * (c as Node3D).transform
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			var bb: AABB = cxf * (c as MeshInstance3D).mesh.get_aabb()
			out = bb if first else out.merge(bb)
			first = false
		var sub := _local_aabb(c, cxf)
		if sub.size != Vector3.ZERO:
			out = sub if first else out.merge(sub)
			first = false
	return out
