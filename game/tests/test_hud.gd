extends TestCase
## T-022: HUD læser state og sender kommandoer.


func test_defs_loaded_from_content() -> void:
	var defs: Array[AttractionDef] = Hud.load_defs()
	assert_true(defs.size() >= 7, "alle attraktioner indlæst")


func test_hud_commands() -> void:
	var hud := Hud.new()
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	hud.refresh()
	assert_true(hud._top_label.text.contains("Dag 1"))
	var a: Attraction = hud.sim.cmd_place_attraction("burger_stand", Vector2i(5, 5))
	assert_true(a != null)
	hud.show_attraction(a.id)
	assert_true(hud._attr_panel.visible)
	var p: int = a.price
	hud._on_price(1)
	assert_eq(a.price, p + 1)
	hud._on_toggle_open()
	assert_true(not a.is_open)
	hud._on_pause()
	assert_true(hud.sim.clock.paused)
	hud._on_demolish()
	assert_true(hud.sim.get_attraction(a.id) == null)
	assert_true(not hud._attr_panel.visible)
	hud.free()


func _check_inside(vp: Vector2) -> void:
	var hud := Hud.new()
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	hud.layout(vp)
	var root: Control = hud.get_node("Root")
	var bounds := Rect2(Vector2.ZERO, vp)
	for n: String in ["BuildMenu", "TopBar"]:
		var p: Control = root.get_node(n)
		var r := Rect2(p.position, p.size)
		assert_true(bounds.encloses(r), "%s %s inden for %s" % [n, r, vp])
		assert_true(r.size.y >= p.get_combined_minimum_size().y - 0.5, "%s ikke klippet" % n)
	# Hver knap skal kunne være på én linje uden at teksten klippes; højden dækker ombrydningen.
	var menu: PanelContainer = root.get_node("BuildMenu")
	var flow: Control = menu.get_child(0)
	assert_true(flow.get_child_count() >= 10, "sti/fjern/vælg + 7 bygninger")
	for b: Control in flow.get_children():
		assert_true(b.get_combined_minimum_size().x <= menu.size.x - 16.0, "knap %s passer i bredden" % (b as Button).text)
		assert_true(not (b as Button).clip_text)
	assert_true(menu.size.y >= flow.get_child(0).get_combined_minimum_size().y, "mindst én række høj")
	hud.free()


func test_layout_1280x720() -> void:
	_check_inside(Vector2(1280, 720))


func test_layout_1024x600() -> void:
	_check_inside(Vector2(1024, 600))


func test_layout_narrow_wraps() -> void:
	_check_inside(Vector2(640, 480))


func test_park_panel_entry_fee_and_stats() -> void:
	var hud := Hud.new()
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	hud.toggle_park_panel()
	assert_true(hud._park_panel.visible)
	var fee: int = hud.sim.entry_fee
	hud.change_entry_fee(1)
	assert_eq(hud.sim.entry_fee, fee + 1)
	hud.sim.cmd_set_entry_fee(0)
	hud.change_entry_fee(-1)
	assert_eq(hud.sim.entry_fee, 0)
	hud.refresh()
	assert_true(hud._park_label.text.contains("Entré: $0"))
	assert_true(hud._park_label.text.contains("I dag"))
	var st: Dictionary = hud.sim.get_stats()
	if st.has("reputation"):
		assert_true(hud._top_label.text.contains("Omdømme"))
	hud.free()


func test_top_text_before_and_after_t030() -> void:
	var old: String = Hud.top_text({"money": 5, "day": 2, "guests": 3, "avg_happiness": 50.0})
	assert_true(old.contains("Gæster: 3") and not old.contains("Omdømme"))
	var new: String = Hud.top_text({"money": 5, "day": 2, "guests": 3, "avg_happiness": 50.0,
		"reputation": 80.0, "max_guests": 40})
	assert_true(new.contains("3/40") and new.contains("★★★★☆"))


func test_park_panel_inside_1024x600() -> void:
	var hud := Hud.new()
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	hud.toggle_park_panel()
	hud.layout(Vector2(1024, 600))
	var p: Control = hud._park_panel
	var r := Rect2(p.position, p.get_combined_minimum_size().max(p.custom_minimum_size))
	assert_true(Rect2(0, 0, 1024, 600).encloses(r), "park-panel %s inden for viewport" % r)
	hud.free()
