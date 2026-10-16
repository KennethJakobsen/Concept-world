class_name UiSettingsPanel
extends PanelContainer
## Rail-panel med UI-indstillinger (T-101): UI-skala (75-200 %), svævetal og farveblind-tilstand.
## Gemmes straks i user://settings.cfg via UserSettings. T-113 kan udvide panelet.

signal settings_changed(s: UserSettings)

var settings: UserSettings
var _scale: OptionButton
var _money: CheckBox
var _cb: CheckBox


func build(s: UserSettings) -> void:
	settings = s
	name = "UiSettingsPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(300, 0)
	var v := VBoxContainer.new()
	add_child(v)
	var title := Label.new()
	title.text = "Indstillinger"
	v.add_child(title)
	var row := HBoxContainer.new()
	v.add_child(row)
	var l := Label.new()
	l.text = "UI-skala"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	_scale = OptionButton.new()
	_scale.name = "Scale"
	_scale.focus_mode = Control.FOCUS_NONE
	for f: float in UserSettings.SCALES:
		_scale.add_item("%d %%" % roundi(f * 100.0))
	row.add_child(_scale)
	_scale.item_selected.connect(_on_scale)
	_money = CheckBox.new()
	_money.name = "FloatingMoney"
	_money.text = "Vis svævende beløb"
	_money.focus_mode = Control.FOCUS_NONE
	_money.toggled.connect(_on_money)
	v.add_child(_money)
	_cb = CheckBox.new()
	_cb.name = "Colorblind"
	_cb.text = "Farveblind-tilstand"
	_cb.focus_mode = Control.FOCUS_NONE
	_cb.toggled.connect(_on_cb)
	v.add_child(_cb)
	sync()
	visible = false


func sync() -> void:
	var idx: int = UserSettings.SCALES.find(settings.scale)
	if idx < 0:
		idx = UserSettings.SCALES.find(1.0)
	_scale.select(idx)
	_money.set_pressed_no_signal(settings.floating_money)
	_cb.set_pressed_no_signal(settings.colorblind)


func set_scale_index(i: int) -> void:
	_scale.select(i)
	_on_scale(i)


func _on_scale(i: int) -> void:
	settings.scale = UserSettings.SCALES[clampi(i, 0, UserSettings.SCALES.size() - 1)]
	_commit()


func _on_money(on: bool) -> void:
	settings.floating_money = on
	_commit()


func _on_cb(on: bool) -> void:
	settings.colorblind = on
	_commit()


func _commit() -> void:
	settings.save()
	if is_inside_tree():
		settings.apply(get_tree())
	settings_changed.emit(settings)
