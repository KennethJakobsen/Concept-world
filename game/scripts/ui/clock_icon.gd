class_name ClockIcon
extends Control
## Tegnet sol/måne-ikon (ingen font-glyffer).

@export var night: bool = false:
	set(v):
		if v != night:
			night = v
			queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(18, 18)


func _draw() -> void:
	if UiIcons.sync_texture(self, "clock_night" if night else "clock_day"):
		return
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5
	if night:
		draw_circle(c, r * 0.75, Color(0.92, 0.92, 0.8))
		draw_circle(c + Vector2(r * 0.35, -r * 0.25), r * 0.62, Color(0.12, 0.14, 0.25))
	else:
		var col := Color(1.0, 0.82, 0.2)
		draw_circle(c, r * 0.5, col)
		for i in 8:
			var d: Vector2 = Vector2.RIGHT.rotated(TAU * i / 8.0)
			draw_line(c + d * r * 0.65, c + d * r * 0.98, col, 2.0)
