class_name PersonAnim
extends RefCounted
## Billig procedurel figur-animation (ingen AnimationPlayer): gå-cyklus som bob +
## vippen af kroppen, samt korte emotes. Ejeren kalder step(delta) fra _process og
## slår processing fra, naar is_idle() er sand.

const EMOTE_TIME: float = 1.2
const EMOTE_COLORS := {
	&"happy": Color(1.0, 0.85, 0.2),
	&"angry": Color(0.95, 0.2, 0.15),
	&"sick": Color(0.45, 0.8, 0.25),
	&"sweep": Color(0.75, 0.6, 0.4),
	&"repair": Color(0.6, 0.65, 0.75),
}

var walking: bool = false
var emote: StringName = &""
var bob_height: float = 0.05
var bob_speed: float = 10.0
var _root: Node3D
var _parts: Array[Node3D] = []
var _base: Array[Transform3D] = []
var _t: float = 0.0
var _et: float = 0.0
var _icon: MeshInstance3D = null
static var _icon_mesh: SphereMesh = null


func _init(root: Node3D, parts: Array[Node3D]) -> void:
	_root = root
	_parts = parts
	for p in parts:
		_base.append(p.transform)


func is_idle() -> bool:
	return not walking and emote == &""


func set_walking(on: bool) -> void:
	walking = on
	if not on and emote == &"":
		_reset()


func play_emote(kind: StringName) -> void:
	if not EMOTE_COLORS.has(kind):
		push_warning("PersonAnim: ukendt emote %s" % kind)
		return
	emote = kind
	_et = 0.0
	if _icon == null:
		if _icon_mesh == null:
			_icon_mesh = SphereMesh.new()
			_icon_mesh.radius = 0.07
			_icon_mesh.height = 0.14
			_icon_mesh.radial_segments = 6
			_icon_mesh.rings = 3
		_icon = MeshInstance3D.new()
		_icon.mesh = _icon_mesh
		_icon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_root.add_child(_icon)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = EMOTE_COLORS[kind]
	_icon.material_override = m
	_icon.visible = true


func step(delta: float) -> void:
	var y := 0.0
	var tilt := 0.0
	var yaw := 0.0
	if walking:
		_t += delta * bob_speed
		y = absf(sin(_t)) * bob_height
		tilt = sin(_t) * 0.08
	if emote != &"":
		_et += delta
		var k := _et / EMOTE_TIME
		match emote:
			&"happy":
				y += absf(sin(k * TAU * 2.0)) * 0.18
			&"angry":
				yaw = sin(_et * 40.0) * 0.12
			&"sick":
				tilt += sin(_et * 6.0) * 0.2
			&"sweep":
				yaw = sin(_et * 9.0) * 0.5
			&"repair":
				tilt += absf(sin(_et * 14.0)) * 0.3
		if _icon:
			_icon.position = Vector3(0, 0.95 + k * 0.2, 0)
			_icon.scale = Vector3.ONE * (1.0 - absf(k * 2.0 - 1.0) * 0.4)
		if k >= 1.0:
			emote = &""
			if _icon:
				_icon.visible = false
	var rot := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tilt)
	for i in _parts.size():
		var b := _base[i]
		_parts[i].transform = Transform3D(rot * b.basis, rot * b.origin + Vector3(0, y, 0))
	if is_idle():
		_reset()


func _reset() -> void:
	for i in _parts.size():
		_parts[i].transform = _base[i]
