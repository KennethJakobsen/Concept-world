class_name MainMenu
extends Control
## Hovedmenu: Nyt scenarie (liste), Fri leg, Fortsæt (autosave), Indlæs (slot-liste), Afslut (skjult på web).

const ICONS: Dictionary = {"Nyt scenarie": "menu_new", "Fri leg": "menu_new", "Fortsæt": "menu_continue",
	"Indlæs...": "menu_load", "Indstillinger": "menu_settings", "Afslut": "menu_quit"}

var store: SaveStore = SaveStore.new()
var _panel: PanelContainer
var _continue_btn: Button
var _quit_btn: Button
var _load_box: VBoxContainer
var _slots: SaveSlotList
var _status: Label
var _scenario_box: VBoxContainer
var _scenario_scroll: ScrollContainer
var scenario_list: ScenarioList
var settings: SettingsPanel


func _ready() -> void:
	UiSound.install(get_tree())
	build()
	layout(get_viewport().get_visible_rect().size)
	get_viewport().size_changed.connect(func() -> void: layout(get_viewport().get_visible_rect().size))


static func show_quit() -> bool:
	return not OS.has_feature("web")


func build() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color("#7FB8D8")
	add_child(bg)
	bg.add_child(_full_rect(_gradient_tex(false)))
	bg.add_child(_full_rect(_gradient_tex(true)))
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(320, 0)
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_panel.add_child(v)
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.texture = load("res://assets/ui/logo/logo_full_512.png") as Texture2D
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(340, 146)
	logo.tooltip_text = "Concept-world"
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(logo)
	_btn(v, "Nyt scenarie", toggle_scenario_list)
	_scenario_box = VBoxContainer.new()
	_scenario_box.name = "Scenarios"
	_scenario_box.visible = false
	v.add_child(_scenario_box)
	_scenario_scroll = ScrollContainer.new()
	_scenario_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scenario_scroll.custom_minimum_size = Vector2(440, 200)
	_scenario_box.add_child(_scenario_scroll)
	scenario_list = ScenarioList.new()
	scenario_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scenario_scroll.add_child(scenario_list)
	scenario_list.build()
	scenario_list.scenario_chosen.connect(start_scenario)
	_btn(v, "Fri leg", new_park)
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
	_btn(v, "Indstillinger", open_settings)
	_quit_btn = _btn(v, "Afslut", func() -> void: get_tree().quit())
	_quit_btn.visible = show_quit()
	_status = Label.new()
	v.add_child(_status)
	settings = SettingsPanel.new()
	add_child(settings)
	settings.build()
	refresh()


func open_settings() -> void:
	settings.open()


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.name = text.replace(".", "")
	b.theme_type_variation = &"BigButton"
	b.custom_minimum_size = Vector2(280, 44)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.icon = UiTheme.icon(ICONS.get(text, ""))
	b.add_theme_constant_override("icon_max_width", 28)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


static func _full_rect(tex: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Himmel -> græs (lodret) eller varm vignet (radial, sort a 0 -> 0,45 i kanterne).
static func _gradient_tex(vignette: bool) -> GradientTexture2D:
	var g := Gradient.new()
	var t := GradientTexture2D.new()
	t.width = 256
	t.height = 256
	if vignette:
		g.set_color(0, Color(0.2, 0.1, 0.0, 0.0))
		g.set_color(1, Color(0.1, 0.05, 0.0, 0.45))
		g.add_point(0.55, Color(0.2, 0.1, 0.0, 0.0))
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 1.0)
	else:
		g.set_color(0, Color("#9FD3EE"))
		g.set_color(1, Color("#5E9E3E"))
		g.add_point(0.62, Color("#E9F2DA"))
		g.add_point(0.66, Color("#7DBF55"))
		t.fill_from = Vector2(0.5, 0.0)
		t.fill_to = Vector2(0.5, 1.0)
	t.gradient = g
	return t


func refresh() -> void:
	_continue_btn.visible = store.exists(SaveStore.AUTOSAVE_SLOT)
	_slots.store = store
	_slots.reload()


func layout(vp: Vector2) -> void:
	position = Vector2.ZERO
	size = vp
	(get_node("Background") as Control).size = vp
	_slots.set_height(clampf(vp.y - 450.0, 60.0, 240.0))
	_scenario_scroll.custom_minimum_size.y = clampf(vp.y - 480.0, 80.0, 320.0)
	var m: Vector2 = _panel.get_combined_minimum_size()
	_panel.size = m
	_panel.position = ((vp - m) * 0.5).max(Vector2.ZERO)
	if settings != null:
		settings.layout(vp)


func panel_rect() -> Rect2:
	return Rect2(_panel.position, _panel.get_combined_minimum_size())


static func _seed() -> int:
	return int(Time.get_unix_time_from_system()) & 0x7fffffff


## "Fri leg" (sandbox).
func new_park() -> void:
	UiSession.start_sandbox(_seed())


func start_scenario(scenario_id: String) -> void:
	UiSession.start_scenario(scenario_id, _seed())


func toggle_scenario_list() -> void:
	set_scenario_list_visible(not _scenario_box.visible)


func set_scenario_list_visible(on: bool) -> void:
	_scenario_box.visible = on
	if on:
		_load_box.visible = false
	if is_inside_tree():
		layout(get_viewport().get_visible_rect().size)


func continue_park() -> void:
	load_slot(SaveStore.AUTOSAVE_SLOT)


func load_slot(slot: String) -> void:
	if not UiSession.load_slot(slot):
		_status.text = "Kunne ikke indlæse " + slot


func toggle_load_list() -> void:
	_load_box.visible = not _load_box.visible
	if _load_box.visible:
		_scenario_box.visible = false
	refresh()
	if is_inside_tree():
		layout(get_viewport().get_visible_rect().size)


func set_load_list_visible(v: bool) -> void:
	_load_box.visible = v
