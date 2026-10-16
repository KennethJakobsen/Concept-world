class_name CoasterTrackMesh
extends MeshInstance3D
## T-069: Procedurel rutsjebanebane (M5-kontrakt §5, ADR-003).
## Input er rene Dictionaries `{def_id, cell, heading, level}` + defs fra
## `content/coaster/pieces.json` (id -> {turn, rise, kind, ...}); ingen sim-afhængighed.
## Konvention: cellemidte = (x+0.5, 0, y+0.5), 1 niveau = 1,0 m,
## heading 0=N(-z), 1=Ø(+x), 2=S(+z), 3=V(-x). Et stykke går fra cellens bagkant
## til forkanten (lige) eller sidekanten (kurve, kvartcirkel r = 0,5).
## Hele banen bygges som én sammenhængende polylinje, så der ikke er huller ved samlinger.

const PIECES_PATH := "res://content/coaster/pieces.json"
const TRACKS_DIR := "res://content/tracks/"
const TRACK_SYSTEMS: Array[String] = ["flume", "train", "monorail"]
const WATER_SHADER := preload("res://shaders/flume_water.gdshader")
const SAMPLES := 8
const GAUGE := 0.17          ## halv sporvidde (m)
const RAIL_W := 0.05
const RAIL_H := 0.06
const RAIL_Y := 0.10         ## skinnetop over centerlinjen
const TIE_HALF := 0.27
const TIE_W := 0.07
const TIE_H := 0.05
const LEG_W := 0.07
const LEG_SPREAD := 0.24

const FLUME_HALF := 0.25
const FLUME_FLOOR_Y := -0.02
const FLUME_WALL_H := 0.24
const WATER_Y := 0.09
const TRAIN_GAUGE := 0.12
const MONO_BEAM_W := 0.18
const MONO_BEAM_H := 0.3

const DEFAULT_DEFS := {
	"track_straight": {"id": "track_straight", "cost": 40, "length": 1.0, "turn": 0, "rise": 0, "kind": "track"},
	"track_turn_left": {"id": "track_turn_left", "cost": 50, "length": 0.785, "turn": -1, "rise": 0, "kind": "track"},
	"track_turn_right": {"id": "track_turn_right", "cost": 50, "length": 0.785, "turn": 1, "rise": 0, "kind": "track"},
	"track_up": {"id": "track_up", "cost": 60, "length": 1.414, "turn": 0, "rise": 1, "kind": "track"},
	"track_down": {"id": "track_down", "cost": 60, "length": 1.414, "turn": 0, "rise": -1, "kind": "track"},
	"track_lift_up": {"id": "track_lift_up", "cost": 90, "length": 1.414, "turn": 0, "rise": 1, "kind": "lift"},
	"coaster_station": {"id": "coaster_station", "cost": 300, "length": 1.0, "turn": 0, "rise": 0, "kind": "station"},
}

const DIRS: Array[Vector3] = [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]

static var _mat_rail: Material
static var _mat_wood: Material
static var _mat_chain: StandardMaterial3D
static var _mat_water: ShaderMaterial
static var _mat_concrete: StandardMaterial3D
static var _mat_ballast: Material

var _ghost_mat: StandardMaterial3D = null


## Indlæser stykke-defs fra pieces.json + tracks/<system>.json (T-092, ADR-004);
## falder tilbage til DEFAULT_DEFS. Hver def får "system" (default fra filen).
static func load_defs() -> Dictionary:
	var out: Dictionary = DEFAULT_DEFS.duplicate(true)
	_merge_file(out, PIECES_PATH, "coaster")
	for sys: String in TRACK_SYSTEMS:
		_merge_file(out, TRACKS_DIR + sys + ".json", sys)
	return out


