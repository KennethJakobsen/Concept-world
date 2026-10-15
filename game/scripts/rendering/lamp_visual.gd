class_name LampVisual
extends Node3D
## Gadelampe. Lyset er slukket som default; set_on()/set_intensity() til dag/nat.
## Kun de MAX_LIT lamper naermest kameraet faar et aktivt (skyggeløst) OmniLight3D;
## resten er emissive-only (se update_lod, kaldes af DayNightRig).

const MAX_LIT: int = 8
static var _all: Array[LampVisual] = []

@export var on_color: Color = Color(1.0, 0.85, 0.55)
@export var max_energy: float = 1.6
var is_on: bool = false
var intensity: float = 0.0
var lod_lit: bool = true
var _mat: StandardMaterial3D


func _enter_tree() -> void:
	_all.append(self)


func _exit_tree() -> void:
	_all.erase(self)


func _ready() -> void:
	var light := get_node("Light") as OmniLight3D
	light.shadow_enabled = false
	set_intensity(intensity)


func set_on(on: bool) -> void:
	set_intensity(1.0 if on else 0.0)


func set_intensity(f: float) -> void:
	intensity = clampf(f, 0.0, 1.0)
	is_on = intensity > 0.01
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.emission_enabled = true
		_mat.emission = on_color
		(get_node("Bulb") as MeshInstance3D).material_override = _mat
	_mat.albedo_color = Color(0.8, 0.8, 0.75).lerp(on_color, intensity)
	_mat.emission_energy_multiplier = intensity * 2.0
	_refresh_light()


func _refresh_light() -> void:
	var light := get_node("Light") as OmniLight3D
	light.visible = is_on and lod_lit
	light.light_energy = max_energy * intensity


## Taender OmniLight kun for de MAX_LIT taendte lamper naermest cam_pos.
static func update_lod(cam_pos: Vector3) -> void:
	var lit: Array[LampVisual] = []
	for l in _all:
		if l.is_on and l.is_inside_tree():
			lit.append(l)
	lit.sort_custom(func(a: LampVisual, b: LampVisual) -> bool:
		return a.global_position.distance_squared_to(cam_pos) < b.global_position.distance_squared_to(cam_pos))
	for i in lit.size():
		var want := i < MAX_LIT
		if lit[i].lod_lit != want:
			lit[i].lod_lit = want
			lit[i]._refresh_light()


static func lamp_count() -> int:
	return _all.size()
