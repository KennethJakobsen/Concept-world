extends TestCase
## T-071: scenarieliste, målpanel, forskningspanel, rutsjebane-palet og glyffer.


func _font_ok(t: String) -> String:
	var f: Font = ThemeDB.fallback_font
	for i in t.length():
		var ch: int = t.unicode_at(i)
		if ch >= 32 and not f.has_char(ch):
			return "glyf U+%04X mangler i '%s'" % [ch, t]
	return ""


func _texts(n: Node, out: Array[String]) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text)
		out.append((n as Button).tooltip_text)
	if n is OptionButton:
		for i in (n as OptionButton).item_count:
			out.append((n as OptionButton).get_item_text(i))
	for c in n.get_children():
		_texts(c, out)


func _check(texts: Array[String]) -> void:
	for t: String in texts:
		var err: String = _font_ok(t)
		assert_true(err == "", err)


func _scenario_sim(id: String) -> ParkSim:
	return ParkSim.new_from_scenario(ScenarioDef.find(id), 1)


func test_scenario_list_shows_all_but_sandbox() -> void:
	var l := ScenarioList.new()
	l.build()
	var all: Array[ScenarioDef] = ScenarioDef.list_all()
	var expected: int = 0
	for d in all:
		if not d.is_sandbox():
			expected += 1
	assert_true(expected >= 3)
	assert_eq(l.entry_count(), expected)
	var got: Array = []
	l.scenario_chosen.connect(func(id: String) -> void: got.append(id))
	l.choose(0)
	assert_eq(got, [l.defs[0].id])
	assert_true(ScenarioList.goals_text(l.defs[0]).contains("Mål:"))
	var texts: Array[String] = []
	_texts(l, texts)
	_check(texts)
	l.free()


func test_main_menu_has_scenario_and_free_play() -> void:
	var m: MainMenu = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	m.store = SaveStore.new("user://test_ui_m5_saves/")
	m.build()
	assert_true(m.find_child("Nyt scenarie", true, false) != null)
	assert_true(m.find_child("Fri leg", true, false) != null)
	m.set_scenario_list_visible(true)
	m.layout(Vector2(1024, 600))
	assert_true(Rect2(0, 0, 1024, 600).encloses(m.panel_rect()), "menu %s" % m.panel_rect())
	var texts: Array[String] = []
	_texts(m, texts)
	_check(texts)
	m.free()


func test_objective_panel_hidden_in_sandbox_and_shows_goals() -> void:
	var p := ObjectivePanel.new()
	p.build()
	p.refresh(ParkSim.new(20, 20, 1))
	assert_true(not p.visible)
	var sim := _scenario_sim("green_meadow")
	p.refresh(sim)
	assert_true(p.visible)
	var n: int = (sim.scenario_status()["objectives"] as Array).size()
	assert_eq(p.lines().size(), n)
	assert_true(p.lines()[0].contains("/"))
	var texts: Array[String] = []
	_texts(p, texts)
	_check(texts)
	p.free()


func test_result_dialog() -> void:
	var d := ResultDialog.new()
	d.build()
	d.show_result(true, "", "Grøn eng")
	assert_true(d.visible)
	assert_eq(d.title_text(), "Sejr!")
	var texts: Array[String] = []
	_texts(d, texts)
	d.show_result(false, "deadline")
	_texts(d, texts)
	_check(texts)
	var hits: Array = []
	d.continue_pressed.connect(func() -> void: hits.append(1))
	d.continue_pressed.emit()
	assert_eq(hits.size(), 1)
	d.free()


func test_research_panel() -> void:
	var p := ResearchPanel.new()
	p.build()
	p.wanted = true
	var off := ParkSim.new(20, 20, 1)
	p.refresh(off)
	assert_true(not p.visible, "skjult når forskning er slået fra")
	var sim := _scenario_sim("green_meadow")
	assert_true(ResearchPanel.enabled(sim))
	p.refresh(sim)
	assert_true(p.visible)
	p.set_funding(2)
	assert_eq(int(sim.research_status()["funding_level"]), 2)
	p.select_priority(1)
	assert_eq(str(sim.research_status()["priority"]), p._topic_ids[1])
	p.refresh(sim)
	assert_true(p.item_text().begins_with("Forsker i:") or p.item_text() == "Alt er udforsket")
	var texts: Array[String] = []
	_texts(p, texts)
	_check(texts)
	p.free()


func test_hud_locks_and_coaster_tab() -> void:
	var hud := Hud.new()
	hud.sim = _scenario_sim("green_meadow")
	hud._build_ui()
	hud.refresh()
	assert_true(hud._build_buttons.has("coaster:wooden_coaster"))
	assert_true(hud.is_build_locked("ferris_wheel"))
	assert_true(LockOverlay.is_locked(hud._build_buttons["ferris_wheel"]))
	assert_eq((hud._build_buttons["ferris_wheel"] as Button).tooltip_text, "Kræver forskning")
	assert_true(not hud.is_build_locked("carousel"))
	assert_true(not hud.is_build_locked("staff:mechanic"))
	hud.set_tab("coaster")
	hud.refresh()
	assert_true(hud.coaster_palette.visible)
	assert_true(LockOverlay.is_locked(hud.coaster_palette.button("track_up")))
	assert_true(hud.objective_panel.visible)
	hud.toggle_research_panel()
	assert_true(hud.research_panel.visible)
	hud.on_scenario_finished(false, "deadline")
	assert_true(hud.result_dialog.visible)
	hud.continue_free_play()
	assert_true(not hud.result_dialog.visible)
	hud.show_warning(&"research_done", {"item_id": "ferris_wheel"})
	assert_true(hud.toast().text().begins_with("Ny forskning"))
	var texts: Array[String] = [hud.toast().text(), CoasterPalette.errors_text(M5Texts.COASTER_ERRORS.keys())]
	_texts(hud, texts)
	_check(texts)
	hud.free()


func test_coaster_info_lines() -> void:
	var sim := ParkSim.new(30, 30, 1)
	var id: int = sim.cmd_start_coaster("wooden_coaster", Vector2i(10, 10), 1)
	assert_true(id >= 0)
	var a: Attraction = sim.get_attraction(id)
	var t: String = Hud.attraction_text(a, sim)
	assert_true(t.contains("Under opførelse"))
	a.ratings = {"excitement": 5.5, "intensity": 4.0, "nausea": 2.25}
	a.profile = CoasterProfile.new()
	a.profile.max_speed = 10.0
	var lines: Array[String] = Hud.coaster_lines(a)
	assert_true(lines.has("Spænding: 5.50"))
	assert_true(lines.has("Max fart: 36 km/t"))
	_check([Hud.attraction_text(a, sim)])


func test_all_m5_texts_glyphs() -> void:
	var texts: Array[String] = []
	for d: Dictionary in [M5Texts.OBJECTIVE_NAMES, M5Texts.LOSE_NAMES, M5Texts.COASTER_ERRORS, M5Texts.REASONS]:
		for v: Variant in d.values():
			texts.append(str(v))
	for n: String in ResearchPanel.LEVEL_NAMES:
		texts.append(n)
	texts.append("Jeg har kvalme!")
	_check(texts)
