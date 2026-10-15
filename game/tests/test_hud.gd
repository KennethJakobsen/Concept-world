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
