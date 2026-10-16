class_name BuildTool
extends Node
## Byggeværktøjer: sender kommandoer til ParkSim via ParkView og viser preview.
## Værktøj vælges via Selection.build_tool_requested (UI) eller taster:
## 1=sti 2=karrusel 3=pariserhjul 4=radiobiler 5=burger 6=drikke 7=is 8=toilet
## X=fjern bygning/dekoration, 0=vælg, Esc=vælg (eller pause-menu hvis allerede vælg).
## "decor:<id>" placerer dekoration, "staff:<type>" ansætter på sti,
## "staff_move:<id>" flytter personale (klik på sti). I vælg-værktøjet kan valgt personale trækkes. Venstre=byg/træk, højre=fjern sti.
## Space = pause, +/- = hastighed.

const HIGHLIGHT_SCRIPT: Script = preload("res://scripts/rendering/cell_highlight.gd")
const SPEEDS: Array[float] = [0.5, 1.0, 2.0, 4.0, 8.0]
const TOOL_PATH: String = "path"
const TOOL_REMOVE: String = "remove"
const TOOL_SELECT: String = "select"
const KEY_TOOLS: Dictionary = {
	KEY_1: "path", KEY_2: "carousel", KEY_3: "ferris_wheel", KEY_4: "bumper_cars",
	KEY_5: "burger_stand", KEY_6: "drinks_stand", KEY_7: "ice_cream_stand", KEY_8: "toilet",
	KEY_X: "remove", KEY_0: "select",
}
const PREFIX_DECOR: String = "decor:"
const PREFIX_STAFF: String = "staff:"
const PREFIX_MOVE: String = "staff_move:"
const PREFIX_COASTER: String = "coaster:"
const GUEST_PICK_RADIUS: float = 0.5

## Fejlkoder fra cmd_finish_coaster (eller "locked"/"no_station" m.fl.) – UI viser dem som toast.
signal coaster_errors(codes: Array[String])
## Banen blev færdig og åbnede.
signal coaster_finished(coaster_id: int)

@export var park_view_path: NodePath
@export var camera_path: NodePath
@export var selection_path: NodePath
@export var ground_path: NodePath = ^"../Ground"

var tool: String = TOOL_SELECT
var _view: ParkView
var _camera: Camera3D
var _selection: Selection
var _picker: GridPicker
var _highlights: Array[CellHighlight] = []
var _dragging: int = 0  ## 0 = ingen, 1 = placér, 2 = fjern
var _speed_idx: int = 1
var _drag_staff: int = -1  ## personale der trækkes i vælg-værktøjet
var grid_lines: GridLineFader  ## grid-linjer kun i byggetilstand (T-063)
## T-070 rutsjebane-byggeri
var coaster_id: int = -1          ## banen der bygges på (-1 = stationen er ikke placeret)
var coaster_heading: int = 1      ## heading for stationen (R roterer)
var coaster_piece: String = ""    ## valgt stykke (set_coaster_piece)
var _ghost: CoasterTrackMesh
var _piece_defs: Dictionary = {}


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
	grid_lines = GridLineFader.new(_ground_material(), tool)


func _ground_material() -> ShaderMaterial:
	var ground := get_node_or_null(ground_path) as MeshInstance3D
	if ground == null or ground.mesh == null:
		return null
	if ground.material_override is ShaderMaterial:
		return ground.material_override as ShaderMaterial
	return ground.mesh.surface_get_material(0) as ShaderMaterial


## Returnerer false (og spiller error-lyd), hvis id'et er låst.
func set_tool(def_id: String) -> bool:
	if is_tool_locked(def_id):
		play_error()
		return false
	tool = def_id
	_dragging = 0
	if not def_id.begins_with(PREFIX_COASTER):
		coaster_id = -1
	elif coaster_id >= 0:
		var a: Attraction = _view.sim.get_attraction(coaster_id) if _view != null and _view.sim != null else null
		if a == null or a.def.id != def_id.substr(PREFIX_COASTER.length()):
			coaster_id = -1
	if def_id.begins_with(PREFIX_COASTER) and coaster_piece != "" and not CoasterContent.pieces(coaster_system()).has(coaster_piece):
		coaster_piece = ""  # T-093: stykket hører til et andet sporsystem
	if grid_lines != null:
		grid_lines.set_tool(def_id)
	return true


## Det id, værktøjet ville placere (bygning/dekoration/rutsjebane), eller "" for andre værktøjer.
static func tool_content_id(t: String) -> String:
	if t.begins_with(PREFIX_COASTER):
		return t.substr(PREFIX_COASTER.length())
	if t.begins_with(PREFIX_DECOR):
		return t.substr(PREFIX_DECOR.length())
	if t == TOOL_PATH or t == TOOL_REMOVE or t == TOOL_SELECT or t.contains(":"):
		return ""
	return t