static func _merge_file(out: Dictionary, path: String, sys: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var arr: Array = []
	if data is Array:
		arr = data
	elif data is Dictionary and (data as Dictionary).get("pieces") is Array:
		arr = data["pieces"]
	for d: Variant in arr:
		if d is Dictionary and d.has("id"):
			var dd: Dictionary = (d as Dictionary).duplicate()
			if not dd.has("system"):
				dd["system"] = sys
			out[String(dd["id"])] = dd


## Banens system (første stykkes def; "coaster" som default).
static func system_of(pieces: Array, defs: Dictionary) -> StringName:
	if pieces.is_empty():
		return &"coaster"
	return StringName(String(_def_for(pieces[0], defs).get("system", "coaster")))


static func heading_dir(h: int) -> Vector3:
	return DIRS[posmod(h, 4)]


static func _cell_of(piece: Dictionary) -> Vector2i:
	var c: Variant = piece.get("cell", Vector2i.ZERO)
	if c is Vector2i:
		return c
	if c is Vector2:
		return Vector2i(c)
	if c is Array and (c as Array).size() >= 2:
		return Vector2i(int(c[0]), int(c[1]))
	return Vector2i.ZERO


static func _horiz_len(def: Dictionary) -> float:
	return PI * 0.25 if int(def.get("turn", 0)) != 0 else 1.0


## Centerlinje i verdenskoordinater med lineær højde (samme model som simulationen).
static func centerline(piece: Dictionary, def: Dictionary, samples: int = SAMPLES) -> PackedVector3Array:
	var r := float(def.get("rise", 0)) / _horiz_len(def)
	return _centerline_slopes(piece, def, samples, r, r)


## Centerlinje med givne hældninger (dh/ds) ved ind- og udgang (kubisk Hermite).
## Endepunkterne er altid præcis på niveauhøjderne, så samlinger matcher.
static func _centerline_slopes(piece: Dictionary, def: Dictionary, samples: int, m0: float, m1: float) -> PackedVector3Array:
	var n := maxi(samples, 1)
	var h := int(piece.get("heading", 0))
	var lvl := float(piece.get("level", 0))
	var rise := float(def.get("rise", 0))
	var turn := int(def.get("turn", 0))
	var cell := _cell_of(piece)
	var center := Vector3(cell.x + 0.5, 0.0, cell.y + 0.5)
	var d := heading_dir(h)
	var L := _horiz_len(def)
	var pts := PackedVector3Array()
	pts.resize(n + 1)
	for i in n + 1:
		var t := float(i) / n
		var p: Vector3
		if turn == 0:
			p = center + d * (t - 0.5)
		else:
			var d2 := heading_dir(h + turn)
			var corner := center - d * 0.5 + d2 * 0.5
			var a := t * PI * 0.5
			p = corner - d2 * (0.5 * cos(a)) + d * (0.5 * sin(a))
		var t2 := t * t
		var t3 := t2 * t
		var y := (2 * t3 - 3 * t2 + 1) * lvl + (t3 - 2 * t2 + t) * L * m0 \
			+ (-2 * t3 + 3 * t2) * (lvl + rise) + (t3 - t2) * L * m1
		p.y = y
		pts[i] = p
	# Eksakte endepunkter (undgå afrundingsstøj ved samlinger).
	pts[0].y = lvl
	pts[n].y = lvl + rise
	return pts


## Hele banens centerlinje som én polylinje med glatte hældningsovergange.
## `piece_index` (valgfri ud-parameter) får stykke-indekset for hvert punkt.
static func full_centerline(pieces: Array, defs: Dictionary, samples: int = SAMPLES, piece_index: PackedInt32Array = PackedInt32Array()) -> PackedVector3Array:
	var out := PackedVector3Array()
	piece_index.clear()
	var cnt := pieces.size()
	if cnt == 0:
		return out
	var slopes: Array[float] = []
	for p: Dictionary in pieces:
		var df := _def_for(p, defs)
		slopes.append(float(df.get("rise", 0)) / _horiz_len(df))
	var closed := cnt > 2 and _is_closed(pieces, defs)
	for i in cnt:
		var p: Dictionary = pieces[i]
		var df := _def_for(p, defs)
		var s := slopes[i]
		var m0 := s
		var m1 := s
		if i > 0 or closed:
			m0 = (s + slopes[posmod(i - 1, cnt)]) * 0.5
		if i < cnt - 1 or closed:
			m1 = (s + slopes[(i + 1) % cnt]) * 0.5
		var seg := _centerline_slopes(p, df, samples, m0, m1)
		var start := 0 if out.is_empty() else 1
		for k in range(start, seg.size()):
			out.append(seg[k])
			piece_index.append(i)
	return out


static func _def_for(piece: Dictionary, defs: Dictionary) -> Dictionary:
	var id := String(piece.get("def_id", "track_straight"))
	if defs.has(id):
		return defs[id]
	return DEFAULT_DEFS.get(id, DEFAULT_DEFS["track_straight"])


static func _is_closed(pieces: Array, defs: Dictionary) -> bool:
	var first: Array = centerline(pieces[0], _def_for(pieces[0], defs), 1)
	var last: Array = centerline(pieces[-1], _def_for(pieces[-1], defs), 1)
	return (last[-1] as Vector3).distance_to(first[0]) < 1e-3


## Kumulativ buelængde for en polylinje.
static func arc_lengths(line: PackedVector3Array) -> PackedFloat32Array:
	var acc := PackedFloat32Array()
	acc.resize(line.size())
	var s := 0.0
	for i in line.size():
		if i > 0:
			s += line[i].distance_to(line[i - 1])
		acc[i] = s
	return acc


## Transform ved buelængde s (wrapper ved lukket bane). Lokal -Z peger fremad.
static func pose_at(line: PackedVector3Array, acc: PackedFloat32Array, s: float) -> Transform3D:
	if line.size() < 2:
		return Transform3D()
	var total := acc[acc.size() - 1]
	var ss := fposmod(s, total) if total > 0.0 else 0.0
	var lo := 0
	var hi := acc.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if acc[mid] <= ss:
			lo = mid
		else:
			hi = mid
	var seg := maxf(acc[hi] - acc[lo], 1e-6)
	var t := clampf((ss - acc[lo]) / seg, 0.0, 1.0)
	var p := line[lo].lerp(line[hi], t)
	var fwd := (line[hi] - line[lo]).normalized()
	return Transform3D(_basis_for(fwd), p)


static func _basis_for(fwd: Vector3) -> Basis:
	var right := fwd.cross(Vector3.UP)
	if right.length_squared() < 1e-6:
		right = Vector3.RIGHT
	right = right.normalized()
	var up := right.cross(fwd).normalized()
	return Basis(right, up, -fwd)


static func _materials() -> void:
	if _mat_rail != null:
		return
	_mat_rail = load("res://assets/materials/steel.tres")
	_mat_wood = load("res://assets/materials/wood.tres")
	_mat_chain = StandardMaterial3D.new()
	_mat_chain.albedo_color = Color(0.16, 0.16, 0.18)
	_mat_chain.roughness = 0.6
	_mat_water = ShaderMaterial.new()
	_mat_water.shader = WATER_SHADER
	_mat_concrete = StandardMaterial3D.new()
	_mat_concrete.albedo_color = Color(0.72, 0.71, 0.68)
	_mat_concrete.albedo_texture = load("res://assets/textures/plaster.png")
	_mat_concrete.uv1_triplanar = true
	_mat_concrete.roughness = 0.9
	_mat_ballast = load("res://assets/materials/path_stone.tres")


## Bygger meshet. Kald kun ved ændring. Dispatcher på system (ADR-004 §5).
func build(pieces: Array, defs: Dictionary) -> void:
	_materials()
	var idx := PackedInt32Array()
	var line := full_centerline(pieces, defs, SAMPLES, idx)
	if line.size() < 2:
		mesh = null
		return
	var closed := pieces.size() > 2 and _is_closed(pieces, defs)
	var frames := _frames(line, closed)
	match system_of(pieces, defs):
		&"flume":
			mesh = _build_flume(pieces, defs, line, frames)
		&"train":
			mesh = _build_train(line, frames, closed)
		&"monorail":
			mesh = _build_monorail(pieces, defs, line, frames)
		_:
			mesh = _build_coaster(pieces, defs, line, frames, idx, closed)
	_apply_ghost()


## Frames pr. punkt (gennemsnitlig tangent ved samlinger -> ingen huller).
static func _frames(line: PackedVector3Array, closed: bool) -> Array[Basis]:
	var n := line.size()
	var frames: Array[Basis] = []
	for i in n:
		var a := line[i - 1] if i > 0 else (line[n - 2] if closed else line[i])
		var b := line[i + 1] if i < n - 1 else (line[1] if closed else line[i])
		frames.append(_basis_for((b - a).normalized()))
	if closed:
		frames[n - 1] = frames[0]
	return frames


func _build_coaster(pieces: Array, defs: Dictionary, line: PackedVector3Array, frames: Array[Basis], idx: PackedInt32Array, closed: bool) -> ArrayMesh:
	var n := line.size()
	var am := ArrayMesh.new()
	# Skinner (2 stk) + rygbjælke under midten.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-GAUGE, GAUGE]:
		_sweep_box(st, line, frames, Vector2(side, RAIL_Y - RAIL_H * 0.5), Vector2(RAIL_W, RAIL_H))
	st.generate_normals()
	st.commit(am)
	am.surface_set_material(am.get_surface_count() - 1, _mat_rail)

	# Sveller + støtteben (træ).
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		if i % 2 == 1 or (closed and i == n - 1):
			continue
		var bs := frames[i]
		var c := line[i] + bs.y * (RAIL_Y - RAIL_H - TIE_H * 0.5)
		_box(st, c, bs.x * TIE_HALF, bs.y * (TIE_H * 0.5), bs.z * (TIE_W * 0.5))
	var seen := {}
	for pi in pieces.size():
		var p: Dictionary = pieces[pi]
		var cell := _cell_of(p)
		var mid := centerline(p, _def_for(p, defs), 2)[1]
		var top := mid.y + RAIL_Y - RAIL_H - TIE_H
		if top < 0.25:
			continue
		var key := Vector3i(cell.x, cell.y, int(round(top * 4)))
		if seen.has(key):
			continue
		seen[key] = true
		var fwd := (centerline(p, _def_for(p, defs), 2)[2] - centerline(p, _def_for(p, defs), 2)[0])
		fwd.y = 0
		var side := fwd.normalized().cross(Vector3.UP).normalized()
		for sgn: float in [-1.0, 1.0]:
			var base := Vector3(mid.x, 0.0, mid.z) + side * (LEG_SPREAD * sgn)
			_box(st, base + Vector3(0, top * 0.5, 0), Vector3(LEG_W * 0.5, 0, 0), Vector3(0, top * 0.5, 0), Vector3(0, 0, LEG_W * 0.5))
		# Tværbjælke under sporet.
		_box(st, Vector3(mid.x, top - 0.04, mid.z), side * (LEG_SPREAD + LEG_W * 0.5), Vector3(0, 0.04, 0), fwd.normalized() * (LEG_W * 0.5))
	st.generate_normals()
	st.commit(am)
	am.surface_set_material(am.get_surface_count() - 1, _mat_wood)

	# Kæde på lift-stykker.
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any_chain := false
	var start := -1
	for i in n + 1:
		var is_lift := i < n and String(_def_for(pieces[idx[i]], defs).get("kind", "track")) == "lift"
		if is_lift and start < 0:
			start = maxi(i - 1, 0) if i > 0 and idx[i - 1] != idx[i] else i
		elif not is_lift and start >= 0:
			var sub := line.slice(start, i)
			var fr := frames.slice(start, i)
			if sub.size() >= 2:
				_sweep_box(st, sub, fr, Vector2(0.0, RAIL_Y - 0.035), Vector2(0.06, 0.03))
				any_chain = true
			start = -1
	if any_chain:
		st.generate_normals()
		st.commit(am)
		am.surface_set_material(am.get_surface_count() - 1, _mat_chain)
	return am


## Flume (T-092): trug af træ (bund + to vægge), vandoverflade og træben.
func _build_flume(pieces: Array, defs: Dictionary, line: PackedVector3Array, frames: Array[Basis]) -> ArrayMesh:
	var am := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_sweep_box(st, line, frames, Vector2(0.0, FLUME_FLOOR_Y - 0.03), Vector2(FLUME_HALF * 2.0 + 0.06, 0.06))
	for side: float in [-FLUME_HALF, FLUME_HALF]:
		_sweep_box(st, line, frames, Vector2(side, FLUME_FLOOR_Y + FLUME_WALL_H * 0.5), Vector2(0.05, FLUME_WALL_H))
	_legs(st, pieces, defs, -FLUME_FLOOR_Y + 0.06, 0.24, 0.07)
	st.generate_normals()
	st.commit(am)
	am.surface_set_material(am.get_surface_count() - 1, _mat_wood)
	# Vand: én strimmel med UV (x på tværs, y = buelængde).
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var acc := arc_lengths(line)
	var hw := FLUME_HALF - 0.03
	for i in line.size() - 1:
		var b0 := frames[i]
		var b1 := frames[i + 1]
		var a0 := line[i] + b0.y * WATER_Y - b0.x * hw
		var a1 := line[i] + b0.y * WATER_Y + b0.x * hw
		var e0 := line[i + 1] + b1.y * WATER_Y - b1.x * hw
		var e1 := line[i + 1] + b1.y * WATER_Y + b1.x * hw
		var v0 := acc[i]
		var v1 := acc[i + 1]
		var up := b0.y
		for t: Array in [[a0, 0.0, v0], [e1, 1.0, v1], [a1, 1.0, v0], [a0, 0.0, v0], [e0, 0.0, v1], [e1, 1.0, v1]]:
			st.set_normal(up)
			st.set_uv(Vector2(t[1], t[2]))
			st.add_vertex(t[0])
	st.commit(am)
	am.surface_set_material(am.get_surface_count() - 1, _mat_water)
	return am


## Train (T-092): to skinner med sveller på et grusleje (jordniveau).
func _build_train(line: PackedVector3Array, frames: Array[Basis], closed: bool) -> ArrayMesh:
	var am := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-TRAIN_GAUGE, TRAIN_GAUGE]:
		_sweep_box(st, line, frames, Vector2(side, 0.065), Vector2(0.035, 0.04))
	st.generate_normals()
	st.commit(am)
	am.surface_set_material(am.get_surface_count() - 1, _mat_rail)
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := line.size()
	for i in n:
		if closed and i == n - 1:
			continue
		var bs := frames[i]
		_box(st, line[i] + bs.y * 0.03, bs.x * 0.2, bs.y * 0.015, bs.z * 0.035)
	st.generate_normals()
	st.commit(am)
	am.surface_set_material(am.get_surface_count() - 1, _mat_wood)
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_sweep_box(st, line, frames, Vector2(0.0, 0.008), Vector2(0.5, 0.016))
	st.generate_normals()
	st.commit(am)
	am.surface_set_material(am.get_surface_count() - 1, _mat_ballast)
	return am


