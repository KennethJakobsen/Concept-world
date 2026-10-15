class_name Spinner
extends Node3D
## Roterer noden om Y-aksen (fx karrusellens top).

@export var speed: float = 0.8


func _process(delta: float) -> void:
	rotate_y(speed * delta)
