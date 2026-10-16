class_name Hud
extends CanvasLayer
## HUD: top-bar, byggemenu og info-paneler. Læser kun state fra ParkSim og sender kommandoer.
## Finder ParkView (gruppe "park_view") og Selection (gruppe "selection") robust (null-checks).

const ATTRACTION_DIR: String = "res://content/attractions/"
const DECOR_DIR: String = "res://content/decor/"
const STAFF_DIR: String = "res://content/staff/"
const TABS: Array[String] = BuildDock.CATEGORIES
const TAB_NAMES: Dictionary = BuildDock.CATEGORY_NAMES
const STAFF_STATE_NAMES: Dictionary = {0: "Ledig", 1: "Går", 2: "Arbejder"}
const STAFF_TASK_NAMES: Dictionary = {"repair": "Reparerer", "inspect": "Inspicerer", "sweep": "Fejer",
	"empty_bin": "Tømmer skraldespand", "patrol": "Underholder"}
const SPEEDS: Array[float] = [1.0, 2.0, 4.0]
const MARGIN: float = 8.0
const NEED_NAMES: Dictionary = {"hunger": "Sult", "thirst": "Tørst", "toilet": "Toilet", "energy": "Træthed"}

var sim: ParkSim
var selection: Node

var _top_label: Label
var _clock_icon: ClockIcon
var _clock_label: Label
var _toast: Toast
var _warn_sim: ParkSim  ## sim, hvis warning-signal er forbundet
var _stars: StarRating
var _pause_btn: Button
var _build_buttons: Dictionary = {}  ## def_id -> Button
var _build_costs: Dictionary = {}    ## def_id -> int
var _attr_panel: Control
var _attr_label: Label
var _attr_open_btn: Button
var _guest_panel: Control
var _guest_label: Label
var _attr_bars: Dictionary = {}  ## "intensity"/"nausea" -> ProgressBar (T-089)
var _attr_bar_box: VBoxContainer
var _guest_bars: Dictionary = {}  ## "nausea"/"tolerance" -> ProgressBar
var _guest_items: HBoxContainer
var _park_panel: PanelContainer
var _park_label: Label
var _staff_panel: Control
var _staff_label: Label
var _staff_list_panel: PanelContainer
var _staff_list: VBoxContainer
var _staff_list_ids: Array = []
var _pause_menu: PauseMenu
var _build_tab: Dictionary = {}  ## def_id -> fane ("" = altid synlig)
var _tab_buttons: Dictionary = {}  ## fane -> Button
var current_tab: String = "rides"
var _sel_staff: int = -1
var _sel_attraction: int = -1
var _sel_guest: int = -1
# M5 (T-071)
var objective_panel: ObjectivePanel
var research_panel: ResearchPanel
var result_dialog: ResultDialog
var coaster_palette: CoasterPalette
var _research_btn: Button
var _attr_resume_btn: Button
var _build_tool: Node
var _scn_sim: ParkSim  ## sim, hvis scenario_finished er forbundet
# M7 (T-101): skærmzoner
var top_bar: TopBar
var build_dock: BuildDock
var inspector: Inspector
var park_rail: ParkRail
var alert_tray: AlertTray
var user_settings: UserSettings
var settings_path: String = UserSettings.PATH
var _alert_count: int = 0  ## tests kan pege et andet sted hen


func _ready() -> void:
	UiSound.install(get_tree())
	TooltipService.install()
	fit_window_to_screen()
	_build_ui()
	_connect_scene()


## Desktop: vinduet må ikke være større end skærmens brugbare område (dock/menulinje).
## Skaleres til max 85 % og centreres. Ingen effekt i browser/headless.
static func fit_window_to_screen() -> void:
	if OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	var screen: int = DisplayServer.window_get_current_screen()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	var size: Vector2i = DisplayServer.window_get_size()
	var max_size := Vector2i(int(usable.size.x * 0.85), int(usable.size.y * 0.85))
	if size.x <= max_size.x and size.y <= max_size.y:
		return
	var f: float = minf(float(max_size.x) / size.x, float(max_size.y) / size.y)
	size = Vector2i(int(size.x * f), int(size.y * f))
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(usable.position + (usable.size - size) / 2)


func _enter_tree() -> void:
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)


var _in_layout: bool = false
var _last_vp: Vector2 = Vector2.ZERO


## Genberegner layoutet straks (samme frame), når dock/top-bar ændrer størrelse.
func _relayout() -> void:
	if _in_layout:
		return
	if is_inside_tree():
		layout(get_viewport().get_visible_rect().size)
	elif _last_vp != Vector2.ZERO:
		layout(_last_vp)


func _on_viewport_resized() -> void:
	layout(get_viewport().get_visible_rect().size)


## Placerer top-bar og byggemenu inden for viewporten. Panelernes højde beregnes ud fra
## ombrydning af knapperne ved den givne bredde, så byggemenuen altid ligger helt synlig i bunden.
func layout(vp: Vector2) -> void:
	var root: Control = get_node_or_null("Root")
	if root == null or _in_layout:
		return
	_in_layout = true
	_last_vp = vp
	_layout_impl(root, vp)
	_in_layout = false


