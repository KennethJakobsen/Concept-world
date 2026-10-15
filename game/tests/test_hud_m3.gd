extends TestCase
## T-040: faner, personale-panel/-liste, bygningsstatus, pause-menu – alt inden for 1024×600.

const VP := Vector2(1024, 600)


func _hud() -> Hud:
	var hud := Hud.new()
	hud.sim = ParkSim.new(30, 30, 1)
	hud._build_ui()
	return hud


func _inside(r: Rect2, what: String) -> void:
	assert_true(Rect2(Vector2.ZERO, VP).encloses(r), "%s %s inden for %s" % [what, r, VP])


func _rect(c: Control) -> Rect2:
	return Rect2(c.position, c.size.max(c.get_combined_minimum_size()))


func test_tabs_filter_build_buttons() -> void:
	var hud := _hud()
	hud.set_tab("rides")
	var ids: Array[String] = hud.visible_build_ids()
	assert_true(ids.has("carousel") and ids.has("path") and ids.has("select") and ids.has("remove"))
	assert_true(not ids.has("burger_stand"))
	hud.set_tab("shops")
	ids = hud.visible_build_ids()
	assert_true(ids.has("burger_stand") and ids.has("toilet") and not ids.has("carousel"))
	hud.set_tab("decor")
	ids = hud.visible_build_ids()
	assert_true(ids.has("decor:bench") and ids.has("decor:bin"))
	hud.set_tab("staff")
	ids = hud.visible_build_ids()
	assert_true(ids.has("staff:mechanic") and ids.has("staff:cleaner") and ids.has("staff:entertainer"))
	hud.free()


func test_build_tool_emits_prefixed_ids() -> void:
	var hud := _hud()
	var sel := Selection.new()
	hud.selection = sel
	var got: Array[String] = []
	sel.build_tool_requested.connect(func(id: String) -> void: got.append(id))
	(hud._build_buttons["staff:mechanic"] as Button).pressed.emit()
	(hud._build_buttons["decor:bench"] as Button).pressed.emit()
	assert_eq(got, ["staff:mechanic", "decor:bench"] as Array[String])
	sel.free()
	hud.free()


func _path_line(s: ParkSim) -> Vector2i:
	var e: Vector2i = s.world.entrance
	for i in range(1, 6):
		s.cmd_place_path(Vector2i(e.x, e.y - i))
	return Vector2i(e.x, e.y - 2)


func test_staff_panel_and_fire() -> void:
	var hud := _hud()
	var cell: Vector2i = _path_line(hud.sim)
	var id: int = hud.sim.cmd_hire_staff("mechanic", cell)
	assert_true(id >= 0)
	hud.show_staff(id)
	assert_true(hud._staff_panel.visible)
	assert_true(hud._staff_label.text.contains("Løn"), hud._staff_label.text)
	hud._on_fire_selected()
	assert_true(not hud.sim.staff.has(id))
	assert_true(not hud._staff_panel.visible)
	hud.free()


func test_staff_list_rows_and_fire() -> void:
	var hud := _hud()
	var cell: Vector2i = _path_line(hud.sim)
	var a: int = hud.sim.cmd_hire_staff("mechanic", cell)
	var b: int = hud.sim.cmd_hire_staff("cleaner", cell)
	hud.toggle_staff_list()
	assert_eq(hud._staff_list.get_child_count(), 2)
	hud.fire_staff(a)
	hud.refresh()
	assert_true(not hud.sim.staff.has(a) and hud.sim.staff.has(b))
	assert_eq(hud._staff_list_ids.size(), 1)
	hud.free()


func test_attraction_status_text() -> void:
	var hud := _hud()
	var e: Vector2i = hud.sim.world.entrance
	var a: Attraction = hud.sim.cmd_place_attraction("carousel", Vector2i(e.x - 1, e.y - 4))
	assert_true(a != null)
	var t: String = Hud.attraction_text(a, hud.sim)
	assert_true(t.contains("Kører") and t.contains("Pålidelighed"), t)
	a.broken = true
	t = Hud.attraction_text(a, hud.sim)
	assert_true(t.contains("I stykker") and t.contains("Ansæt en mekaniker"), t)
	a.broken = false
	hud.sim.cmd_set_open(a.id, false)
	assert_true(Hud.attraction_text(a, hud.sim).contains("Lukket"))
	hud.free()


func test_topbar_broken_and_litter() -> void:
	var t: String = Hud.top_text({"money": 1, "day": 1, "guests": 0, "avg_happiness": 0.0, "broken": 2, "litter": 7})
	assert_true(t.contains("Ødelagt: 2") and t.contains("Affald: 7"), t)


func test_pause_menu_pauses_and_restores() -> void:
	var hud := _hud()
	hud.sim.clock.paused = false
	hud.open_pause_menu()
	assert_true(hud.is_pause_menu_open())
	assert_true(hud.sim.clock.paused)
	hud._pause_menu.close()
	assert_true(not hud.sim.clock.paused)
	hud.free()


func test_everything_inside_1024x600() -> void:
	var hud := _hud()
	var cell: Vector2i = _path_line(hud.sim)
	for i in 30:
		hud.sim.cmd_hire_staff("cleaner", cell)
	for tab: String in Hud.TABS:
		hud.set_tab(tab)
		hud.layout(VP)
		var root: Control = hud.get_node("Root")
		_inside(_rect(root.get_node("BuildMenu")), "BuildMenu/" + tab)
		_inside(_rect(root.get_node("TopBar")), "TopBar/" + tab)
	hud.toggle_staff_list()
	hud.refresh()
	hud.layout(VP)
	for p: Control in hud.right_panels():
		var was: bool = p.visible
		p.visible = true
		hud.layout(VP)
		_inside(Rect2(p.position, p.get_combined_minimum_size().max(p.custom_minimum_size)), p.name)
		p.visible = was
	hud.open_pause_menu()
	hud._pause_menu.set_load_list_visible(true)
	hud.layout(VP)
	_inside(hud._pause_menu.panel_rect(), "PauseMenu")
	hud.free()
