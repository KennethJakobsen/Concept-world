class_name QueuePathVisual
extends Node3D
## T-107: Køsti-flise. Rødlig belægning + kædestolper/rækværk på de sider, der IKKE er forbundet.
## set_connections(mask): bit 0=N(-z) 1=E(+x) 2=S(+z) 3=W(-x). Forbundne sider er åbne.
## Alle meshes er procedurelle og deles statisk (Compatibility-sikkert).

const N := 1
const E := 2
const S := 4
const W := 8
const POST_H := 0.55

static var _tile_mesh: BoxMesh
static var _post_mesh: CylinderMesh
static var _cap_mesh: SphereMesh
static var _rope_mesh: CylinderMesh

var connections: int = 0
var _parts: Node3D


func _init() -> void:
	_ensure_meshes()
	var t := MeshInstance3D.new()
	t.name = "Tile"
	t.mesh = _tile_mesh
	t.position.y = 0.03
	add_child(t)
	_parts = Node3D.new()
	_parts.name = "Rails"
	add_child(_parts)
	set_connections(0)


static func _ensure_meshes() -> void:
	if _tile_mesh != null:
		return
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.72, 0.5, 0.42)
	tm.roughness = 0.9
	_tile_mesh = BoxMesh.new()
	_tile_mesh.size = Vector3(1.0, 0.06, 1.0)
	_tile_mesh.material = tm
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.82, 0.68, 0.25)
	pm.metallic = 0.5
	pm.roughness = 0.4
	_post_mesh = CylinderMesh.new()
	_post_mesh.top_radius = 0.03
	_post_mesh.bottom_radius = 0.035
	_post_mesh.height = POST_H
	_post_mesh.radial_segments = 6
	_post_mesh.rings = 1
	_post_mesh.material = pm
	_cap_mesh = SphereMesh.new()
	_cap_mesh.radius = 0.045
	_cap_mesh.height = 0.09
	_cap_mesh.radial_segments = 6
	_cap_mesh.rings = 3
	_cap_mesh.material = pm
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.75, 0.12, 0.14)
	rm.roughness = 0.6
	_rope_mesh = CylinderMesh.new()
	_rope_mesh.top_radius = 0.018
	_rope_mesh.bottom_radius = 0.018
	_rope_mesh.height = 1.0
	_rope_mesh.radial_segments = 5
	_rope_mesh.rings = 1
	_rope_mesh.material = rm


## Mask ud fra naboer: has_neighbor(dir: Vector2i) -> bool. Hjælper til bridge.
static func mask_from(cell: Vector2i, is_connected: Callable) -> int:
	var m := 0
	if is_connected.call(cell + Vector2i(0, -1)): m |= N
	if is_connected.call(cell + Vector2i(1, 0)): m |= E
	if is_connected.call(cell + Vector2i(0, 1)): m |= S
	if is_connected.call(cell + Vector2i(-1, 0)): m |= W
	return m


func set_connections(mask: int) -> void:
	connections = mask & 15
	for c in _parts.get_children():
		c.queue_free()
		_parts.remove_child(c)
	const H := 0.42
	# Sider: [bit, a, b] (hjørner i xz)
	var sides := [
		[N, Vector2(-H, -H), Vector2(H, -H)],
		[E, Vector2(H, -H), Vector2(H, H)],
		[S, Vector2(-H, H), Vector2(H, H)],
		[W, Vector2(-H, -H), Vector2(-H, H)],
	]
	var posts := {}
	for sd: Array in sides:
		if connections & int(sd[0]):
			continue
		var a: Vector2 = sd[1]
		var b: Vector2 = sd[2]
		posts[a] = true
		posts[b] = true
		_add_rope(a, b, POST_H - 0.08, 0.06)
		_add_rope(a, b, POST_H * 0.5, 0.0)
	# Stolper ved hjørner mellem to forbundne sider (indre hjørner) så åbne forløb stadig ses.
	for c: Vector2 in [Vector2(-H, -H), Vector2(H, -H), Vector2(H, H), Vector2(-H, H)]:
		posts[c] = true
	for p: Vector2 in posts:
		var post := MeshInstance3D.new()
		post.mesh = _post_mesh
		post.position = Vector3(p.x, 0.06 + POST_H * 0.5, p.y)
		_parts.add_child(post)
		var cap := MeshInstance3D.new()
		cap.mesh = _cap_mesh
		cap.position = Vector3(p.x, 0.06 + POST_H + 0.02, p.y)
		_parts.add_child(cap)


func _add_rope(a: Vector2, b: Vector2, y: float, sag: float) -> void:
	# To segmenter giver et let hæng i kæden.
	var mid := (a + b) * 0.5
	var y0 := 0.06 + y
	var pts := [Vector3(a.x, y0, a.y), Vector3(mid.x, y0 - sag, mid.y), Vector3(b.x, y0, b.y)]
	for i in 2:
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var r := MeshInstance3D.new()
		r.mesh = _rope_mesh
		var d := p1 - p0
		var up := d.normalized()
		var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
		var fwd := side.cross(up)
		r.transform = Transform3D(Basis(side, up * d.length(), fwd), (p0 + p1) * 0.5)
		_parts.add_child(r)
