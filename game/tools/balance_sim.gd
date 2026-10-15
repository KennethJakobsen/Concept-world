extends SceneTree
## Balance-simulation (T-024, T-030, T-032): 3 scenarier à 5 dage headless.
## Kør: tools/balance.sh  (eller: cd game && godot --headless -s res://tools/balance_sim.gd)

const DAYS: int = 5
const STEP: float = 5.0  # sekunder pr. update (= 100 ticks)


func _init() -> void:
	_run("Startpark (karrusel + 2 boder + toilet)", false, -1)
	_run("Fuld park (alle 7 bygninger)", true, -1)
	_run("Fuld park, QA-layout fra T-032 (pariserhjul/radiobiler uden sti)", true, -1, false)
	_run("Startpark, entré 30", false, 30)
	_run("Startpark uden personale (nedbrud + affald)", false, -1, true, false)
	_run("Startpark + mekaniker + rengøring + 2 skraldespande (T-037)", false, -1, true, true)
	_m3_compare()
	for d in ScenarioDef.list_all():
		if not d.is_sandbox():
			_scenario_run(d)
	quit(0)


## T-041: startpark med/uden personale, 7 dage, flere seeds. Samme layout som _run.
func _m3_compare() -> void:
	print("\n=== T-041: startpark 7 dage, uden vs. med personale (mekaniker+rengøring+2 skraldespande) ===")
	print("Seed | Personale | Penge d7 | Omdømme | Gæster i alt | Glæde | Nedbrud | Ødelagt-dage(snit) | Affald d7")
	var agg: Dictionary = {}
	for seed in [12345, 1, 2, 3, 4]:
		for staff in [false, true]:
			var r: Dictionary = _m3_one(seed, staff)
			print("%d | %s | %d | %.1f | %d | %.1f | %d | %.2f | %d" % [seed, "ja" if staff else "nej", r.money,
				r.rep, r.guests, r.hap, r.breaks, r.broken_days, r.litter])
			var a: Dictionary = agg.get(staff, {})
			for k: String in r:
				a[k] = float(a.get(k, 0.0)) + float(r[k]) / 5.0
			agg[staff] = a
	for staff in [false, true]:
		var a: Dictionary = agg[staff]
		print("SNIT | %s | %d | %.1f | %d | %.1f | %.1f | %.2f | %d" % ["ja" if staff else "nej", a.money, a.rep,
			a.guests, a.hap, a.breaks, a.broken_days, a.litter])


func _m3_one(p_seed: int, staff: bool) -> Dictionary:
	var sim := ParkSim.new(64, 64, p_seed)
	var e: Vector2i = sim.world.entrance
	for y in range(e.y - 1, 49, -1):
		sim.cmd_place_path(Vector2i(e.x, y))
	for x in range(e.x - 10, e.x + 11):
		if x != e.x:
			sim.cmd_place_path(Vector2i(x, 50))
	sim.cmd_place_attraction("carousel", Vector2i(e.x - 2, 46))
	sim.cmd_place_attraction("burger_stand", Vector2i(e.x + 2, 49))
	sim.cmd_place_attraction("drinks_stand", Vector2i(e.x + 4, 49))
	sim.cmd_place_attraction("toilet", Vector2i(e.x - 4, 49))
	if staff:
		sim.cmd_hire_staff("mechanic", Vector2i(e.x, 52))
		sim.cmd_hire_staff("cleaner", Vector2i(e.x, 51))
		sim.cmd_place_decor("bin", Vector2i(e.x + 3, 50))
		sim.cmd_place_decor("bin", Vector2i(e.x - 3, 50))
	var breaks: Array = [0]
	sim.attraction_broken.connect(func(_a: Attraction) -> void: breaks[0] += 1)
	var day_seconds: float = sim.balance.day_ticks * SimClock.TICK_DELTA
	var total: float = day_seconds * 7
	var t: float = 0.0
	var hap: float = 0.0
	var n: int = 0
	var broken_steps: int = 0
	var steps: int = 0
	while t < total - 1e-3:
		sim.update(STEP)
		t += STEP
		steps += 1
		var s: Dictionary = sim.get_stats()
		broken_steps += int(s.broken)
		if s.guests > 0:
			hap += s.avg_happiness
			n += 1
	var s2: Dictionary = sim.get_stats()
	return {"money": sim.economy.money, "rep": sim.reputation, "guests": sim._next_guest_id - 1,
		"hap": hap / maxi(1, n), "breaks": breaks[0], "broken_days": float(broken_steps) / steps * 7.0,
		"litter": s2.litter}


