class_name SettingsPanel
extends Control
## Lydindstillinger: volumen + mute for 5 busser via AudioManager (som også persisterer).
## Ingen spillogik; tåler manglende AudioManager (skydere virker blot ikke).

signal closed

const BUSES: Array[StringName] = [&"Master", &"Music", &"SFX", &"Ambience", &"UI"]
const BUS_NAMES: Dictionary = {&"Master": "Samlet", &"Music": "Musik", &"SFX": "Effekter",
	&"Ambience": "Omgivelser", &"UI": "Menulyde"}

var audio: Node  ## Tests kan injicere; ellers autoload AudioManager
var _panel: PanelContainer
var _sliders: Dictionary = {}  ## bus -> HSlider
var _mutes: Dictionary = {}    ## bus -> CheckBox


func _am() -> Node:
	return audio if audio != null else UiSound.audio_manager()


func build() -> void:
	name = "SettingsPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(320, 0)
	add_child(_panel)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	var title := Label.new()
	title.text = "Indstillinger - lyd"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 3
	v.add_child(grid)
	for bus: StringName in BUSES:
		var l := Label.new()
		l.text = BUS_NAMES[bus]
		grid.add_child(l)
		var s := HSlider.new()
		s.name = "Vol_" + String(bus)
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.custom_minimum_size = Vector2(150, 0)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.focus_mode = Control.FOCUS_NONE
		s.value_changed.connect(set_volume.bind(bus))
		grid.add_child(s)
		_sliders[bus] = s
		var m := CheckBox.new()
		m.name = "Mute_" + String(bus)
		m.text = "Fra"
		m.focus_mode = Control.FOCUS_NONE
		m.toggled.connect(set_muted.bind(bus))
		grid.add_child(m)
		_mutes[bus] = m
	var b := Button.new()
	b.text = "Luk"
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(close)
	v.add_child(b)


func slider(bus: StringName) -> HSlider:
	return _sliders.get(bus)


func mute_box(bus: StringName) -> CheckBox:
	return _mutes.get(bus)


## Læser aktuelle værdier fra AudioManager (uden at udsende ændringer tilbage).
func sync_from_audio() -> void:
	var am: Node = _am()
	for bus: StringName in BUSES:
		var vol: float = 1.0
		var muted: bool = false
		if am != null and am.has_method("get_bus_volume"):
			vol = float(am.call("get_bus_volume", bus))
		if am != null and am.has_method("is_muted"):
			muted = bool(am.call("is_muted", bus))
		(_sliders[bus] as HSlider).set_value_no_signal(vol)
		(_mutes[bus] as CheckBox).set_pressed_no_signal(muted)


func set_volume(v: float, bus: StringName) -> void:
	var am: Node = _am()
	if am != null and am.has_method("set_bus_volume"):
		am.call("set_bus_volume", bus, v)


func set_muted(on: bool, bus: StringName) -> void:
	var am: Node = _am()
	if am != null and am.has_method("set_muted"):
		am.call("set_muted", bus, on)


func layout(vp: Vector2) -> void:
	position = Vector2.ZERO
	size = vp
	(get_node("Dim") as Control).size = vp
	var m: Vector2 = _panel.get_combined_minimum_size()
	m.x = minf(m.x, vp.x)
	_panel.size = m
	_panel.position = ((vp - m) * 0.5).max(Vector2.ZERO)


func panel_rect() -> Rect2:
	return Rect2(_panel.position, _panel.get_combined_minimum_size())


func open() -> void:
	sync_from_audio()
	visible = true
	UiSound.play(&"open")
	if is_inside_tree():
		layout(get_viewport().get_visible_rect().size)


func close() -> void:
	if not visible:
		return
	visible = false
	UiSound.play(&"close")
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
