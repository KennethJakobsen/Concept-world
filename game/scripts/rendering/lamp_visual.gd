class_name LampVisual
extends Node3D
## Gadelampe. Lyset er slukket som default; set_on() til dag/nat.

@export var on_color: Color = Color(1.0, 0.85, 0.55)
var is_on: bool = false


func _ready() -> void:
	set_on(is_on)


func set_on(on: bool) -> void:
	is_on = on
	var light := get_node("Light") as OmniLight3D
	light.visible = on
	var bulb := get_node("Bulb") as MeshInstance3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = on_color if on else Color(0.8, 0.8, 0.75)
	if on:
		mat.emission_enabled = true
		mat.emission = on_color
		mat.emission_energy_multiplier = 1.5
	bulb.material_override = mat
