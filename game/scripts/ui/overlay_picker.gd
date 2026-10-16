class_name OverlayPicker
extends PanelContainer
## T-113: overlay-vælger (rail-panel, tast O). Knapper for ParkColors.OVERLAY_KINDS + "Ingen" og en
## legende for det valgte overlay. Kalder GameSession.show_overlay/hide_overlay (tåler at den mangler).

signal overlay_changed(kind: StringName)

var current: StringName = &""
var buttons: Dictionary = {}  ## kind -> Button (&"" = Ingen)
var _legend: VBoxContainer
var _legend_title: Label
## Tests kan erstatte kaldet til GameSession.
var show_fn: Callable = func(k: StringName) -> void: UiSession.call_session("show_overlay", [k])
var hide_fn: Callable = func() -> void: UiSession.call_session("hide_overlay")


func build() -> void:
	name = "OverlayPicker"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(260, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var t := Label.new()
	t.text = "Overlays (O)"
	t.theme_type_variation = &"TitleLabel"
	v.add_child(t)
	var grid := GridContainer.new()
	grid.name = "Kinds"
	grid.columns = 2
	v.add_child(grid)
	var kinds: Array[StringName] = [&""]
	kinds.append_array(ParkColors.OVERLAY_KINDS)
	for k: StringName in kinds:
		var b := Button.new()
		b.name = "Kind_" + (String(k) if k != &"" else "none")
		b.text = M7Texts.overlay_name(k) if k != &"" else "Ingen"
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(select.bind(k))
		grid.add_child(b)
		buttons[k] = b
	_legend_title = Label.new()
	_legend_title.name = "LegendTitle"
	v.add_child(_legend_title)
	_legend = VBoxContainer.new()
	_legend.name = "Legend"
	v.add_child(_legend)
	_sync()
	visible = false


func select(kind: StringName) -> void:
	current = kind
	if kind == &"":
		hide_fn.call()
	else:
		show_fn.call(kind)
	_sync()
	overlay_changed.emit(kind)


## Skjul overlayet, uden at panelet behøver være åbent (fx når panelet lukkes).
func clear() -> void:
	if current != &"":
		select(&"")


func legend_labels() -> Array[String]:
	var out: Array[String] = []
	for row in _legend.get_children():
		var l: Label = row.get_node_or_null("Label") as Label
		if l != null:
			out.append(l.text)
	return out


func _sync() -> void:
	for k: StringName in buttons:
		(buttons[k] as Button).set_pressed_no_signal(k == current)
	for c in _legend.get_children():
		_legend.remove_child(c)
		c.queue_free()
	_legend_title.visible = current != &""
	_legend_title.text = "Forklaring: " + M7Texts.overlay_name(current)
	if current == &"":
		return
	for e: Dictionary in ParkColors.legend(current):
		var row := HBoxContainer.new()
		_legend.add_child(row)
		var sw := ColorRect.new()
		sw.name = "Swatch"
		sw.color = e["color"]
		sw.custom_minimum_size = Vector2(22, 16)
		sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sw)
		var l := Label.new()
		l.name = "Label"
		l.text = str(e["label"])
		row.add_child(l)
