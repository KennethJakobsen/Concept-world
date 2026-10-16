extends TestCase
## T-113: milepæle, overlay-vælger, indstillinger, låste grene, M7-tanker og pengeblink.


func _hud() -> Hud:
	var hud := Hud.new()
	hud.settings_path = "user://test_t113_settings.cfg"
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	return hud


func _texts(n: Node, out: Array[String]) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_texts(c, out)


func test_rail_has_milestones_and_overlays() -> void:
	var hud := _hud()
	assert_true(hud.park_rail.ids().has(&"milestones"))
	assert_true(hud.park_rail.ids().has(&"overlays"))
	hud.park_rail.toggle(&"milestones")
	var p: MilestonePanel = hud.park_rail.panel(&"milestones") as MilestonePanel
	assert_true(p != null and p.visible)
	hud.refresh()
	assert_eq(p.rows.size(), hud.sim.milestones().size())
	hud.free()


func test_milestone_progress_and_toast() -> void:
	var hud := _hud()
	hud.park_rail.toggle(&"milestones")
	var p: MilestonePanel = hud.park_rail.panel(&"milestones") as MilestonePanel
	p.refresh(hud.sim)
	var m: Dictionary = hud.sim.milestones()[0]
	assert_true(absf(p.progress_of(str(m["id"])) - float(m["progress"]) * 100.0) < 0.01)
	var before: int = hud.alert_tray.history.size()
	hud.on_milestone_achieved(str(m["id"]))
	assert_eq(hud.alert_tray.history.size(), before + 1)
	assert_true(str(hud.alert_tray.history[-1]["text"]).contains(str(m["name"])))
	hud.free()


func test_overlay_picker_calls_session_and_legend() -> void:
	var hud := _hud()
	hud.park_rail.toggle(&"overlays")
	var op: OverlayPicker = hud.overlay_picker()
	var shown: Array = []
	op.show_fn = func(k: StringName) -> void: shown.append(k)
	op.hide_fn = func() -> void: shown.append(&"none")
	assert_eq(op.buttons.size(), ParkColors.OVERLAY_KINDS.size() + 1)
	op.select(&"litter")
	assert_eq(shown, [&"litter"])
	assert_eq(op.legend_labels().size(), ParkColors.legend(&"litter").size())
	hud.park_rail.close_panel()  # lukning skjuler overlayet
	assert_eq(shown, [&"litter", &"none"])
	assert_eq(op.current, &"")
	hud.free()


func test_settings_colorblind_sets_palette() -> void:
	var hud := _hud()
	hud.park_rail.toggle(&"settings")
	var sp: UiSettingsPanel = hud.park_rail.panel(&"settings") as UiSettingsPanel
	sp._on_cb(true)
	assert_true(ParkColors.colorblind)
	sp._on_cb(false)
	assert_true(not ParkColors.colorblind)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(hud.settings_path))
	hud.free()


func test_locked_topic_shows_milestone() -> void:
	var hud := _hud()
	var sim: ParkSim = hud.sim
	var locked: String = ""
	for tp: Dictionary in sim.research.def.topics:
		if sim.topic_locked_by(str(tp["id"])) != "":
			locked = str(tp["id"])
			break
	if locked == "":
		hud.free()
		return  # sandbox-sim uden låste grene
	hud.research_panel.wanted = true
	hud.research_panel.refresh(sim)
	var mname: String = M7Texts.milestone_name(sim, sim.topic_locked_by(locked))
	assert_true(hud.research_panel.locked_text().contains(mname))
	hud.free()


func test_m7_thoughts_and_glyphs() -> void:
	var font: Font = ThemeDB.fallback_font
	var texts: Array[String] = []
	for k: String in ParkSim.M7_THOUGHTS:
		assert_true(M7Texts.thought_text(k) != k, "tanke '%s' mangler tekst" % k)
		texts.append(M7Texts.thought_text(k))
	assert_eq(M7Texts.thought_text("Her er mørkt."), "Her er mørkt.")
	var hud := _hud()
	for id: StringName in [&"milestones", &"overlays", &"settings"]:
		hud.park_rail.toggle(id)
		hud.refresh()
	hud.overlay_picker().show_fn = func(_k: StringName) -> void: pass
	for k: StringName in ParkColors.OVERLAY_KINDS:
		hud.overlay_picker().select(k)
		_texts(hud, texts)
	hud.research_panel.wanted = true
	hud.research_panel.refresh(hud.sim)
	texts.append(hud.research_panel.locked_text())
	texts.append(M7Texts.locked_text("x"))
	texts.append(M7Texts.achieved_text("x"))
	_texts(hud, texts)
	for t: String in texts:
		for i in t.length():
			var ch: int = t.unicode_at(i)
			if ch >= 32:
				assert_true(font.has_char(ch), "glyf U+%04X mangler i '%s'" % [ch, t])
	hud.free()


func test_money_flash() -> void:
	var hud := _hud()
	hud.top_bar.flash_money(1)
	assert_eq(hud.top_bar.last_flash, 1)
	assert_true(hud.top_bar.label.has_theme_color_override("font_color"))
	hud.top_bar.flash_money(-1)
	assert_eq(hud.top_bar.last_flash, -1)
	hud.free()