func _layout_impl(root: Control, vp: Vector2) -> void:
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2.ZERO
	root.size = vp
	var w: float = maxf(0.0, vp.x - 2.0 * MARGIN)
	var top: PanelContainer = root.get_node("TopBar")
	var bottom: PanelContainer = root.get_node("BuildMenu")
	var top_h: float = _panel_height(top, w)
	top.position = Vector2(MARGIN, MARGIN)
	top.size = Vector2(w, top_h)
	# Byggedok: centreret, svæver 12 px over bunden; kortgitteret tilpasses bredden.
	var cols: int = int((w - 40.0) / (BuildDock.CARD_SIZE.x + BuildDock.CARD_GAP))
	build_dock.set_grid(cols, 2 if vp.y >= 900.0 else 1)
	var bs: Vector2 = build_dock.dock_size()
	bs.x = minf(bs.x, w)
	bottom.size = bs
	bs = bottom.size  # Control kan klampe til (cachet) minimum – placér ud fra den faktiske størrelse
	bottom.position = Vector2(maxf(MARGIN, (vp.x - bs.x) * 0.5), maxf(MARGIN, vp.y - 12.0 - bs.y))
	for p: Control in [top, bottom]:
		_sort_tree(p)
	if _staff_list_panel == null:
		return  # under opbygning
	var max_h: float = maxf(0.0, bottom.position.y - top_h - 3.0 * MARGIN)
	for p: Control in right_panels():
		p.position = Vector2(maxf(MARGIN, vp.x - MARGIN - p.custom_minimum_size.x), top_h + 2.0 * MARGIN)
		p.size = Vector2(p.custom_minimum_size.x, minf(p.get_combined_minimum_size().y, max_h))
	var rail_w: float = 0.0
	if park_rail != null:
		park_rail.position = Vector2(MARGIN, top_h + 2.0 * MARGIN)
		park_rail.size = park_rail.get_combined_minimum_size()
		rail_w = park_rail.size.x + MARGIN
		var rp: Control = park_rail.panel(park_rail.open_id)
		if rp != null:
			var ps: Vector2 = rp.get_combined_minimum_size()
			ps.y = minf(ps.y, max_h)
			rp.size = ps
			rp.position = Vector2(maxf(MARGIN + rail_w, (vp.x - ps.x) * 0.5), top_h + 2.0 * MARGIN)
	# Personale-listen scroller inden for den plads der er mellem top- og byggebjælke.
	var scroll: ScrollContainer = _staff_list_panel.get_node("V/Scroll")
	scroll.custom_minimum_size.y = clampf(max_h - 90.0, 40.0, 260.0)
	if objective_panel != null:
		objective_panel.position = Vector2(MARGIN + rail_w, top_h + 2.0 * MARGIN)
		objective_panel.size = objective_panel.get_combined_minimum_size()
	if coaster_palette != null:
		var ph: float = _panel_height(coaster_palette, w)
		coaster_palette.position = Vector2(MARGIN, maxf(MARGIN, bottom.position.y - MARGIN - ph))
		coaster_palette.size = Vector2(w, ph)
		_sort_tree(coaster_palette)
	if alert_tray != null:
		var floor_y: float = bottom.position.y
		if coaster_palette != null and coaster_palette.visible:
			floor_y = coaster_palette.position.y
		var ah: float = alert_tray.get_combined_minimum_size().y
		alert_tray.size = Vector2(alert_tray.custom_minimum_size.x, ah)
		alert_tray.position = Vector2(maxf(MARGIN, vp.x - MARGIN - alert_tray.size.x),
			maxf(top_h + 2.0 * MARGIN, floor_y - MARGIN - ah))
	if result_dialog != null:
		result_dialog.layout(vp)
	if _toast != null:
		var tw: float = minf(420.0, w)
		_toast.size = Vector2(tw, 0)
		_toast.position = Vector2((vp.x - tw) * 0.5, top_h + 2.0 * MARGIN)
	if _pause_menu != null:
		_pause_menu.layout(vp)


func right_panels() -> Array[Control]:
	return [inspector, _park_panel, _staff_list_panel, research_panel]


static func _sort_tree(c: Control) -> void:
	if c is Container:
		c.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for ch in c.get_children():
		if ch is Control:
			_sort_tree(ch)


## Højde af et panel med én flow-container når indholdet ombrydes til bredden w.
static func _panel_height(p: PanelContainer, w: float) -> float:
	var sb: StyleBox = p.get_theme_stylebox("panel")
	var inner_w: float = w - (sb.get_minimum_size().x if sb != null else 0.0)
	var flow: FlowContainer = p.get_child(0)
	var hsep: float = flow.get_theme_constant("h_separation")
	var vsep: float = flow.get_theme_constant("v_separation")
	var x: float = 0.0
	var line_h: float = 0.0
	var total: float = 0.0
	for ch in flow.get_children():
		if not (ch as Control).visible:
			continue
		var m: Vector2 = (ch as Control).get_combined_minimum_size()
		if x > 0.0 and x + m.x > inner_w:
			total += line_h + vsep
			x = 0.0
			line_h = 0.0
		x += m.x + hsep
		line_h = maxf(line_h, m.y)
	total += line_h
	return total + (sb.get_minimum_size().y if sb != null else 0.0)


func _connect_scene() -> void:
	if sim == null:
		var pv: Node = get_tree().get_first_node_in_group("park_view")
		if pv != null and "sim" in pv:
			sim = pv.get("sim")
	if selection == null:
		selection = get_tree().get_first_node_in_group("selection")
		if selection != null:
			if selection.has_signal("selected_attraction"):
				selection.connect("selected_attraction", show_attraction)
			if selection.has_signal("selected_guest"):
				selection.connect("selected_guest", show_guest)
			if selection.has_signal("cleared"):
				selection.connect("cleared", clear_selection)
			if selection.has_signal("selected_staff"):
				selection.connect("selected_staff", show_staff)
			if selection.has_signal("pause_menu_requested"):
				selection.connect("pause_menu_requested", open_pause_menu)


func _process(_delta: float) -> void:
	if selection == null:
		_connect_scene()
	# Følg ParkView's sim (kan udskiftes ved indlæsning).
	var pv: Node = get_tree().get_first_node_in_group("park_view")
	if pv != null and "sim" in pv and pv.get("sim") != null and pv.get("sim") != sim:
		sim = pv.get("sim")
		clear_selection()
	refresh()
	if alert_tray != null and alert_tray.items().size() != _alert_count:
		_alert_count = alert_tray.items().size()
		layout(get_viewport().get_visible_rect().size)


# --- Opbygning ---