## Monorail (T-092): betonbjælke under centerlinjen på søjler med T-hoved.
func _build_monorail(pieces: Array, defs: Dictionary, line: PackedVector3Array, frames: Array[Basis]) -> ArrayMesh:
	var am := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_sweep_box(st, line, frames, Vector2(0.0, -MONO_BEAM_H * 0.5), Vector2(MONO_BEAM_W, MONO_BEAM_H))
	var seen := {}
	for p: Dictionary in pieces:
		var cl := centerline(p, _def_for(p, defs), 2)
		var mid := cl[1]
		var top := mid.y - MONO_BEAM_H
		var cell := _cell_of(p)
		if top < 0.1 or seen.has(cell):
			continue
		seen[cell] = true
		var fwd := cl[2] - cl[0]
		fwd.y = 0.0
		fwd = fwd.normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		var base := Vector3(mid.x, 0.0, mid.z)
		_box(st, base + Vector3(0, top * 0.5, 0), side * 0.07, Vector3(0, top * 0.5, 0), fwd * 0.07)
		_box(st, base + Vector3(0, top - 0.05, 0), side * 0.16, Vector3(0, 0.05, 0), fwd * 0.1)
		_box(st, base + Vector3(0, 0.04, 0), side * 0.16, Vector3(0, 0.04, 0), fwd * 0.16)
	st.generate_normals()
	st.commit(am)
	am.surface_set_material(am.get_surface_count() - 1, _mat_concrete)
	return am


