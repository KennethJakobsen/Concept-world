class_name ParkCamera
extends Node3D
## RTS-kamera: WASD/pile flytter, Q/E roterer, scroll zoomer.

@export var move_speed: float = 20.0
@export var rotate_speed: float = 1.5
@export var min_distance: float = 8.0
@export var max_distance: float = 60.0

@onready var _camera: Camera3D = $Camera3D
var _distance: float = 25.0


func _ready() -> void:
	_apply_distance()


func _process(delta: float) -> void:
	var input := Vector2(
		Input.get_axis(&"ui_left", &"ui_right"),
		Input.get_axis(&"ui_up", &"ui_down"))
	var dir := (transform.basis * Vector3(input.x, 0.0, input.y))
	dir.y = 0.0
	position += dir.normalized() * move_speed * delta if dir.length() > 0.0 else Vector3.ZERO
	if Input.is_key_pressed(KEY_Q):
		rotate_y(rotate_speed * delta)
	if Input.is_key_pressed(KEY_E):
		rotate_y(-rotate_speed * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(min_distance, _distance * 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(max_distance, _distance * 1.1)
		_apply_distance()


func _apply_distance() -> void:
	_camera.position = Vector3(0.0, _distance * 0.8, _distance * 0.6)
	_camera.look_at(global_position)
