class_name Spinner
extends Node3D
## Roterer noden om en lokal akse (default Y, fx karrusellens top; Z for pariserhjul).
## speed_scale (0..1) styres af RideVisual for blød acceleration/deceleration.

@export var speed: float = 0.8
@export var axis: Vector3 = Vector3.UP
var speed_scale: float = 1.0


func _process(delta: float) -> void:
	if speed_scale > 0.0001:
		rotate_object_local(axis.normalized(), speed * speed_scale * delta)