## To ben pr. hævet stykke (én gang pr. celle/højde) + tværbjælke.
static func _legs(st: SurfaceTool, pieces: Array, defs: Dictionary, below: float, spread: float, w: float) -> void:
	var seen := {}
	for p: Dictionary in pieces:
		var cl := centerline(p, _def_for(p, defs), 2)
		var mid := cl[1]
		var top := mid.y - below
		if top < 0.2:
			continue
		var cell := _cell_of(p)
		var key := Vector3i(cell.x, cell.y, int(round(top * 4)))
		if seen.has(key):
			continue
		seen[key] = true
		var fwd := cl[2] - cl[0]
		fwd.y = 0.0
		fwd = fwd.normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		for sgn: float in [-1.0, 1.0]:
			var base := Vector3(mid.x, 0.0, mid.z) + side * (spread * sgn)
			_box(st, base + Vector3(0, top * 0.5, 0), Vector3(w * 0.5, 0, 0), Vector3(0, top * 0.5, 0), Vector3(0, 0, w * 0.5))
		_box(st, Vector3(mid.x, top - 0.04, mid.z), side * (spread + w * 0.5), Vector3(0, 0.04, 0), fwd * (w * 0.5))


## Halvgennemsigtig grøn (ok) / rød preview-variant.
func set_ghost(ok: bool) -> void:
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_mat.albedo_color = Color(0.3, 0.95, 0.4, 0.45) if ok else Color(1.0, 0.3, 0.25, 0.45)
	_ghost_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_apply_ghost()


