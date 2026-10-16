class_name AttractionTabs
extends RefCounted
## T-112: Inspector-faner for bygninger (Indstillinger, Økonomi, Kø). Fanerne læser kun
## sim-state og sender `cmd_*`, så handlingerne kan fortrydes.

const CONFIG_NAMES: Dictionary = {"capacity": "Kapacitet", "ride_ticks": "Turlængde", "speed": "Hastighed"}
const LOW_PRICE_RATIO: float = 0.6


static func register(inspector: Inspector) -> void:
	inspector.register_tab(&"attraction", &"settings", "Indstillinger", func() -> Control: return SettingsTab.new())
	inspector.register_tab(&"attraction", &"economy", "Økonomi", func() -> Control: return EconomyTab.new())
	inspector.register_tab(&"attraction", &"queue", "Kø", func() -> Control: return QueueTab.new())


static func config_value_text(key: String, v: float) -> String:
	match key:
		"ride_ticks":
			return "%.1f s" % (v / float(SimClock.TICKS_PER_SECOND))
		"speed":
			return "%d%%" % roundi(v * 100.0)
	return "%d" % roundi(v)


static func price_warning(price: int, base: int) -> String:
	if base > 0 and float(price) < float(base) * LOW_PRICE_RATIO:
		return "Meget lav pris: gæsterne kan købe for meget og få kvalme."
	return ""


static func payback_text(day: int) -> String:
	return "Tjent hjem på dag %d" % day if day >= 0 else "Ikke tjent hjem endnu"


static func _label(parent: Control, text: String = "") -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(200, 0)
	parent.add_child(l)
	return l


