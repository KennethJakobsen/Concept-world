extends SceneTree
## Balance-simulation (T-024): scriptet startpark, 5 dage headless.
## Kør: tools/balance.sh  (eller: cd game && godot --headless -s res://tools/balance_sim.gd)

const DAYS: int = 5
const STEP: float = 5.0  # sekunder pr. update (= 100 ticks)

var sim: ParkSim
var too_expensive: int = 0
var _seen: Dictionary = {}  # guest id -> sidste tanke


func _init() -> void:
	sim = ParkSim.new(64, 64, 12345)
	var e: Vector2i = sim.world.entrance
	var ok: bool = true
	for y in range(e.y - 1, 49, -1):
		ok = sim.cmd_place_path(Vector2i(e.x, y)) and ok
	for x in range(e.x - 6, e.x + 7):
		if x != e.x:
			ok = sim.cmd_place_path(Vector2i(x, 50)) and ok
	ok = sim.cmd_place_attraction("carousel", Vector2i(e.x - 2, 46)) != null and ok
	ok = sim.cmd_place_attraction("burger_stand", Vector2i(e.x + 2, 49)) != null and ok
	ok = sim.cmd_place_attraction("drinks_stand", Vector2i(e.x + 4, 49)) != null and ok
	ok = sim.cmd_place_attraction("toilet", Vector2i(e.x - 4, 49)) != null and ok
	print("Byggeri ok: %s, penge efter byggeri: %d" % [ok, sim.economy.money])
	var build_day: Dictionary = sim.economy.today.duplicate()
	print("Dag | Penge | Gæster | Glæde | Besøgt | entry | tickets | running | build+path | netto | For dyrt!")
	var day_seconds: float = sim.balance.day_ticks * SimClock.TICK_DELTA
	var visitors: Dictionary = {}
	for d in DAYS:
		var max_guests: int = 0
		var hap_sum: float = 0.0
		var samples: int = 0
		var spawned_before: int = sim._next_guest_id
		too_expensive = 0
		var t: float = 0.0
		while t < day_seconds - 1e-3:
			sim.update(STEP)
			t += STEP
			_scan_thoughts()
			var s: Dictionary = sim.get_stats()
			max_guests = maxi(max_guests, s.guests)
			if s.guests > 0:
				hap_sum += s.avg_happiness
				samples += 1
		var h: Dictionary = sim.economy.history.back() if not sim.economy.history.is_empty() else {}
		var tot: Dictionary = h.get("totals", {})
		if d == 0:
			for k in build_day:
				tot[k] = int(tot.get(k, 0))  # allerede inkluderet
		print("%d | %d | %d (max %d, nye %d) | %.1f | %s | %d | %d | %d | %d | %d | %d" % [
			h.get("day", d + 1), sim.economy.money, sim.guests.size(), max_guests,
			sim._next_guest_id - spawned_before, hap_sum / maxi(1, samples),
			_visits(visitors), tot.get("entry", 0), tot.get("tickets", 0), tot.get("running", 0),
			int(tot.get("build", 0)) + int(tot.get("path", 0)), h.get("net", 0), too_expensive])
	quit(0)


func _visits(prev: Dictionary) -> String:
	var parts: Array[String] = []
	for a: Attraction in sim.attractions:
		var v: int = a.total_visitors - int(prev.get(a.id, 0))
		prev[a.id] = a.total_visitors
		parts.append("%s=%d" % [a.def.id, v])
	return ",".join(parts)


func _scan_thoughts() -> void:
	for g: Guest in sim.guests.values():
		if g.thought != _seen.get(g.id, ""):
			_seen[g.id] = g.thought
			if g.thought == ParkSim.TOO_EXPENSIVE_THOUGHT:
				too_expensive += 1