func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.theme = UiTheme.get_theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	user_settings = UserSettings.load_from(settings_path)
	if is_inside_tree():
		user_settings.apply(get_tree())

	# Top-bar
	top_bar = TopBar.new()
	root.add_child(top_bar)
	top_bar.build()
	top_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)  # placeres af layout()
	_clock_icon = top_bar.clock_icon
	_clock_label = top_bar.clock_label
	_top_label = top_bar.label
	_stars = top_bar.stars
	_pause_btn = top_bar.pause_btn
	top_bar.pause_pressed.connect(_on_pause)
	top_bar.speed_pressed.connect(_on_speed)
	top_bar.bell_pressed.connect(_on_bell)

	# Bund-dok: værktøjer, 6 kategorier og kort
	build_dock = BuildDock.new()
	root.add_child(build_dock)
	build_dock.build()
	build_dock.set_anchors_preset(Control.PRESET_TOP_LEFT)  # placeres af layout()
	build_dock.category_selected.connect(set_tab)
	build_dock.layout_changed.connect(_relayout)  # T-141: luk/åbn kort -> dock tilbage i bunden
	top_bar.minimum_size_changed.connect(_relayout)  # T-142: tekst-/datoskift -> ingen hop
	build_dock.card_pressed.connect(request_build_tool)
	_add_build_button(null, "select", "Vælg", 0)
	_add_build_button(null, "remove", "Fjern", 0)
	TooltipService.attach(_build_buttons["select"], "Vælg (Esc)", "Klik på en bygning, gæst eller medarbejder for at se detaljer.")
	TooltipService.attach(_build_buttons["remove"], "Fjern (X)", "Fjern sti, bygning eller dekoration. Træk for at fjerne flere stier. Højreklik i sti-værktøjet fjerner også sti.")
	for t: String in TABS:
		_tab_buttons[t] = build_dock.add_category(t)
	_add_build_button(null, "path", "Sti", 0, "paths")
	TooltipService.attach(_build_buttons["path"], "Sti (1)", "Træk for at bygge, højreklik-træk for at fjerne.")
	_add_build_button(null, "queue_path", "Køsti", 15, "paths", "$15",  # T-140
		"Byg fra en forlystelses indgang og ud til en sti. Gæsterne stiller sig i kø langs køstien.\nTræk for at bygge, højreklik-træk for at fjerne.")
	for d: AttractionDef in load_defs():
		var body: String = card_body(d)
		if CoasterContent.is_tracked_kind(d.kind):
			_add_build_button(null, "coaster:" + d.id, d.name, d.build_cost, "coaster", "fra $%d" % d.build_cost, body)
			continue
		var tab: String = "rides" if d.kind == "ride" else "shops"
		_add_build_button(null, d.id, d.name, d.build_cost, tab, "$%d" % d.build_cost, body)
	for d: DecorDef in load_decor_defs():
		_add_build_button(null, "decor:" + d.id, d.name, d.build_cost, "decor", "$%d" % d.build_cost,
			"Pris: $%d" % d.build_cost + ("\nGlæde i nærheden +%s" % str(d.happiness_aura) if d.happiness_aura > 0.0 else ""))
	for d: StaffDef in load_staff_defs():
		_add_build_button(null, "staff:" + d.id, d.name, 0, "staff", "$%d/dag" % d.wage_per_day,
			"Løn: $%d/dag. Klik på en sti for at ansætte." % d.wage_per_day)
	set_tab(current_tab)
	build_dock.close_cards()

	# Inspektør (højre side): oversigter for bygning, gæst og personale
	inspector = Inspector.new()
	root.add_child(inspector)
	inspector.build()
	_place_right(inspector)
	inspector.custom_minimum_size = Vector2(Inspector.WIDTH, 0)
	inspector.closed.connect(_on_inspector_closed)
	_attr_panel = VBoxContainer.new()
	_attr_panel.name = "AttractionPanel"
	inspector.set_overview(&"attraction", _attr_panel)
	var av: VBoxContainer = _attr_panel
	_attr_label = Label.new()
	av.add_child(_attr_label)
	_attr_bar_box = VBoxContainer.new()
	av.add_child(_attr_bar_box)
	_attr_bars["intensity"] = _bar(_attr_bar_box, "Intensitet", Color(0.95, 0.6, 0.2))
	_attr_bars["nausea"] = _bar(_attr_bar_box, "Kvalme", Color(0.45, 0.8, 0.3))
	var ph := HBoxContainer.new()
	av.add_child(ph)
	_button(ph, "Pris -", _on_price.bind(-1))
	_button(ph, "Pris +", _on_price.bind(1))
	_attr_open_btn = _button(av, "Luk", _on_toggle_open)
	_attr_resume_btn = _button(av, "Fortsæt byg", _on_resume_coaster)
	_attr_resume_btn.visible = false
	_button(av, "Riv ned", _on_demolish)

	_guest_panel = VBoxContainer.new()
	_guest_panel.name = "GuestPanel"
	inspector.set_overview(&"guest", _guest_panel)
	var gv: VBoxContainer = _guest_panel
	_guest_label = Label.new()
	gv.add_child(_guest_label)
	_guest_bars["nausea"] = _bar(gv, "Kvalme", Color(0.45, 0.8, 0.3))
	_guest_bars["tolerance"] = _bar(gv, "Tolerance", Color(0.4, 0.6, 0.95))
	_guest_items = HBoxContainer.new()
	_guest_items.name = "GuestItems"
	gv.add_child(_guest_items)

	_staff_panel = VBoxContainer.new()
	_staff_panel.name = "StaffPanel"
	inspector.set_overview(&"staff", _staff_panel)
	var sv: VBoxContainer = _staff_panel
	_staff_label = Label.new()
	sv.add_child(_staff_label)
	_button(sv, "Fyr", _on_fire_selected)

	_park_panel = _panel(root, "ParkPanel")
	_place_right(_park_panel)
	var pv := VBoxContainer.new()
	_park_panel.add_child(pv)
	_park_label = Label.new()
	pv.add_child(_park_label)
	var eh := HBoxContainer.new()
	pv.add_child(eh)
	_button(eh, "Entré -", change_entry_fee.bind(-1))
	_button(eh, "Entré +", change_entry_fee.bind(1))
	_button(pv, "Luk panel", toggle_park_panel)
	_park_panel.visible = false

	_staff_list_panel = _panel(root, "StaffListPanel")
	_place_right(_staff_list_panel)
	var lv := VBoxContainer.new()
	lv.name = "V"
	_staff_list_panel.add_child(lv)
	var lt := Label.new()
	lt.name = "Title"
	lv.add_child(lt)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 200)
	lv.add_child(scroll)
	_staff_list = VBoxContainer.new()
	_staff_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_staff_list)
	_button(lv, "Luk panel", toggle_staff_list)
	_staff_list_panel.visible = false

	_pause_menu = PauseMenu.new()
	_pause_menu.name = "PauseMenu"
	root.add_child(_pause_menu)
	_pause_menu.build()
	_pause_menu.closed.connect(_on_pause_menu_closed)
	_pause_menu.sim_provider = func() -> ParkSim: return sim

	_build_m5(root)
	_build_rail(root)
	alert_tray = AlertTray.new()
	root.add_child(alert_tray)
	alert_tray.unread_changed.connect(top_bar.set_unread)
	_toast = Toast.new()
	root.add_child(_toast)
	if is_inside_tree():
		layout.call_deferred(get_viewport().get_visible_rect().size)