## --- Indstillinger: config-skydere, opskrifter og pris-stepper ---
class SettingsTab extends VBoxContainer:
	var sim: ParkSim
	var target: int = -1
	var sliders: Dictionary = {}    ## key -> HSlider
	var values: Dictionary = {}     ## key -> Label
	var recipes: Dictionary = {}    ## recipe id -> CheckBox
	var price_label: Label
	var warning: Label
	var derived: Label
	var _dragging: bool = false

	func _init() -> void:
		name = "SettingsTab"

	func refresh(p_sim: ParkSim, id: int) -> void:
		sim = p_sim
		var a: Attraction = sim.get_attraction(id) if sim != null else null
		if a == null:
			return
		if id != target:
			target = id
			_rebuild(a)
		var cfg: Dictionary = sim.effective_config(id)
		for key: String in sliders:
			var s: HSlider = sliders[key]
			var v: float = a.cfg_current(key)  # valgt værdi (gælder fra næste tur)
			if not _dragging:
				s.set_value_no_signal(v)
			(values[key] as Label).text = AttractionTabs.config_value_text(key, s.value)
		if derived != null and not cfg.is_empty():
			derived.text = "Drift: $%d/dag\nSpænding: %.1f  Intensitet: %.1f  Kvalme: %.1f" % [
				int(cfg.get("upkeep_per_day", 0)), float(cfg.get("excitement", 0.0)) / 10.0,
				float(cfg.get("intensity", 0.0)) / 10.0, float(cfg.get("nausea", 0.0)) / 10.0]
		for rid: String in recipes:
			(recipes[rid] as CheckBox).set_pressed_no_signal(a.recipes.has(rid))
		price_label.text = "Pris: $%d" % a.price
		warning.text = AttractionTabs.price_warning(a.price, a.def.ticket_price)
		warning.visible = warning.text != ""

	func _rebuild(a: Attraction) -> void:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		sliders.clear()
		values.clear()
		recipes.clear()
		derived = null
		if not a.def.config.is_empty() and not a.is_tracked():
			var h := Label.new()
			h.text = "Drift"
			h.theme_type_variation = &"TitleLabel"
			add_child(h)
			for key: String in ["capacity", "ride_ticks", "speed"]:
				if not a.def.config.has(key):
					continue
				var e: Dictionary = a.def.config[key]
				var row := HBoxContainer.new()
				row.name = "Cfg_" + key
				add_child(row)
				var n := Label.new()
				n.text = CONFIG_NAMES.get(key, key)
				n.custom_minimum_size = Vector2(84, 0)
				row.add_child(n)
				var s := HSlider.new()
				s.name = "Slider"
				s.min_value = float(e["min"])
				s.max_value = float(e["max"])
				s.step = 0.05 if key == "speed" else 1.0
				s.value = float(e["default"])
				s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				s.value_changed.connect(_on_slider.bind(key))
				s.drag_started.connect(func() -> void: _dragging = true)
				s.drag_ended.connect(_on_drag_ended.bind(key))
				TooltipService.attach(s, CONFIG_NAMES.get(key, key), "Gælder fra næste tur.")
				row.add_child(s)
				var v := Label.new()
				v.custom_minimum_size = Vector2(48, 0)
				v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				row.add_child(v)
				sliders[key] = s
				values[key] = v
			derived = AttractionTabs._label(self)
			derived.name = "Derived"
		if not a.def.recipes.is_empty():
			var h2 := Label.new()
			h2.text = "Opskrifter"
			h2.theme_type_variation = &"TitleLabel"
			add_child(h2)
			for r: Dictionary in a.def.recipes:
				var cb := CheckBox.new()
				var rid: String = str(r.get("id", ""))
				cb.name = "Recipe_" + rid
				cb.text = "%s (+$%.2f pr. salg)" % [str(r.get("name", rid)), float(r.get("cost_per_sale", 0.0))]
				cb.toggled.connect(_on_recipe.bind(rid))
				add_child(cb)
				recipes[rid] = cb
		var h3 := Label.new()
		h3.text = "Pris"
		h3.theme_type_variation = &"TitleLabel"
		add_child(h3)
		var ph := HBoxContainer.new()
		ph.name = "PriceStepper"
		add_child(ph)
		var minus := Button.new()
		minus.name = "Minus"
		minus.text = "-"
		minus.custom_minimum_size = Vector2(32, 0)
		minus.pressed.connect(_on_price.bind(-1))
		ph.add_child(minus)
		price_label = Label.new()
		price_label.name = "Price"
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ph.add_child(price_label)
		var plus := Button.new()
		plus.name = "Plus"
		plus.text = "+"
		plus.custom_minimum_size = Vector2(32, 0)
		plus.pressed.connect(_on_price.bind(1))
		ph.add_child(plus)
		if a.def.ticket_price > 0:
			AttractionTabs._label(self, "Standardpris: $%d" % a.def.ticket_price)
		warning = AttractionTabs._label(self)
		warning.name = "PriceWarning"
		warning.add_theme_color_override("font_color", UiTheme.RED)
		if a.is_tracked():
			AttractionTabs._label(self, "Sporbaner kan ikke justeres.")

	func _on_slider(v: float, key: String) -> void:
		if not _dragging and sim != null:
			sim.cmd_set_config(target, key, v)
		(values[key] as Label).text = AttractionTabs.config_value_text(key, v)

	func _on_drag_ended(changed: bool, key: String) -> void:
		_dragging = false
		if changed and sim != null:
			sim.cmd_set_config(target, key, (sliders[key] as HSlider).value)

	func _on_recipe(on: bool, rid: String) -> void:
		if sim != null:
			sim.cmd_set_recipe(target, rid, on)

	func _on_price(delta: int) -> void:
		var a: Attraction = sim.get_attraction(target) if sim != null else null
		if a != null:
			sim.cmd_set_price(a.id, maxi(0, a.price + delta))
			refresh(sim, target)


