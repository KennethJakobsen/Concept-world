class_name BuildTool
extends Node
## Byggeværktøjer: sender kommandoer til ParkSim via ParkView og viser preview.
## Værktøj vælges via Selection.build_tool_requested (UI) eller taster:
## 1-6 = byggekategorier (stier/forlystelser/butikker/pynt/personale/rutsjebaner)
## X=fjern bygning/dekoration/sti (træk for flere stier), 0=vælg, Esc=vælg (eller pause-menu hvis allerede vælg).
## "decor:<id>" placerer dekoration, "staff:<type>" ansætter på sti,
## "staff_move:<id>" flytter personale (klik på sti). I vælg-værktøjet kan valgt personale trækkes. Venstre=byg/træk, højre=fjern sti.
## Space = pause, +/- = hastighed.
## T-110: M = flyt (klik på bygning/pynt løfter, R roterer 90°, klik placerer; også sporbaner som helhed),
## Ctrl/Cmd+Z = fortryd, Ctrl/Cmd+Shift+Z (eller Ctrl+Y) = gentag. Ghost viser pris ved musen,
## Fjern viser refusion (sim.sell_refund) før klik, og stier uden forbindelse til porten markeres røde.

const HIGHLIGHT_SCRIPT: Script = preload("res://scripts/rendering/cell_highlight.gd")
const SPEEDS: Array[float] = [0.5, 1.0, 2.0, 4.0, 8.0]
const TOOL_PATH: String = "path"
const TOOL_QUEUE: String = "queue_path"  ## T-140: køsti (træk for flere, højreklik fjerner)
const TOOL_REMOVE: String = "remove"
const TOOL_SELECT: String = "select"
const TOOL_MOVE: String = "move"  ## T-110
const KEY_TOOLS: Dictionary = {
	KEY_X: "remove", KEY_0: "select", KEY_M: "move",
}
const DISCONNECTED_SHOW_TIME: float = 4.0
## T-111: tasterne 1-6 åbner BuildDock-kategorierne (samme rækkefølge som BuildDock.CATEGORIES).
const KEY_CATEGORIES: Dictionary = {
	KEY_1: "paths", KEY_2: "rides", KEY_3: "shops", KEY_4: "decor", KEY_5: "staff", KEY_6: "coaster",
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
## En fjernelse blev afvist (T-132) – UI viser teksten som toast.
signal remove_blocked(message: String)
## T-110: fortryd/gentag udført (eller afvist: ok=false). label = handlingens tekst.
signal undo_performed(redo: bool, ok: bool, label: String)

const MSG_ENTRANCE: String = "Stien er indgang til en attraktion - fjern attraktionen først."

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
var _last_drag_cell: Vector2i = GridPicker.INVALID
var _speed_idx: int = 1
var _drag_staff: int = -1  ## personale der trækkes i vælg-værktøjet
var grid_lines: GridLineFader  ## grid-linjer kun i byggetilstand (T-063)
## T-070 rutsjebane-byggeri
var coaster_id: int = -1          ## banen der bygges på (-1 = stationen er ikke placeret)
var coaster_heading: int = 1      ## heading for stationen (R roterer)
var coaster_piece: String = ""    ## valgt stykke (set_coaster_piece)
var _ghost: CoasterTrackMesh
var _piece_defs: Dictionary = {}
## T-110 flyt-værktøj
var move_kind: String = ""        ## "" (intet løftet), "attraction" eller "decor"
var move_id: int = -1
var move_rotation: int = 0        ## absolut rotation (0..3) for den løftede bygning
var _price_label: Label3D
var _warn_highlights: Array[CellHighlight] = []
var _disconnected: Array[Vector2i] = []
var _disconnected_time: float = 0.0


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
	_add_tool_card.call_deferred()


## T-110: medaljon for Flyt via BuildDock's eksisterende add_card (cat "" = værktøj). Hud sender
## card_pressed videre som build_tool_requested, så der kræves ingen ændring i UI-koden.
func _add_tool_card() -> void:
	if not is_inside_tree():
		return
	var docks: Array[Node] = get_tree().root.find_children("*", "BuildDock", true, false)
	if docks.is_empty():
		return
	var dock: BuildDock = docks[0] as BuildDock
	if dock.cards.has(TOOL_MOVE):
		return
	var b: Button = dock.add_card(TOOL_MOVE, "Flyt (M)", "", "",
		"Klik på en bygning, sporbane eller pynt for at løfte den, R roterer, klik for at placere. Gratis.\nCtrl+Z fortryder, Ctrl+Shift+Z gentager.")
	if b.icon == null:
		b.text = "M"


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
	if def_id != TOOL_MOVE:
		cancel_move()
	else:
		refresh_disconnected()
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
	if t == TOOL_PATH or t == TOOL_QUEUE or t == TOOL_REMOVE or t == TOOL_SELECT or t == TOOL_MOVE or t.contains(":"):
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
	if tool == TOOL_PATH or tool == TOOL_QUEUE or tool == TOOL_REMOVE or tool == TOOL_SELECT or tool == TOOL_MOVE \
			or tool.contains(":"):
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
	_disconnected_time = maxf(_disconnected_time - delta, 0.0)
	_update_preview()
	_update_warnings()


func _update_preview() -> void:
	for h in _highlights:
		h.hide_highlight()
	if _ghost != null:
		_ghost.visible = false
	_hide_price()
	if tool == TOOL_MOVE:
		_update_move_preview()
		return
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
		_show_price(origin, "+$%d" % sell_preview(origin), true)
		return
	if (tool == TOOL_REMOVE or tool == TOOL_SELECT) and _drag_staff < 0:
		var a: Attraction = w.get_attraction_at(origin)
		if a == null:
			if tool == TOOL_REMOVE and (w.get_tile(origin) == ParkWorld.Tile.PATH or w.is_queue(origin)):
				_ensure_highlights(1)
				_highlights[0].show_at(origin, false)  # rød = fjernes
			return
		var acells: Array[Vector2i] = a.footprint_cells()
		_ensure_highlights(acells.size())
		for j in acells.size():
			_highlights[j].show_at(acells[j], tool == TOOL_SELECT)
		if tool == TOOL_REMOVE:
			_show_price(origin, "Sælg +$%d" % sell_preview(origin), true)
		return
	_ensure_highlights(fp.x * fp.y)
	if tool.begins_with(PREFIX_DECOR):
		var dd: DecorDef = _view.sim.get_decor_def(tool.substr(PREFIX_DECOR.length()))
		var dok: bool = dd != null and _view.sim.can_place_decor(dd, origin) and _view.sim.economy.can_afford(dd.build_cost)
		_highlights[0].show_at(origin, dok)
		if dd != null:
			_show_price(origin, "$%d" % dd.build_cost, dok)
	elif tool.begins_with(PREFIX_STAFF) or tool.begins_with(PREFIX_MOVE) or _drag_staff >= 0:
		_highlights[0].show_at(origin, w.is_walkable(origin))
	elif def != null:
		var valid: bool = w.can_place_attraction(def, origin) and _view.sim.economy.can_afford(def.build_cost)
		var i: int = 0
		for y in fp.y:
			for x in fp.x:
				_highlights[i].show_at(origin + Vector2i(x, y), valid)
				i += 1
		_show_price(origin + Vector2i(fp.x / 2, fp.y / 2), "$%d" % def.build_cost, valid)
	elif tool == TOOL_QUEUE and w.in_bounds(origin):
		var removing_q: bool = _dragging == 2 or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		var qok: bool = not removing_q and w.can_place_path(origin) \
			and _view.sim.economy.can_afford(_view.sim.balance.queue_path_cost)
		_highlights[0].show_at(origin, qok)
		_show_price(origin, "+$%d" % _view.sim.balance.queue_path_refund if removing_q
			else "$%d" % _view.sim.balance.queue_path_cost, qok or removing_q)
	elif w.in_bounds(origin):
		var removing: bool = _dragging == 2 or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		_highlights[0].show_at(origin, w.can_place_path(origin) and not removing)  # rød ved fjern
		if tool == TOOL_PATH:
			_show_price(origin, "+$%d" % _view.sim.balance.path_refund if removing
				else "$%d" % _view.sim.balance.path_cost, not removing and w.can_place_path(origin))


# --- T-110: pris ved musen, flyt, fortryd og afbrudte stier ---

func _show_price(cell: Vector2i, text: String, ok: bool) -> void:
	if _price_label == null:
		_price_label = Label3D.new()
		_price_label.name = "GhostPrice"
		_price_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_price_label.no_depth_test = true
		_price_label.pixel_size = 0.008
		_price_label.outline_size = 8
		_view.add_child(_price_label)
	_price_label.text = text
	_price_label.modulate = ParkColors.ghost(ok, 1.0)
	_price_label.position = ParkView.cell_center(cell) + Vector3(0, 1.2, 0)
	_price_label.visible = true


func _hide_price() -> void:
	if _price_label != null:
		_price_label.visible = false


## Teksten ved musen (tests/UI). "" hvis skjult.
func price_text() -> String:
	return _price_label.text if _price_label != null and _price_label.visible else ""


## Refusion ved salg/fjernelse af det, der ligger på cellen (pynt, bygning, sti/køsti). -1 = intet.
func sell_preview(cell: Vector2i) -> int:
	var sim: ParkSim = _view.sim
	var did: int = _view.decor_at(cell)
	if did >= 0:
		return (sim.get_decor(did) as Decor).def.build_cost / 2
	var a: Attraction = sim.world.get_attraction_at(cell)
	if a != null:
		return sim.sell_refund(a.id)
	if sim.world.is_queue(cell):
		return sim.balance.queue_path_refund
	if sim.world.get_tile(cell) == ParkWorld.Tile.PATH:
		return sim.balance.path_refund
	return -1


## Løfter bygningen/sporbanen (eller pynten) på cellen. Returnerer true hvis noget blev løftet.
func pick_up_at(cell: Vector2i) -> bool:
	var a: Attraction = _view.sim.world.get_attraction_at(cell)
	if a != null and not a.building:
		move_kind = "attraction"
		move_id = a.id
		move_rotation = a.rotation
		return true
	var did: int = _view.decor_at(cell)
	if did >= 0:
		move_kind = "decor"
		move_id = did
		move_rotation = 0
		return true
	return false


func cancel_move() -> void:
	move_kind = ""
	move_id = -1
	move_rotation = 0


func rotate_move() -> void:
	if move_kind == "attraction":
		move_rotation = posmod(move_rotation + 1, 4)


## Origin for den løftede bygning, når musen står på cell (centreret; sporbaner: stationens celle).
func move_origin_for(cell: Vector2i) -> Vector2i:
	if move_kind != "attraction":
		return cell
	var a: Attraction = _view.sim.get_attraction(move_id)
	if a == null or a.track != null:
		return cell
	var fp: Vector2i = Attraction.rotated_size(a.def, move_rotation)
	return cell - Vector2i(fp.x / 2, fp.y / 2)


## Placerer det løftede på origin (bygning) eller cellen (pynt). Gratis; kan fortrydes.
func drop_move(origin: Vector2i) -> bool:
	var ok: bool = false
	if move_kind == "attraction":
		ok = bool(_view.sim.cmd_move_attraction(move_id, origin, move_rotation).get("ok", false))
	elif move_kind == "decor":
		ok = _view.sim.cmd_move_decor(move_id, origin)
	if not ok:
		play_error()
		return false
	cancel_move()
	refresh_disconnected()
	return true


func _update_move_preview() -> void:
	var cell: Vector2i = _picker.cell_under_mouse(_camera)
	if cell == GridPicker.INVALID:
		return
	var w: ParkWorld = _view.sim.world
	if move_kind == "":
		var a: Attraction = w.get_attraction_at(cell)
		var cells: Array[Vector2i] = []
		if a != null and not a.building:
			cells = a.footprint_cells()
		elif _view.decor_at(cell) >= 0:
			cells = [cell]
		_ensure_highlights(cells.size())
		for i in cells.size():
			_highlights[i].show_at(cells[i], true)
		return
	if move_kind == "decor":
		var d: Decor = _view.sim.get_decor(move_id)
		var dok: bool = d != null and _view.sim.can_place_decor(d.def, cell)
		_ensure_highlights(1)
		_highlights[0].show_at(cell, dok)
		_show_price(cell, "Flyt (gratis)", dok)
		return
	var origin: Vector2i = move_origin_for(cell)
	var pv: Dictionary = _view.sim.preview_move(move_id, origin, move_rotation)
	var ok: bool = bool(pv.get("ok", false))
	var pcells: Array = pv.get("cells", [])
	var ent: Vector2i = pv.get("entrance", Vector2i(-1, -1))
	_ensure_highlights(pcells.size() + 1)
	for i in pcells.size():
		_highlights[i].show_at(pcells[i] as Vector2i, ok)
	if w.in_bounds(ent):
		_highlights[pcells.size()].show_at(ent, ok)
	_show_price(cell, "Flyt (gratis)" if ok or str(pv.get("reason", "")) == "same" else "Kan ikke flytte hertil", ok)


## Fortryd (redo=false) eller gentag. Udsender undo_performed.
func undo(redo: bool = false) -> Dictionary:
	var sim: ParkSim = _view.sim
	var label: String = sim.redo_label() if redo else sim.undo_label()
	var r: Dictionary = sim.cmd_redo() if redo else sim.cmd_undo()
	var ok: bool = bool(r.get("ok", false))
	if not ok:
		play_error()
	else:
		cancel_move()
		refresh_disconnected()
	undo_performed.emit(redo, ok, label)
	return r


## Sticeller (ikke køstier), der ikke kan nås fra parkens indgang.
static func disconnected_paths(w: ParkWorld) -> Array[Vector2i]:
	var seen: Dictionary = {}
	var stack: Array[Vector2i] = []
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var c: Vector2i = w.entrance + d
		if w.in_bounds(c) and w.get_tile(c) == ParkWorld.Tile.PATH and not seen.has(c):
			seen[c] = true
			stack.append(c)
	while not stack.is_empty():
		var cur: Vector2i = stack.pop_back()
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = cur + d
			if not seen.has(n) and w.in_bounds(n) and w.get_tile(n) == ParkWorld.Tile.PATH:
				seen[n] = true
				stack.append(n)
	var out: Array[Vector2i] = []
	for y in w.height:
		for x in w.width:
			var c := Vector2i(x, y)
			if w.get_tile(c) == ParkWorld.Tile.PATH and not seen.has(c):
				out.append(c)
	return out


## Genberegner afbrudte stier og viser dem i DISCONNECTED_SHOW_TIME sek. (altid i flyt-værktøjet).
func refresh_disconnected() -> void:
	if _view == null or _view.sim == null:
		return
	_disconnected = disconnected_paths(_view.sim.world)
	_disconnected_time = DISCONNECTED_SHOW_TIME


func disconnected_cells() -> Array[Vector2i]:
	return _disconnected


func _update_warnings() -> void:
	var show: bool = tool == TOOL_MOVE or _disconnected_time > 0.0
	var n: int = _disconnected.size() if show else 0
	while _warn_highlights.size() < n:
		var h := MeshInstance3D.new()
		h.set_script(HIGHLIGHT_SCRIPT)
		_view.add_child(h)
		_warn_highlights.append(h as CellHighlight)
	for i in _warn_highlights.size():
		if i < n:
			_warn_highlights[i].show_at(_disconnected[i], false)
		else:
			_warn_highlights[i].hide_highlight()


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


## T-140: køsti på græs; den kobles til den forlystelse, hvis indgang kæden starter ved.
func place_queue_path(cell: Vector2i) -> bool:
	if not _view.sim.cmd_place_queue_path(cell):
		return false
	_view.spawn_floating_text(ParkView.cell_center(cell), "-%d" % _view.sim.balance.queue_path_cost, Color(1, 0.4, 0.4))
	return true


func remove_queue_path_at(cell: Vector2i) -> bool:
	if not _view.sim.cmd_remove_queue_path(cell):
		return false
	_view.spawn_floating_text(ParkView.cell_center(cell), "+%d" % _view.sim.balance.queue_path_refund, Color(0.4, 1, 0.4))
	return true


## Fjerner stien (eller køstien) på cellen (T-132). Indgangsceller giver en forklarende besked.
func remove_path_at(cell: Vector2i) -> bool:
	var w: ParkWorld = _view.sim.world
	if w.is_queue(cell):
		return remove_queue_path_at(cell)
	if w.get_tile(cell) != ParkWorld.Tile.PATH:
		return false
	if w.get_attraction_by_entrance(cell) != null:
		remove_blocked.emit(MSG_ENTRANCE)
		return false
	if not _view.sim.cmd_remove_path(cell):
		return false
	_view.spawn_floating_text(ParkView.cell_center(cell), "+%d" % _view.sim.balance.path_refund, Color(0.4, 1, 0.4))
	return true


## Fjerner dekoration på cellen, ellers bygning, ellers sti.
func remove_building_at(cell: Vector2i) -> bool:
	var did: int = _view.decor_at(cell)
	if did >= 0:
		var refund: int = sell_preview(cell)
		if _view.sim.cmd_remove_decor(did):
			_view.spawn_floating_text(ParkView.cell_center(cell), "+%d" % refund, Color(0.4, 1, 0.4))
			return true
		return false
	var a: Attraction = _view.sim.world.get_attraction_at(cell)
	if a == null:
		return remove_path_at(cell)
	var c: Vector3 = _center(a)
	var refund: int = _view.sim.sell_refund(a.id)
	if not _view.sim.cmd_remove_attraction(a.id):
		return false
	_view.spawn_floating_text(c, "+%d" % refund, Color(0.4, 1, 0.4))
	if _selection != null:
		_selection.cleared.emit()
	refresh_disconnected()
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
	var fp: Vector2i = a.footprint_size()
	return Vector3(a.origin.x + fp.x * 0.5, 0.0, a.origin.y + fp.y * 0.5)


func _apply_drag() -> void:
	var cell: Vector2i = _picker.cell_under_mouse(_camera)
	if cell == GridPicker.INVALID or cell == _last_drag_cell:
		return
	_last_drag_cell = cell
	if _dragging == 1:
		if tool == TOOL_QUEUE:
			place_queue_path(cell)
		else:
			_view.sim.cmd_place_path(cell)
	elif _dragging == 2:
		if tool == TOOL_QUEUE:
			remove_queue_path_at(cell)
		else:
			remove_path_at(cell)


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
			_last_drag_cell = GridPicker.INVALID
			if _drag_staff >= 0 and mb.button_index == MOUSE_BUTTON_LEFT:
				var drop: Vector2i = _picker.cell_under_mouse(_camera)
				if drop != GridPicker.INVALID:
					move_staff(_drag_staff, drop)
				_drag_staff = -1
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var cell: Vector2i = _picker.cell_under_mouse(_camera)
			if tool == TOOL_PATH or tool == TOOL_QUEUE:
				_dragging = 1
				_last_drag_cell = GridPicker.INVALID
				_apply_drag()
			elif cell == GridPicker.INVALID:
				return
			elif is_coaster_tool():
				if coaster_id < 0:
					place_coaster_station(cell)
				else:
					place_coaster_piece()
			elif tool == TOOL_MOVE:
				if move_kind == "":
					if not pick_up_at(cell):
						play_error()
				else:
					drop_move(move_origin_for(cell))
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
				if _view.decor_at(cell) < 0 and _view.sim.world.get_attraction_at(cell) == null:
					_dragging = 2  # træk for at fjerne flere stier
					_last_drag_cell = cell
				remove_building_at(cell)
			else:
				place_building(tool, _origin_under_mouse())
		elif tool == TOOL_MOVE:
			cancel_move()  # højreklik slipper det løftede (bliver hvor det var)
		else:
			_dragging = 2
			_last_drag_cell = GridPicker.INVALID
			_apply_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging != 0:
		_apply_drag()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		var clock: SimClock = _view.sim.clock
		if (k.ctrl_pressed or k.meta_pressed) and (k.keycode == KEY_Z or k.keycode == KEY_Y):
			undo(k.keycode == KEY_Y or k.shift_pressed)
			get_viewport().set_input_as_handled()
			return
		if tool == TOOL_MOVE and k.keycode == KEY_R:
			rotate_move()
			get_viewport().set_input_as_handled()
			return
		if k.keycode == KEY_ESCAPE and tool == TOOL_MOVE and move_kind != "":
			cancel_move()
			get_viewport().set_input_as_handled()
			return
		if k.keycode == KEY_ESCAPE:
			handle_escape()
			get_viewport().set_input_as_handled()
			return
		if is_coaster_tool() and _coaster_key(k.keycode):
			get_viewport().set_input_as_handled()
			return
		if KEY_CATEGORIES.has(k.keycode) and not k.ctrl_pressed and not k.meta_pressed:
			request_category(KEY_CATEGORIES[k.keycode])
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
## Åbner en kategori i BuildDock (som et klik på medaljonen). Signal via Selection til UI.
func request_category(cat: String) -> void:
	if _selection != null:
		_selection.build_category_requested.emit(cat)


func _request_tool(id: String) -> void:
	if _selection != null:
		_selection.build_tool_requested.emit(id)
	else:
		set_tool(id)
