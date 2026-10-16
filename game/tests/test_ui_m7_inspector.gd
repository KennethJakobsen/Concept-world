extends TestCase
## T-112: Inspector-faner for bygninger (Indstillinger, Økonomi, Kø).


func _hud() -> Hud:
	var hud := Hud.new()
	hud.settings_path = "user://test_t112_settings.cfg"
	hud.sim = ParkSim.new(20, 20, 1)
	hud.sim.economy.money = 100000
	hud._build_ui()
	return hud


func _texts(n: Node, out: Array[String]) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_texts(c, out)


func test_tabs_registered() -> void:
	var hud := _hud()
	var a: Attraction = hud.sim.cmd_place_attraction("bouncy_castle", Vector2i(5, 5))
	hud.show_attraction(a.id)
	assert_eq(hud.inspector.tab_ids(), [&"overview", &"settings", &"economy", &"queue"] as Array[StringName])
	assert_true(not Hud.attraction_text(a, hud.sim).contains("Kø:"), "kølinjen er flyttet til Kø-fanen")
	hud.free()


func test_settings_slider_calls_sim() -> void:
	var hud := _hud()
	var a: Attraction = hud.sim.cmd_place_attraction("bouncy_castle", Vector2i(5, 5))
	hud.show_attraction(a.id)
	hud.inspector.select_tab(&"settings")
	hud.refresh()
	var tab: AttractionTabs.SettingsTab = hud.inspector.current_control()
	assert_true(tab.sliders.has("capacity"))
	(tab.sliders["capacity"] as HSlider).value_changed.emit(14.0)  # uden for træet udsendes signalet ikke af sig selv
	assert_eq(int(a.cfg_current("capacity")), 14)
	hud.refresh()
	assert_eq((tab.sliders["capacity"] as HSlider).value, 14.0, "skyderen springer ikke tilbage")
	(tab.sliders["speed"] as HSlider).value_changed.emit(99.0)
	assert_true(a.cfg_current("speed") <= 1.3)
	hud.free()


func test_recipes_and_price_warning() -> void:
	var hud := _hud()
	var a: Attraction = hud.sim.cmd_place_attraction("burger_stand", Vector2i(5, 5))
	hud.show_attraction(a.id)
	hud.inspector.select_tab(&"settings")
	hud.refresh()
	var tab: AttractionTabs.SettingsTab = hud.inspector.current_control()
	assert_true(tab.sliders.is_empty())
	(tab.recipes["salt"] as CheckBox).button_pressed = true
	assert_true(a.recipes.has("salt"))
	assert_true(not (tab.warning.visible))
	for i in a.price:
		tab._on_price(-1)
	assert_eq(a.price, 0)
	assert_true(tab.warning.visible)
	assert_true(tab.warning.text.contains("lav pris"))
	hud.free()


func test_economy_and_queue_tabs() -> void:
	var hud := _hud()
	var a: Attraction = hud.sim.cmd_place_attraction("bouncy_castle", Vector2i(5, 5))
	a.revenue_days = PackedInt32Array([10, 40, 20])
	a.payback_day = 4
	hud.show_attraction(a.id)
	hud.inspector.select_tab(&"economy")
	hud.refresh()
	var eco: AttractionTabs.EconomyTab = hud.inspector.current_control()
	assert_eq(eco.payback.text, "Tjent hjem på dag 4")
	assert_eq(eco.spark.values.size(), 3)
	assert_true(eco.info.text.contains("Netto"))
	assert_eq(AttractionTabs.payback_text(-1), "Ikke tjent hjem endnu")
	hud.inspector.select_tab(&"queue")
	hud.refresh()
	var q: AttractionTabs.QueueTab = hud.inspector.current_control()
	assert_true(q.info.text.contains("Ventetid"))
	var t: String = AttractionTabs.queue_text({"queue_length": 3, "queue_capacity": 12, "queue_cells": 4, "wait_ticks_estimate": 200}, 30.0)
	assert_true(t.contains("Kø: 3/12"))
	assert_true(t.contains("ca. 10 s"))
	hud.free()


func test_tab_glyphs() -> void:
	var font: Font = ThemeDB.fallback_font
	var hud := _hud()
	var texts: Array[String] = []
	for kind: String in ["bouncy_castle", "burger_stand"]:
		var a: Attraction = hud.sim.cmd_place_attraction(kind, Vector2i(3 + texts.size() % 10, 3))
		hud.show_attraction(a.id)
		a.price = 0
		for tab: StringName in [&"settings", &"economy", &"queue"]:
			hud.inspector.select_tab(tab)
			hud.refresh()
			_texts(hud.inspector, texts)
	for t: String in texts:
		for i in t.length():
			var ch: int = t.unicode_at(i)
			if ch >= 32:
				assert_true(font.has_char(ch), "glyf U+%04X mangler i '%s'" % [ch, t])
	hud.free()