## --- Økonomi: tal, sparkline over 7 dage og tilbagebetaling ---
class EconomyTab extends VBoxContainer:
	var info: Label
	var spark: Sparkline
	var payback: Label

	func _init() -> void:
		name = "EconomyTab"
		info = AttractionTabs._label(self)
		info.name = "Info"
		var h := Label.new()
		h.text = "Omsætning, sidste 7 dage"
		add_child(h)
		spark = Sparkline.new()
		spark.name = "Sparkline"
		spark.custom_minimum_size = Vector2(200, 48)
		add_child(spark)
		payback = AttractionTabs._label(self)
		payback.name = "Payback"

	func refresh(sim: ParkSim, id: int) -> void:
		var st: Dictionary = sim.attraction_stats(id) if sim != null else {}
		if st.is_empty():
			return
		info.text = "\n".join([
			"I dag: $%d (%d kunder)" % [int(st.get("revenue_today", 0)), int(st.get("customers_today", 0))],
			"I går: $%d" % int(st.get("revenue_yesterday", 0)),
			"Omsætning i alt: $%d" % int(st.get("revenue_total", 0)),
			"Drift i alt: $%d" % int(st.get("upkeep_total", 0)),
			"Varekøb i alt: $%d" % int(st.get("supplies_total", 0)),
			"Netto: $%d" % int(st.get("net_total", 0)),
		])
		var vals: Array[float] = []
		for v: Variant in st.get("revenue_days", []):
			vals.append(float(v))
		spark.set_values(vals)
		payback.text = AttractionTabs.payback_text(int(st.get("payback_day", -1)))
		payback.add_theme_color_override("font_color", UiTheme.GREEN if int(st.get("payback_day", -1)) >= 0 else UiTheme.INK)


class Sparkline extends Control:
	var values: Array[float] = []

	func set_values(v: Array[float]) -> void:
		if v != values:
			values = v.duplicate()
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, UiTheme.PAPER_SHADE)
		draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), UiTheme.PAPER_EDGE, 1.0)
		if values.is_empty():
			return
		var hi: float = 1.0
		for v in values:
			hi = maxf(hi, v)
		var n: int = 7
		var w: float = size.x / float(n)
		var off: int = n - values.size()
		for i in values.size():
			var h: float = (size.y - 4.0) * values[i] / hi
			draw_rect(Rect2((off + i) * w + 2.0, size.y - 1.0 - h, w - 4.0, h), UiTheme.GREEN)


## --- Kø: længde/kapacitet, ventetid og tålmodighed ---
class QueueTab extends VBoxContainer:
	var info: Label
	var bar: ProgressBar

	func _init() -> void:
		name = "QueueTab"
		bar = ProgressBar.new()
		bar.name = "Fill"
		bar.max_value = 1.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(200, 14)
		add_child(bar)
		info = AttractionTabs._label(self)
		info.name = "Info"

	func refresh(sim: ParkSim, id: int) -> void:
		var st: Dictionary = sim.attraction_stats(id) if sim != null else {}
		if st.is_empty():
			return
		info.text = AttractionTabs.queue_text(st, AttractionTabs.avg_patience_s(sim, id))
		var cap: int = int(st.get("queue_capacity", 0))
		bar.visible = cap > 0 and cap < 100000
		bar.value = float(st.get("queue_length", 0)) / float(maxi(1, cap))


static func queue_text(st: Dictionary, patience_s: float) -> String:
	var lines: Array[String] = []
	var cap: int = int(st.get("queue_capacity", 0))
	var qlen: int = int(st.get("queue_length", st.get("queue", 0)))
	if cap > 0 and cap < 100000:
		lines.append("Kø: %d/%d" % [qlen, cap])
		lines.append("Køsti: %d felter" % int(st.get("queue_cells", 0)))
	else:
		lines.append("Kø: %d (ingen køsti)" % qlen)
	lines.append("Ventetid: ca. %d s" % (int(st.get("wait_ticks_estimate", 0)) / SimClock.TICKS_PER_SECOND))
	if patience_s >= 0.0:
		lines.append("Tålmodighed i køen: ca. %d s tilbage" % roundi(patience_s))
	else:
		lines.append("Ingen i kø")
	return "\n".join(lines)


## Gennemsnitlig resterende tålmodighed (sekunder) for gæsterne i køen; -1 hvis tom.
static func avg_patience_s(sim: ParkSim, id: int) -> float:
	var a: Attraction = sim.get_attraction(id) if sim != null else null
	if a == null or a.queue.is_empty():
		return -1.0
	var sum: float = 0.0
	var n: int = 0
	for gid: Variant in a.queue:
		var g: Guest = sim.guests.get(gid, null)
		if g != null:
			sum += maxf(0.0, g.patience)
			n += 1
	return sum / float(n) / float(SimClock.TICKS_PER_SECOND) if n > 0 else -1.0
