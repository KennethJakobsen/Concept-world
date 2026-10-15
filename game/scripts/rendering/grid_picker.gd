class_name GridPicker
extends Node
## Omsaetter musens position til en grid-celle via ray mod y=0-planet.

const INVALID := Vector2i(-9999, -9999)


func cell_under_mouse(camera: Camera3D) -> Vector2i:
	if camera == null or not camera.is_inside_tree():
		return INVALID
	var mouse: Vector2 = camera.get_viewport().get_mouse_position()
	var origin: Vector3 = camera.project_ray_origin(mouse)
	var dir: Vector3 = camera.project_ray_normal(mouse)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, dir)
	if hit == null:
		return INVALID
	var p: Vector3 = hit
	return Vector2i(floori(p.x), floori(p.z))
