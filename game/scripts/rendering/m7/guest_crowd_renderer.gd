class_name GuestCrowdRenderer
extends Node3D
## T-107 (ADR-005 §7): Tegner mange gæster billigt. Bridge kalder update(entries, cam_pos)
## med entries = Array[Dictionary] {id:int, pos:Vector3, color:Color}. Renderer vælger de
## (højst MAX_INDIVIDUAL) nærmeste inden for NEAR_DIST som "individuelle" (returneres, så
## bridge kan vise GuestVisual-noder for dem) og tegner resten via MultiMesh.
## T-148: LOD0 bruger præcis samme mesh-dele/offsets/farver som guest.tscn (krop, bukser,
## hoved, hår – én MultiMesh pr. del), så skiftet ikke ses. LOD1 (langt væk): krop + hoved
## med færre segmenter. Instanser er altid oprejste med identitets-basis (ingen skala).
## Buffere allokeres med fast kapacitet + visible_instance_count (at ændre instance_count
## hver frame gav garbage-transforms/strakte kapsler i Compatibility).
## Visuel separation: lane_offset(id) giver 6 baner pr. celle (±0,3), ingen sim-påvirkning.

const MAX_INDIVIDUAL := 120
const NEAR_DIST := 30.0
const LOD1_DIST := 60.0   ## over: LOD1 (forenklet krop + hoved)
const LOD2_DIST := 120.0  ## over: skjult
const LANES := 6
const LANE_SPAN := 0.3

const SKIN := Color(0.96, 0.8, 0.66)
const DENIM := Color(0.25, 0.32, 0.5)
const HAIR := Color(0.35, 0.22, 0.12)

## Del-offsets svarer til guest.tscn (Body y=0.2, Pants = Body-0.12, Head y=0.46, Hair = Head+(0,0.005,-0.004)).
const OFF_BODY := Vector3(0, 0.2, 0)
const OFF_PANTS := Vector3(0, 0.08, 0)
const OFF_HEAD := Vector3(0, 0.46, 0)
const OFF_HAIR := Vector3(0, 0.465, -0.004)

## Hver del: {mi, lod, offset, tinted}. tinted = bruger gæstens farve (instance color).
var _parts: Array[Dictionary] = []
var _counts: PackedInt32Array = PackedInt32Array([0, 0])


func _init() -> void:
	var tinted := StandardMaterial3D.new()
	tinted.vertex_color_use_as_albedo = true
	tinted.roughness = 0.8
	# LOD0 – identisk med guest.tscn
	var body := CapsuleMesh.new()
	body.radius = 0.12
	body.height = 0.4
	body.radial_segments = 10
	body.rings = 3
	var pants := CylinderMesh.new()
	pants.top_radius = 0.123
	pants.bottom_radius = 0.123
	pants.height = 0.14
	pants.radial_segments = 10
	pants.rings = 1
	var head := SphereMesh.new()
	head.radius = 0.08
	head.height = 0.16
	head.radial_segments = 10
	head.rings = 5
	var hair := SphereMesh.new()
	hair.radius = 0.085
	hair.height = 0.085
	hair.radial_segments = 10
	hair.rings = 5
	hair.is_hemisphere = true
	_add_part("Lod0Body", 0, body, OFF_BODY, tinted, true)
	_add_part("Lod0Pants", 0, pants, OFF_PANTS, _flat(DENIM, 0.75), false)
	_add_part("Lod0Head", 0, head, OFF_HEAD, _flat(SKIN, 0.8), false)
	_add_part("Lod0Hair", 0, hair, OFF_HAIR, _flat(HAIR, 0.75), false)
	# LOD1 – samme proportioner, færre segmenter
	var body1 := CapsuleMesh.new()
	body1.radius = 0.12
	body1.height = 0.4
	body1.radial_segments = 6
	body1.rings = 1
	var head1 := SphereMesh.new()
	head1.radius = 0.08
	head1.height = 0.16
	head1.radial_segments = 6
	head1.rings = 3
	_add_part("Lod1Body", 1, body1, OFF_BODY, tinted, true)
	_add_part("Lod1Head", 1, head1, OFF_HEAD, _flat(SKIN, 0.8), false)


static func _flat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _add_part(n: String, lod: int, mesh: Mesh, off: Vector3, mat: Material, tinted: bool) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = tinted
	mm.mesh = mesh
	mm.instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.name = n
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if lod == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_parts.append({"mi": mi, "lod": lod, "offset": off, "tinted": tinted})


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
	var buckets: Array = [[], []]
	for e: Dictionary in entries:
		var p: Vector3 = e["pos"]
		var d2 := p.distance_squared_to(cam_pos)
		if d2 < NEAR_DIST * NEAR_DIST:
			near.append([d2, e])
		elif d2 < LOD1_DIST * LOD1_DIST:
			buckets[0].append(e)
		elif d2 < LOD2_DIST * LOD2_DIST:
			buckets[1].append(e)
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var ids := PackedInt32Array()
	for i in near.size():
		var e: Dictionary = near[i][1]
		if i < MAX_INDIVIDUAL:
			ids.append(int(e["id"]))
		else:
			buckets[0].append(e)
	for l in 2:
		_counts[l] = (buckets[l] as Array).size()
	for part in _parts:
		var list: Array = buckets[part["lod"]]
		var mm: MultiMesh = (part["mi"] as MultiMeshInstance3D).multimesh
		var n := list.size()
		if mm.instance_count < n:
			mm.instance_count = maxi(64, nearest_po2(n))
		mm.visible_instance_count = n
		var off: Vector3 = part["offset"]
		var tinted: bool = part["tinted"]
		for i in n:
			var e: Dictionary = list[i]
			mm.set_instance_transform(i, part_transform(e["pos"], off))
			if tinted:
				mm.set_instance_color(i, e.get("color", Color(0.8, 0.5, 0.4)))
	return ids


## Instans-transform for en del: altid oprejst og uskaleret (T-148).
static func part_transform(pos: Vector3, offset: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY, pos + offset)


## Antal gæster tegnet via MultiMesh (ikke antal del-instanser).
func instanced_count() -> int:
	return _counts[0] + _counts[1]


## Til tests: MultiMesh-instanserne for en del (navn som "Lod0Body").
func part_multimesh(part_name: String) -> MultiMesh:
	var mi := get_node_or_null(part_name) as MultiMeshInstance3D
	return mi.multimesh if mi != null else null
