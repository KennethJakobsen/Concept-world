extends TestCase
## T-101: UX-fundament – TopBar, BuildDock, Inspector, ParkRail, AlertTray, TooltipService, UserSettings.

const TMP: String = "user://test_t101_settings.cfg"


func _hud() -> Hud:
	var hud := Hud.new()
	hud.settings_path = TMP
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	hud.refresh()
	return hud


func _texts(n: Node, out: Array[String]) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text)
	if n is Control and (n as Control).tooltip_text != "":
		out.append((n as Control).tooltip_text)
	for c in n.get_children():
		_texts(c, out)


func test_zones_exist() -> void:
	var hud := _hud()
	var root: Control = hud.get_node("Root")
	assert_true(root.get_node("TopBar") is TopBar)
	assert_true(root.get_node("BuildMenu") is BuildDock)
	assert_true(hud.inspector is Inspector)
	assert_true(hud.park_rail is ParkRail)
	assert_true(hud.alert_tray is AlertTray)
	assert_eq(BuildDock.CATEGORIES.size(), 6)
	for c: String in BuildDock.CATEGORIES:
		assert_true(hud.build_dock.cat_buttons.has(c), c)
	hud.free()


func test_dock_cards_have_tooltips_with_price() -> void:
	var hud := _hud()
	var b: Button = hud._build_buttons["carousel"]
	assert_true(BuildDock.price_text(b).contains("$"))
	assert_true(b.tooltip_text.contains("Pris"))
	assert_true(b.tooltip_text.begins_with(str(b.get_meta(TooltipService.META_TITLE))))
	hud.free()


func test_tooltip_service() -> void:
	var c := Control.new()
	TooltipService.attach(c, "Titel", "Krop")
	assert_eq(c.tooltip_text, "Titel\nKrop")
	assert_eq(TooltipService.text_for(c), "Titel\nKrop")
	TooltipService.attach(c, "Kun titel")
	assert_eq(c.tooltip_text, "Kun titel")
	var b := Button.new()
	TooltipService.attach(b, "Byg", "Pris: $5")
	LockOverlay.apply(b, true)
	assert_eq(b.tooltip_text, M5Texts.LOCKED_TOOLTIP)
	LockOverlay.apply(b, false)
	assert_eq(b.tooltip_text, "Byg\nPris: $5", "låst -> ulåst gendanner tooltip")
	TooltipService.install()
	assert_eq(float(ProjectSettings.get_setting("gui/timers/tooltip_delay_sec")), 0.4)
	c.free()
	b.free()


func test_inspector_tabs_and_close() -> void:
	var hud := _hud()
	var a: Attraction = hud.sim.cmd_place_attraction("burger_stand", Vector2i(5, 5))
	var made: Array[int] = [0]
	hud.inspector.register_tab(&"attraction", &"econ", "Økonomi", func() -> Control:
		made[0] += 1
		var l := Label.new()
		l.name = "EconTab"
		return l)
	hud.show_attraction(a.id)
	assert_true(hud.inspector.is_open())
	assert_true(hud._attr_panel.visible)
	assert_eq(hud.inspector.tab_ids(), [Inspector.OVERVIEW, &"econ"] as Array[StringName])
	assert_eq(made[0], 0, "fabrik kaldes først når fanen vises")
	hud.inspector.select_tab(&"econ")
	assert_eq(made[0], 1)
	assert_true(not hud._attr_panel.visible)
	assert_eq(hud.inspector.current_control().name, "EconTab")
	hud.inspector.select_tab(Inspector.OVERVIEW)
	hud.inspector.select_tab(&"econ")
	assert_eq(made[0], 1, "fanen genbruges")
	# Gæst-kontekst har ikke fanen
	hud.inspector.open(&"guest", 1)
	assert_eq(hud.inspector.tab_ids(), [Inspector.OVERVIEW] as Array[StringName])
	hud.show_attraction(a.id)
	assert_true(hud.handle_escape(), "Esc lukker inspektøren")
	assert_true(not hud.inspector.is_open())
	assert_true(not hud._attr_panel.visible)
	assert_eq(hud._sel_attraction, -1)
	assert_true(not hud.handle_escape(), "intet åbent -> Esc går videre (pause-menu)")
	hud.free()


