class_name RideVisual
extends Node3D
## Faelles visuel adfaerd for forlystelser (duck-typed API jf. M4-kontrakt §3):
## set_running(bool), set_broken(bool), set_lights(f).
## Spinnere (Spinner-noder) accelererer/decelererer blødt. Pariserhjulets kabiner
## (Wheel/Cab*) kontra-roteres, saa de altid haenger lodret.

const ACCEL: float = 0.6  ## andel af fuld fart pr. sekund
const BROKEN_TILT_DEG: float = 4.0  ## synlig, men ikke absurd haeldning ved nedbrud
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


## T-062: lyskæden sidder på faktiske kanter (tagkant, hegn, portal) pr. forlystelse.
## Nøgle = rodnodens navn; værdi = stier til MeshInstance3D'er, hvis kant pærerne følger.
const BULB_ANCHORS: Dictionary = {
	"BumperCars": ["RoofTrim"],
	"Carousel": ["Top/Rim"],
	"FerrisWheel": ["Wheel/RimA", "Wheel/RimB"],
	"GoKarts": ["Banner", "Wall0", "Wall1", "Wall2", "Wall3", "Wall4"],
	"HauntedHouse": ["Eaves"],
	"SwingRide": ["Top/Canopy"],
	# T-083 (M6)
	"BouncyCastle": ["Castle/WallBack", "Castle/WallL", "Castle/WallR"],
	"Teacups": ["Platter/Disc"],
	"SkyRings": ["Beam"],
	"PirateShip": ["Base"],
	"SpaceRocket": ["Base"],
	"DropTower": ["Pad"],
	"SouvenirShop": ["AwnTrim"],
	# T-099: boder får lyskæden på markisekanten i stedet for fallback (øverste mesh).
	"FriesStand": ["AwnTrim"],
	"CoffeeStand": ["AwnTrim"],
	"BalloonStand": ["CartTop"],
	"CoconutShy": ["AwnTrim"],
	"ShootingGallery": ["AwnTrim"],
	"HookADuck": ["PoolRim"],
	"StrengthTester": ["Platform"],
}
const BULB_SPACING: float = 0.35
const BULB_MIN: int = 8
const BULB_MAX: int = 28


## Proceduralt lyskæde langs ankermeshenes kanter (emissive, ingen lys-noder).
## Pærerne lægges under ankerets forælder, så de følger med, når den roterer.
func _build_bulbs() -> void:
	var anchors: Array[MeshInstance3D] = []
	for path: String in BULB_ANCHORS.get(String(name), []):
		var mi := get_node_or_null(path) as MeshInstance3D
		if mi and mi.mesh:
			anchors.append(mi)
	if anchors.is_empty():
		var top := _top_mesh(self)
		if top == null:
			return
		anchors.append(top)
	var paths: Array = []
	var total := 0.0
	for mi in anchors:
		var pts := _edge_path(mi)
		paths.append(pts)
		total += _path_len(pts)
	if total <= 0.0:
		return
	var count := clampi(roundi(total / BULB_SPACING), BULB_MIN, BULB_MAX)
	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	mesh.radial_segments = 6
	mesh.rings = 3
	for k in BULB_COLORS.size():
		var m := StandardMaterial3D.new()
		m.emission_enabled = true
		m.emission = BULB_COLORS[k]
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_bulb_mats.append(m)
	var idx := 0
	for a in anchors.size():
		var mi := anchors[a]
		var pts: PackedVector3Array = paths[a]
		var length := _path_len(pts)
		var n := maxi(1, roundi(float(count) * length / total))
		var holder := mi.get_parent().get_node_or_null("Bulbs") as Node3D
		if holder == null:
			holder = Node3D.new()
			holder.name = "Bulbs"
			mi.get_parent().add_child(holder)
			if _bulbs == null:
				_bulbs = holder
		var closed := pts[0].is_equal_approx(pts[pts.size() - 1])
		for i in n:
			var t := (float(i) / float(n)) if closed else ((float(i) + 0.5) / float(n))
			var b := MeshInstance3D.new()
			b.mesh = mesh
			b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			b.material_override = _bulb_mats[idx % _bulb_mats.size()]
			b.position = mi.transform * _sample(pts, t * length)
			holder.add_child(b)
			idx += 1


## Kantforløb i meshets lokale rum: ring (torus/cylinder), top-rektangel eller top-linje (boks).
func _edge_path(mi: MeshInstance3D) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var m := mi.mesh
	if m is TorusMesh or m is CylinderMesh:
		var r: float
		var y := 0.0
		if m is TorusMesh:
			r = (m as TorusMesh).outer_radius
		else:
			var c := m as CylinderMesh
			r = maxf(c.top_radius, c.bottom_radius)
			y = c.height * (0.5 if c.top_radius >= c.bottom_radius else -0.5)
		for i in 33:
			var a := TAU * float(i) / 32.0
			pts.append(Vector3(cos(a) * r, y, sin(a) * r))
		return pts
	var bb := m.get_aabb()
	var y := bb.end.y
	if bb.size.z < 0.2 and bb.size.x >= bb.size.z:
		var z := bb.get_center().z
		pts.append(Vector3(bb.position.x, y, z))
		pts.append(Vector3(bb.end.x, y, z))
	elif bb.size.x < 0.2:
		var x := bb.get_center().x
		pts.append(Vector3(x, y, bb.position.z))
		pts.append(Vector3(x, y, bb.end.z))
	else:
		pts.append(Vector3(bb.position.x, y, bb.position.z))
		pts.append(Vector3(bb.end.x, y, bb.position.z))
		pts.append(Vector3(bb.end.x, y, bb.end.z))
		pts.append(Vector3(bb.position.x, y, bb.end.z))
		pts.append(Vector3(bb.position.x, y, bb.position.z))
	return pts


func _path_len(pts: PackedVector3Array) -> float:
	var l := 0.0
	for i in range(1, pts.size()):
		l += pts[i - 1].distance_to(pts[i])
	return l


func _sample(pts: PackedVector3Array, d: float) -> Vector3:
	for i in range(1, pts.size()):
		var seg := pts[i - 1].distance_to(pts[i])
		if d <= seg and seg > 0.0:
			return pts[i - 1].lerp(pts[i], d / seg)
		d -= seg
	return pts[pts.size() - 1]


## Fallback for ukendte forlystelser: øverste direkte mesh.
func _top_mesh(n: Node) -> MeshInstance3D:
	var best: MeshInstance3D = null
	var best_y := -INF
	for c in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			var mi := c as MeshInstance3D
			var top := (mi.transform * mi.mesh.get_aabb()).end.y
			if top > best_y:
				best_y = top
				best = mi
	return best


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
