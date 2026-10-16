class_name AlertTray
extends VBoxContainer
## Varsler nederst til højre (T-101): små toasts med ikon, der forsvinder efter 4 s. Klik flytter
## kameraet til `cell` via GameSession.focus_cell (T-111), hvis den findes. Historik til klokken i TopBar.
##
## Udvidelses-API (kontrakt M7 §4): `push(text, icon, cell := Vector2i(-1, -1))`.

signal alert_clicked(cell: Vector2i)
signal unread_changed(count: int)

const NO_CELL := Vector2i(-1, -1)
const DURATION: float = 4.0
const MAX_VISIBLE: int = 4
const HISTORY: int = 10
const WIDTH: float = 300.0

var unread: int = 0
var history: Array[Dictionary] = []  ## {text, icon, cell}, nyeste sidst


func _init() -> void:
	name = "AlertTray"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_END
	custom_minimum_size = Vector2(WIDTH, 0)
	add_theme_constant_override("separation", 4)


## Tilføjer et varsel. icon er en UiIcons-kind ("alert", "info", ...). Returnerer knappen.
func push(text: String, icon: String = "info", cell: Vector2i = NO_CELL) -> Button:
	history.append({"text": text, "icon": icon, "cell": cell})
	while history.size() > HISTORY:
		history.pop_front()
	unread += 1
	unread_changed.emit(unread)
	return _add_item(text, icon, cell)


func _add_item(text: String, icon: String, cell: Vector2i) -> Button:
	var b := Button.new()
	b.name = "Alert"
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(WIDTH, 32)
	b.text = "      " + text  # plads til det tegnede ikon
	b.set_meta(&"left", DURATION)
	b.set_meta(&"cell", cell)
	var ic := UiIcons.new(icon, 18.0)
	ic.position = Vector2(8, 7)
	b.add_child(ic)
	if cell != NO_CELL:
		TooltipService.attach(b, "Klik for at se stedet")
	b.pressed.connect(_on_click.bind(b))
	add_child(b)
	while items().size() > MAX_VISIBLE:
		var old: Control = items()[0]
		remove_child(old)
		old.queue_free()
	return b


func items() -> Array[Button]:
	var out: Array[Button] = []
	for c in get_children():
		if c is Button and not c.is_queued_for_deletion():
			out.append(c)
	return out


func texts() -> Array[String]:
	var out: Array[String] = []
	for b in items():
		out.append(b.text.strip_edges())
	return out


func clear_unread() -> void:
	unread = 0
	unread_changed.emit(0)


## Viser de seneste varsler igen (klokken).
func show_history() -> void:
	clear_unread()
	for c in items():
		remove_child(c)
		c.queue_free()
	var start: int = maxi(0, history.size() - MAX_VISIBLE)
	for i in range(start, history.size()):
		var h: Dictionary = history[i]
		_add_item(str(h.text), str(h.icon), h.cell)


func _on_click(b: Button) -> void:
	var cell: Vector2i = b.get_meta(&"cell", NO_CELL)
	if cell != NO_CELL:
		alert_clicked.emit(cell)
		var gs: Node = get_node_or_null("/root/GameSession") if is_inside_tree() else null
		if gs != null and gs.has_method("focus_cell"):
			gs.call("focus_cell", cell)
	remove_child(b)
	b.queue_free()


## Kaldes hver frame (eller manuelt i tests).
func tick(delta: float) -> void:
	for b in items():
		var left: float = float(b.get_meta(&"left", 0.0)) - delta
		b.set_meta(&"left", left)
		b.modulate.a = clampf(left / 0.5, 0.0, 1.0)
		if left <= 0.0:
			remove_child(b)
			b.queue_free()


func _process(delta: float) -> void:
	tick(delta)