func test_rail_actions_and_factory() -> void:
	var hud := _hud()
	var ids: Array[StringName] = hud.park_rail.ids()
	for id: StringName in [&"park", &"staff", &"research", &"settings", &"menu"]:
		assert_true(ids.has(id), String(id))
	hud.park_rail.toggle(&"park")
	assert_true(hud._park_panel.visible)
	hud.park_rail.toggle(&"settings")
	assert_true(not hud._park_panel.visible, "kun ét panel ad gangen")
	assert_true(hud.park_rail.panel(&"settings") is UiSettingsPanel)
	assert_true(hud.park_rail.panel(&"settings").visible)
	hud.park_rail.toggle(&"settings")
	assert_true(not hud.park_rail.panel(&"settings").visible)
	var calls: Array[int] = [0]
	hud.park_rail.register(&"custom", "info", func() -> Control:
		calls[0] += 1
		return PanelContainer.new(), "Eget panel")
	hud.park_rail.toggle(&"custom")
	assert_eq(calls[0], 1)
	assert_eq(hud.park_rail.open_id, &"custom")
	assert_true(hud.handle_escape())
	assert_eq(hud.park_rail.open_id, &"")
	hud.free()


func test_alert_tray_push_expire_and_click() -> void:
	var t := AlertTray.new()
	var clicked: Array[Vector2i] = []
	t.alert_clicked.connect(func(c: Vector2i) -> void: clicked.append(c))
	var b: Button = t.push("Hej", "alert", Vector2i(3, 4))
	assert_eq(t.items().size(), 1)
	assert_eq(t.unread, 1)
	b.pressed.emit()
	assert_eq(clicked, [Vector2i(3, 4)] as Array[Vector2i])
	for i in 6:
		t.push("x%d" % i)
	assert_eq(t.items().size(), AlertTray.MAX_VISIBLE)
	t.tick(AlertTray.DURATION + 0.1)
	assert_eq(t.items().size(), 0)
	t.show_history()
	assert_eq(t.items().size(), AlertTray.MAX_VISIBLE)
	assert_eq(t.unread, 0)
	t.free()


func test_warning_cell_from_attraction() -> void:
	var hud := _hud()
	var a: Attraction = hud.sim.cmd_place_attraction("burger_stand", Vector2i(5, 5))
	hud.show_warning(&"broken_no_mechanic", {"attraction_id": a.id})
	var b: Button = hud.alert_tray.items()[0]
	assert_eq(b.get_meta(&"cell"), a.origin)
	hud.free()


func test_user_settings_keep_audio_keys() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "Master_volume", 0.3)
	cfg.save(TMP)
	var s: UserSettings = UserSettings.load_from(TMP)
	assert_eq(s.scale, 1.0)
	assert_true(s.floating_money)
	assert_true(not s.colorblind)
	s.scale = 1.5
	s.colorblind = true
	s.floating_money = false
	s.save()
	var back := ConfigFile.new()
	back.load(TMP)
	assert_eq(float(back.get_value("audio", "Master_volume", 0.0)), 0.3, "audio-nøgler bevares")
	var s2: UserSettings = UserSettings.load_from(TMP)
	assert_eq(s2.scale, 1.5)
	assert_true(s2.colorblind)
	assert_true(not s2.floating_money)
	assert_eq(UserSettings.clamp_scale(5.0), 2.0)
	assert_eq(UserSettings.clamp_scale(0.1), 0.75)
	assert_eq(UserSettings.SCALES, [0.75, 1.0, 1.25, 1.5, 2.0] as Array[float])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_settings_panel_writes() -> void:
	var s: UserSettings = UserSettings.load_from(TMP)
	var p := UiSettingsPanel.new()
	p.build(s)
	p.set_scale_index(4)
	assert_eq(UserSettings.load_from(TMP).scale, 2.0)
	p.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_smiley_steps() -> void:
	assert_eq(UiIcons.smiley_step(0.0), 0)
	assert_eq(UiIcons.smiley_step(50.0), 2)
	assert_eq(UiIcons.smiley_step(100.0), 4)


