class_name ParkCamera
extends Node3D
## RTS-kamera: WASD/pile flytter, Q/E roterer, scroll zoomer.

@export var move_speed: float = 20.0
@export var rotate_speed: float = 1.5
@export var min_distance: float = 8.0
@export var max_distance: float = 80.0
## T-135: XZ-grænse for kamerafokus (tom = ingen grænse). Sættes af ParkView inkl. omgivelsesbæltet.
var bounds: Rect2 = Rect2()

@onready var _camera: Camera3D = $Camera3D
var _distance: float = 25.0


func _ready() -> void:
	_apply_distance()


func _process(delta: float) -> void:
	var input := Vector2(
		Input.get_axis(&"cam_left", &"cam_right"),
		Input.get_axis(&"cam_forward", &"cam_back"))  # forward = -Z (væk fra seeren)
	var dir := (transform.basis * Vector3(input.x, 0.0, input.y))
	dir.y = 0.0
	position += dir.normalized() * move_speed * delta if dir.length() > 0.0 else Vector3.ZERO
	if bounds.has_area():
		position.x = clampf(position.x, bounds.position.x, bounds.end.x)
		position.z = clampf(position.z, bounds.position.y, bounds.end.y)
	if Input.is_action_pressed(&"cam_rotate_left"):
		rotate_y(rotate_speed * delta)
	if Input.is_action_pressed(&"cam_rotate_right"):
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


func set_bounds(r: Rect2) -> void:
	bounds = r
