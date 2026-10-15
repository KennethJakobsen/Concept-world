class_name StaffVisual
extends Node3D
## Personale-figur. Samme rod-API som GuestVisual (set_color) + gå/hop-hook.

@export var bob_height: float = 0.05
@export var bob_speed: float = 10.0

var walking: bool = false
var _t: float = 0.0
@onready var _figure: Node3D = $Figure


func set_color(c: Color) -> void:
	var body: MeshInstance3D = get_node("Figure/Body")
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.8
	body.material_override = mat


func set_walking(on: bool) -> void:
	walking = on
	if not on and _figure:
		_figure.position.y = 0.0


## Lille enkelt-hop (fx når en opgave er løst).
func hop() -> void:
	if _figure == null:
		return
	var tw := create_tween()
	tw.tween_property(_figure, "position:y", 0.15, 0.12)
	tw.tween_property(_figure, "position:y", 0.0, 0.12)


func _process(delta: float) -> void:
	if walking:
		_t += delta * bob_speed
		_figure.position.y = absf(sin(_t)) * bob_height
