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

	gs.call("go_to_main_menu")
	await _frames(3)
	_check(current_scene.scene_file_path.ends_with("main_menu.tscn"), "tilbage til hovedmenu")
	UiSession.store().delete(SLOT)
	print("Integration: %s (%d fejl)" % ["OK" if _fails == 0 else "FEJL", _fails])
	quit(0 if _fails == 0 else 1)
