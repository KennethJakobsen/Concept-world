class_name PauseMenu
extends Control
## Pause-overlay i HUD: Fortsæt, Gem (slotnavn), Indlæs (slot-liste), Hovedmenu.
## HUD pauser/genoptager simulationen; denne klasse sender kun kommandoer via UiSession.

signal closed

var sim_provider: Callable  ## () -> ParkSim (sættes af HUD)
var _panel: PanelContainer
var _name_edit: LineEdit
var _status: Label
var _slots: SaveSlotList
var _load_box: VBoxContainer


func build() -> void:
	name = "PauseMenu"
	mouse_filter = Control.MOUSE_FILTER_STOP  # blokerer klik til spillet mens åben
	visible = false
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.custom_minimum_size = Vector2(320, 0)
	add_child(_panel)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	var title := Label.new()
	title.text = "Pause"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_btn(v, "Fortsæt", close)
	var sh := HBoxContainer.new()
	v.add_child(sh)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Navn på gemt park"
	_name_edit.text = "park1"
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(_name_edit)
	_btn(sh, "Gem", func() -> void: save_as(_name_edit.text.strip_edges()))
	_btn(v, "Indlæs...", toggle_load_list)
	_load_box = VBoxContainer.new()
	_load_box.visible = false
	v.add_child(_load_box)
	_slots = SaveSlotList.new()
	_load_box.add_child(_slots)
	_slots.build(140.0)
	_slots.slot_chosen.connect(load_slot)
	_btn(v, "Hovedmenu", to_main_menu)
	_status = Label.new()
	_status.name = "Status"
	v.add_child(_status)


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func layout(vp: Vector2) -> void:
	position = Vector2.ZERO
	size = vp
	var dim: Control = get_node("Dim")
	dim.position = Vector2.ZERO
	dim.size = vp
	# Slot-listen må krympe på lave skærme.
	_slots.set_height(clampf(vp.y - 330.0, 60.0, 200.0))
	var m: Vector2 = _panel.get_combined_minimum_size()
	_panel.size = m
	_panel.position = ((vp - m) * 0.5).max(Vector2.ZERO)


func panel_rect() -> Rect2:
	return Rect2(_panel.position, _panel.get_combined_minimum_size())


func open() -> void:
	_status.text = ""
	_slots.reload()
	visible = true
	var vp: Vector2 = get_viewport().get_visible_rect().size if is_inside_tree() else size
	layout(vp)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func toggle_load_list() -> void:
	_load_box.visible = not _load_box.visible
	_slots.reload()
	if is_inside_tree():
		layout(get_viewport().get_visible_rect().size)


func set_load_list_visible(v: bool) -> void:
	_load_box.visible = v


func save_as(slot: String) -> bool:
	if not SaveStore.is_valid_slot(slot):
		_status.text = "Ugyldigt navn"
		return false
	var sim: ParkSim = sim_provider.call() if sim_provider.is_valid() else null
	var ok: bool = UiSession.save_slot(slot, sim)
	_status.text = ("Gemt: " + slot) if ok else "Kunne ikke gemme"
	_slots.reload()
	return ok


func load_slot(slot: String) -> void:
	if UiSession.load_slot(slot):
		visible = false  # ny scene/sim overtager; HUD genoptager ikke gammel sim
	else:
		_status.text = "Kunne ikke indlæse"


func to_main_menu() -> void:
	visible = false
	UiSession.go_to_main_menu()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