## Mærkat + bjælke 0..10 (T-089).
func _bar(parent: Control, text: String, col: Color) -> ProgressBar:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = 80.0
	row.add_child(l)
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 10.0
	b.step = 0.1
	b.custom_minimum_size = Vector2(110.0, 14.0)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.show_percentage = false
	var fill: StyleBoxFlat = UiTheme.box(col, Color.TRANSPARENT, 0, 4, 0, 0.0)
	b.add_theme_stylebox_override("fill", fill)
	row.add_child(b)
	return b


func _panel(parent: Control, n: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = n
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(p)
	return p


## Fuld bredde med MARGIN, forankret top (y=0) eller bund (y=1).
func _anchor_wide(p: Control, y: float, grow: Control.GrowDirection) -> void:
	p.anchor_left = 0.0
	p.anchor_right = 1.0
	p.anchor_top = y
	p.anchor_bottom = y
	p.offset_left = MARGIN
	p.offset_right = -MARGIN
	var off: float = MARGIN if y == 0.0 else -MARGIN
	p.offset_top = off
	p.offset_bottom = off
	p.grow_vertical = grow


func _place_right(p: Control) -> void:
	p.anchor_left = 1.0
	p.anchor_right = 1.0
	p.offset_left = -250.0
	p.offset_right = -8.0
	p.offset_top = 60.0
	p.custom_minimum_size = Vector2(240, 0)


func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.clip_text = false
	b.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _add_build_button(_parent: Control, def_id: String, text: String, cost: int, tab: String = "",
		cost_text: String = "", body: String = "") -> void:
	_build_buttons[def_id] = build_dock.add_card(def_id, text, cost_text, tab, body)
	_build_costs[def_id] = cost
	_build_tab[def_id] = tab


## Tooltip-tekst for et byggekort: pris, drift og nøgletal.
static func card_body(d: AttractionDef) -> String:
	var lines: Array[String] = ["Pris: $%d" % d.build_cost]
	if d.running_cost_per_day > 0:
		lines.append("Drift: $%d/dag" % d.running_cost_per_day)
	if d.ticket_price > 0:
		lines.append("Billet: $%d" % d.ticket_price)
	if d.excitement > 0:
		lines.append("Spænding: %d" % d.excitement)
	if d.capacity > 1:
		lines.append("Kapacitet: %d" % d.capacity)
	lines.append("Størrelse: %dx%d" % [d.footprint.x, d.footprint.y])
	return "\n".join(lines)


## Viser kun byggeknapper for fanen (Vælg/Sti/Fjern altid synlige).
func set_tab(tab: String) -> void:
	current_tab = tab
	build_dock.set_category(tab)
	_relayout()


func visible_build_ids() -> Array[String]:
	var out: Array[String] = []
	out.assign(build_dock.visible_ids())
	return out


static func _json_files(dir: String) -> Array[String]:
	var names: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		var fn: String = f.trim_suffix(".remap").trim_suffix(".import")
		if fn.ends_with(".json") and not names.has(fn):
			names.append(fn)
	names.sort()
	return names


static func load_defs() -> Array[AttractionDef]:
	var out: Array[AttractionDef] = []
	for fn in _json_files(ATTRACTION_DIR):
		var d: AttractionDef = AttractionDef.from_json(ATTRACTION_DIR + fn)
		if d != null:
			out.append(d)
	return out


static func load_decor_defs() -> Array[DecorDef]:
	var out: Array[DecorDef] = []
	for fn in _json_files(DECOR_DIR):
		var d: DecorDef = DecorDef.from_json(DECOR_DIR + fn)
		if d != null:
			out.append(d)
	return out


static func load_staff_defs() -> Array[StaffDef]:
	var out: Array[StaffDef] = []
	for fn in _json_files(STAFF_DIR):
		var d: StaffDef = StaffDef.from_json(STAFF_DIR + fn)
		if d != null:
			out.append(d)
	return out


# --- Opdatering ---

func refresh() -> void:
	if _top_label == null:
		return
	if sim == null:
		_top_label.text = "Indlæser park..."
		return
	_connect_warnings()
	_refresh_clock()
	var st: Dictionary = sim.get_stats()
	var old_len: int = _top_label.text.length()
	_top_label.text = top_text(st)
	_stars.visible = st.has("reputation")
	_stars.value = float(st.get("reputation", 0.0))
	if _top_label.text.length() != old_len and is_inside_tree():
		layout(get_viewport().get_visible_rect().size)  # topbar kan ombrydes anderledes
	_refresh_park(st)
	top_bar.set_clock_state(sim.clock.paused, sim.clock.speed)
	top_bar.smiley.value = float(st.get("avg_happiness", 0.0)) if int(st.get("guests", 0)) > 0 else 50.0
	for id: String in _build_buttons:
		var b: Button = _build_buttons[id]
		var locked: bool = is_build_locked(id)
		var afford: bool = sim.economy.can_afford(_build_costs[id])
		b.disabled = locked or not afford
		LockOverlay.apply(b, locked)
		build_dock.set_affordable(id, afford)
	_refresh_m5()
	_refresh_attraction()
	_refresh_guest()
	_refresh_staff()
	_refresh_staff_list()
	inspector.refresh(sim)
	park_rail.refresh(sim)


func _connect_warnings() -> void:
	_connect_scenario()
	if sim == _warn_sim:
		return
	if _warn_sim != null and _warn_sim.has_signal("warning") and _warn_sim.is_connected("warning", show_warning):
		_warn_sim.disconnect("warning", show_warning)
	_warn_sim = sim
	if sim != null and sim.has_signal("warning"):
		sim.connect("warning", show_warning)


## Sim-varsler lander i AlertTray (nederst til højre); klik flytter kameraet til stedet.
func show_warning(code: StringName, data: Dictionary = {}) -> void:
	if alert_tray == null:
		return
	var icon: String = "info" if code == &"research_done" else "alert"
	alert_tray.push(Toast.warning_message(code, data), icon, warning_cell(data))


func warning_cell(data: Dictionary) -> Vector2i:
	var c: Variant = data.get("cell", null)
	if c is Vector2i:
		return c
	if data.has("attraction_id") and sim != null:
		var a: Attraction = sim.get_attraction(int(data.attraction_id))
		if a != null:
			return a.origin
	return AlertTray.NO_CELL


func _on_bell() -> void:
	alert_tray.show_history()
	if is_inside_tree():
		layout(get_viewport().get_visible_rect().size)


func toast() -> Toast:
	return _toast


func _refresh_clock() -> void:
	var clock: Control = _clock_label.get_parent()
	var has: bool = sim.has_method("clock_text")
	clock.visible = has
	if not has:
		return
	_clock_label.text = String(sim.call("clock_text"))
	if sim.has_method("is_night"):
		_clock_icon.night = bool(sim.call("is_night"))


## Topbar-tekst. Robust over for get_stats() før/efter T-030 (reputation/max_guests valgfri).
static func top_text(st: Dictionary) -> String:
	var t: String = "$%d   Dag %d   " % [int(st.get("money", 0)), int(st.get("day", 1))]
	if st.has("max_guests"):
		t += "Gæster: %d/%d   " % [int(st.get("guests", 0)), int(st.max_guests)]
	else:
		t += "Gæster: %d   " % int(st.get("guests", 0))
	t += "Glæde: %d%%" % roundi(float(st.get("avg_happiness", 0.0)))
	if st.has("reputation"):
		t += "   Omdømme: %d%%" % roundi(float(st.reputation))  # stjerner tegnes af StarRating
	if int(st.get("broken", 0)) > 0:
		t += "   Ødelagt: %d" % int(st.broken)
	if st.has("litter"):
		t += "   Affald: %d" % int(st.litter)
	return t


func _refresh_park(st: Dictionary) -> void:
	if not _park_panel.visible:
		return
	var income: int = 0
	var expense: int = 0
	for k: Variant in sim.economy.today:
		var v: int = int(sim.economy.today[k])
		if v > 0:
			income += v
		else:
			expense -= v
	var lines: Array[String] = ["Parken", "Entré: $%d" % sim.entry_fee]
	if st.has("reputation"):
		lines.append("Omdømme: %d%%" % roundi(float(st.reputation)))
	if st.has("attraction_score"):
		lines.append("Tiltrækning: %.1f" % float(st.attraction_score))
	elif sim.has_method("attraction_score"):
		lines.append("Tiltrækning: %.1f" % float(sim.call("attraction_score")))
	if st.has("guests_per_day"):
		lines.append("Forventede gæster/dag: %d" % roundi(float(st.guests_per_day)))
	elif sim.has_method("expected_guests_per_day"):
		lines.append("Forventede gæster/dag: %d" % roundi(float(sim.call("expected_guests_per_day"))))
	lines.append("I dag: +$%d / -$%d" % [income, expense])
	lines.append("  Entré: $%d  Billetter: $%d" % [sim.economy.get_today_total("entry"), sim.economy.get_today_total("tickets")])
	lines.append("  %s: $%d" % [M6Texts.category_name("prizes"), -sim.economy.get_today_total("prizes")])
	_park_label.text = "\n".join(lines)


func toggle_park_panel() -> void:
	var show: bool = not _park_panel.visible
	if show:
		clear_selection()
		_staff_list_panel.visible = false
	_park_panel.visible = show
	refresh()


func change_entry_fee(delta: int) -> void:
	if sim != null:
		sim.cmd_set_entry_fee(maxi(0, sim.entry_fee + delta))


func _refresh_attraction() -> void:
	if _sel_attraction < 0:
		return
	var a: Attraction = sim.get_attraction(_sel_attraction)
	if a == null:
		clear_selection()
		return
	_attr_label.text = attraction_text(a, sim)
	var st: Dictionary = sim.attraction_stats(a.id) if sim.has_method("attraction_stats") else {}
	var ride: bool = a.is_ride() or a.def.kind == "coaster"
	_attr_bar_box.visible = ride and not st.is_empty()
	if not st.is_empty():
		(_attr_bars["intensity"] as ProgressBar).value = float(st.get("intensity", 0.0)) / 10.0
		(_attr_bars["nausea"] as ProgressBar).value = float(st.get("nausea", 0.0)) / 10.0
		(_attr_bars["intensity"] as ProgressBar).tooltip_text = M6Texts.rating10(float(st.get("intensity", 0.0)))
		(_attr_bars["nausea"] as ProgressBar).tooltip_text = M6Texts.rating10(float(st.get("nausea", 0.0)))
	_attr_open_btn.text = "Luk" if a.is_open else "Åbn"
	var unfinished: bool = a.track != null and a.building
	_attr_resume_btn.visible = unfinished
	_attr_open_btn.visible = not unfinished


static func status_text(a: Attraction) -> String:
	if "status" in a:
		match int(a.get("status")):
			Attraction.Status.BROKEN:
				return "I stykker"
			Attraction.Status.CLOSED:
				return "Lukket"
		return "Kører"
	return "Åben" if a.is_open else "Lukket"


static func attraction_text(a: Attraction, p_sim: ParkSim) -> String:
	var lines: Array[String] = [a.def.name, "Status: " + status_text(a)]
	if a.has_method("effective_reliability"):
		lines.append("Pålidelighed: %d%%" % roundi(float(a.call("effective_reliability")) * 100.0))
	if "mechanic_id" in a:
		var mid: int = int(a.get("mechanic_id"))
		if mid >= 0:
			lines.append("Mekaniker: #%d" % mid)
		elif "broken" in a and bool(a.get("broken")):
			lines.append("Ingen mekaniker ledig!" if _has_mechanic(p_sim) else "Ansæt en mekaniker!")
	if CoasterContent.is_tracked_kind(a.def.kind):
		lines.append_array(coaster_lines(a))
		if p_sim != null:
			lines.append_array(M6Texts.track_lines(a, p_sim.attraction_stats(a.id)))
	if a.is_sideshow() and p_sim != null:
		lines.append_array(M6Texts.sideshow_lines(p_sim.attraction_stats(a.id)))
	lines.append("Besøgende: %d" % a.total_visitors)
	lines.append("Omsætning: $%d" % a.total_revenue)
	lines.append("Pris: $%d" % a.price)
	var qs: Dictionary = p_sim.attraction_stats(a.id) if p_sim != null else {}
	if qs.has("queue_capacity") and int(qs["queue_capacity"]) < 100000:  # T-140: kølængde og ventetid (indtil T-112's kø-fane)
		lines.append("Kø: %d/%d, ventetid ca. %d s" % [int(qs["queue_length"]), int(qs["queue_capacity"]),
			int(qs.get("wait_ticks_estimate", 0)) / SimClock.TICKS_PER_SECOND])
	else:
		lines.append("Kø: %d" % a.queue.size())
	return "\n".join(lines)


static func _has_mechanic(p_sim: ParkSim) -> bool:
	if p_sim == null or not "staff" in p_sim:
		return false
	for s: Variant in (p_sim.get("staff") as Dictionary).values():
		if (s as Staff).type_id() == "mechanic":
			return true
	return false


static func staff_status(s: Staff) -> String:
	if s.task != "":
		return STAFF_TASK_NAMES.get(s.task, s.task)
	return STAFF_STATE_NAMES.get(s.state, "")


func _get_staff_dict() -> Dictionary:
	if sim == null or not "staff" in sim:
		return {}
	return sim.get("staff")


func _refresh_staff() -> void:
	if _sel_staff < 0:
		return
	var s: Staff = _get_staff_dict().get(_sel_staff, null)
	if s == null:
		clear_selection()
		return
	_staff_label.text = "%s #%d\nLøn: $%d/dag\nStatus: %s" % [s.def.name, s.id, s.def.wage_per_day, staff_status(s)]


func _refresh_staff_list() -> void:
	if not _staff_list_panel.visible:
		return
	var d: Dictionary = _get_staff_dict()
	var ids: Array = d.keys()
	ids.sort()
	var wages: int = 0
	for id: int in ids:
		wages += (d[id] as Staff).def.wage_per_day
	(_staff_list_panel.get_node("V/Title") as Label).text = "Personale: %d (løn $%d/dag)" % [ids.size(), wages]
	if ids != _staff_list_ids:
		_staff_list_ids = ids
		for c in _staff_list.get_children():
			_staff_list.remove_child(c)
			c.queue_free()
		for id: int in ids:
			var row := HBoxContainer.new()
			row.name = "Row_%d" % id
			var l := Label.new()
			l.name = "L"
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(l)
			_button(row, "Fyr", fire_staff.bind(id))
			_staff_list.add_child(row)
	for id: int in ids:
		var s: Staff = d[id]
		var row: Node = _staff_list.get_node_or_null("Row_%d" % id)
		if row != null:
			(row.get_node("L") as Label).text = "%s #%d $%d - %s" % [s.def.name, id, s.def.wage_per_day, staff_status(s)]


func toggle_staff_list() -> void:
	var show: bool = not _staff_list_panel.visible
	if show:
		clear_selection()
		_park_panel.visible = false
	_staff_list_panel.visible = show
	refresh()


func fire_staff(id: int) -> void:
	if sim != null and sim.has_method("cmd_fire_staff"):
		sim.call("cmd_fire_staff", id)
	if id == _sel_staff:
		clear_selection()
	refresh()


func _on_fire_selected() -> void:
	fire_staff(_sel_staff)


func _refresh_guest() -> void:
	if _sel_guest < 0:
		return
	var g: Guest = sim.guests.get(_sel_guest, null)
	if g == null:
		clear_selection()
		return
	var lines: Array[String] = ["Gæst #%d" % g.id, "Glæde: %d%%" % roundi(g.happiness), "Penge: $%d" % g.money]
	var keys: Array = g.needs.keys()
	keys.sort()
	for k: String in keys:
		lines.append("%s: %d" % [NEED_NAMES.get(k, k), roundi(g.needs[k])])
	var info: Dictionary = sim.guest_info(g.id)
	if not info.is_empty():
		lines.append("Kvalme: %d  Tolerance: %d" % [roundi(float(info.get("nausea", 0.0))),
			roundi(float(info.get("intensity_tolerance", 0.0)))])
		(_guest_bars["nausea"] as ProgressBar).value = float(info.get("nausea", 0.0)) / 10.0
		(_guest_bars["tolerance"] as ProgressBar).value = float(info.get("intensity_tolerance", 0.0)) / 10.0
		_refresh_guest_items(info.get("items", []) as Array)
	if g.thought != "":
		lines.append("\"%s\"" % M6Texts.thought_text(g.thought))
	_guest_label.text = "\n".join(lines)


func _refresh_guest_items(items: Array) -> void:
	var ids: Array[String] = []
	for it: Variant in items:
		ids.append(str(it))
	var cur: Array[String] = []
	for c in _guest_items.get_children():
		cur.append((c as ItemIcon).item_id)
	if cur == ids:
		return
	for c in _guest_items.get_children():
		_guest_items.remove_child(c)
		c.queue_free()
	for id in ids:
		_guest_items.add_child(ItemIcon.new(id, 20.0))
	_guest_items.visible = not ids.is_empty()


# --- Selection ---

func show_attraction(id: int) -> void:
	_hide_overviews()
	_sel_staff = -1
	_sel_guest = -1
	_sel_attraction = id
	if coaster_palette != null:
		coaster_palette.resume_id = id
	inspector.open(&"attraction", id)
	refresh()


func show_guest(id: int) -> void:
	_hide_overviews()
	_sel_staff = -1
	_sel_attraction = -1
	_sel_guest = id
	inspector.open(&"guest", id)
	refresh()


func show_staff(id: int) -> void:
	_hide_overviews()
	_sel_attraction = -1
	_sel_guest = -1
	_sel_staff = id
	inspector.open(&"staff", id)
	refresh()


func _hide_overviews() -> void:
	if research_panel != null:
		research_panel.wanted = false
		research_panel.visible = false
	if _park_panel != null:
		_park_panel.visible = false
		_staff_list_panel.visible = false
	if park_rail != null:
		park_rail.close_panel()


func clear_selection() -> void:
	_sel_attraction = -1
	_sel_guest = -1
	_sel_staff = -1
	if inspector != null:
		inspector.close_inspector()


## Inspektøren lukket med X/Esc: ryd også markeringen i verden.
func _on_inspector_closed() -> void:
	var had: bool = _sel_attraction >= 0 or _sel_guest >= 0 or _sel_staff >= 0
	clear_selection()
	if had and selection != null and selection.has_signal("cleared"):
		selection.emit_signal("cleared")


## Esc lukker inspektøren (før BuildTool får tasten og evt. åbner pause-menuen).
func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo \
			and (event as InputEventKey).keycode == KEY_ESCAPE:
		if handle_escape():
			get_viewport().set_input_as_handled()


## Returnerer true, hvis Esc blev brugt af HUD'en (inspektør eller rail-panel lukket).
func handle_escape() -> bool:
	if is_pause_menu_open():
		return false
	if inspector != null and inspector.is_open():
		inspector.close_inspector()
		return true
	if build_dock != null and build_dock.cards_open():
		build_dock.close_cards()
		return true
	if park_rail != null and park_rail.open_id != &"":
		park_rail.close_panel()
		return true
	return false


# --- Pause-menu ---

var _was_paused: bool = false


func open_pause_menu() -> void:
	if _pause_menu == null or _pause_menu.visible:
		return
	if sim != null:
		_was_paused = sim.clock.paused
		sim.clock.paused = true
	_pause_menu.open()


func is_pause_menu_open() -> bool:
	return _pause_menu != null and _pause_menu.visible


func _on_pause_menu_closed() -> void:
	if sim != null:
		sim.clock.paused = _was_paused


# --- Kommandoer ---

func request_build_tool(def_id: String) -> void:
	if def_id.begins_with("coaster:") and coaster_palette != null:
		coaster_palette.set_system(system_for_build(def_id))
	if selection != null and selection.has_signal("build_tool_requested"):
		selection.emit_signal("build_tool_requested", def_id)


func _on_pause() -> void:
	if sim != null:
		sim.clock.paused = not sim.clock.paused


func _on_speed(s: float) -> void:
	if sim != null:
		sim.clock.speed = s
		sim.clock.paused = false


func _on_price(delta: int) -> void:
	var a: Attraction = sim.get_attraction(_sel_attraction) if sim != null else null
	if a != null:
		sim.cmd_set_price(a.id, maxi(0, a.price + delta))


func _on_toggle_open() -> void:
	var a: Attraction = sim.get_attraction(_sel_attraction) if sim != null else null
	if a != null:
		sim.cmd_set_open(a.id, not a.is_open)


func _on_demolish() -> void:
	if sim != null and _sel_attraction >= 0 and sim.cmd_remove_attraction(_sel_attraction):
		clear_selection()


# --- M5 (T-071): scenarie, forskning, rutsjebane ---

func _build_rail(root: Control) -> void:
	park_rail = ParkRail.new()
	root.add_child(park_rail)
	park_rail.build()
	park_rail.host = root
	park_rail.register_action(&"park", "park", "Park og økonomi", toggle_park_panel)
	park_rail.register_action(&"staff", "staff", "Personale", toggle_staff_list)
	_research_btn = park_rail.register_action(&"research", "research", "Forskning", toggle_research_panel)
	_research_btn.visible = false
	park_rail.register(&"settings", "settings", _make_settings_panel, "Indstillinger")
	park_rail.register_action(&"menu", "menu", "Menu (Esc)", open_pause_menu)
	park_rail.panel_toggled.connect(_on_rail_panel)


func _make_settings_panel() -> Control:
	var p := UiSettingsPanel.new()
	p.build(user_settings)
	return p


func _on_rail_panel(_id: StringName, open: bool) -> void:
	if open:
		clear_selection()
		_park_panel.visible = false
		_staff_list_panel.visible = false
		research_panel.wanted = false
		research_panel.visible = false
	if is_inside_tree():
		layout(get_viewport().get_visible_rect().size)


func _build_m5(root: Control) -> void:
	objective_panel = ObjectivePanel.new()
	root.add_child(objective_panel)
	objective_panel.build()
	research_panel = ResearchPanel.new()
	root.add_child(research_panel)
	research_panel.build()
	_place_right(research_panel)
	coaster_palette = CoasterPalette.new()
	root.add_child(coaster_palette)
	coaster_palette.build()
	coaster_palette.message.connect(show_message)
	result_dialog = ResultDialog.new()
	root.add_child(result_dialog)
	result_dialog.build()
	result_dialog.continue_pressed.connect(continue_free_play)
	result_dialog.menu_pressed.connect(func() -> void: UiSession.go_to_main_menu())


## Sporsystem for en "coaster:<def_id>"-byggeknap (default &"coaster").
static func system_for_build(build_id: String) -> StringName:
	var id: String = build_id.substr(8)
	var path: String = "res://content/attractions/%s.json" % id
	if FileAccess.file_exists(path):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			var sys: StringName = CoasterContent.system_for_kind(str((d as Dictionary).get("kind", "")))
			if sys != &"":
				return sys
	return &"coaster"


## Forsknings-id for en byggeknap ("" = aldrig låst).
static func research_id(build_id: String) -> String:
	if build_id in ["select", "path", "queue_path", "remove"] or build_id.begins_with("staff:"):
		return ""
	if build_id.begins_with("decor:"):
		return build_id.substr(6)
	if build_id.begins_with("coaster:"):
		return build_id.substr(8)
	return build_id


func is_build_locked(build_id: String) -> bool:
	var rid: String = research_id(build_id)
	return rid != "" and sim != null and sim.has_method("is_unlocked") and not sim.is_unlocked(rid)


func _refresh_m5() -> void:
	objective_panel.refresh(sim)
	var r_on: bool = ResearchPanel.enabled(sim)
	if _research_btn.visible != r_on:
		_research_btn.visible = r_on
		if is_inside_tree():
			layout(get_viewport().get_visible_rect().size)
	research_panel.refresh(sim)
	_find_build_tool()
	coaster_palette.tool = _build_tool
	var show_pal: bool = current_tab == "coaster"
	if coaster_palette.visible != show_pal:
		coaster_palette.visible = show_pal
		if is_inside_tree():
			layout(get_viewport().get_visible_rect().size)
	if show_pal:
		coaster_palette.refresh(sim)


func _find_build_tool() -> void:
	if _build_tool != null and is_instance_valid(_build_tool):
		return
	_build_tool = null
	if not is_inside_tree():
		return
	var found: Array[Node] = get_tree().root.find_children("*", "BuildTool", true, false)
	if found.is_empty():
		return
	_build_tool = found[0]
	if _build_tool.has_signal("coaster_errors"):
		_build_tool.connect("coaster_errors", show_coaster_errors)
	if _build_tool.has_signal("remove_blocked") and _toast != null:
		_build_tool.connect("remove_blocked", _toast.show_message)


func _connect_scenario() -> void:
	if sim == _scn_sim:
		return
	if _scn_sim != null and _scn_sim.has_signal("scenario_finished") and _scn_sim.is_connected("scenario_finished", on_scenario_finished):
		_scn_sim.disconnect("scenario_finished", on_scenario_finished)
	_scn_sim = sim
	if result_dialog != null:
		result_dialog.visible = false
	if sim != null and sim.has_signal("scenario_finished"):
		sim.connect("scenario_finished", on_scenario_finished)


func on_scenario_finished(won: bool, reason: String) -> void:
	if result_dialog == null:
		return
	var nm: String = ""
	if sim != null and sim.has_method("scenario_status"):
		nm = str(sim.scenario_status().get("name", ""))
	result_dialog.show_result(won, reason, nm)
	if is_inside_tree():
		result_dialog.layout(get_viewport().get_visible_rect().size)


## "Fortsæt i fri leg": luk dialogen og lad tiden køre videre.
func continue_free_play() -> void:
	result_dialog.visible = false
	if sim != null:
		sim.clock.paused = false
		if sim.clock.speed <= 0.0:
			sim.clock.speed = 1.0


func toggle_research_panel() -> void:
	var show: bool = not research_panel.wanted
	if show:
		clear_selection()
		_park_panel.visible = false
		_staff_list_panel.visible = false
	research_panel.wanted = show
	refresh()
	if is_inside_tree():
		layout(get_viewport().get_visible_rect().size)


func show_message(t: String) -> void:
	if _toast != null:
		_toast.show_message(t)


func show_coaster_errors(codes: Array) -> void:
	show_message(CoasterPalette.errors_text(codes))


func _on_resume_coaster() -> void:
	set_tab("coaster")
	coaster_palette.resume_id = _sel_attraction
	var ra: Attraction = sim.get_attraction(_sel_attraction) if sim != null else null
	if ra != null and ra.track != null:
		coaster_palette.set_system(ra.track.system)
	coaster_palette.tool = _build_tool
	coaster_palette.resume()


## Ratings og statistik for en rutsjebane.
static func coaster_lines(a: Attraction) -> Array[String]:
	var out: Array[String] = []
	if a.building:
		out.append("Under opførelse")
	if a.ratings.is_empty():
		out.append("Ratings: ikke beregnet endnu")
	else:
		out.append("Spænding: %.2f" % float(a.ratings.get("excitement", 0.0)))
		out.append("Intensitet: %.2f" % float(a.ratings.get("intensity", 0.0)))
		out.append("Kvalme: %.2f" % float(a.ratings.get("nausea", 0.0)))
	if a.profile != null:
		out.append("Længde: %d m" % roundi(a.profile.length))
		out.append("Max fart: %d km/t" % roundi(a.profile.max_speed * 3.6))
		out.append("Max g: %.1f" % a.profile.max_g)
	if a.track != null:
		out.append("Stykker: %d" % a.track.pieces.size())
	return out