func is_tool_locked(t: String) -> bool:
	var id: String = tool_content_id(t)
	if id == "" or _view == null or _view.sim == null:
		return false
	return not _view.sim.is_unlocked(id)


func play_error() -> void:
	var am: Node = get_node_or_null("/root/AudioManager") if is_inside_tree() else null
	if am != null:
		am.call("play_sfx", &"error", Vector3.INF)


# --- Rutsjebane (T-070, kontrakt §6) ---

func is_coaster_tool() -> bool:
	return tool.begins_with(PREFIX_COASTER)


func is_building_coaster() -> bool:
	if coaster_id < 0 or _view == null or _view.sim == null:
		return false
	var a: Attraction = _view.sim.get_attraction(coaster_id)
	return a != null and a.building


func rotate_coaster() -> void:
	coaster_heading = posmod(coaster_heading + 1, 4)


## T-093: sporsystemet for det aktive spor-værktøj (&"" hvis intet).
func coaster_system() -> StringName:
	if not is_coaster_tool() or _view == null or _view.sim == null:
		return &""
	var def: AttractionDef = _view.sim.get_def(tool.substr(PREFIX_COASTER.length()))
	return def.track_system() if def != null else &""


## T-093: stykker til paletten for systemet (uden stationer), sorteret.
func coaster_palette() -> Array[String]:
	var out: Array[String] = []
	var sys: StringName = coaster_system()
	if sys == &"":
		return out
	var ps: Dictionary = CoasterContent.pieces(sys)
	for id: String in ps:
		if (ps[id] as TrackPieceDef).kind != "station":
			out.append(id)
	out.sort()
	return out


## T-093: endestationens stykke-id for åbne systemer (svævebanen), ellers "".
func end_station_piece() -> String:
	var sys: StringName = coaster_system()
	if sys == &"" or bool(CoasterContent.system_def(sys).get("closed_loop", true)):
		return ""
	return CoasterContent.station_id(sys, "end")


## "Endestation" tilbydes, når banen er længere end 1 stykke og ikke allerede har en.
func can_place_end_station() -> bool:
	if end_station_piece() == "" or not is_building_coaster():
		return false
	var a: Attraction = _view.sim.get_attraction(coaster_id)
	return a.track != null and a.track.pieces.size() > 1 and a.track.end_station() == null


func place_end_station() -> bool:
	if not can_place_end_station():
		play_error()
		return false
	var prev: String = coaster_piece
	coaster_piece = end_station_piece()
	var ok: bool = place_coaster_piece()
	coaster_piece = prev
	return ok


## Placerer stationen (første klik). Returnerer coaster-id eller -1.
func place_coaster_station(cell: Vector2i, heading: int = coaster_heading) -> int:
	var def_id: String = tool.substr(PREFIX_COASTER.length()) if is_coaster_tool() else ""
	if def_id == "" or not _view.sim.is_unlocked(def_id):
		play_error()
		return -1
	var id: int = _view.sim.cmd_start_coaster(def_id, cell, heading)
	if id < 0:
		play_error()
		return -1
	coaster_id = id
	coaster_heading = heading
	var a: Attraction = _view.sim.get_attraction(id)
	_view.spawn_floating_text(ParkView.cell_center(cell), "-%d" % (a.build_value()), Color(1, 0.4, 0.4))
	return id


func set_coaster_piece(piece_id: String) -> void:
	coaster_piece = piece_id


## Placerer det valgte stykke for enden af banen.
func place_coaster_piece() -> bool:
	if coaster_id < 0 or coaster_piece == "":
		return false
	if not _view.sim.is_unlocked(coaster_piece) or not _view.sim.cmd_place_track_piece(coaster_id, coaster_piece):
		play_error()
		return false
	return true


func remove_last_coaster_piece() -> bool:
	return coaster_id >= 0 and _view.sim.cmd_remove_last_piece(coaster_id)


## "Færdig": validerer. Fejl udsendes via coaster_errors; ved succes skiftes til vælg-værktøjet.
## T-130: prefer_id = ufærdig bane valgt i UI (paletten's resume_id). Har værktøjet mistet
## sin aktive bane (Esc, Vælg-klik, skift af værktøj, indlæst save), genoptages den.
func finish_coaster(prefer_id: int = -1) -> Array[String]:
	if coaster_id < 0:
		var found: int = find_unfinished_coaster(prefer_id)
		if found >= 0:
			resume_coaster(found)
		if coaster_id < 0:
			var none: Array[String] = ["no_active_track" if found == -2 else "no_station"]
			coaster_errors.emit(none)
			return none
	var id: int = coaster_id
	var errs: Array[String] = _view.sim.cmd_finish_coaster(id)
	if not errs.is_empty():
		play_error()
		coaster_errors.emit(errs)
		return errs
	coaster_id = -1
	_request_tool(TOOL_SELECT)
	coaster_finished.emit(id)
	return errs


