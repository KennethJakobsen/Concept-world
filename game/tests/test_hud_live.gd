extends TestCase
## T-032: HUD i main.tscn viser omdømme og gæster nu/max fra en rigtig ParkSim (T-030 landet).


func test_main_scene_topbar_shows_reputation_and_capacity() -> void:
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	# Runneren har ingen aktiv SceneTree; vi wirer som _ready/_connect_scene gør.
	var pv: Node = main.get_node("ParkView")
	pv.setup(ParkSim.new(64, 64, 1))
	var hud: Hud = main.get_node("Hud")
	hud.sim = pv.sim
	hud._build_ui()
	var e: Vector2i = hud.sim.world.entrance
	hud.sim.cmd_place_path(Vector2i(e.x, e.y - 1))
	hud.sim.cmd_place_attraction("carousel", Vector2i(e.x - 3, e.y - 3))
	hud.sim.update(30.0)
	assert_true(hud.sim != null, "HUD fandt ParkSim")
	hud.refresh()
	var st: Dictionary = hud.sim.get_stats()
	var txt: String = hud._top_label.text
	assert_true(txt.contains("Omdømme"), "omdømme i topbar: " + txt)
	assert_true(txt.contains("%d%%" % roundi(float(st.reputation))), "omdømme-værdi: " + txt)
	assert_true(txt.contains("%d/%d" % [int(st.guests), int(st.max_guests)]), "nu/max: " + txt)
	hud.toggle_park_panel()
	assert_true(hud._park_label.text.contains("Tiltrækning"), hud._park_label.text)
	var fee: int = hud.sim.entry_fee
	hud.change_entry_fee(1)
	assert_eq(hud.sim.entry_fee, fee + 1)
	main.free()
