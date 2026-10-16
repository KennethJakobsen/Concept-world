extends TestCase
## T-116: tutorial-trinpanel, highlights og glyffer.


func _hud() -> Hud:
	var hud := Hud.new()
	hud.settings_path = "user://test_t116_settings.cfg"
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	return hud


func _steps() -> Array:
	var f := FileAccess.open("res://content/scenarios/tutorial.json", FileAccess.READ)
	return (JSON.parse_string(f.get_as_text()) as Dictionary)["steps"]


func _texts(n: Node, out: Array[String]) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text + (n as Button).tooltip_text)
	for c in n.get_children():
		_texts(c, out)


func test_panel_shows_step_and_progress() -> void:
	var hud := _hud()
	assert_true(not hud.tutorial_panel.visible)
	var steps: Array = _steps()
	hud.on_tutorial_step(1, steps[1])
	assert_true(hud.tutorial_panel.visible)
	assert_eq(hud.tutorial_panel.text_label.text, str(steps[1]["text"]))
	assert_eq(hud.tutorial_panel.progress_label.text, "Trin 2 af %d" % steps.size())
	assert_true(hud.tutorial_panel.skip_button.visible)
	assert_eq(hud.tutorial_highlight.target_key, "build:carousel")
	hud.on_tutorial_finished()
	assert_true(not hud.tutorial_panel.visible)
	assert_eq(hud.tutorial_highlight.target_key, "")
	hud.free()


func test_skip_hides_panel() -> void:
	var hud := _hud()
	hud.on_tutorial_step(0, _steps()[0])
	var got: Array = []
	hud.tutorial_panel.skip_requested.connect(func() -> void: got.append(1))
	hud.tutorial_panel.skip_button.pressed.emit()
	assert_eq(got.size(), 1)
	assert_true(not hud.tutorial_panel.visible)
	hud.free()


func test_highlight_targets() -> void:
	var hud := _hud()
	var h: TutorialHighlight = hud.tutorial_highlight
	h.target_key = "build:carousel"
	assert_true(h.target() != null)  # kategori-knap, når kortet ikke er synligt
	h.target_key = "staff:cleaner"
	assert_true(h.target() == hud.build_dock.cat_buttons["staff"])
	h.target_key = "overlay:queue"
	assert_true(h.target() == hud.park_rail.button(&"overlays"))
	h.target_key = "entrance"
	assert_true(h.target() == null)
	h.target_key = "attraction:shop"
	assert_true(h.target() == null)
	hud.free()


func test_tutorial_glyphs() -> void:
	var font: Font = ThemeDB.fallback_font
	var hud := _hud()
	var texts: Array[String] = []
	for i in _steps().size():
		hud.on_tutorial_step(i, _steps()[i])
		_texts(hud.tutorial_panel, texts)
	texts.append("Introduktionen er færdig. God fornøjelse med parken!")
	for t: String in texts:
		for i in t.length():
			var ch: int = t.unicode_at(i)
			if ch >= 32:
				assert_true(font.has_char(ch), "glyf U+%04X mangler i '%s'" % [ch, t])
	hud.free()
