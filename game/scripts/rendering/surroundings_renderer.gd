class_name SurroundingsRenderer
extends Node3D
## T-108: kosmetiske omgivelser uden for parken (GDD §5).
## Mur (hæk/hegn) med port, et bælte (margin_cells) med græs, træer, marker og vej,
## samt biler/busser på vejen og gæster fra stoppestedet til porten. Ingen sim.
## Brug: add_child(r); r.build(w.width, w.height, w.entrance, SurroundingsRenderer.load_config(theme))
## Alt er MultiMesh/simple meshes og Compatibility-sikkert.

const PARK_JSON: String = "res://content/park.json"
const THEMES: Array[StringName] = [&"countryside", &"river", &"mountain"]
const ROAD_W: float = 3.0
const CAR_COUNT: int = 6
const WALKER_COUNT: int = 10

var config: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _roads: Array[PackedVector2Array] = []
var _fields: Array[Rect2] = []
var _park_rect: Rect2
var _cross_a: Vector2
var _cross_b: Vector2
var _stop_pos: Vector2
var _gate_pos: Vector2
var _cars: Array[Dictionary] = []
var _walkers: Array[Dictionary] = []


## Standardkonfiguration + park.json.surroundings + evt. scenarie-tema. Fallback: countryside.
static func load_config(scenario_theme: String = "") -> Dictionary:
	var cfg: Dictionary = {"wall": "hedge", "margin_cells": 24, "theme": "countryside"}
	if FileAccess.file_exists(PARK_JSON):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PARK_JSON))
		if data is Dictionary and (data as Dictionary).get("surroundings") is Dictionary:
			cfg.merge((data as Dictionary)["surroundings"] as Dictionary, true)
	if scenario_theme != "":
		cfg["theme"] = scenario_theme
	if not THEMES.has(StringName(str(cfg["theme"]))):
		cfg["theme"] = "countryside"
	return cfg


func build(width: int, height: int, entrance: Vector2i, cfg: Dictionary = {}) -> void:
	for c in get_children():
		c.queue_free()
	_cars.clear()
	_walkers.clear()
	_roads.clear()
	_fields.clear()
	config = cfg if not cfg.is_empty() else load_config()
	var margin: int = maxi(4, int(config.get("margin_cells", 24)))
	var theme := StringName(str(config.get("theme", "countryside")))
	_rng.seed = hash(Vector3i(width, height, entrance.x * 1000 + entrance.y))
	_park_rect = Rect2(0, 0, width, height)

	# Udadvendt retning fra indgangen.
	var out := Vector2i(0, 1)
	if entrance.y == 0:
		out = Vector2i(0, -1)
	elif entrance.x == 0:
		out = Vector2i(-1, 0)
	elif entrance.x == width - 1:
		out = Vector2i(1, 0)
	var outf := Vector2(out)
	var side := Vector2(-outf.y, outf.x)
	var ent_c := Vector2(entrance) + Vector2(0.5, 0.5)
	_gate_pos = ent_c + outf * 1.0
	var cross_dist: float = minf(10.0, margin * 0.5)
	var cross_c := ent_c + outf * (cross_dist + 0.5)
	var half_len: float = (width if out.y != 0 else height) * 0.5 + margin
	_cross_a = cross_c - side * half_len
	_cross_b = cross_c + side * half_len
	_roads.append(PackedVector2Array([_gate_pos, cross_c]))
	_roads.append(PackedVector2Array([_cross_a, _cross_b]))
	_stop_pos = cross_c - outf * (ROAD_W * 0.5 + 1.2) + side * 4.0

	_build_ground(width, height, margin, theme)
	_build_fields(width, height, margin)
	if theme == &"river":
		_build_river(width, height, margin, out)
	elif theme == &"mountain":
		_build_mountains(width, height, margin)
	_build_roads()
	_build_wall(width, height, entrance, str(config.get("wall", "hedge")))
	_build_gate(ent_c, outf)
	_build_bus_stop(side)
	_build_trees(width, height, margin, theme)
	_spawn_traffic()
	_spawn_walkers()


# --- Byggesten -------------------------------------------------------------

