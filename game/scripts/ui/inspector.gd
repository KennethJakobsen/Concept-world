class_name Inspector
extends PanelContainer
## Højre panel (T-101): detaljer om det valgte (bygning, gæst, personale). Fanerække øverst;
## "Oversigt" er altid første fane. Kun én kontekst ad gangen. Esc lukker (håndteres af Hud).
##
## Udvidelses-API (kontrakt M7 §4, bruges af T-112):
##   `register_tab(context, tab_id, title, factory)`. `factory` kaldes uden argumenter og skal
##   returnere en Control. Fanen bygges første gang den vises. Har kontrollen en metode
##   `refresh(sim: ParkSim, target_id: int)`, kaldes den hver frame mens fanen er synlig.

signal closed

const OVERVIEW: StringName = &"overview"
const WIDTH: float = 280.0
const TITLES: Dictionary = {&"attraction": "Bygning", &"guest": "Gæst", &"staff": "Personale"}
const PORTRAITS: Dictionary = {&"attraction": "cat_rides", &"guest": "guest_portrait", &"staff": "staff_portrait"}

var context: StringName = &""
var target_id: int = -1
var current_tab: StringName = OVERVIEW
var _overviews: Dictionary = {}   ## context -> Control
var _tabs: Dictionary = {}        ## context -> Array[Dictionary] {id, title, factory}
var _built: Dictionary = {}       ## "context/tab" -> Control
var _tab_row: HBoxContainer
var _body: VBoxContainer
var _title: Label
var _portrait: TextureRect


func build() -> void:
	name = "Inspector"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(WIDTH, 0)
	var v := VBoxContainer.new()
	v.name = "V"
	add_child(v)
	var sign := PanelContainer.new()
	sign.name = "Sign"
	sign.theme_type_variation = &"SignWood"
	v.add_child(sign)
	var sh := HBoxContainer.new()
	sign.add_child(sh)
	_portrait = UiTheme.icon_rect("guest_portrait", 32.0)
	sh.add_child(_portrait)
	_title = Label.new()
	_title.name = "Title"
	_title.theme_type_variation = &"TitleLabel"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(_title)
	var close: Button = UiTheme.medallion("close", 28.0)
	close.name = "Close"
	TooltipService.attach(close, "Luk", "Esc")
	close.pressed.connect(close_inspector)
	sh.add_child(close)
	var head := HBoxContainer.new()
	head.name = "Head"
	v.add_child(head)
	_tab_row = HBoxContainer.new()
	_tab_row.name = "Tabs"
	_tab_row.add_theme_constant_override("separation", 2)
	_tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_tab_row)
	_body = VBoxContainer.new()
	_body.name = "Body"
	v.add_child(_body)
	visible = false


## Oversigtsfanen for en kontekst (sat af Hud).
func set_overview(ctx: StringName, c: Control) -> void:
	_overviews[ctx] = c
	c.visible = false
	_body.add_child(c)


func register_tab(ctx: StringName, tab_id: StringName, title: String, factory: Callable) -> void:
	if not _tabs.has(ctx):
		_tabs[ctx] = []
	for t: Dictionary in _tabs[ctx]:
		if t.id == tab_id:
			t.title = title
			t.factory = factory
			_rebuild_tab_row()
			return
	(_tabs[ctx] as Array).append({"id": tab_id, "title": title, "factory": factory})
	_rebuild_tab_row()


func tab_ids(ctx: StringName = context) -> Array[StringName]:
	var out: Array[StringName] = [OVERVIEW]
	for t: Dictionary in _tabs.get(ctx, []):
		out.append(t.id)
	return out


func is_open() -> bool:
	return visible and context != &""


## Åbner inspektøren for et mål. Samme kontekst bevarer fanen.
func open(ctx: StringName, id: int) -> void:
	if ctx != context:
		current_tab = OVERVIEW
	context = ctx
	target_id = id
	visible = true
	_title.text = TITLES.get(ctx, String(ctx).capitalize())
	_portrait.texture = UiTheme.icon(PORTRAITS.get(ctx, "alert_info"))
	_rebuild_tab_row()
	_show_current()


func close_inspector() -> void:
	var was: bool = visible
	context = &""
	target_id = -1
	visible = false
	for c: Control in _overviews.values():
		c.visible = false
	if was:
		closed.emit()


func select_tab(tab_id: StringName) -> void:
	if not tab_ids().has(tab_id):
		return
	current_tab = tab_id
	_rebuild_tab_row()
	_show_current()


func current_control() -> Control:
	if current_tab == OVERVIEW:
		return _overviews.get(context, null)
	return _built.get("%s/%s" % [context, current_tab], null)


func refresh(sim: ParkSim) -> void:
	if not is_open() or current_tab == OVERVIEW:
		return
	var c: Control = current_control()
	if c != null and c.has_method("refresh"):
		c.call("refresh", sim, target_id)


func _show_current() -> void:
	for c in _body.get_children():
		(c as Control).visible = false
	if current_tab != OVERVIEW:
		var key: String = "%s/%s" % [context, current_tab]
		if not _built.has(key):
			for t: Dictionary in _tabs.get(context, []):
				if t.id == current_tab:
					var made: Variant = (t.factory as Callable).call()
					if made is Control:
						_built[key] = made
						_body.add_child(made)
	var cur: Control = current_control()
	if cur != null:
		cur.visible = true


func _rebuild_tab_row() -> void:
	if _tab_row == null:
		return
	for c in _tab_row.get_children():
		_tab_row.remove_child(c)
		c.queue_free()
	var defs: Array = [{"id": OVERVIEW, "title": "Oversigt"}]
	defs.append_array(_tabs.get(context, []))
	_tab_row.visible = defs.size() > 1
	for t: Dictionary in defs:
		var b := Button.new()
		b.name = "Tab_" + String(t.id)
		b.theme_type_variation = &"Tab"
		b.text = str(t.title)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.set_pressed_no_signal(t.id == current_tab)
		b.pressed.connect(select_tab.bind(t.id))
		_tab_row.add_child(b)
