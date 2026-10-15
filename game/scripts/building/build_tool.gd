class_name BuildTool
extends Node
## Byggeværktøjer: sender kommandoer til ParkSim via ParkView og viser preview.
## 1 = sti (venstreklik/træk), højreklik/træk = fjern sti, 2 = karrusel.
## Space = pause, +/- = hastighed.

enum Tool { PATH, CAROUSEL }

const HIGHLIGHT_SCRIPT: Script = preload("res://scripts/rendering/cell_highlight.gd")
const SPEEDS: Array[float] = [0.5, 1.0, 2.0, 4.0, 8.0]

@export var park_view_path: NodePath
@export var camera_path: NodePath

var tool: int = Tool.PATH
var _view: ParkView
var _camera: Camera3D
var _picker: GridPicker
var _highlights: Array[CellHighlight] = []
var _dragging: int = 0  ## 0 = ingen, 1 = placér, 2 = fjern
var _speed_idx: int = 1
var _label: Label


func _ready() -> void:
	_view = get_node(park_view_path) as ParkView
	_camera = get_node(camera_path) as Camera3D
	_picker = GridPicker.new()
	add_child(_picker)
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(10, 10)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(_label)


func _footprint() -> Vector2i:
	if tool == Tool.CAROUSEL:
		var def: AttractionDef = _view.sim.get_def("carousel")
		return def.footprint if def != null else Vector2i.ONE
	return Vector2i.ONE


## Musens celle -> origin (karrusel centreres om musen).
func _origin_under_mouse() -> Vector2i:
	var cell: Vector2i = _picker.cell_under_mouse(_camera)
	if cell == GridPicker.INVALID:
		return cell
	var fp: Vector2i = _footprint()
	return cell - Vector2i(fp.x / 2, fp.y / 2)


func _ensure_highlights(n: int) -> void:
	while _highlights.size() < n:
		var h := MeshInstance3D.new()
		h.set_script(HIGHLIGHT_SCRIPT)
		_view.add_child(h)
		_highlights.append(h as CellHighlight)


func _process(_delta: float) -> void:
	if _view == null or _view.sim == null:
		return
	_update_preview()
	_update_label()


func _update_preview() -> void:
	var origin: Vector2i = _origin_under_mouse()
	var fp: Vector2i = _footprint()
	_ensure_highlights(fp.x * fp.y)
	for h in _highlights:
		h.hide_highlight()
	if origin == GridPicker.INVALID:
		return
	var w: ParkWorld = _view.sim.world
	if tool == Tool.CAROUSEL:
		var valid: bool = w.can_place_attraction(_view.sim.get_def("carousel"), origin)
		var i: int = 0
		for y in fp.y:
			for x in fp.x:
				_highlights[i].show_at(origin + Vector2i(x, y), valid)
				i += 1
	elif w.in_bounds(origin):
		_highlights[0].show_at(origin, w.can_place_path(origin) or _dragging == 2)


func _apply_drag() -> void:
	var cell: Vector2i = _picker.cell_under_mouse(_camera)
	if cell == GridPicker.INVALID:
		return
	if _dragging == 1:
		_view.sim.cmd_place_path(cell)
	elif _dragging == 2:
		_view.sim.cmd_remove_path(cell)


func _unhandled_input(event: InputEvent) -> void:
	if _view == null or _view.sim == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# Scroll håndteres af kameraet.
		if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
			return
		if not mb.pressed:
			_dragging = 0
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if tool == Tool.CAROUSEL:
				var origin: Vector2i = _origin_under_mouse()
				if origin != GridPicker.INVALID:
					_view.sim.cmd_place_attraction("carousel", origin)
			else:
				_dragging = 1
				_apply_drag()
		else:
			_dragging = 2
			_apply_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging != 0:
		_apply_drag()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		var clock: SimClock = _view.sim.clock
		match k.keycode:
			KEY_1:
				tool = Tool.PATH
			KEY_2:
				tool = Tool.CAROUSEL
			KEY_SPACE:
				clock.paused = not clock.paused
			KEY_PLUS, KEY_KP_ADD, KEY_EQUAL:
				_speed_idx = mini(_speed_idx + 1, SPEEDS.size() - 1)
				clock.speed = SPEEDS[_speed_idx]
			KEY_MINUS, KEY_KP_SUBTRACT:
				_speed_idx = maxi(_speed_idx - 1, 0)
				clock.speed = SPEEDS[_speed_idx]
			_:
				return
		get_viewport().set_input_as_handled()


func _update_label() -> void:
	var clock: SimClock = _view.sim.clock
	var tool_name: String = "Sti" if tool == Tool.PATH else "Karrusel"
	_label.text = "Gæster: %d   Tick: %d   Hastighed: %sx%s\nVærktøj: %s\n1=Sti  2=Karrusel  Venstre=byg/træk  Højre=fjern sti\nSpace=pause  +/-=hastighed  WASD=kamera  Q/E=rotér  Scroll=zoom" % [
		_view.sim.guests.size(), clock.tick, str(clock.speed), "  (PAUSE)" if clock.paused else "", tool_name]