static func _mat(col: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	return m


func _box(size: Vector3, pos: Vector3, col: Color, parent: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = _mat(col)
	mi.mesh = bm
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _flat(rect: Rect2, y: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = rect.size
	pm.material = _mat(col, 1.0)
	mi.mesh = pm
	mi.position = Vector3(rect.get_center().x, y, rect.get_center().y)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _multimesh(mesh: Mesh, xforms: Array[Transform3D], colors: Array[Color] = []) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _build_ground(w: int, h: int, m: int, theme: StringName) -> void:
	var col := Color(0.38, 0.58, 0.28)
	if theme == &"mountain":
		col = Color(0.42, 0.52, 0.32)
	# Ligger lidt under parkens egen jord for at undgå z-fighting.
	_flat(Rect2(-m, -m, w + 2 * m, h + 2 * m), -0.03, col)


func _blocked(p: Vector2, pad: float) -> bool:
	if _park_rect.grow(1.5 + pad).has_point(p):
		return true
	for seg in _roads:
		if _seg_dist(p, seg[0], seg[1]) < ROAD_W * 0.5 + 0.8 + pad:
			return true
	if p.distance_to(_stop_pos) < 3.0 + pad:
		return true
	return false


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _rand_band_point(w: int, h: int, m: int) -> Vector2:
	return Vector2(_rng.randf_range(-m, w + m), _rng.randf_range(-m, h + m))


func _build_fields(w: int, h: int, m: int) -> void:
	var palette: Array[Color] = [Color(0.78, 0.68, 0.32), Color(0.55, 0.42, 0.26), Color(0.52, 0.66, 0.3)]
	var tries: int = 0
	while _fields.size() < 8 and tries < 200:
		tries += 1
		var sz := Vector2(_rng.randf_range(6, 12), _rng.randf_range(5, 10))
		var c := _rand_band_point(w, h, m)
		var r := Rect2(c - sz * 0.5, sz)
		if not Rect2(-m, -m, w + 2 * m, h + 2 * m).encloses(r):
			continue
		var bad := false
		for corner: Vector2 in [r.position, r.end, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), r.get_center()]:
			if _blocked(corner, 0.5):
				bad = true
		for f in _fields:
			if f.grow(1.0).intersects(r):
				bad = true
		if bad:
			continue
		_fields.append(r)
		var col: Color = palette[_rng.randi() % palette.size()]
		_flat(r, -0.02, col)
		# Furer som tynde striber.
		var rows: int = int(r.size.y / 1.2)
		for i in rows:
			var y: float = r.position.y + 0.6 + i * 1.2
			_flat(Rect2(r.position.x + 0.3, y - 0.12, r.size.x - 0.6, 0.24), -0.015, col.darkened(0.18))


func _build_river(w: int, h: int, m: int, out: Vector2i) -> void:
	# Flod langs siden modsat indgangen (væk fra vejen).
	var water := Color(0.22, 0.45, 0.68)
	var rect: Rect2
	var off: float = m * 0.55
	if out.y != 0:
		var y: float = (-off if out.y > 0 else h + off)
		rect = Rect2(-m, y - 3.0, w + 2 * m, 6.0)
	else:
		var x: float = (-off if out.x > 0 else w + off)
		rect = Rect2(x - 3.0, -m, 6.0, h + 2 * m)
	var mi := _flat(rect, -0.01, water)
	var mat := mi.mesh.surface_get_material(0) as StandardMaterial3D
	mat.roughness = 0.15
	mat.metallic_specular = 0.8
	_fields.append(rect.grow(1.0))


func _build_mountains(w: int, h: int, m: int) -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 7
	cone.rings = 1
	cone.material = _mat(Color(0.5, 0.5, 0.52))
	(cone.material as StandardMaterial3D).vertex_color_use_as_albedo = true
	var xf: Array[Transform3D] = []
	var cols: Array[Color] = []
	# Bjerge i den yderste tredjedel af bæltet.
	for i in 40:
		var p := _rand_band_point(w, h, m)
		if _park_rect.grow(m * 0.65).has_point(p) or _blocked(p, 4.0):
			continue
		var r: float = _rng.randf_range(4.0, 8.0)
		var hgt: float = _rng.randf_range(6.0, 14.0)
		xf.append(Transform3D(Basis.from_scale(Vector3(r, hgt, r)).rotated(Vector3.UP, _rng.randf() * TAU), Vector3(p.x, hgt * 0.5 - 0.05, p.y)))
		cols.append(Color(0.55, 0.53, 0.5).lerp(Color(0.4, 0.42, 0.38), _rng.randf()))
	_multimesh(cone, xf, cols)


func _build_roads() -> void:
	for seg in _roads:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var d := b - a
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(ROAD_W, d.length() + ROAD_W)
		pm.material = _mat(Color(0.26, 0.26, 0.28), 0.95)
		mi.mesh = pm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mid := (a + b) * 0.5
		mi.position = Vector3(mid.x, -0.005, mid.y)
		mi.rotation.y = atan2(d.x, d.y)
		add_child(mi)
	# Midterstriber på tværvejen.
	var xf: Array[Transform3D] = []
	var d2 := _cross_b - _cross_a
	var n: int = int(d2.length() / 3.0)
	var rot := Basis(Vector3.UP, atan2(d2.x, d2.y))
	for i in n:
		var p := _cross_a + d2 * ((i + 0.5) / n)
		xf.append(Transform3D(rot, Vector3(p.x, 0.0, p.y)))
	var stripe := PlaneMesh.new()
	stripe.size = Vector2(0.12, 1.2)
	stripe.material = _mat(Color(0.92, 0.9, 0.8))
	_multimesh(stripe, xf)


func _build_wall(w: int, h: int, entrance: Vector2i, kind: String) -> void:
	var hedge: bool = kind != "fence"
	var mesh := BoxMesh.new()
	if hedge:
		mesh.size = Vector3(1.0, 1.1, 0.6)
		mesh.material = _mat(Color(0.18, 0.4, 0.17))
	else:
		mesh.size = Vector3(1.0, 0.9, 0.08)
		mesh.material = _mat(Color(0.55, 0.4, 0.26))
	var xf: Array[Transform3D] = []
	var e := Vector2(entrance) + Vector2(0.5, 0.5)
	var off: float = 0.35
	# Nord/syd-kanter (x varierer) og vest/øst-kanter (z varierer).
	for x in range(-1, w + 1):
		for z: float in [-off, h + off]:
			var p := Vector2(x + 0.5, z)
			if p.distance_to(e) < 1.6:
				continue
			xf.append(Transform3D(Basis(), Vector3(p.x, mesh.size.y * 0.5, p.y)))
	for y in range(0, h):
		for x: float in [-off, w + off]:
			var p := Vector2(x, y + 0.5)
			if p.distance_to(e) < 1.6:
				continue
			xf.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(p.x, mesh.size.y * 0.5, p.y)))
	_multimesh(mesh, xf)


