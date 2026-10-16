extends SceneTree
## T-041: Headless integrationstest af hele UI-flowet med rigtige scene-skift.
## main_menu → GameSession.start_new → byg via kommandoer → 1 dag → save_to("qa")
## → load_from("qa") → ParkView rebuild node_counts + HUD-penge matcher. Esc-routing.
## Kør: tools/integration.sh

const SLOT: String = "qa_integration"
var _fails: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _view() -> ParkView:
	return get_first_node_in_group("park_view") as ParkView


func _hud() -> Node:
	return current_scene.get_node_or_null("Hud") if current_scene != null else null


func _esc() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.physical_keycode = KEY_ESCAPE
	ev.pressed = true
	root.push_input(ev)
	var up: InputEventKey = ev.duplicate()
	up.pressed = false
	root.push_input(up)
	await _frames(3)


## T-093: bygger tømmerrende, minitog og svævebane med spor-værktøjet (BuildTool) og
## tjekker scene-noderne (spor, tog, stationer, endestation).
func _build_tracks(v: ParkView) -> void:
	var sim: ParkSim = v.sim
	var bt: BuildTool = current_scene.get_node("BuildTool") as BuildTool
	var was_enabled: bool = sim.research.enabled
	sim.research.enabled = false
	sim.economy.money += 1000000
	var flume: Array[String] = ["flume_lift_up", "flume_lift_up", "flume_straight", "flume_straight", "flume_straight",
		"flume_turn_right", "flume_turn_right", "flume_drop", "flume_straight", "flume_straight", "flume_straight",
		"flume_straight", "flume_straight", "flume_turn_right", "flume_turn_right"]
	var train: Array[String] = ["train_straight", "train_straight", "train_straight", "train_straight", "train_straight",
		"train_turn_right", "train_turn_right", "train_straight", "train_straight", "train_straight", "train_straight",
		"train_straight", "train_straight", "train_turn_right", "train_turn_right"]
	var mono: Array[String] = []
	for i in 8:
		mono.append("monorail_straight")
	var specs: Array = [["log_flume", Vector2i(6, 8), flume], ["mini_train", Vector2i(6, 18), train], ["monorail", Vector2i(6, 28), mono]]
	for spec: Array in specs:
		var def_id: String = spec[0]
		_check(bt.set_tool("coaster:" + def_id), "spor-værktøj %s" % def_id)
		var pal: Array[String] = bt.coaster_palette()
		var sys: StringName = bt.coaster_system()
		_check(not pal.is_empty() and pal.all(func(p: String) -> bool: return (CoasterContent.piece(p) as TrackPieceDef).system == sys),
			"palette filtreret (%s: %d stykker)" % [sys, pal.size()])
		var id: int = bt.place_coaster_station(spec[1], 1)
		_check(id > 0, "station %s placeret" % def_id)
		if id <= 0:
			continue
		var all_ok: bool = true
		for p: String in spec[2]:
			bt.set_coaster_piece(p)
			all_ok = bt.place_coaster_piece() and all_ok
		_check(all_ok, "%s: alle stykker placeret" % def_id)
		if sim.get_attraction(id).is_transport():
			_check(bt.can_place_end_station(), "endestation tilbydes")
			_check(bt.place_end_station(), "endestation placeret")
		var errs: Array[String] = bt.finish_coaster()
		_check(errs.is_empty(), "%s færdig %s" % [def_id, errs])
		await _frames(2)
		_check(v.coaster_mesh(id) != null and v.coaster_train(id) != null, "%s: spor + tog i scenen" % def_id)
		if sim.get_attraction(id).is_transport():
			_check(v.end_station_node(id) is TrackStation, "svævebanens endestation i scenen")
	sim.research.enabled = was_enabled
	bt.set_tool("select")


