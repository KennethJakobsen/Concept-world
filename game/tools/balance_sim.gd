extends SceneTree
## Balance-simulation (T-024, T-030, T-032): 3 scenarier à 5 dage headless.
## Kør: tools/balance.sh  (eller: cd game && godot --headless -s res://tools/balance_sim.gd)

const DAYS: int = 5
const STEP: float = 5.0  # sekunder pr. update (= 100 ticks)


func _init() -> void:
	_run("Startpark (karrusel + 2 boder + toilet)", false, -1)
	_run("Fuld park (alle 7 bygninger)", true, -1)
	_run("Startpark, entré 30", false, 30)
	quit(0)


func _run(title: String, full: bool, fee: int) -> void:
	var sim := ParkSim.new(64, 64, 12345)
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
	if full:
		sim.economy.money += 5000  # finansieret ekstra byggeri, så vi måler drift
		ok = sim.cmd_place_attraction("ice_cream_stand", Vector2i(e.x + 6, 49)) != null and ok
		ok = sim.cmd_place_attraction("ferris_wheel", Vector2i(e.x + 4, 51)) != null and ok
		ok = sim.cmd_place_attraction("bumper_cars", Vector2i(e.x - 8, 51)) != null and ok
	if fee >= 0:
		sim.cmd_set_entry_fee(fee)
	var st0: Dictionary = sim.get_stats()
	print("\n=== %s ===" % title)
	print("Byggeri ok: %s, penge: %d, entré %d, score %.2f, rate %.1f/dag, max %d, omdømme %.1f" % [
		ok, sim.economy.money, sim.entry_fee, st0.attraction_score, st0.guests_per_day, st0.max_guests, st0.reputation])
	print("Dag | Penge | Netto | Omdømme | Rate/dag | Nye | Gæster nu/max | Glæde")
	var day_seconds: float = sim.balance.day_ticks * SimClock.TICK_DELTA
	for d in DAYS:
		var hap_sum: float = 0.0
		var samples: int = 0
		var before: int = sim._next_guest_id
		var t: float = 0.0
		while t < day_seconds - 1e-3:
			sim.update(STEP)
			t += STEP
			var s: Dictionary = sim.get_stats()
			if s.guests > 0:
				hap_sum += s.avg_happiness
				samples += 1
		var h: Dictionary = sim.economy.history.back() if not sim.economy.history.is_empty() else {}
		var s2: Dictionary = sim.get_stats()
		print("%d | %d | %d | %.1f | %.1f | %d | %d/%d | %.1f" % [d + 1, sim.economy.money, h.get("net", 0),
			sim.reputation, sim.expected_guests_per_day(), sim._next_guest_id - before,
			s2.guests, s2.max_guests, hap_sum / maxi(1, samples)])