func _build_gate(ent_c: Vector2, outf: Vector2) -> void:
	var gate := Node3D.new()
	gate.name = "Gate"
	var gp := ent_c + outf * 0.85
	gate.position = Vector3(gp.x, 0.0, gp.y)
	gate.rotation.y = atan2(outf.x, outf.y)
	add_child(gate)
	var stone := Color(0.72, 0.66, 0.56)
	_box(Vector3(0.5, 2.6, 0.5), Vector3(-1.3, 1.3, 0), stone, gate)
	_box(Vector3(0.5, 2.6, 0.5), Vector3(1.3, 1.3, 0), stone, gate)
	_box(Vector3(3.2, 0.45, 0.6), Vector3(0, 2.75, 0), Color(0.75, 0.22, 0.2), gate)
	_box(Vector3(1.6, 0.35, 0.65), Vector3(0, 3.15, 0), Color(0.95, 0.8, 0.3), gate)


func _build_bus_stop(side: Vector2) -> void:
	var stop := Node3D.new()
	stop.name = "BusStop"
	stop.position = Vector3(_stop_pos.x, 0, _stop_pos.y)
	stop.rotation.y = atan2(side.x, side.y)
	add_child(stop)
	_box(Vector3(0.08, 1.8, 0.08), Vector3(-0.8, 0.9, -0.3), Color(0.3, 0.3, 0.32), stop)
	_box(Vector3(0.08, 1.8, 0.08), Vector3(0.8, 0.9, -0.3), Color(0.3, 0.3, 0.32), stop)
	_box(Vector3(1.9, 0.08, 0.9), Vector3(0, 1.84, 0), Color(0.2, 0.45, 0.7), stop)
	_box(Vector3(1.5, 0.08, 0.35), Vector3(0, 0.45, -0.2), Color(0.5, 0.35, 0.22), stop)
	_box(Vector3(0.06, 2.2, 0.06), Vector3(1.3, 1.1, 0.4), Color(0.4, 0.4, 0.42), stop)
	_box(Vector3(0.45, 0.45, 0.05), Vector3(1.3, 2.1, 0.4), Color(0.95, 0.8, 0.2), stop)


func _build_trees(w: int, h: int, m: int, theme: StringName) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.08
	trunk.bottom_radius = 0.12
	trunk.height = 1.0
	trunk.radial_segments = 5
	trunk.rings = 1
	trunk.material = _mat(Color(0.4, 0.27, 0.16))
	var crown := CylinderMesh.new()
	crown.top_radius = 0.0
	crown.bottom_radius = 0.7
	crown.height = 1.8
	crown.radial_segments = 6
	crown.rings = 1
	var cm := _mat(Color(1, 1, 1))
	cm.vertex_color_use_as_albedo = true
	crown.material = cm
	var tx: Array[Transform3D] = []
	var cx: Array[Transform3D] = []
	var cc: Array[Color] = []
	var target: int = int((w + 2 * m) * (h + 2 * m) * 0.012)
	var tries: int = 0
	while tx.size() < target and tries < target * 6:
		tries += 1
		var p := _rand_band_point(w, h, m)
		if _blocked(p, 0.0):
			continue
		var in_field := false
		for f in _fields:
			if f.has_point(p):
				in_field = true
				break
		if in_field:
			continue
		var s: float = _rng.randf_range(0.8, 1.5)
		var yaw: float = _rng.randf() * TAU
		tx.append(Transform3D(Basis.from_scale(Vector3(s, s * 0.8, s)), Vector3(p.x, s * 0.4, p.y)))
		cx.append(Transform3D(Basis.from_scale(Vector3.ONE * s).rotated(Vector3.UP, yaw), Vector3(p.x, s * (0.8 + 0.9), p.y)))
		var g := Color(0.16, 0.42, 0.18) if theme != &"mountain" else Color(0.12, 0.32, 0.2)
		cc.append(g.lerp(Color(0.3, 0.5, 0.2), _rng.randf() * 0.6))
	_multimesh(trunk, tx)
	_multimesh(crown, cx, cc)