func test_new_zone_texts_use_default_font() -> void:
	var font: Font = ThemeDB.fallback_font
	var hud := _hud()
	var a: Attraction = hud.sim.cmd_place_attraction("burger_stand", Vector2i(5, 5))
	hud.show_attraction(a.id)
	hud.show_warning(&"broken_no_mechanic", {"attraction_id": a.id})
	hud.park_rail.toggle(&"settings")
	var texts: Array[String] = []
	_texts(hud, texts)
	for t: String in texts:
		for i in t.length():
			var ch: int = t.unicode_at(i)
			if ch >= 32:
				assert_true(font.has_char(ch), "glyf U+%04X mangler i '%s'" % [ch, t])
	hud.free()


func test_layout_zones_inside_1024x600() -> void:
	var hud := _hud()
	var vp := Vector2(1024, 600)
	hud.alert_tray.push("Test")
	hud.park_rail.toggle(&"settings")
	hud.layout(vp)
	var bounds := Rect2(Vector2.ZERO, vp)
	for c: Control in [hud.park_rail, hud.alert_tray, hud.park_rail.panel(&"settings")]:
		assert_true(bounds.encloses(Rect2(c.position, c.size)), "%s inden for" % c.name)
	var dock: Control = hud.build_dock
	assert_true(hud.alert_tray.position.y + hud.alert_tray.size.y <= dock.position.y, "varsler over dokken")
	hud.free()


## T-141: docken skal falde tilbage til bunden, når kortpanelet lukkes (klik igen, Esc, værktøj).
func test_dock_returns_to_bottom_after_close() -> void:
	var hud := _hud()
	var vp := Vector2(1280, 720)
	hud.layout(vp)
	var dock: BuildDock = hud.build_dock
	dock.close_cards()
	var closed_y: float = dock.position.y
	assert_true(absf(dock.position.y + dock.size.y - (vp.y - 12.0)) < 1.0, "dock i bunden")
	dock.cat_buttons["rides"].emit_signal("pressed")
	assert_true(dock.cards_open())
	assert_true(dock.position.y < closed_y, "panel åbent -> dock løftet")
	dock.cat_buttons["rides"].emit_signal("pressed")  # klik igen
	assert_true(not dock.cards_open())
	assert_eq(dock.position.y, closed_y)
	assert_true(absf(dock.position.y + dock.size.y - (vp.y - 12.0)) < 1.0)
	hud.set_tab("shops")
	assert_true(dock.cards_open())
	hud.handle_escape()  # Esc
	assert_true(not dock.cards_open())
	assert_eq(dock.position.y, closed_y)
	hud.free()


## T-142: dagskift (længere/kortere tekst) må ikke flytte dock eller top-bar.
func test_layout_stable_across_day_change() -> void:
	var hud := _hud()
	var vp := Vector2(1280, 720)
	hud.layout(vp)
	var dock_pos: Vector2 = hud.build_dock.position
	var top_pos: Vector2 = hud.top_bar.position
	for d in [9, 10, 100]:
		hud.sim.day = d
		hud.refresh()
		hud.top_bar.clock_label.text = "23:59" if d % 2 == 0 else "00:00"
		assert_eq(hud.build_dock.position, dock_pos)
		assert_eq(hud.top_bar.position, top_pos)
		assert_true(hud.top_bar.size.x <= vp.x)
	hud.free()
