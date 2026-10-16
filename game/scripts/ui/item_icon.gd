class_name ItemIcon
extends Control
## Tegnet ikon for en bærbar ting (T-089): ballon, souvenir, and, bamse. Ingen glyffer.

var item_id: String = ""


func _init(p_id: String = "", p_size: float = 20.0) -> void:
	item_id = p_id
	custom_minimum_size = Vector2(p_size, p_size)
	tooltip_text = M6Texts.item_name(p_id)


func _draw() -> void:
	var s: Vector2 = size if size.x > 0.0 else custom_minimum_size
	var c: Vector2 = s * 0.5
	var r: float = minf(s.x, s.y) * 0.5
	match item_id:
		"balloon":
			draw_line(c + Vector2(0, r * 0.2), Vector2(c.x, s.y), Color(0.9, 0.9, 0.9), 1.0)
			draw_circle(c - Vector2(0, r * 0.25), r * 0.55, Color(0.95, 0.25, 0.3))
		"souvenir":
			draw_rect(Rect2(s * Vector2(0.2, 0.35), s * Vector2(0.6, 0.5)), Color(0.85, 0.6, 0.25))
			draw_rect(Rect2(s * Vector2(0.45, 0.35), s * Vector2(0.1, 0.5)), Color(0.9, 0.2, 0.2))
			draw_rect(Rect2(s * Vector2(0.2, 0.55), s * Vector2(0.6, 0.08)), Color(0.9, 0.2, 0.2))
		"prize_duck":
			draw_circle(c + Vector2(0, r * 0.25), r * 0.5, Color(1.0, 0.85, 0.2))
			draw_circle(c - Vector2(r * 0.2, r * 0.35), r * 0.3, Color(1.0, 0.85, 0.2))
			draw_colored_polygon(PackedVector2Array([c - Vector2(r * 0.5, r * 0.4), c - Vector2(r * 0.85, r * 0.3),
				c - Vector2(r * 0.5, r * 0.25)]), Color(1.0, 0.5, 0.1))
		"prize_bear":
			var b := Color(0.6, 0.4, 0.25)
			draw_circle(c + Vector2(0, r * 0.3), r * 0.5, b)
			draw_circle(c - Vector2(0, r * 0.3), r * 0.35, b)
			draw_circle(c - Vector2(r * 0.3, r * 0.6), r * 0.15, b)
			draw_circle(c + Vector2(r * 0.3, -r * 0.6), r * 0.15, b)
		_:
			draw_circle(c, r * 0.4, Color(0.8, 0.8, 0.8))
