class_name TutorialArrow
extends Node3D
## T-115: hoppende pil i verden over en celle (tutorial-highlight).

const HEIGHT: float = 2.2
var _t: float = 0.0
var _base: Vector3 = Vector3.ZERO


func _ready() -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.35
	cone.bottom_radius = 0.0
	cone.height = 0.7
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.82, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = cone
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	visible = false


func point_at(cell: Vector2i) -> void:
	visible = cell.x >= 0
	if visible:
		_base = Vector3(cell.x + 0.5, HEIGHT, cell.y + 0.5)
		position = _base


func _process(delta: float) -> void:
	if visible:
		_t += delta
		position = _base + Vector3(0.0, sin(_t * 4.0) * 0.25, 0.0)
