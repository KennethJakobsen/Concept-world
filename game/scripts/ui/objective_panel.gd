class_name ObjectivePanel
extends PanelContainer
## Scenarie-mål i HUD'en (skjult i sandbox): navn, dag x/y og hvert mål med current/value + tegnet flueben.

var _title: Label
var _day: Label
var _rows: VBoxContainer
var _state: Label
var _last_count: int = -1


func build() -> void:
	name = "ObjectivePanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(240, 0)
	var v := VBoxContainer.new()
	add_child(v)
	_title = Label.new()
	v.add_child(_title)
	_day = Label.new()
	v.add_child(_day)
	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	v.add_child(_rows)
	_state = Label.new()
	v.add_child(_state)
	visible = false


## Opdaterer ud fra sim.scenario_status(). Skjules når status er tom (sandbox).
func refresh(sim: ParkSim) -> void:
	var st: Dictionary = sim.scenario_status() if sim != null and sim.has_method("scenario_status") else {}
	visible = not st.is_empty()
	if not visible:
		return
	_title.text = "Mål: " + str(st.get("name", ""))
	_day.text = M5Texts.day_line(st)
	var objs: Array = st.get("objectives", [])
	if objs.size() != _last_count:
		for c in _rows.get_children():
			_rows.remove_child(c)
			c.queue_free()
		for i in objs.size():
			var h := HBoxContainer.new()
			h.add_child(UiIcons.new("empty", 16.0))
			h.add_child(Label.new())
			_rows.add_child(h)
		_last_count = objs.size()
	for i in objs.size():
		var o: Dictionary = objs[i]
		var h: HBoxContainer = _rows.get_child(i)
		var icon: UiIcons = h.get_child(0)
		var k: String = "check" if bool(o.get("met", false)) else "empty"
		if icon.kind != k:
			icon.kind = k
			icon.queue_redraw()
		(h.get_child(1) as Label).text = M5Texts.objective_line(o)
	match StringName(st.get("state", &"running")):
		&"won":
			_state.text = "Scenariet er vundet!"
		&"lost":
			_state.text = "Scenariet er tabt."
		_:
			_state.text = ""
	_state.visible = _state.text != ""


func met_flags() -> Array[bool]:
	var out: Array[bool] = []
	for h in _rows.get_children():
		out.append((h.get_child(0) as UiIcons).kind == "check")
	return out


func lines() -> Array[String]:
	var out: Array[String] = []
	for h in _rows.get_children():
		out.append((h.get_child(1) as Label).text)
	return out
