class_name ResearchPanel
extends PanelContainer
## Forskning: finansiering 0..3 (pris/dag), prioritet (emner), aktuelt item og progress.
## Skjules når forskning er slået fra.

const LEVEL_NAMES: Array[String] = ["Ingen", "Lav", "Mellem", "Høj"]

var _funding_box: GridContainer
var _funding_btns: Array[Button] = []
var _prio: OptionButton
var _topic_ids: Array[String] = []
var _item: Label
var _bar: ProgressBar
var _built_for: ParkSim
var wanted: bool = false  ## brugeren har åbnet panelet


func build() -> void:
	name = "ResearchPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(240, 0)
	var v := VBoxContainer.new()
	add_child(v)
	var t := Label.new()
	t.text = "Forskning"
	v.add_child(t)
	var fl := Label.new()
	fl.text = "Finansiering:"
	v.add_child(fl)
	_funding_box = GridContainer.new()  # T-146: 2x2, så panelet ikke bliver for bredt
	_funding_box.columns = 2
	_funding_box.name = "Funding"
	v.add_child(_funding_box)
	var pl := Label.new()
	pl.text = "Prioritet:"
	v.add_child(pl)
	_prio = OptionButton.new()
	_prio.name = "Priority"
	_prio.focus_mode = Control.FOCUS_NONE
	_prio.item_selected.connect(_on_prio)
	_prio.clip_text = true
	_prio.fit_to_longest_item = false
	v.add_child(_prio)
	_item = Label.new()
	_item.name = "Item"
	_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_item)
	_bar = ProgressBar.new()
	_bar.name = "Progress"
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.custom_minimum_size = Vector2(0, 16)
	v.add_child(_bar)
	var close := Button.new()
	close.text = "Luk panel"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func() -> void: wanted = false; visible = false)
	v.add_child(close)
	visible = false


var _sim: ParkSim


func _rebuild(sim: ParkSim) -> void:
	_built_for = sim
	_sim = sim
	for b in _funding_btns:
		b.queue_free()
	_funding_btns.clear()
	var rdef: ResearchDef = sim.research.def if "research" in sim and sim.research != null else null
	for lvl in 4:
		var b := Button.new()
		var cost: int = rdef.cost_for(lvl) if rdef != null else 0
		b.text = "%s\n$%d/dag" % [LEVEL_NAMES[lvl], cost]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(set_funding.bind(lvl))
		_funding_box.add_child(b)
		_funding_btns.append(b)
	_prio.clear()
	_topic_ids = [""]
	_prio.add_item("Ingen prioritet")
	if rdef != null:
		for tp: Dictionary in rdef.topics:
			_topic_ids.append(str(tp.get("id", "")))
			_prio.add_item(str(tp.get("name", tp.get("id", ""))))


static func enabled(sim: ParkSim) -> bool:
	if sim == null or not sim.has_method("research_status"):
		return false
	return bool(sim.research_status().get("enabled", false))


func toggle() -> void:
	wanted = not wanted


func refresh(sim: ParkSim) -> void:
	if not enabled(sim):
		visible = false
		return
	visible = wanted
	if sim != _built_for:
		_rebuild(sim)
	var st: Dictionary = sim.research_status()
	var lvl: int = int(st.get("funding_level", 0))
	for i in _funding_btns.size():
		_funding_btns[i].set_pressed_no_signal(i == lvl)
	var pi: int = maxi(0, _topic_ids.find(str(st.get("priority", ""))))
	if _prio.selected != pi:
		_prio.select(pi)
	var cur: String = str(st.get("current_item", ""))
	var need: float = float(st.get("points_needed", 0.0))
	if cur == "":
		_item.text = "Alt er udforsket"
	else:
		_item.text = "Forsker i: " + M5Texts.item_name(cur)
	_bar.value = 0.0 if need <= 0.0 else clampf(float(st.get("progress", 0.0)) / need * 100.0, 0.0, 100.0)
	if lvl == 0 and cur != "":
		_item.text += " (sat på pause)"


func set_funding(level: int) -> void:
	if _sim != null:
		_sim.cmd_set_research_funding(level)


func _on_prio(idx: int) -> void:
	if _sim != null and idx >= 0 and idx < _topic_ids.size():
		_sim.cmd_set_research_priority(_topic_ids[idx])


func select_priority(idx: int) -> void:
	_prio.select(idx)
	_on_prio(idx)


func item_text() -> String:
	return _item.text


func progress_value() -> float:
	return _bar.value


func topic_names() -> Array[String]:
	var out: Array[String] = []
	for i in _prio.item_count:
		out.append(_prio.get_item_text(i))
	return out
