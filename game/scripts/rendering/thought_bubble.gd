class_name ThoughtBubble
extends Node3D
## Lille tankeboble over en gæst. Billboard-quad + Label3D (Compatibility-venlig).
## T-056: boblens størrelse beregnes ud fra tekstens målte størrelse.

const FONT_SIZE: int = 40
const PIXEL_SIZE: float = 0.004
const PAD_X: float = 0.08   ## meter på hver side
const PAD_Y: float = 0.05
const MIN_W: float = 0.3

@onready var _label: Label3D = $Label
@onready var _bg: MeshInstance3D = $Background


func _ready() -> void:
	visible = false
	_label.font_size = FONT_SIZE
	_label.pixel_size = PIXEL_SIZE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector3.ZERO


## Tekstens størrelse i meter (samme font/størrelse som Label3D).
static func text_size(t: String, font: Font = null) -> Vector2:
	var f: Font = font if font != null else ThemeDB.fallback_font
	var s: Vector2 = f.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE)
	s.y = maxf(s.y, f.get_height(FONT_SIZE))
	return s * PIXEL_SIZE


## Boblens størrelse i meter: tekst + padding.
static func bubble_size(t: String, font: Font = null) -> Vector2:
	var ts: Vector2 = text_size(t, font)
	return Vector2(maxf(MIN_W, ts.x + 2.0 * PAD_X), ts.y + 2.0 * PAD_Y)


func show_text(t: String) -> void:
	if not is_node_ready():
		await ready
	_label.text = t
	var font: Font = _label.font if _label.font != null else null
	var bs: Vector2 = bubble_size(t, font)
	var q: QuadMesh = _bg.mesh as QuadMesh
	if q != null:
		_bg.scale = Vector3(bs.x / q.size.x, bs.y / q.size.y, 1.0)
	_bg.position = Vector3.ZERO
	visible = true


func hide_bubble() -> void:
	visible = false
