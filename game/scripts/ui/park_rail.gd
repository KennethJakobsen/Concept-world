class_name ParkRail
extends PanelContainer
## Venstre kant (T-101): små ikonknapper for park-overblik (økonomi, personale, forskning,
## indstillinger, menu ...). Kun ét rail-panel åbent ad gangen.
##
## Udvidelses-API (kontrakt M7 §4, bruges af T-113):
##   `register(id, icon, panel_factory, title := "")`. `icon` er en UiIcons-kind.
##   `panel_factory` kaldes uden argumenter første gang og skal returnere en Control; den lægges
##   i `host` (HUD-roden) og vises/skjules ved klik. Har kontrollen `refresh(sim)`, kaldes den
##   hver frame mens den er synlig. Interne knapper kan i stedet bruge `register_action`.

signal panel_toggled(id: StringName, open: bool)

const BUTTON_SIZE: float = 48.0

var host: Control  ## hvor fabrik-paneler lægges
var open_id: StringName = &""
var _entries: Dictionary = {}  ## id -> {button, factory, action, panel}
var _box: VBoxContainer


func build() -> void:
	name = "ParkRail"
	theme_type_variation = &"RailWood"
	mouse_filter = Control.MOUSE_FILTER_STOP
	_box = VBoxContainer.new()
	_box.name = "V"
	_box.add_theme_constant_override("separation", 10)
	add_child(_box)


func register(id: StringName, icon: String, panel_factory: Callable, title: String = "") -> Button:
	return _add(id, icon, title, panel_factory, Callable())


## Knap der kalder `action` (fx eksisterende HUD-paneler).
func register_action(id: StringName, icon: String, title: String, action: Callable) -> Button:
	return _add(id, icon, title, Callable(), action)


func _add(id: StringName, icon: String, title: String, factory: Callable, action: Callable) -> Button:
	var b: Button = _entries[id].button if _entries.has(id) else null
	if b == null:
		b = UiTheme.medallion("rail_" + icon, BUTTON_SIZE)
		b.name = "Rail_" + String(id)
		b.toggle_mode = true
		if b.icon == null:  # intet malet ikon: tegnet fallback
			var ic := UiIcons.new(icon, BUTTON_SIZE - 20.0)
			ic.name = "Icon"
			ic.color = UiTheme.CREAM
			ic.position = Vector2(10, 10)
			b.add_child(ic)
		b.pressed.connect(toggle.bind(id))
		_box.add_child(b)
	TooltipService.attach(b, title if title != "" else String(id))
	_entries[id] = {"button": b, "factory": factory, "action": action, "panel": null}
	return b


func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in _entries:
		out.append(k)
	return out


func button(id: StringName) -> Button:
	return _entries[id].button if _entries.has(id) else null


func panel(id: StringName) -> Control:
	return _entries[id].panel if _entries.has(id) else null


func set_entry_visible(id: StringName, on: bool) -> void:
	var b: Button = button(id)
	if b != null:
		b.visible = on


func toggle(id: StringName) -> void:
	if not _entries.has(id):
		return
	var e: Dictionary = _entries[id]
	if (e.action as Callable).is_valid():
		close_panel()
		_sync_pressed()
		(e.action as Callable).call()
		return
	var was_open: bool = open_id == id
	close_panel()
	if was_open:
		return
	if e.panel == null and (e.factory as Callable).is_valid():
		var made: Variant = (e.factory as Callable).call()
		if made is Control:
			e.panel = made
			(host if host != null else self).add_child(made)
	if e.panel != null:
		(e.panel as Control).visible = true
		open_id = id
		_sync_pressed()
		panel_toggled.emit(id, true)


func close_panel() -> void:
	if open_id == &"":
		return
	var p: Control = panel(open_id)
	if p != null:
		p.visible = false
	var old: StringName = open_id
	open_id = &""
	_sync_pressed()
	panel_toggled.emit(old, false)


func refresh(sim: ParkSim) -> void:
	var p: Control = panel(open_id)
	if p != null and p.visible and p.has_method("refresh"):
		p.call("refresh", sim)


func _sync_pressed() -> void:
	for k: StringName in _entries:
		(_entries[k].button as Button).set_pressed_no_signal(k == open_id)
