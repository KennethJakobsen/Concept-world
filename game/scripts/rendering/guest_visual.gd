class_name GuestVisual
extends Node3D
## Placeholder-gaest. Farve saettes via set_color().

@onready var _body: MeshInstance3D = $Body


func _ready() -> void:
	if _body.material_override == null:
		set_color(Color.from_hsv(randf(), 0.55, 0.9))


func set_color(c: Color) -> void:
	if _body == null:
		_body = $Body
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.8
	_body.material_override = mat
