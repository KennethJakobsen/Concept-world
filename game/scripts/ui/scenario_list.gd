class_name ScenarioList
extends VBoxContainer
## Liste over scenarier (ScenarioDef.list_all, sandbox udeladt) med navn, beskrivelse og mål.

signal scenario_chosen(scenario_id: String)

var defs: Array[ScenarioDef] = []


func build(p_defs: Variant = null) -> void:
	name = "ScenarioList"
	add_theme_constant_override("separation", 10)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	defs.clear()
	var all: Array[ScenarioDef] = ScenarioDef.list_all() if p_defs == null else p_defs
	for d: ScenarioDef in all:
		if d.is_sandbox():
			continue
		defs.append(d)
		_add_entry(d)
	if defs.is_empty():
		var l := Label.new()
		l.text = "Ingen scenarier fundet."
		add_child(l)


func _add_entry(d: ScenarioDef) -> void:
	var p := PanelContainer.new()
	p.name = "S_" + d.id
	add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	var b := Button.new()
	b.name = "Start"
	b.text = d.name
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void: scenario_chosen.emit(d.id))
	v.add_child(b)
	var desc := Label.new()
	desc.text = d.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(400, 0)
	v.add_child(desc)
	var goals := Label.new()
	goals.name = "Goals"
	goals.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goals.custom_minimum_size = Vector2(400, 0)
	goals.text = goals_text(d)
	v.add_child(goals)


static func goals_text(d: ScenarioDef) -> String:
	var lines: Array[String] = ["Mål:"]
	for o: Dictionary in d.objectives:
		lines.append("- " + M5Texts.goal_line(o))
	lines.append("- Frist: %d dage" % d.deadline_days if d.deadline_days > 0 else "- Ingen frist")
	for l: Dictionary in d.lose:
		lines.append("Tabes ved: " + M5Texts.lose_line(l))
	lines.append("Forskning: " + ("til" if d.research_enabled else "fra") + "   Start: $%d" % d.start_money)
	return "\n".join(lines)


func entry_count() -> int:
	return defs.size()


func choose(idx: int) -> void:
	scenario_chosen.emit(defs[idx].id)