## T-130: finder en ufærdig bane: prefer_id hvis gyldig, ellers den eneste for værktøjets
## type, ellers den eneste i parken. -1 = ingen, -2 = flere (tvetydigt).
func find_unfinished_coaster(prefer_id: int = -1) -> int:
	if _view == null or _view.sim == null:
		return -1
	var p: Attraction = _view.sim.get_attraction(prefer_id) if prefer_id >= 0 else null
	if p != null and p.track != null and p.building:
		return p.id
	var def_id: String = tool.substr(PREFIX_COASTER.length()) if is_coaster_tool() else ""
	var same: Array[int] = []
	var all: Array[int] = []
	for a: Attraction in _view.sim.attractions:
		if a.track == null or not a.building:
			continue
		all.append(a.id)
		if a.def.id == def_id:
			same.append(a.id)
	if same.size() == 1:
		return same[0]
	if same.size() > 1:
		return -2
	if all.size() == 1:
		return all[0]
	return -2 if all.size() > 1 else -1


## "Fortsæt byg" på en ufærdig bane.
func resume_coaster(id: int) -> bool:
	var a: Attraction = _view.sim.get_attraction(id)
	if a == null or a.track == null or not a.building:
		return false
	_request_tool(PREFIX_COASTER + a.def.id)
	if tool != PREFIX_COASTER + a.def.id:
		return false
	coaster_id = id
	return true


func _ensure_ghost() -> void:
	if _ghost != null:
		return
	_piece_defs = CoasterTrackMesh.load_defs()
	_ghost = CoasterTrackMesh.new()
	_ghost.name = "CoasterGhost"
	_view.add_child(_ghost)


func _update_coaster_preview() -> void:
	if coaster_id < 0:
		var cell: Vector2i = _picker.cell_under_mouse(_camera)
		if cell == GridPicker.INVALID:
			return
		var w: ParkWorld = _view.sim.world
		var ent: Vector2i = cell + TrackPiece.dir(coaster_heading + 3)
		var def: AttractionDef = _view.sim.get_def(tool.substr(PREFIX_COASTER.length()))
		var ok: bool = def != null and w.in_bounds(cell) and w.in_bounds(ent) and w.get_tile(cell) == ParkWorld.Tile.GRASS \
			and _view.sim.economy.can_afford(def.build_cost)
		_ensure_highlights(2)
		_highlights[0].show_at(cell, ok)
		_highlights[1].show_at(ent, ok)
		return
	if coaster_piece == "" or not is_building_coaster():
		return
	var pv: Dictionary = _view.sim.preview_track_piece(coaster_id, coaster_piece)
	_ensure_ghost()
	_ghost.build([{"def_id": coaster_piece, "cell": pv["cell"], "heading": pv["heading"], "level": pv["level"]}], _piece_defs)
	_ghost.set_ghost(bool(pv["ok"]))
	_ghost.visible = true


func _building_def() -> AttractionDef:
	if tool == TOOL_PATH or tool == TOOL_REMOVE or tool == TOOL_SELECT or tool.contains(":"):
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


func _process(delta: float) -> void:
	if grid_lines != null:
		grid_lines.update(delta)
	if _view == null or _view.sim == null:
		return
	_update_preview()


func _update_preview() -> void:
	for h in _highlights:
		h.hide_highlight()
	if _ghost != null:
		_ghost.visible = false
	if is_coaster_tool():
		_update_coaster_preview()
		return
	var w: ParkWorld = _view.sim.world
	var def: AttractionDef = _building_def()
	var fp: Vector2i = _footprint()
	var origin: Vector2i = _origin_under_mouse()
	if origin == GridPicker.INVALID:
		return
	if tool == TOOL_REMOVE and _view.decor_at(origin) >= 0:
		_ensure_highlights(1)
		_highlights[0].show_at(origin, false)
		return
	if (tool == TOOL_REMOVE or tool == TOOL_SELECT) and _drag_staff < 0:
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
	if tool.begins_with(PREFIX_DECOR):
		var dd: DecorDef = _view.sim.get_decor_def(tool.substr(PREFIX_DECOR.length()))
		_highlights[0].show_at(origin, _view.sim.can_place_decor(dd, origin) and dd != null and _view.sim.economy.can_afford(dd.build_cost))
	elif tool.begins_with(PREFIX_STAFF) or tool.begins_with(PREFIX_MOVE) or _drag_staff >= 0:
		_highlights[0].show_at(origin, w.is_walkable(origin))
	elif def != null:
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


