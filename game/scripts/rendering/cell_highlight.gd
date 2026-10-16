class_name CellHighlight
extends MeshInstance3D
## Halvgennemsigtig markering af en celle. Farver fra ParkColors (grøn/rød eller blå/orange).
## I farveblind-tilstand tegnes desuden et form-signal: flueben (gyldig) eller kryds (ugyldig).

const VALID_COLOR := Color(0.3, 0.9, 0.35, 0.45)  # bagudkompatibel; brug ParkColors
const INVALID_COLOR := Color(0.95, 0.25, 0.2, 0.45)

var _material: StandardMaterial3D
var _check: MeshInstance3D
var _cross: MeshInstance3D


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
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1, 1, 1)
	_check = _shape([[Vector2(-0.25, 0.0), Vector2(-0.08, 0.18)], [Vector2(-0.08, 0.18), Vector2(0.28, -0.2)]], smat)
	_cross = _shape([[Vector2(-0.22, -0.22), Vector2(0.22, 0.22)], [Vector2(-0.22, 0.22), Vector2(0.22, -0.22)]], smat)


## Flade streger (bokse) i cellens plan; procedurel, virker i Compatibility.
func _shape(segs: Array, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := 0.06
	for seg in segs:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var n := (b - a).normalized().orthogonal() * w
		var q := [a + n, b + n, b - n, a - n]
		for idx in [0, 1, 2, 0, 2, 3]:
			var v: Vector2 = q[idx]
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(v.x, 0.01, v.y))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	return mi


func show_at(cell: Vector2i, valid: bool) -> void:
	position = Vector3(cell.x + 0.5, 0.02, cell.y + 0.5)
	_material.albedo_color = ParkColors.ghost(valid)
	_check.visible = ParkColors.colorblind and valid
	_cross.visible = ParkColors.colorblind and not valid
	visible = true


func hide_highlight() -> void:
	visible = false
