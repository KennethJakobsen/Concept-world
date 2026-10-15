class_name Hud
extends CanvasLayer
## HUD: top-bar, byggemenu og info-paneler. Læser kun state fra ParkSim og sender kommandoer.
## Finder ParkView (gruppe "park_view") og Selection (gruppe "selection") robust (null-checks).

const ATTRACTION_DIR: String = "res://content/attractions/"
const THEME_RES: Theme = preload("res://ui/theme.tres")
const SPEEDS: Array[float] = [1.0, 2.0, 4.0]
const MARGIN: float = 8.0
const NEED_NAMES: Dictionary = {"hunger": "Sult", "thirst": "Tørst", "toilet": "Toilet", "energy": "Træthed"}

var sim: ParkSim
var selection: Node

var _top_label: Label
var _pause_btn: Button
var _build_buttons: Dictionary = {}  ## def_id -> Button
var _build_costs: Dictionary = {}    ## def_id -> int
var _attr_panel: PanelContainer
var _attr_label: Label
var _attr_open_btn: Button
var _guest_panel: PanelContainer
var _guest_label: Label
var _sel_attraction: int = -1
var _sel_guest: int = -1


func _ready() -> void:
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
	for p: Control in [_attr_panel, _guest_panel]:
		p.position = Vector2(maxf(MARGIN, vp.x - MARGIN - p.custom_minimum_size.x), top_h + 2.0 * MARGIN)


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


func _process(_delta: float) -> void:
	if sim == null or selection == null:
		_connect_scene()
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
	_anchor_wide(top, 0.0, Control.GROW_DIRECTION_END)
	var th := HFlowContainer.new()
	th.add_theme_constant_override("h_separation", 12)
	top.add_child(th)
	_top_label = Label.new()
	th.add_child(_top_label)
	_pause_btn = _button(th, "Pause", _on_pause)
	for s: float in SPEEDS:
		_button(th, "%dx" % int(s), _on_speed.bind(s))

	# Byggemenu
	var bottom := _panel(root, "BuildMenu")
	# Forankret i bunden; vokser opad når knapperne ombrydes (smalle vinduer).
	_anchor_wide(bottom, 1.0, Control.GROW_DIRECTION_BEGIN)
	var bh := HFlowContainer.new()
	bottom.add_child(bh)
	_add_build_button(bh, "select", "Vælg", 0)
	_add_build_button(bh, "path", "Sti", 0)
	_add_build_button(bh, "remove", "Fjern", 0)
	for d: AttractionDef in load_defs():
		_add_build_button(bh, d.id, "%s ($%d)" % [d.name, d.build_cost], d.build_cost)

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


func _add_build_button(parent: Control, def_id: String, text: String, cost: int) -> void:
	_build_buttons[def_id] = _button(parent, text, request_build_tool.bind(def_id))
	_build_costs[def_id] = cost


static func load_defs() -> Array[AttractionDef]:
	var out: Array[AttractionDef] = []
	var files: PackedStringArray = DirAccess.get_files_at(ATTRACTION_DIR)
	var names: Array[String] = []
	for f in files:
		var fn: String = f.trim_suffix(".remap").trim_suffix(".import")
		if fn.ends_with(".json") and not names.has(fn):
			names.append(fn)
	names.sort()
	for fn in names:
		var d: AttractionDef = AttractionDef.from_json(ATTRACTION_DIR + fn)
		if d != null:
			out.append(d)
	return out


# --- Opdatering ---

func refresh() -> void:
	if _top_label == null:
		return
	if sim == null:
		_top_label.text = "Indlæser park…"
		return
	var st: Dictionary = sim.get_stats()
	_top_label.text = "$%d   Dag %d   Gæster: %d   Glæde: %d%%" % [
		st.money, st.day, st.guests, roundi(st.avg_happiness)]
	_pause_btn.text = "Fortsæt" if sim.clock.paused else "Pause"
	for id: String in _build_buttons:
		(_build_buttons[id] as Button).disabled = not sim.economy.can_afford(_build_costs[id])
	_refresh_attraction()
	_refresh_guest()


func _refresh_attraction() -> void:
	if _sel_attraction < 0:
		_attr_panel.visible = false
		return
	var a: Attraction = sim.get_attraction(_sel_attraction)
	if a == null:
		clear_selection()
		return
	_attr_panel.visible = true
	_attr_label.text = "%s\nStatus: %s\nBesøgende: %d\nOmsætning: $%d\nPris: $%d\nKø: %d" % [
		a.def.name, "Åben" if a.is_open else "Lukket", a.total_visitors, a.total_revenue,
		a.price, a.queue.size()]
	_attr_open_btn.text = "Luk" if a.is_open else "Åbn"


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
	_sel_guest = -1
	_sel_attraction = id
	refresh()


func show_guest(id: int) -> void:
	_sel_attraction = -1
	_sel_guest = id
	refresh()


func clear_selection() -> void:
	_sel_attraction = -1
	_sel_guest = -1
	if _attr_panel != null:
		_attr_panel.visible = false
		_guest_panel.visible = false


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
