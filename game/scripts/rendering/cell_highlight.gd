class_name CellHighlight
extends MeshInstance3D
## Halvgennemsigtig markering af en celle: groen = gyldig, roed = ugyldig.

const VALID_COLOR := Color(0.3, 0.9, 0.35, 0.45)
const INVALID_COLOR := Color(0.95, 0.25, 0.2, 0.45)

var _material: StandardMaterial3D


func _ready() -> void:
	if mesh == null:
		var plane := PlaneMesh.new()
		plane.size = Vector2(0.96, 0.96)
		mesh = plane
	_material = StandardMaterial3D.new()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.no_depth_test = false
	_material.albedo_color = VALID_COLOR
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false


func show_at(cell: Vector2i, valid: bool) -> void:
	position = Vector3(cell.x + 0.5, 0.02, cell.y + 0.5)
	_material.albedo_color = VALID_COLOR if valid else INVALID_COLOR
	visible = true


func hide_highlight() -> void:
	visible = false
