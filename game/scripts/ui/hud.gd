class_name Hud
extends CanvasLayer
## HUD: top-bar, byggemenu og info-paneler. Læser kun state fra ParkSim og sender kommandoer.
## Finder ParkView (gruppe "park_view") og Selection (gruppe "selection") robust (null-checks).

const ATTRACTION_DIR: String = "res://content/attractions/"
const DECOR_DIR: String = "res://content/decor/"
const STAFF_DIR: String = "res://content/staff/"
const TABS: Array[String] = ["rides", "coaster", "shops", "decor", "staff"]
const TAB_NAMES: Dictionary = {"rides": "Forlystelser", "coaster": "Rutsjebaner", "shops": "Butikker", "decor": "Dekoration", "staff": "Personale"}
const STAFF_STATE_NAMES: Dictionary = {0: "Ledig", 1: "Går", 2: "Arbejder"}
const STAFF_TASK_NAMES: Dictionary = {"repair": "Reparerer", "inspect": "Inspicerer", "sweep": "Fejer",
	"empty_bin": "Tømmer skraldespand", "patrol": "Underholder"}
const THEME_RES: Theme = preload("res://ui/theme.tres")
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
var _attr_panel: PanelContainer
var _attr_label: Label
var _attr_open_btn: Button
var _guest_panel: PanelContainer
var _guest_label: Label
var _park_panel: PanelContainer
var _park_label: Label
var _staff_panel: PanelContainer
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


func _ready() -> void:
	UiSound.install(get_tree())
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


func _on_viewport_resized() -> void:
	layout(get_viewport().get_visible_rect().size)


## Placerer top-bar og byggemenu inden for viewporten. Panelernes højde beregnes ud fra
## ombrydning af knapperne ved den givne bredde, så byggemenuen altid ligger helt synlig i bunden.
func layout(vp: Vector2) -> void:
	var root: Control = get_node_or_null("Root")
	if root == null:
		return
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2.ZERO
	root.size = vp
	var w: float = maxf(0.0, vp.x - 2.0 * MARGIN)
	var top: PanelContainer = root.get_node("TopBar")
	var bottom: PanelContainer = root.get_node("BuildMenu")
	var top_h: float = _panel_height(top, w)
	var bottom_h: float = _panel_height(bottom, w)
	top.position = Vector2(MARGIN, MARGIN)
	top.size = Vector2(w, top_h)
	bottom.position = Vector2(MARGIN, maxf(MARGIN, vp.y - MARGIN - bottom_h))
	bottom.size = Vector2(w, bottom_h)
	for p: Control in [top, bottom]:
		_sort_tree(p)
	if _staff_list_panel == null:
		return  # under opbygning
	var max_h: float = maxf(0.0, bottom.position.y - top_h - 3.0 * MARGIN)
	for p: Control in right_panels():
		p.position = Vector2(maxf(MARGIN, vp.x - MARGIN - p.custom_minimum_size.x), top_h + 2.0 * MARGIN)
		p.size = Vector2(p.custom_minimum_size.x, minf(p.get_combined_minimum_size().y, max_h))
	# Personale-listen scroller inden for den plads der er mellem top- og byggebjælke.
	var scroll: ScrollContainer = _staff_list_panel.get_node("V/Scroll")
	scroll.custom_minimum_size.y = clampf(max_h - 90.0, 40.0, 260.0)
	if objective_panel != null:
		objective_panel.position = Vector2(MARGIN, top_h + 2.0 * MARGIN)
		objective_panel.size = objective_panel.get_combined_minimum_size()
	if coaster_palette != null:
		var ph: float = _panel_height(coaster_palette, w)
		coaster_palette.position = Vector2(MARGIN, maxf(MARGIN, bottom.position.y - MARGIN - ph))
		coaster_palette.size = Vector2(w, ph)
		_sort_tree(coaster_palette)
	if result_dialog != null:
		result_dialog.layout(vp)
	if _toast != null:
		var tw: float = minf(420.0, w)
		_toast.size = Vector2(tw, 0)
		_toast.position = Vector2((vp.x - tw) * 0.5, top_h + 2.0 * MARGIN)
	if _pause_menu != null:
		_pause_menu.layout(vp)


func right_panels() -> Array[Control]:
	return [_attr_panel, _guest_panel, _park_panel, _staff_panel, _staff_list_panel, research_panel]


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


# --- Opbygning ---

