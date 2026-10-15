class_name UiIcons
extends Control
## Små tegnede ikoner (ingen glyffer): "lock", "check", "cross" og banestykker ("piece:<id>").

@export var kind: String = "check"
@export var color: Color = Color(1, 1, 1)
var piece_turn: int = 0
var piece_rise: int = 0
var piece_kind: String = "track"


func _init(p_kind: String = "check", p_size: float = 16.0) -> void:
	kind = p_kind
	custom_minimum_size = Vector2(p_size, p_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func piece_icon(def: TrackPieceDef, p_size: float = 28.0) -> UiIcons:
	var i := UiIcons.new("piece", p_size)
	if def != null:
		i.piece_turn = def.turn
		i.piece_rise = def.rise
		i.piece_kind = def.kind
	return i


func _draw() -> void:
	var s: Vector2 = size if size.x > 0.0 else custom_minimum_size
	match kind:
		"lock":
			draw_lock(self, Rect2(Vector2.ZERO, s), color)
		"check":
			draw_polyline(PackedVector2Array([s * Vector2(0.15, 0.55), s * Vector2(0.4, 0.8), s * Vector2(0.85, 0.2)]),
				Color(0.3, 0.9, 0.3), maxf(2.0, s.x * 0.15))
		"cross":
			var c := Color(0.9, 0.35, 0.3)
			draw_line(s * 0.2, s * 0.8, c, maxf(2.0, s.x * 0.12))
			draw_line(s * Vector2(0.8, 0.2), s * Vector2(0.2, 0.8), c, maxf(2.0, s.x * 0.12))
		"empty":
			draw_rect(Rect2(s * 0.2, s * 0.6), Color(0.8, 0.8, 0.8), false, 1.5)
		"piece":
			_draw_piece(s)


## Hængelås: bøjle + krop + nøglehul.
static func draw_lock(ci: CanvasItem, r: Rect2, col: Color) -> void:
	var w: float = r.size.x
	var h: float = r.size.y
	var body := Rect2(r.position + Vector2(w * 0.18, h * 0.45), Vector2(w * 0.64, h * 0.5))
	ci.draw_arc(r.position + Vector2(w * 0.5, h * 0.45), w * 0.22, PI, TAU, 12, col, maxf(1.5, w * 0.1))
	ci.draw_rect(body, col)
	ci.draw_circle(body.get_center() - Vector2(0, h * 0.04), maxf(1.0, w * 0.07), Color(0.15, 0.15, 0.15))


func _draw_piece(s: Vector2) -> void:
	var c := Color(0.95, 0.85, 0.4) if piece_kind != "station" else Color(0.6, 0.8, 1.0)
	var lw: float = maxf(2.0, s.x * 0.1)
	var bot := Vector2(s.x * 0.5, s.y * 0.9)
	if piece_kind == "station":
		draw_rect(Rect2(s * Vector2(0.2, 0.55), s * Vector2(0.6, 0.15)), c)
		draw_line(s * Vector2(0.2, 0.3), s * Vector2(0.8, 0.3), c, lw)
		draw_line(s * Vector2(0.25, 0.3), s * Vector2(0.25, 0.55), c, lw * 0.5)
		draw_line(s * Vector2(0.75, 0.3), s * Vector2(0.75, 0.55), c, lw * 0.5)
		return
	if piece_turn != 0:
		# set ovenfra: kører opad og drejer
		var sx: float = -1.0 if piece_turn > 0 else 1.0
		var center := Vector2(s.x * (0.1 if piece_turn < 0 else 0.9), s.y * 0.9)
		var pts := PackedVector2Array()
		for i in 9:
			var a: float = (PI * 0.5) * (i / 8.0)
			pts.append(center + Vector2(cos(a) * sx, -sin(a)) * (s.x * 0.4))
		draw_polyline(pts, c, lw)
		return
	if piece_rise != 0:
		# set fra siden
		var a := Vector2(s.x * 0.1, s.y * (0.8 if piece_rise > 0 else 0.2))
		var b := Vector2(s.x * 0.9, s.y * (0.2 if piece_rise > 0 else 0.8))
		draw_line(a, b, c, lw)
		if piece_kind == "lift":
			for i in 4:
				var p: Vector2 = a.lerp(b, (i + 0.5) / 4.0)
				draw_line(p + Vector2(-2, -4), p + Vector2(2, 4), Color(0.3, 0.3, 0.3), 2.0)
		return
	draw_line(bot, Vector2(s.x * 0.5, s.y * 0.1), c, lw)