func _run() -> void:
	var gs: Node = root.get_node_or_null("GameSession")
	_check(gs != null, "autoload GameSession findes")
	if gs == null:
		quit(1)
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await _frames(3)
	_check(current_scene != null and current_scene.scene_file_path.ends_with("main_menu.tscn"), "hovedmenu indlæst")

	# Ny park via UI-laget (UiSession → GameSession)
	UiSession.start_new(4242)
	await _frames(5)
	var v: ParkView = _view()
	_check(v != null and v.sim != null, "main.tscn med ParkView/sim efter start_new")
	if v == null:
		quit(1)
		return
	_check(gs.call("current_sim") == v.sim, "GameSession.current_sim == ParkView.sim")
	var sim: ParkSim = v.sim
	sim.clock.paused = true  # vi styrer tiden selv
	var e: Vector2i = sim.world.entrance
	var ok: bool = true
	for y in range(e.y - 1, 49, -1):
		ok = sim.cmd_place_path(Vector2i(e.x, y)) and ok
	for x in range(e.x - 10, e.x + 11):
		if x != e.x:
			ok = sim.cmd_place_path(Vector2i(x, 50)) and ok
	ok = sim.cmd_place_attraction("carousel", Vector2i(e.x - 2, 46)) != null and ok
	ok = sim.cmd_place_attraction("burger_stand", Vector2i(e.x + 2, 49)) != null and ok
	ok = sim.cmd_place_attraction("drinks_stand", Vector2i(e.x + 4, 49)) != null and ok
	ok = sim.cmd_place_attraction("toilet", Vector2i(e.x - 4, 49)) != null and ok
	ok = sim.cmd_hire_staff("mechanic", Vector2i(e.x, 52)) > 0 and ok
	ok = sim.cmd_hire_staff("cleaner", Vector2i(e.x, 51)) > 0 and ok
	ok = sim.cmd_hire_staff("entertainer", Vector2i(e.x + 5, 50)) > 0 and ok
	ok = sim.cmd_place_decor("bin", Vector2i(e.x + 3, 50)) > 0 and ok
	ok = sim.cmd_place_decor("bench", Vector2i(e.x - 3, 50)) > 0 and ok
	ok = sim.cmd_place_decor("tree_round", Vector2i(e.x + 1, 52)) > 0 and ok
	_check(ok, "startpark + personale + dekoration bygget")

	# Kør 1 dag
	var day_seconds: float = sim.balance.day_ticks * SimClock.TICK_DELTA
	var day0: int = int(sim.get_stats().day)
	sim.clock.paused = false
	var t: float = 0.0
	while t < day_seconds + 1.0:
		sim.update(5.0)
		t += 5.0
	sim.clock.paused = true
	await _frames(3)
	_check(int(sim.get_stats().day) == day0 + 1, "1 dag kørt (dag %d, gæster i alt %d)" % [sim.get_stats().day, sim._next_guest_id])
	_check(UiSession.store().load("autosave").size() > 0, "autosave skrevet ved day_passed")

	var counts_before: Dictionary = v.node_counts()
	var money_before: int = sim.economy.money
	var hud: Node = _hud()
	_check(hud != null and hud.get("sim") == sim, "HUD følger sim før gem")

	var bt: Node = current_scene.get_node("BuildTool")
	var sel: Node = current_scene.get_node("Selection")
	var pm_count: Array = [0]
	sel.connect("pause_menu_requested", func() -> void: pm_count[0] += 1)
	# Esc-routing: værktøj → select; select → pause-menu; Esc igen lukker (ikke dobbelt-håndteret)
	_check(bt.get("tool") == "select", "ny park starter i select-værktøj")
	bt.call("set_tool", "path")
	await _esc()
	_check(bt.get("tool") == "select" and not hud.call("is_pause_menu_open"), "Esc med værktøj → select, ingen pause-menu")
	await _esc()
	_check(pm_count[0] == 1, "pause_menu_requested udsendt præcis én gang")
	_check(hud.call("is_pause_menu_open"), "Esc åbner pause-menu")
	_check(sim.clock.paused, "sim pauset med pause-menu")
	await _esc()
	_check(not hud.call("is_pause_menu_open") and pm_count[0] == 1, "Esc lukker pause-menu (ikke genåbnet)")
	_check(sim.clock.paused, "pause-tilstand genskabt efter luk")

	_check(UiSession.save_slot(SLOT, sim), "save_to via UiSession")
	_check(bool(gs.call("load_from", SLOT)), "load_from")
	await _frames(5)
	var v2: ParkView = _view()
	_check(v2 != null and v2 != v and v2.sim != null and v2.sim != sim, "ny scene + ny sim efter load")
	if v2 == null:
		quit(1)
		return
	v2.sim.clock.paused = true
	var counts_after: Dictionary = v2.node_counts()
	_check(counts_after == counts_before, "node_counts ens: %s vs %s" % [counts_before, counts_after])
	_check(v2.sim.economy.money == money_before, "penge ens i sim (%d)" % money_before)
	var hud2: Node = _hud()
	await _frames(2)
	_check(hud2 != null and hud2.get("sim") == v2.sim, "HUD følger ny sim efter load")
	var lbl: Label = hud2.get("_top_label") as Label
	_check(lbl != null and lbl.text.begins_with("$%d " % money_before), "HUD viser samme penge: '%s'" % (lbl.text if lbl else ""))

	await _build_tracks(v2)

	gs.call("go_to_main_menu")
	await _frames(3)
	_check(current_scene.scene_file_path.ends_with("main_menu.tscn"), "tilbage til hovedmenu")

	# T-070: menu → scenarie → gem → indlæs
	_check(ScenarioDef.list_all().size() >= 2, "scenarier listes via DirAccess (%d)" % ScenarioDef.list_all().size())
	gs.call("start_scenario", "green_meadow", 77)
	await _frames(5)
	var v3: ParkView = _view()
	_check(v3 != null and v3.sim != null and v3.sim.scenario != null, "scenarie startet via GameSession")
	if v3 != null and v3.sim != null and v3.sim.scenario != null:
		var ss: ParkSim = v3.sim
		ss.clock.paused = true
		_check(ss.world.width == 48 and ss.scenario.def_id == "green_meadow", "scenariets kort/id")
		_check(bool(ss.research_status()["enabled"]), "forskning slået til i scenariet")
		var cb: Array = [0]
		ss.scenario_finished.connect(func(_w: bool, _r: String) -> void: cb[0] += 1)
		ss.clock.paused = false
		ss.scenario_finished.emit(true, "test")
		_check(ss.clock.paused and cb[0] == 1, "scenario_finished pauser simulationen")
		var sc_counts: Dictionary = v3.node_counts()
		_check(UiSession.save_slot(SLOT, ss), "scenarie gemt")
		_check(bool(gs.call("load_from", SLOT)), "scenarie indlæst")
		await _frames(5)
		var v4: ParkView = _view()
		_check(v4 != null and v4.sim != null and v4.sim != ss and v4.sim.scenario != null \
			and v4.sim.scenario.def_id == "green_meadow", "scenarie bevaret efter load")
		if v4 != null and v4.sim != null:
			v4.sim.clock.paused = true
			_check(v4.node_counts() == sc_counts, "scenarie node_counts ens")
	gs.call("go_to_main_menu")
	await _frames(3)
	UiSession.store().delete(SLOT)
	print("Integration: %s (%d fejl)" % ["OK" if _fails == 0 else "FEJL", _fails])
	quit(0 if _fails == 0 else 1)