func clear_ghost() -> void:
	_ghost_mat = null
	material_override = null


func _apply_ghost() -> void:
	material_override = _ghost_mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if _ghost_mat else GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func triangle_count() -> int:
	if mesh == null:
		return 0
	var t := 0
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		t += (ix.size() if ix.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return t


## Fejer et rektangulært tværsnit (offset i frame-x/y, størrelse) langs polylinjen (4 sider, ingen ender).
static func _sweep_box(st: SurfaceTool, line: PackedVector3Array, frames: Array, off: Vector2, size: Vector2) -> void:
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	var corners: Array[Vector2] = [Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)]
	for i in line.size() - 1:
		var b0: Basis = frames[i]
		var b1: Basis = frames[i + 1]
		for k in 4:
			var c0 := corners[k] + off
			var c1 := corners[(k + 1) % 4] + off
			var a0 := line[i] + b0.x * c0.x + b0.y * c0.y
			var a1 := line[i] + b0.x * c1.x + b0.y * c1.y
			var e0 := line[i + 1] + b1.x * c0.x + b1.y * c0.y
			var e1 := line[i + 1] + b1.x * c1.x + b1.y * c1.y
			_quad(st, a0, a1, e1, e0, (line[i] + line[i + 1]) * 0.5 + (b0.x * off.x + b0.y * off.y))