func place_decor(def_id: String, cell: Vector2i) -> int:
	var id: int = _view.sim.cmd_place_decor(def_id, cell)
	if id >= 0:
		var dd: DecorDef = _view.sim.get_decor_def(def_id)
		_view.spawn_floating_text(ParkView.cell_center(cell), "-%d" % dd.build_cost, Color(1, 0.4, 0.4))
	return id


func hire_staff(type_id: String, cell: Vector2i) -> int:
	var id: int = _view.sim.cmd_hire_staff(type_id, cell)
	if id >= 0 and _selection != null:
		_selection.selected_staff.emit(id)
	return id


func move_staff(staff_id: int, cell: Vector2i) -> bool:
	return _view.sim.cmd_move_staff(staff_id, cell)


## Fjerner dekoration på cellen, ellers bygning.
func remove_building_at(cell: Vector2i) -> bool:
	var did: int = _view.decor_at(cell)
	if did >= 0:
		var refund: int = (_view.sim.get_decor(did) as Decor).def.build_cost / 2
		if _view.sim.cmd_remove_decor(did):
			_view.spawn_floating_text(ParkView.cell_center(cell), "+%d" % refund, Color(0.4, 1, 0.4))
			return true
		return false
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


## Prioritet: personale, gæst, bygning. Returnerer valgt personale-id (eller -1).
func select_at(cell: Vector2i, ground: Variant) -> int:
	if _selection == null:
		return -1
	if ground != null:
		var sid: int = _view.staff_near(ground as Vector3, GUEST_PICK_RADIUS)
		if sid >= 0:
			_selection.selected_staff.emit(sid)
			return sid
		var gid: int = _view.guest_near(ground as Vector3, GUEST_PICK_RADIUS)
		if gid >= 0:
			_selection.selected_guest.emit(gid)
			return -1
	var a: Attraction = _view.sim.world.get_attraction_at(cell)
	if a != null:
		_selection.selected_attraction.emit(a.id)
	else:
		_selection.cleared.emit()
	return -1


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
			if _drag_staff >= 0 and mb.button_index == MOUSE_BUTTON_LEFT:
				var drop: Vector2i = _picker.cell_under_mouse(_camera)
				if drop != GridPicker.INVALID:
					move_staff(_drag_staff, drop)
				_drag_staff = -1
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var cell: Vector2i = _picker.cell_under_mouse(_camera)
			if tool == TOOL_PATH:
				_dragging = 1
				_apply_drag()
			elif cell == GridPicker.INVALID:
				return
			elif is_coaster_tool():
				if coaster_id < 0:
					place_coaster_station(cell)
				else:
					place_coaster_piece()
			elif tool == TOOL_SELECT:
				_drag_staff = select_at(cell, _ground_under_mouse())
			elif tool.begins_with(PREFIX_DECOR):
				place_decor(tool.substr(PREFIX_DECOR.length()), cell)
			elif tool.begins_with(PREFIX_STAFF):
				if hire_staff(tool.substr(PREFIX_STAFF.length()), cell) >= 0:
					_request_tool(TOOL_SELECT)
			elif tool.begins_with(PREFIX_MOVE):
				if move_staff(tool.substr(PREFIX_MOVE.length()).to_int(), cell):
					_request_tool(TOOL_SELECT)
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
		if k.keycode == KEY_ESCAPE:
			handle_escape()
			get_viewport().set_input_as_handled()
			return
		if is_coaster_tool() and _coaster_key(k.keycode):
			get_viewport().set_input_as_handled()
			return
		if KEY_TOOLS.has(k.keycode):
			var id: String = KEY_TOOLS[k.keycode]
			_request_tool(id)
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


func _coaster_key(code: Key) -> bool:
	match code:
		KEY_R:
			if coaster_id < 0:
				rotate_coaster()
		KEY_ENTER, KEY_KP_ENTER:
			place_coaster_piece()
		KEY_BACKSPACE:
			remove_last_coaster_piece()
		_:
			return false
	return true


## Esc: værktøj ≠ select → select; ellers pause-menu.
func handle_escape() -> void:
	_drag_staff = -1
	coaster_id = -1  # en ufærdig bane bliver stående (genoptages med resume_coaster)
	if tool != TOOL_SELECT:
		_request_tool(TOOL_SELECT)
		if _selection != null:
			_selection.cleared.emit()
	elif _selection != null:
		_selection.pause_menu_requested.emit()


## Udsender via Selection (så UI holder sig i sync); set_tool kaldes via signalet.
func _request_tool(id: String) -> void:
	if _selection != null:
		_selection.build_tool_requested.emit(id)
	else:
		set_tool(id)
