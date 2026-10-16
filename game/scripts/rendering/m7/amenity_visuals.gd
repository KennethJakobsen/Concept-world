class_name AmenityVisuals
extends RefCounted
## T-107: Hjælpere til spand-fyldniveau og siddende gæst. Ingen state.

static var _fill_mat: StandardMaterial3D
static var _icon_mat: StandardMaterial3D


## level 0/1/2 (= 0/50/100 %). Tilføjer/opdaterer "Fill"-mesh og et rødt fuld-ikon over spanden.
static func set_bin_level(bin: Node3D, level: int) -> void:
	if _fill_mat == null:
		_fill_mat = StandardMaterial3D.new()
		_fill_mat.albedo_color = Color(0.5, 0.42, 0.3)
		_icon_mat = StandardMaterial3D.new()
		_icon_mat.albedo_color = Color(0.95, 0.2, 0.15)
		_icon_mat.emission_enabled = true
		_icon_mat.emission = Color(0.9, 0.15, 0.1)
		_icon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_icon_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var can := bin.get_node_or_null("Can") as Node3D
	var base := can.position if can != null else Vector3(0, 0.175, 0)
	var fill := bin.get_node_or_null("Fill") as MeshInstance3D
	if fill == null:
		fill = MeshInstance3D.new()
		fill.name = "Fill"
		var m := SphereMesh.new()
		m.radius = 0.11
		m.height = 0.12
		m.radial_segments = 8
		m.rings = 3
		m.material = _fill_mat
		fill.mesh = m
		bin.add_child(fill)
	fill.visible = level >= 1
	fill.position = base + Vector3(0, 0.2 + (0.05 if level >= 2 else -0.03), 0)
	var icon := bin.get_node_or_null("FullIcon") as MeshInstance3D
	if icon == null:
		icon = MeshInstance3D.new()
		icon.name = "FullIcon"
		var q := QuadMesh.new()
		q.size = Vector2(0.22, 0.22)
		q.material = _icon_mat
		icon.mesh = q
		icon.visibility_range_end = 40.0
		bin.add_child(icon)
	icon.visible = level >= 2
	icon.position = base + Vector3(0, 0.6, 0)


## Lokal position på bænk for plads seat (0/1). Bænkens lokale x-akse er langs sædet.
static func bench_seat_position(seat: int) -> Vector3:
	return Vector3(-0.2 if seat == 0 else 0.2, 0.28, 0.0)


## Sætter/rejser en GuestVisual (sænket, bøjet fremad, stopper gang).
static func set_guest_seated(guest: Node3D, seated: bool) -> void:
	if guest.has_method("set_walking"):
		guest.call("set_walking", false)
	var body := guest.get_node_or_null("Body") as Node3D
	if body == null:
		return
	if seated:
		guest.set_meta("seated", true)
		body.scale = Vector3(1, 0.7, 1)
	else:
		guest.remove_meta("seated")
		body.scale = Vector3.ONE