func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.theme = THEME_RES
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Top-bar
	var top := _panel(root, "TopBar")
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)  # placeres af layout()
	var th := HFlowContainer.new()
	th.add_theme_constant_override("h_separation", 12)
	top.add_child(th)
	var clock := HBoxContainer.new()
	clock.name = "Clock"
	clock.visible = false
	th.add_child(clock)
	_clock_icon = ClockIcon.new()
	_clock_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clock.add_child(_clock_icon)
	_clock_label = Label.new()
	_clock_label.name = "ClockLabel"
	clock.add_child(_clock_label)
	_top_label = Label.new()
	th.add_child(_top_label)
	_stars = StarRating.new()
	_stars.name = "ReputationStars"
	_stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_stars.visible = false
	th.add_child(_stars)
	_button(th, "Park", toggle_park_panel)
	_button(th, "Personale", toggle_staff_list)
	_research_btn = _button(th, "Forskning", toggle_research_panel)
	_research_btn.visible = false
	_button(th, "Menu", open_pause_menu)
	_pause_btn = _button(th, "Pause", _on_pause)
	for s: float in SPEEDS:
		_button(th, "%dx" % int(s), _on_speed.bind(s))

	# Byggemenu
	var bottom := _panel(root, "BuildMenu")
	# Forankret i bunden; vokser opad når knapperne ombrydes (smalle vinduer).
	bottom.set_anchors_preset(Control.PRESET_TOP_LEFT)  # placeres af layout()
	var bh := HFlowContainer.new()
	bottom.add_child(bh)
	_add_build_button(bh, "select", "Vælg", 0)
	_add_build_button(bh, "path", "Sti", 0)
	_add_build_button(bh, "remove", "Fjern", 0)
	for t: String in TABS:
		var tb: Button = _button(bh, "[%s]" % TAB_NAMES[t], set_tab.bind(t))
		tb.toggle_mode = true
		tb.name = "Tab_" + t
		_tab_buttons[t] = tb
	for d: AttractionDef in load_defs():
		if d.kind == "coaster":
			_add_build_button(bh, "coaster:" + d.id, "%s ($%d+)" % [d.name, d.build_cost], d.build_cost, "coaster")
			continue
		var tab: String = "rides" if d.kind == "ride" else "shops"
		_add_build_button(bh, d.id, "%s ($%d)" % [d.name, d.build_cost], d.build_cost, tab)
	for d: DecorDef in load_decor_defs():
		_add_build_button(bh, "decor:" + d.id, "%s ($%d)" % [d.name, d.build_cost], d.build_cost, "decor")
	for d: StaffDef in load_staff_defs():
		_add_build_button(bh, "staff:" + d.id, "%s ($%d/dag)" % [d.name, d.wage_per_day], 0, "staff")
	set_tab(current_tab)

	# Info-paneler (højre side)
	_attr_panel = _panel(root, "AttractionPanel")
	_place_right(_attr_panel)
	var av := VBoxContainer.new()
	_attr_panel.add_child(av)
	_attr_label = Label.new()
	av.add_child(_attr_label)
	var ph := HBoxContainer.new()
	av.add_child(ph)
	_button(ph, "Pris -", _on_price.bind(-1))
	_button(ph, "Pris +", _on_price.bind(1))
	_attr_open_btn = _button(av, "Luk", _on_toggle_open)
	_attr_resume_btn = _button(av, "Fortsæt byg", _on_resume_coaster)
	_attr_resume_btn.visible = false
	_button(av, "Riv ned", _on_demolish)
	_button(av, "Luk panel", clear_selection)
	_attr_panel.visible = false

	_guest_panel = _panel(root, "GuestPanel")
	_place_right(_guest_panel)
	var gv := VBoxContainer.new()
	_guest_panel.add_child(gv)
	_guest_label = Label.new()
	gv.add_child(_guest_label)
	_button(gv, "Luk panel", clear_selection)
	_guest_panel.visible = false

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

	_staff_panel = _panel(root, "StaffPanel")
	_place_right(_staff_panel)
	var sv := VBoxContainer.new()
	_staff_panel.add_child(sv)
	_staff_label = Label.new()
	sv.add_child(_staff_label)
	_button(sv, "Fyr", _on_fire_selected)
	_button(sv, "Luk panel", clear_selection)
	_staff_panel.visible = false

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
	_toast = Toast.new()
	root.add_child(_toast)
	if is_inside_tree():
		layout.call_deferred(get_viewport().get_visible_rect().size)


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


