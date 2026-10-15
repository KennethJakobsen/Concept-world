class_name StarRating
extends Control
## Tegner 0..5 stjerner for value 0..100 (halve stjerner via clipping). Ingen font-afhængighed.

const STARS: int = 5

@export var value: float = 0.0:
	set(v):
		value = clampf(v, 0.0, 100.0)
		queue_redraw()
@export var star_size: float = 16.0
@export var spacing: float = 2.0
@export var fill_color: Color = Color(1.0, 0.8, 0.2)
@export var empty_color: Color = Color(1, 1, 1, 0.25)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_minimum_size() -> Vector2:
	return Vector2(STARS * star_size + (STARS - 1) * spacing, star_size)


## Antal udfyldte stjerner, afrundet til nærmeste halve.
func filled() -> float:
	return roundf(value / 100.0 * STARS * 2.0) / 2.0


static func star_points(center: Vector2, r_outer: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var r: float = r_outer if i % 2 == 0 else r_outer * 0.45
		var a: float = -PI / 2.0 + i * PI / 5.0
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


## Klipper polygonen til x <= max_x (venstre del – til halve stjerner).
static func clip_left(pts: PackedVector2Array, max_x: float) -> PackedVector2Array:
	var box := PackedVector2Array([Vector2(-1e6, -1e6), Vector2(max_x, -1e6), Vector2(max_x, 1e6), Vector2(-1e6, 1e6)])
	var res: Array[PackedVector2Array] = Geometry2D.intersect_polygons(pts, box)
	return res[0] if not res.is_empty() else PackedVector2Array()


func _draw() -> void:
	var f: float = filled()
	var y: float = size.y * 0.5
	for i in STARS:
		var c := Vector2(i * (star_size + spacing) + star_size * 0.5, y)
		var pts: PackedVector2Array = star_points(c, star_size * 0.5)
		draw_colored_polygon(pts, empty_color)
		if f >= i + 1:
			draw_colored_polygon(pts, fill_color)
		elif f > i:
			var half: PackedVector2Array = clip_left(pts, c.x)
			if half.size() >= 3:
				draw_colored_polygon(half, fill_color)
