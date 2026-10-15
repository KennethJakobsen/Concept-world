class_name ResultDialog
extends PanelContainer
## Vises ved scenario_finished: "Fortsæt i fri leg" eller "Hovedmenu".

signal continue_pressed
signal menu_pressed

var _title: Label
var _body: Label


func build() -> void:
	name = "ResultDialog"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(340, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(320, 0)
	v.add_child(_body)
	for t: Array in [["Fortsæt i fri leg", continue_pressed], ["Hovedmenu", menu_pressed]]:
		var b := Button.new()
		b.text = t[0]
		b.name = (t[0] as String).replace(" ", "")
		b.focus_mode = Control.FOCUS_NONE
		var sig: Signal = t[1]
		b.pressed.connect(func() -> void: sig.emit())
		v.add_child(b)
	visible = false


func show_result(won: bool, reason: String, scenario_name: String = "") -> void:
	_title.text = "Sejr!" if won else "Nederlag"
	var lines: Array[String] = []
	if scenario_name != "":
		lines.append(scenario_name)
	lines.append("Alle mål er nået. Godt gået!" if won else M5Texts.reason_text(reason))
	_body.text = "\n".join(lines)
	visible = true


func title_text() -> String:
	return _title.text


func layout(vp: Vector2) -> void:
	var m: Vector2 = get_combined_minimum_size()
	size = m
	position = ((vp - m) * 0.5).max(Vector2.ZERO)