func _add_build_button(parent: Control, def_id: String, text: String, cost: int, tab: String = "") -> void:
	_build_buttons[def_id] = _button(parent, text, request_build_tool.bind(def_id))
	_build_costs[def_id] = cost
	_build_tab[def_id] = tab


## Viser kun byggeknapper for fanen (Vælg/Sti/Fjern altid synlige).
func set_tab(tab: String) -> void:
	current_tab = tab
	for id: String in _build_buttons:
		var t: String = _build_tab.get(id, "")
		(_build_buttons[id] as Button).visible = t == "" or t == tab
	for t: String in _tab_buttons:
		(_tab_buttons[t] as Button).set_pressed_no_signal(t == tab)
	if is_inside_tree():
		layout(get_viewport().get_visible_rect().size)


func visible_build_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in _build_buttons:
		if (_build_buttons[id] as Button).visible:
			out.append(id)
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
	_pause_btn.text = "Fortsæt" if sim.clock.paused else "Pause"
	for id: String in _build_buttons:
		var b: Button = _build_buttons[id]
		var locked: bool = is_build_locked(id)
		b.disabled = locked or not sim.economy.can_afford(_build_costs[id])
		LockOverlay.apply(b, locked)
	_refresh_m5()
	_refresh_attraction()
	_refresh_guest()
	_refresh_staff()
	_refresh_staff_list()


func _connect_warnings() -> void:
	_connect_scenario()
	if sim == _warn_sim:
		return
	if _warn_sim != null and _warn_sim.has_signal("warning") and _warn_sim.is_connected("warning", show_warning):
		_warn_sim.disconnect("warning", show_warning)
	_warn_sim = sim
	if sim != null and sim.has_signal("warning"):
		sim.connect("warning", show_warning)


func show_warning(code: StringName, data: Dictionary = {}) -> void:
	if _toast != null:
		_toast.show_warning(code, data)


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
		_attr_panel.visible = false
		return
	var a: Attraction = sim.get_attraction(_sel_attraction)
	if a == null:
		clear_selection()
		return
	_attr_panel.visible = true
	_attr_label.text = attraction_text(a, sim)
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
	if a.def.kind == "coaster":
		lines.append_array(coaster_lines(a))
	lines.append("Besøgende: %d" % a.total_visitors)
	lines.append("Omsætning: $%d" % a.total_revenue)
	lines.append("Pris: $%d" % a.price)
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
		_staff_panel.visible = false
		return
	var s: Staff = _get_staff_dict().get(_sel_staff, null)
	if s == null:
		clear_selection()
		return
	_staff_panel.visible = true
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
		_guest_panel.visible = false
		return
	var g: Guest = sim.guests.get(_sel_guest, null)
	if g == null:
		clear_selection()
		return
	_guest_panel.visible = true
	var lines: Array[String] = ["Gæst #%d" % g.id, "Glæde: %d%%" % roundi(g.happiness), "Penge: $%d" % g.money]
	var keys: Array = g.needs.keys()
	keys.sort()
	for k: String in keys:
		lines.append("%s: %d" % [NEED_NAMES.get(k, k), roundi(g.needs[k])])
	if g.thought != "":
		lines.append("\"%s\"" % g.thought)
	_guest_label.text = "\n".join(lines)


# --- Selection ---

func show_attraction(id: int) -> void:
	_hide_overviews()
	_sel_staff = -1
	_sel_guest = -1
	_sel_attraction = id
	if coaster_palette != null:
		coaster_palette.resume_id = id
	refresh()


func show_guest(id: int) -> void:
	_hide_overviews()
	_sel_staff = -1
	_sel_attraction = -1
	_sel_guest = id
	refresh()


func show_staff(id: int) -> void:
	_hide_overviews()
	_sel_attraction = -1
	_sel_guest = -1
	_sel_staff = id
	refresh()


func _hide_overviews() -> void:
	if research_panel != null:
		research_panel.wanted = false
		research_panel.visible = false
	if _park_panel != null:
		_park_panel.visible = false
		_staff_list_panel.visible = false


func clear_selection() -> void:
	_sel_attraction = -1
	_sel_guest = -1
	_sel_staff = -1
	if _attr_panel != null:
		_attr_panel.visible = false
		_guest_panel.visible = false
		_staff_panel.visible = false


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


## Forsknings-id for en byggeknap ("" = aldrig låst).
static func research_id(build_id: String) -> String:
	if build_id in ["select", "path", "remove"] or build_id.begins_with("staff:"):
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
