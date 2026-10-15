class_name BuildTool
extends Node
## Byggeværktøjer: sender kommandoer til ParkSim via ParkView og viser preview.
## Værktøj vælges via Selection.build_tool_requested (UI) eller taster:
## 1=sti 2=karrusel 3=pariserhjul 4=radiobiler 5=burger 6=drikke 7=is 8=toilet
## X=fjern bygning, Esc/0=vælg. Venstre=byg/træk, højre=fjern sti.
## Space = pause, +/- = hastighed.

const HIGHLIGHT_SCRIPT: Script = preload("res://scripts/rendering/cell_highlight.gd")
const SPEEDS: Array[float] = [0.5, 1.0, 2.0, 4.0, 8.0]
const TOOL_PATH: String = "path"
const TOOL_REMOVE: String = "remove"
const TOOL_SELECT: String = "select"
const KEY_TOOLS: Dictionary = {
	KEY_1: "path", KEY_2: "carousel", KEY_3: "ferris_wheel", KEY_4: "bumper_cars",
	KEY_5: "burger_stand", KEY_6: "drinks_stand", KEY_7: "ice_cream_stand", KEY_8: "toilet",
	KEY_X: "remove", KEY_0: "select", KEY_ESCAPE: "select",
}
const GUEST_PICK_RADIUS: float = 0.5

@export var park_view_path: NodePath
@export var camera_path: NodePath
@export var selection_path: NodePath

var tool: String = TOOL_PATH
var _view: ParkView
var _camera: Camera3D
var _selection: Selection
var _picker: GridPicker
var _highlights: Array[CellHighlight] = []
var _dragging: int = 0  ## 0 = ingen, 1 = placér, 2 = fjern
var _speed_idx: int = 1


func _ready() -> void:
	_view = get_node_or_null(park_view_path) as ParkView
	if _view == null:
		_view = get_tree().get_first_node_in_group("park_view") as ParkView
	_camera = get_node_or_null(camera_path) as Camera3D
	_selection = get_node_or_null(selection_path) as Selection
	if _selection == null:
		_selection = get_tree().get_first_node_in_group("selection") as Selection
	if _selection != null:
		_selection.build_tool_requested.connect(set_tool)
	_picker = GridPicker.new()
	add_child(_picker)


func set_tool(def_id: String) -> void:
	tool = def_id
	_dragging = 0


func _building_def() -> AttractionDef:
	if tool == TOOL_PATH or tool == TOOL_REMOVE or tool == TOOL_SELECT:
		return null
	return _view.sim.get_def(tool)


func _footprint() -> Vector2i:
	var def: AttractionDef = _building_def()
	return def.footprint if def != null else Vector2i.ONE


## Musens celle -> origin (bygning centreres om musen).
func _origin_under_mouse() -> Vector2i:
	var cell: Vector2i = _picker.cell_under_mouse(_camera)
	if cell == GridPicker.INVALID:
		return cell
	var fp: Vector2i = _footprint()
	return cell - Vector2i(fp.x / 2, fp.y / 2)


func _ground_under_mouse() -> Variant:
	if _camera == null or not _camera.is_inside_tree():
		return null
	var mouse: Vector2 = _camera.get_viewport().get_mouse_position()
	return Plane(Vector3.UP, 0.0).intersects_ray(_camera.project_ray_origin(mouse), _camera.project_ray_normal(mouse))


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


func _update_preview() -> void:
	for h in _highlights:
		h.hide_highlight()
	var w: ParkWorld = _view.sim.world
	var def: AttractionDef = _building_def()
	var fp: Vector2i = _footprint()
	var origin: Vector2i = _origin_under_mouse()
	if origin == GridPicker.INVALID:
		return
	if tool == TOOL_REMOVE or tool == TOOL_SELECT:
		var a: Attraction = w.get_attraction_at(origin)
		if a == null:
			return
		_ensure_highlights(a.def.footprint.x * a.def.footprint.y)
		var j: int = 0
		for y in a.def.footprint.y:
			for x in a.def.footprint.x:
				_highlights[j].show_at(a.origin + Vector2i(x, y), tool == TOOL_SELECT)
				j += 1
		return
	_ensure_highlights(fp.x * fp.y)
	if def != null:
		var valid: bool = w.can_place_attraction(def, origin) and _view.sim.economy.can_afford(def.build_cost)
		var i: int = 0
		for y in fp.y:
			for x in fp.x:
				_highlights[i].show_at(origin + Vector2i(x, y), valid)
				i += 1
	elif w.in_bounds(origin):
		_highlights[0].show_at(origin, w.can_place_path(origin) or _dragging == 2)


## Kommandoer – offentlige så tests kan drive dem uden input.
func place_building(def_id: String, origin: Vector2i) -> Attraction:
	var a: Attraction = _view.sim.cmd_place_attraction(def_id, origin)
	if a != null:
		_view.spawn_floating_text(_center(a), "-%d" % a.def.build_cost, Color(1, 0.4, 0.4))
	return a


func remove_building_at(cell: Vector2i) -> bool:
	var a: Attraction = _view.sim.world.get_attraction_at(cell)
	if a == null:
		return false
	var c: Vector3 = _center(a)
	var refund: int = a.def.build_cost / 2
	if not _view.sim.cmd_remove_attraction(a.id):
		return false
	_view.spawn_floating_text(c, "+%d" % refund, Color(0.4, 1, 0.4))
	if _selection != null:
		_selection.cleared.emit()
	return true


func select_at(cell: Vector2i, ground: Variant) -> void:
	if _selection == null:
		return
	if ground != null:
		var gid: int = _view.guest_near(ground as Vector3, GUEST_PICK_RADIUS)
		if gid >= 0:
			_selection.selected_guest.emit(gid)
			return
	var a: Attraction = _view.sim.world.get_attraction_at(cell)
	if a != null:
		_selection.selected_attraction.emit(a.id)
	else:
		_selection.cleared.emit()


static func _center(a: Attraction) -> Vector3:
	return Vector3(a.origin.x + a.def.footprint.x * 0.5, 0.0, a.origin.y + a.def.footprint.y * 0.5)


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
			var cell: Vector2i = _picker.cell_under_mouse(_camera)
			if tool == TOOL_PATH:
				_dragging = 1
				_apply_drag()
			elif cell == GridPicker.INVALID:
				return
			elif tool == TOOL_SELECT:
				select_at(cell, _ground_under_mouse())
			elif tool == TOOL_REMOVE:
				remove_building_at(cell)
			else:
				place_building(tool, _origin_under_mouse())
		else:
			_dragging = 2
			_apply_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging != 0:
		_apply_drag()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		var clock: SimClock = _view.sim.clock
		if KEY_TOOLS.has(k.keycode):
			var id: String = KEY_TOOLS[k.keycode]
			if _selection != null:
				_selection.build_tool_requested.emit(id)  # UI holder sig i sync; set_tool kaldes via signal
			else:
				set_tool(id)
			if id == TOOL_SELECT and _selection != null:
				_selection.cleared.emit()
			get_viewport().set_input_as_handled()
			return
		match k.keycode:
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