func _run(title: String, full: bool, fee: int, connect_rides: bool = true, with_staff: Variant = null) -> void:
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
	if full and connect_rides:
		# T-033: indgangene skal forbindes til stinettet – i T-032 var de afskåret.
		for y in range(51, 55):
			ok = sim.cmd_place_path(Vector2i(e.x + 8, y)) and ok
		for y in range(51, 56):
			ok = sim.cmd_place_path(Vector2i(e.x - 3, y)) and ok
		for x in range(e.x + 6, e.x + 8):
			ok = sim.cmd_place_path(Vector2i(x, 54)) and ok
		for x in range(e.x - 5, e.x - 3):
			ok = sim.cmd_place_path(Vector2i(x, 55)) and ok
	if fee >= 0:
		sim.cmd_set_entry_fee(fee)
	if with_staff == true:
		ok = sim.cmd_hire_staff("mechanic", Vector2i(e.x, 52)) > 0 and ok
		ok = sim.cmd_hire_staff("cleaner", Vector2i(e.x, 51)) > 0 and ok
		ok = sim.cmd_place_decor("bin", Vector2i(e.x + 3, 50)) > 0 and ok
		ok = sim.cmd_place_decor("bin", Vector2i(e.x - 3, 50)) > 0 and ok
	var st0: Dictionary = sim.get_stats()
	print("\n=== %s ===" % title)
	print("Byggeri ok: %s, penge: %d, entré %d, score %.2f, rate %.1f/dag, max %d, omdømme %.1f" % [
		ok, sim.economy.money, sim.entry_fee, st0.attraction_score, st0.guests_per_day, st0.max_guests, st0.reputation])
	print("Dag | Penge | Netto | Omdømme | Rate/dag | Nye | Gæster nu/max | Glæde | Løn | Nedbrud | I stykker | Affald")
	var breaks: Array = [0]
	sim.attraction_broken.connect(func(_a: Attraction) -> void: breaks[0] += 1)
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
		print("%d | %d | %d | %.1f | %.1f | %d | %d/%d | %.1f | %d | %d | %d | %d" % [d + 1, sim.economy.money,
			h.get("net", 0), sim.reputation, sim.expected_guests_per_day(), sim._next_guest_id - before,
			s2.guests, s2.max_guests, hap_sum / maxi(1, samples), int(h.get("totals", {}).get("wages", 0)),
			breaks[0], s2.broken, s2.litter])
		breaks[0] = 0
		if full:
			_diag(sim)



## Instrumentering (T-033): tilstande, køer, behov over tærskel og tanker.
func _diag(sim: ParkSim) -> void:
	var states: Dictionary = {}
	var over: Dictionary = {}
	var thoughts: Dictionary = {}
	var wander: int = 0
	var low_money: int = 0
	for g: Guest in sim.guests.values():
		var st: String = Guest.State.keys()[g.state]
		states[st] = int(states.get(st, 0)) + 1
		thoughts[g.thought] = int(thoughts.get(g.thought, 0)) + 1
		if g.state == Guest.State.WALKING and g.target_attraction_id < 0:
			wander += 1
		if g.money < 5:
			low_money += 1
		for k: String in g.needs:
			if g.needs[k] > sim.balance.need_threshold(k):
				over[k] = int(over.get(k, 0)) + 1
	var queues: Array[String] = []
	for a: Attraction in sim.attractions:
		queues.append("%s=%d" % [a.def.id, a.queue.size()])
	print("   tilstande %s, vandrer %d, penge<5 %d" % [states, wander, low_money])
	print("   køer %s" % ", ".join(queues))
	print("   behov>tærskel %s" % over)
	print("   tanker %s" % thoughts)


