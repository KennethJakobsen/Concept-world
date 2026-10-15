class_name Spinner
extends Node3D
## Roterer noden om en lokal akse (default Y, fx karrusellens top; Z for pariserhjul).

@export var speed: float = 0.8
@export var axis: Vector3 = Vector3.UP


func _process(delta: float) -> void:
	rotate_object_local(axis.normalized(), speed * delta)
