class_name CoasterPalette
extends PanelContainer
## Rutsjebane-byggepalet: tegnede stykke-ikoner + "Fjern sidste", "Færdig" og "Fortsæt byg".
## Kalder BuildTool-metoderne fra kontrakt §6 defensivt (has_method).

signal message(text: String)

var tool: Node  ## BuildTool (kan mangle)
var _piece_btns: Dictionary = {}  ## piece_id -> Button
var _flow: HFlowContainer
var resume_id: int = -1  ## ufærdig bane valgt i info-panelet
var system: StringName = &"coaster"  ## aktivt sporsystem (ADR-004)
var _end_btn: Button


func build() -> void:
	name = "CoasterPalette"
	mouse_filter = Control.MOUSE_FILTER_STOP
	_flow = HFlowContainer.new()
	add_child(_flow)
	_rebuild()
	visible = false


## Skifter sporsystem og bygger stykke-knapperne om (filtreret efter system).
func set_system(sys: StringName) -> void:
	if sys == system and not _piece_btns.is_empty():
		return
	system = sys
	_rebuild()


func _rebuild() -> void:
	for c: Node in _flow.get_children():
		_flow.remove_child(c)
		c.queue_free()
	_piece_btns.clear()
	var pieces: Dictionary = CoasterContent.pieces(system)
	for id: String in _ordered_ids(pieces):
		var d: TrackPieceDef = pieces[id]
		if d.kind == "station":
			continue
		var b := Button.new()
		b.name = "Piece_" + id
		b.text = "%s ($%d)" % [d.name, d.cost]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		var icon := UiIcons.piece_icon(d, 24.0)
		icon.position = Vector2(4, 3)
		b.add_child(icon)
		b.custom_minimum_size = Vector2(0, 30)
		b.pressed.connect(choose_piece.bind(id))
		_flow.add_child(b)
		_piece_btns[id] = b
		# plads til ikonet til venstre for teksten
		b.text = "      " + b.text
	_end_btn = null
	var end_id: String = end_station_id(system)
	if end_id != "":
		_end_btn = _btn("Endestation", choose_piece.bind(end_id))
		_end_btn.toggle_mode = true
		_end_btn.tooltip_text = "Placér endestationen (banen skal være mindst 2 stykker)"
		_piece_btns[end_id] = _end_btn
	_btn("Fjern sidste", remove_last)
	_btn("Færdig", finish)
	_btn("Fortsæt byg", resume)


## Endestationens stykke-id, hvis systemet har to stationer (svævebanen), ellers "".
static func end_station_id(sys: StringName) -> String:
	if int(CoasterContent.system_def(sys).get("max_stations", 1)) < 2:
		return ""
	return CoasterContent.station_id(sys, "end")


static func _ordered_ids(pieces: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for id: String in pieces:
		out.append(id)
	return out


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.name = text.replace(" ", "")
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	_flow.add_child(b)
	return b


func piece_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in _piece_btns:
		out.append(id)
	return out


func button(id: String) -> Button:
	return _piece_btns.get(id, null)


func _tool_ok(m: String) -> bool:
	return tool != null and is_instance_valid(tool) and tool.has_method(m)


func choose_piece(id: String) -> void:
	for pid: String in _piece_btns:
		(_piece_btns[pid] as Button).set_pressed_no_signal(pid == id)
	if _tool_ok("set_coaster_piece"):
		tool.call("set_coaster_piece", id)


func remove_last() -> void:
	if _tool_ok("remove_last_coaster_piece"):
		tool.call("remove_last_coaster_piece")


func finish() -> void:
	if _tool_ok("finish_coaster"):
		var errs: Array = tool.call("finish_coaster", resume_id)  # T-130
		if errs.is_empty():
			message.emit("Rutsjebanen er åben!" if system == &"coaster" else "Banen er åben!")


func resume() -> void:
	if resume_id >= 0 and _tool_ok("resume_coaster"):
		if not bool(tool.call("resume_coaster", resume_id)):
			message.emit("Banen kan ikke genoptages.")
	elif resume_id < 0:
		message.emit("Vælg en ufærdig rutsjebane først.")


## Låste stykker grå med hængelås og tooltip.
func refresh(sim: ParkSim) -> void:
	for id: String in _piece_btns:
		var b: Button = _piece_btns[id]
		var locked: bool = sim != null and not sim.is_unlocked(id)
		LockOverlay.apply(b, locked)
		if _tool_ok("get") and "coaster_piece" in tool:
			b.set_pressed_no_signal(str(tool.get("coaster_piece")) == id)


## Oversætter fejlkoder til én dansk tekst.
static func errors_text(codes: Array) -> String:
	var out: Array[String] = []
	for c: Variant in codes:
		out.append(M6Texts.track_error(str(c)))
	return " ".join(out)