## Kasse med centrum c og halve akser ax, ay, az (5 sider: bunden udelades).
static func _box(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, az: Vector3) -> void:
	var v := func(sx: float, sy: float, sz: float) -> Vector3: return c + ax * sx + ay * sy + az * sz
	_quad(st, v.call(-1, 1, -1), v.call(1, 1, -1), v.call(1, 1, 1), v.call(-1, 1, 1), c)
	_quad(st, v.call(-1, -1, 1), v.call(1, -1, 1), v.call(1, 1, 1), v.call(-1, 1, 1), c)
	_quad(st, v.call(1, -1, -1), v.call(-1, -1, -1), v.call(-1, 1, -1), v.call(1, 1, -1), c)
	_quad(st, v.call(1, -1, 1), v.call(1, -1, -1), v.call(1, 1, -1), v.call(1, 1, 1), c)
	_quad(st, v.call(-1, -1, -1), v.call(-1, -1, 1), v.call(-1, 1, 1), v.call(-1, 1, -1), c)


## Firkant a-b-c-d; vindingen vælges, så fladen vender væk fra `inside`
## (Godot: Plane(a,b,c)-normalen = forside).
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	var ctr := (a + b + c + d) * 0.25
	var nrm := (a - c).cross(a - b)
	if nrm.dot(ctr - inside) < 0.0:
		var t := b
		b = d
		d = t
	st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
	st.add_vertex(a); st.add_vertex(c); st.add_vertex(d)