# --- Kosmetisk trafik ------------------------------------------------------

func _spawn_traffic() -> void:
	var len: float = _cross_a.distance_to(_cross_b)
	var palette: Array[Color] = [Color(0.8, 0.2, 0.2), Color(0.2, 0.4, 0.8), Color(0.9, 0.9, 0.9), Color(0.2, 0.6, 0.3), Color(0.15, 0.15, 0.17)]
	for i in CAR_COUNT:
		var bus: bool = i % 3 == 0
		var body := Node3D.new()
		add_child(body)
		if bus:
			_box(Vector3(1.1, 1.2, 3.6), Vector3(0, 0.75, 0), Color(0.95, 0.75, 0.15), body)
			_box(Vector3(1.12, 0.35, 3.0), Vector3(0, 1.0, 0.1), Color(0.2, 0.25, 0.3), body)
		else:
			_box(Vector3(0.8, 0.45, 1.6), Vector3(0, 0.38, 0), palette[_rng.randi() % palette.size()], body)
			_box(Vector3(0.7, 0.35, 0.8), Vector3(0, 0.75, -0.1), Color(0.25, 0.3, 0.35), body)
		_cars.append({"node": body, "t": _rng.randf() * len, "dir": 1 if i % 2 == 0 else -1,
			"speed": (4.0 if bus else _rng.randf_range(5.0, 8.0)), "len": len, "bus": bus, "wait": 0.0})


func _spawn_walkers() -> void:
	var cap := CapsuleMesh.new()
	cap.radius = 0.13
	cap.height = 0.7
	var cols: Array[Color] = [Color(0.85, 0.3, 0.3), Color(0.3, 0.5, 0.85), Color(0.95, 0.8, 0.3), Color(0.4, 0.7, 0.4), Color(0.7, 0.4, 0.8)]
	for i in WALKER_COUNT:
		var mi := MeshInstance3D.new()
		mi.mesh = cap
		mi.material_override = _mat(cols[i % cols.size()])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_walkers.append({"node": mi, "t": float(i) / WALKER_COUNT, "speed": _rng.randf_range(0.9, 1.3), "lane": _rng.randf_range(-0.6, 0.6)})


func _process(delta: float) -> void:
	if _cars.is_empty() and _walkers.is_empty():
		return
	var d := _cross_b - _cross_a
	var dn := d.normalized()
	var perp := Vector2(-dn.y, dn.x)
	for car in _cars:
		var node := car["node"] as Node3D
		var len: float = car["len"]
		var dir: int = car["dir"]
		if float(car["wait"]) > 0.0:
			car["wait"] = float(car["wait"]) - delta
		else:
			var prev: float = car["t"]
			car["t"] = fposmod(prev + float(car["speed"]) * delta, len)
			# Busser holder kort ved stoppestedet.
			if car["bus"]:
				var stop_t: float = (_stop_pos - _cross_a).dot(dn)
				if dir < 0:
					stop_t = len - stop_t
				if prev < stop_t and float(car["t"]) >= stop_t:
					car["wait"] = 3.0
		var t: float = car["t"] if dir > 0 else len - float(car["t"])
		var p := _cross_a + dn * t + perp * (ROAD_W * 0.25 * dir)
		node.position = Vector3(p.x, 0, p.y)
		node.rotation.y = atan2(dn.x * dir, dn.y * dir)
	var path_len: float = _stop_pos.distance_to(_gate_pos) + 0.001
	for wk in _walkers:
		wk["t"] = fposmod(float(wk["t"]) + float(wk["speed"]) * delta / path_len, 1.0)
		var tt: float = wk["t"]
		var a := _stop_pos
		var b := _gate_pos
		var dir2 := (b - a).normalized()
		var side2 := Vector2(-dir2.y, dir2.x) * float(wk["lane"])
		var p2 := a.lerp(b, tt) + side2
		var node2 := wk["node"] as Node3D
		var bob: float = absf(sin(tt * path_len * 6.0)) * 0.05
		node2.position = Vector3(p2.x, 0.35 + bob, p2.y)
		node2.visible = tt > 0.02 and tt < 0.97
