class_name MilestonePanel
extends PanelContainer
## T-113: rail-panel med parkens milepæle: navn, fremskridtslinje, belønning og flueben.
## Læser kun `sim.milestones()`; ejer ingen logik.

var rows: Dictionary = {}  ## id -> {bar: ProgressBar, check: Label, name: Label}
var _list: VBoxContainer
var _note: Label
var _built_ids: Array[String] = []


func build() -> void:
	name = "MilestonePanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(320, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var t := Label.new()
	t.text = "Milepæle"
	t.theme_type_variation = &"TitleLabel"
	v.add_child(t)
	_note = Label.new()
	_note.name = "Note"
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.visible = false
	v.add_child(_note)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.add_theme_constant_override("separation", 8)
	v.add_child(_list)
	visible = false


func _rebuild(ms: Array[Dictionary], sim: ParkSim) -> void:
	for c in _list.get_children():
		c.queue_free()
		_list.remove_child(c)
	rows.clear()
	_built_ids.clear()
	for m: Dictionary in ms:
		var id: String = str(m["id"])
		_built_ids.append(id)
		var box := VBoxContainer.new()
		box.name = "M_" + id
		box.add_theme_constant_override("separation", 2)
		_list.add_child(box)
		var h := HBoxContainer.new()
		box.add_child(h)
		var check := UiIcons.new("check", 18.0)
		check.name = "Check"
		check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(check)
		var n := Label.new()
		n.name = "Name"
		n.text = str(m["name"])
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		var bar := ProgressBar.new()
		bar.name = "Progress"
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.custom_minimum_size = Vector2(0, 14)
		box.add_child(bar)
		var r := Label.new()
		r.name = "Reward"
		r.text = M7Texts.reward_text(m.get("reward", {}) as Dictionary, sim)
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		r.add_theme_font_size_override("font_size", 12)
		box.add_child(r)
		rows[id] = {"bar": bar, "check": check, "name": n}


func refresh(sim: ParkSim) -> void:
	if sim == null:
		return
	var ms: Array[Dictionary] = sim.milestones()
	var ids: Array[String] = []
	for m: Dictionary in ms:
		ids.append(str(m["id"]))
	if ids != _built_ids:
		_rebuild(ms, sim)
	var on: bool = sim.milestones_enabled()
	_note.visible = not on
	_note.text = "Milepæle er slået fra i denne park - alt er åbent."
	for m: Dictionary in ms:
		var r: Dictionary = rows[str(m["id"])]
		var done: bool = bool(m["achieved"])
		(r.bar as ProgressBar).value = 100.0 if done else clampf(float(m["progress"]) * 100.0, 0.0, 100.0)
		(r.check as Control).modulate.a = 1.0 if done else 0.15
		(r.name as Label).modulate = Color(1, 1, 1, 1.0 if (done or on) else 0.6)


func progress_of(id: String) -> float:
	return (rows[id].bar as ProgressBar).value if rows.has(id) else -1.0