## T-067: scenarie-run med simpel bot. Bygger en sti ind til midten og en "gade" på tværs; hver morgen
## bygges den billigste ulåste forlystelse/bod nord for gaden, hvis der er råd (reserve 2000).
## Forskning på niveau 1. Kører til sejr/nederlag (eller frist; max 120 dage).
func _scenario_run(def: ScenarioDef) -> void:
	var sim := ParkSim.new_from_scenario(def, 12345)
	var result: Array = ["kører stadig"]
	sim.scenario_finished.connect(func(won: bool, reason: String) -> void:
		result[0] = ("VUNDET" if won else "TABT (%s)" % reason) + " dag %d" % sim.scenario.days_elapsed)
	sim.cmd_set_research_funding(0)
	var c := Vector2i(def.map_size.x / 2, def.map_size.y / 2)
	var cur: Vector2i = sim.world.entrance
	sim.economy.money += 0
	while cur.y != c.y:
		cur.y += signi(c.y - cur.y)
		sim.cmd_place_path(cur)
	while cur.x != c.x:
		cur.x += signi(c.x - cur.x)
		sim.cmd_place_path(cur)
	for x in range(maxi(0, c.x - 24), mini(def.map_size.x, c.x + 25)):
		sim.cmd_place_path(Vector2i(x, c.y))
	var slot_x: Array = [maxi(1, c.x - 24)]
	var ids: Array[String] = []
	for f in DirAccess.get_files_at(ParkSim.ATTRACTION_DIR):
		if f.ends_with(".json"):
			var ad: AttractionDef = sim.get_def(f.get_basename())
			if ad != null and ad.kind != "coaster":
				ids.append(ad.id)
	var built: Dictionary = {}
	var day_seconds: float = sim.balance.day_ticks * SimClock.TICK_DELTA
	var limit: int = def.deadline_days if def.deadline_days > 0 else 120
	print("\n=== Scenarie-bot: %s (%s) ===" % [def.name, def.id])
	for d in limit:
		# byg: den billigste ikke-byggede ulåste; ellers den billigste ulåste igen
		var best: AttractionDef = null
		for id in ids:
			var ad: AttractionDef = sim.get_def(id)
			if not sim.is_unlocked(id) or sim.economy.money - ad.build_cost < 2000:
				continue
			var score: float = ad.build_cost * (1 + int(built.get(id, 0)) * 3)
			if best == null or score < best.build_cost * (1 + int(built.get(best.id, 0)) * 3):
				best = ad
		if best != null and slot_x[0] + best.footprint.x < def.map_size.x:
			var o := Vector2i(slot_x[0], c.y - best.footprint.y)
			if sim.cmd_place_attraction(best.id, o) != null:
				built[best.id] = int(built.get(best.id, 0)) + 1
			slot_x[0] += best.footprint.x + 1
		var t: float = 0.0
		while t < day_seconds - 1e-3:
			sim.update(STEP)
			t += STEP
		if not sim.scenario.is_running():
			break
	var st: Dictionary = sim.scenario_status()
	var parts: Array[String] = []
	for o: Dictionary in st.objectives:
		parts.append("%s %.1f/%.1f%s" % [o.type, o.current, o.value, " ok" if o.met else ""])
	print("Resultat: %s | penge %d, omdømme %.1f, gæster %d, forlystelser %d, parkværdi %d" % [result[0],
		sim.economy.money, sim.reputation, sim.guests.size(), sim.rides_count(), sim.park_value()])
	print("Mål: %s" % ", ".join(parts))
