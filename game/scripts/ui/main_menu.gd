class_name MainMenu
extends Control
## Hovedmenu: Ny park, Fortsæt (autosave), Indlæs (slot-liste), Afslut (skjult på web).

const THEME_RES: Theme = preload("res://ui/theme.tres")

var store: SaveStore = SaveStore.new()
var _panel: PanelContainer
var _continue_btn: Button
var _quit_btn: Button
var _load_box: VBoxContainer
var _slots: SaveSlotList
var _status: Label


func _ready() -> void:
	build()
	layout(get_viewport().get_visible_rect().size)
	get_viewport().size_changed.connect(func() -> void: layout(get_viewport().get_visible_rect().size))


static func show_quit() -> bool:
	return not OS.has_feature("web")


func build() -> void:
	theme = THEME_RES
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.16, 0.32, 0.22)
	add_child(bg)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(320, 0)
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_panel.add_child(v)
	var title := Label.new()
	title.text = "Concept-world"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_btn(v, "Ny park", new_park)
	_continue_btn = _btn(v, "Fortsæt", continue_park)
	_btn(v, "Indlæs...", toggle_load_list)
	_load_box = VBoxContainer.new()
	_load_box.visible = false
	v.add_child(_load_box)
	_slots = SaveSlotList.new()
	_slots.store = store
	_load_box.add_child(_slots)
	_slots.build(160.0)
	_slots.slot_chosen.connect(load_slot)
	_quit_btn = _btn(v, "Afslut", func() -> void: get_tree().quit())
	_quit_btn.visible = show_quit()
	_status = Label.new()
	v.add_child(_status)
	refresh()


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.name = text.replace(".", "")
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func refresh() -> void:
	_continue_btn.visible = store.exists(SaveStore.AUTOSAVE_SLOT)
	_slots.store = store
	_slots.reload()


func layout(vp: Vector2) -> void:
	position = Vector2.ZERO
	size = vp
	(get_node("Background") as Control).size = vp
	_slots.set_height(clampf(vp.y - 360.0, 60.0, 240.0))
	var m: Vector2 = _panel.get_combined_minimum_size()
	_panel.size = m
	_panel.position = ((vp - m) * 0.5).max(Vector2.ZERO)


func panel_rect() -> Rect2:
	return Rect2(_panel.position, _panel.get_combined_minimum_size())


func new_park() -> void:
	UiSession.start_new(int(Time.get_unix_time_from_system()) & 0x7fffffff)


func continue_park() -> void:
	load_slot(SaveStore.AUTOSAVE_SLOT)


func load_slot(slot: String) -> void:
	if not UiSession.load_slot(slot):
		_status.text = "Kunne ikke indlæse " + slot


func toggle_load_list() -> void:
	_load_box.visible = not _load_box.visible
	refresh()
	if is_inside_tree():
		layout(get_viewport().get_visible_rect().size)


func set_load_list_visible(v: bool) -> void:
	_load_box.visible = v
