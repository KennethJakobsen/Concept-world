class_name TutorialPanel
extends PanelContainer
## T-116: tutorial-trinpanel. Viser trin-tekst, fremskridt ("Trin x af y") og "Spring over".
## Ejer ingen logik: GameSession (TutorialDirector, T-115) sender tutorial_step_changed /
## tutorial_finished, og "Spring over" kalder tutorial_skip(). Highlights i dokken/rail'en
## tegnes af TutorialHighlight; pile i verden laver gameplay.

signal skip_requested

var step_index: int = -1
var step_count: int = 0
var step: Dictionary = {}
var title_label: Label
var progress_label: Label
var text_label: Label
var progress_bar: ProgressBar
var skip_button: Button
var highlight: TutorialHighlight


func build() -> void:
	name = "TutorialPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(320, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var h := HBoxContainer.new()
	v.add_child(h)
	title_label = Label.new()
	title_label.text = "Introduktion"
	title_label.theme_type_variation = &"TitleLabel"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(title_label)
	progress_label = Label.new()
	h.add_child(progress_label)
	progress_bar = ProgressBar.new()
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 8)
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(progress_bar)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(300, 0)
	v.add_child(text_label)
	skip_button = Button.new()
	skip_button.text = "Spring over"
	skip_button.tooltip_text = "Afslut introduktionen og spil videre"
	skip_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	skip_button.pressed.connect(_on_skip)
	v.add_child(skip_button)
	visible = false


## step_dict: {id, text, highlight, complete_when}. Totalt antal trin kan komme fra dict'en
## ("count"/"total") eller fra set_step_count().
func show_step(index: int, step_dict: Dictionary) -> void:
	step_index = index
	step = step_dict
	for k: String in ["count", "total", "step_count"]:
		if step_dict.has(k):
			step_count = int(step_dict[k])
	step_count = maxi(step_count, index + 1)
	text_label.text = str(step_dict.get("text", ""))
	progress_label.text = progress_text(index, step_count)
	progress_bar.max_value = step_count
	progress_bar.value = index
	skip_button.visible = bool(step_dict.get("skippable", true))
	visible = true
	if highlight != null:
		highlight.target_key = str(step_dict.get("highlight", ""))


func set_step_count(n: int) -> void:
	step_count = n
	if step_index >= 0:
		progress_label.text = progress_text(step_index, step_count)
		progress_bar.max_value = step_count


func finish() -> void:
	visible = false
	step_index = -1
	step = {}
	if highlight != null:
		highlight.target_key = ""


static func progress_text(index: int, count: int) -> String:
	return "Trin %d af %d" % [index + 1, maxi(count, index + 1)]


func _on_skip() -> void:
	skip_requested.emit()
	UiSession.call_session("tutorial_skip")
	finish()
