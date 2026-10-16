class_name GuestCrowdRenderer
extends Node3D
## T-107 (ADR-005 §7): Tegner mange gæster billigt. Bridge kalder update(entries, cam_pos)
## med entries = Array[Dictionary] {id:int, pos:Vector3, color:Color}. Renderer vælger de
## (højst MAX_INDIVIDUAL) nærmeste inden for NEAR_DIST som "individuelle" (returneres, så
## bridge kan vise GuestVisual-noder for dem) og tegner resten via MultiMesh i 3 LOD-niveauer.
## Visuel separation: lane_offset(id) giver 6 baner pr. celle (±0,3), ingen sim-påvirkning.

const MAX_INDIVIDUAL := 120
const NEAR_DIST := 18.0
const LOD1_DIST := 40.0   ## over: LOD2 (billboard-agtig kasse)
const LOD2_DIST := 90.0   ## over: skjult
const LANES := 6
const LANE_SPAN := 0.3

var _mm: Array[MultiMeshInstance3D] = []


func _init() -> void:
	var meshes: Array[Mesh] = []
	var cap := CapsuleMesh.new()
	cap.radius = 0.12
	cap.height = 0.55
	cap.radial_segments = 8
	cap.rings = 2
	meshes.append(cap)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.13
	cyl.height = 0.55
	cyl.radial_segments = 5
	cyl.rings = 1
	meshes.append(cyl)
	var box := BoxMesh.new()
	box.size = Vector3(0.22, 0.55, 0.22)
	meshes.append(box)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	for i in 3:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = meshes[i]
		mm.instance_count = 0
		var mi := MultiMeshInstance3D.new()
		mi.name = "Lod%d" % i
		mi.multimesh = mm
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if i > 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mi)
		_mm.append(mi)


## Deterministisk sideforskydning (lokal, i celle-enheder) ud fra gæste-id.
static func lane_offset(guest_id: int) -> float:
	var lane := posmod(guest_id * 7 + 3, LANES)
	return -LANE_SPAN + (2.0 * LANE_SPAN) * float(lane) / float(LANES - 1)


## Forskyder pos vinkelret på gåretningen dir (xz). dir = ZERO -> lille diagonal spredning.
static func separate(pos: Vector3, dir: Vector3, guest_id: int) -> Vector3:
	var off := lane_offset(guest_id)
	var d := Vector3(dir.x, 0, dir.z)
	if d.length_squared() < 0.0001:
		var a := float(posmod(guest_id * 2654435761, 360)) * PI / 180.0
		return pos + Vector3(cos(a), 0, sin(a)) * absf(off)
	d = d.normalized()
	return pos + Vector3(-d.z, 0, d.x) * off


## Returnerer id'erne der skal vises som individuelle GuestVisual-noder.
func update(entries: Array, cam_pos: Vector3) -> PackedInt32Array:
	var near: Array = []
	var buckets: Array = [[], [], []]
	for e: Dictionary in entries:
		var p: Vector3 = e["pos"]
		var d2 := p.distance_squared_to(cam_pos)
		if d2 < NEAR_DIST * NEAR_DIST:
			near.append([d2, e])
		elif d2 < LOD1_DIST * LOD1_DIST:
			buckets[0].append(e)
		elif d2 < LOD2_DIST * LOD2_DIST:
			buckets[1 if d2 < 60.0 * 60.0 else 2].append(e)
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var ids := PackedInt32Array()
	for i in near.size():
		var e: Dictionary = near[i][1]
		if i < MAX_INDIVIDUAL:
			ids.append(int(e["id"]))
		else:
			buckets[0].append(e)
	for l in 3:
		var mm := _mm[l].multimesh
		var list: Array = buckets[l]
		mm.instance_count = list.size()
		for i in list.size():
			var e: Dictionary = list[i]
			var p: Vector3 = e["pos"]
			mm.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, 0.3, 0)))
			mm.set_instance_color(i, e.get("color", Color(0.8, 0.5, 0.4)))
	return ids


func instanced_count() -> int:
	var n := 0
	for mi in _mm:
		n += mi.multimesh.instance_count
	return n
