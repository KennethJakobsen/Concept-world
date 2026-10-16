extends TestCase
## T-052: ur-ikon, lydindstillinger, klik-lyd, advarsels-toast.


class FakeAudio:
	extends Node
	var vol: Dictionary = {}
	var mute: Dictionary = {}
	var ui: Array = []
	func set_bus_volume(bus: StringName, v: float) -> void: vol[bus] = v
	func get_bus_volume(bus: StringName) -> float: return float(vol.get(bus, 0.5))
	func set_muted(bus: StringName, on: bool) -> void: mute[bus] = on
	func is_muted(bus: StringName) -> bool: return bool(mute.get(bus, false))
	func play_ui(id: StringName) -> void: ui.append(id)


func _font_ok(t: String) -> bool:
	var f: Font = ThemeDB.fallback_font
	for i in t.length():
		if t.unicode_at(i) >= 32 and not f.has_char(t.unicode_at(i)):
			return false
	return true


func _texts(n: Node, out: Array[String]) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_texts(c, out)


func test_settings_panel_drives_audio() -> void:
	var fa := FakeAudio.new()
	fa.vol[&"Music"] = 0.3
	fa.mute[&"SFX"] = true
	var p := SettingsPanel.new()
	p.audio = fa
	p.build()
	p.open()
	assert_eq(p.slider(&"Music").value, 0.3)
	assert_true(p.mute_box(&"SFX").button_pressed)
	# Range udsender ikke value_changed uden for træet: tjek forbindelsen og kald handleren.
	assert_true(p.slider(&"UI").value_changed.get_connections().size() > 0)
	p.set_volume(0.8, &"UI")
	assert_eq(float(fa.vol.get(&"UI", -1.0)), 0.8)
	p.mute_box(&"Master").button_pressed = true
	assert_true(bool(fa.mute[&"Master"]))
	var texts: Array[String] = []
	_texts(p, texts)
	for t in texts:
		assert_true(_font_ok(t), "glyf mangler: " + t)
	p.layout(Vector2(1024, 600))
	var r: Rect2 = p.panel_rect()
	assert_true(r.position.x >= 0 and r.end.x <= 1024 and r.end.y <= 600, "panel uden for skærm")
	p.free()
	fa.free()


func test_settings_without_audio_manager() -> void:
	var p := SettingsPanel.new()
	p.build()
	p.open()
	p.slider(&"Master").value = 0.1
	p.free()


func test_toast_and_warning_text() -> void:
	assert_true(_font_ok(Toast.warning_text(&"broken_no_mechanic")))
	assert_true(_font_ok(Toast.warning_text(&"ukendt")))
	var t := Toast.new()
	t.show_warning(&"broken_no_mechanic", {"attraction_id": 1})
	assert_true(t.visible)
	assert_true(t.text().contains("mekaniker"))
	t.tick(10.0)
	assert_true(not t.visible)
	t.free()


func test_hud_has_clock_and_toast() -> void:
	var hud := Hud.new()
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	hud.refresh()
	assert_true(hud.toast() != null)
	hud.show_warning(&"broken_no_mechanic")
	assert_eq(hud.alert_tray.items().size(), 1, "varsler lander i AlertTray (T-101)")
	if hud.sim.has_method("clock_text"):
		var txt: String = hud._clock_label.text
		assert_eq(txt.length(), 5)
		assert_true(_font_ok(txt))
	var ic := ClockIcon.new()
	ic.night = true
	assert_true(ic.night)
	ic.free()
	hud.free()


func test_click_helper_wires_buttons() -> void:
	var root := Control.new()
	var b := Button.new()
	root.add_child(b)
	UiSound.wire(root)
	UiSound.wire(root)
	assert_true(UiSound.is_wired(b))
	b.pressed.emit()  # ingen AudioManager -> ingen crash
	root.free()
