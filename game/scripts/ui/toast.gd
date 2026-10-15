class_name Toast
extends PanelContainer
## Kortvarig besked, der forsvinder af sig selv. Viser én besked ad gangen (nyeste vinder).

const WARNING_TEXTS: Dictionary = {
	&"broken_no_mechanic": "Forlystelse i stykker - ansæt en mekaniker!",
}

@export var duration: float = 4.0
var _label: Label
var _left: float = 0.0


func _init() -> void:
	name = "Toast"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)


static func warning_text(code: StringName) -> String:
	return String(WARNING_TEXTS.get(code, "Advarsel: " + String(code)))


func text() -> String:
	return _label.text


func show_message(t: String) -> void:
	_label.text = t
	_left = duration
	modulate.a = 1.0
	visible = true


func show_warning(code: StringName, data: Dictionary = {}) -> void:
	if code == &"research_done":
		show_message("Ny forskning: %s er klar til at bygge!" % M5Texts.item_name(str(data.get("item_id", ""))))
		return
	show_message(warning_text(code))


## Kaldes hver frame (eller manuelt i tests).
func tick(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	modulate.a = clampf(_left / 0.5, 0.0, 1.0)
	if _left <= 0.0:
		visible = false


func _process(delta: float) -> void:
	tick(delta)
