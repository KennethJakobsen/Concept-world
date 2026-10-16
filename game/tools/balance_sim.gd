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
	for sd in [12345, 1, 2]:
		_m6_park(sd)
	for d in ScenarioDef.list_all():
		if not d.is_sandbox():
			_scenario_runs(d)
	_m7_perf()
	_m7_balance()
	quit(0)


## T-103 / ADR-005 §7: 500 gæster, ms pr. tick (budget 4 ms headless desktop) + køopgivelser.
func _m7_perf() -> void:
	print("\n=== T-103: ydeevne med 500 gæster (budget ≤ 4 ms/tick) ===")
	var Q: GDScript = load("res://tests/test_m7_queues.gd")
	for sd in [99, 7]:
		var s: ParkSim = Q.call("mass_park", sd)
		for i in 700:
			s.update(SimClock.TICK_DELTA)
		var t0: int = Time.get_ticks_usec()
		for i in 400:
			s.update(SimClock.TICK_DELTA)
		var ms: float = float(Time.get_ticks_usec() - t0) / 400.0 / 1000.0
		var queued: int = 0
		var bored: int = 0
		for g: Guest in s.guests.values():
			if g.state == Guest.State.QUEUING:
				queued += 1
				if g.patience <= 0.0:
					bored += 1
		print("seed %d | gæster %d | %.2f ms/tick | i kø %d (utålmodige %d) | trange celler %d | %s" % [sd,
			s.guests.size(), ms, queued, bored, s.crowded_cells().size(), "OK" if ms <= 4.0 else "OVER BUDGET"])


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
	var ok: bool = _build_park(sim, full, fee, connect_rides, with_staff)
	var e: Vector2i = sim.world.entrance
	var st0: Dictionary = sim.get_stats()
	print("\n=== %s ===" % title)
	print("Byggeri ok: %s, penge: %d, entré %d, score %.2f, rate %.1f/dag, max %d, omdømme %.1f" % [
		ok, sim.economy.money, sim.entry_fee, st0.attraction_score, st0.guests_per_day, st0.max_guests, st0.reputation])
	print("Dag | Penge | Netto | Omdømme | Rate/dag | Nye | Gæster nu/max | Glæde | Løn | Nedbrud | I stykker | Affald")
	var breaks: Array = [0]
	sim.attraction_broken.connect(func(_a: Attraction) -> void: breaks[0] += 1)
	var vomits: Array = [0]
	sim.guest_vomited.connect(func(_g: int, _c: Vector2i) -> void: vomits[0] += 1)
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
	_m6_report(sim, vomits[0], {}, DAYS)



## Fælles startpark/fuld park-layout (T-150: genbrugt af M7-målingerne).
func _build_park(sim: ParkSim, full: bool, fee: int = -1, connect_rides: bool = true, with_staff: Variant = null) -> bool:
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
	return ok


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


## T-067/T-072: scenarie-bot der spiller "fornuftigt": sti ind til midten og en gade på tværs, mekaniker,
## rengøring og skraldespande, forskning på niveau 1 med prioritet på rutsjebaner, en simpel oval
## rutsjebane syd for gaden, så snart stykkerne er låst op, og den billigste ulåste forlystelse/bod
## nord for gaden hver morgen, hvis der er råd (reserve 2000). Kører til sejr/nederlag (eller frist; max 120 dage).
const BOT_OVAL: Array[String] = [
	"track_lift_up", "track_lift_up", "track_lift_up", "track_straight", "track_straight",
	"track_turn_right", "track_turn_right",
	"track_down", "track_down", "track_down", "track_straight", "track_straight", "track_straight",
	"track_turn_right", "track_turn_right",
]
const IMPULSE_SHOPS: Array[String] = ["balloon_stand", "souvenir_shop"]
const VOMIT_SHARE_MAX: float = 0.15
const BOT_SEEDS: Array[int] = [12345, 1, 2, 3, 4]


func _scenario_runs(def: ScenarioDef) -> void:
	print("\n=== Scenarie-bot: %s (%s), %d seeds ===" % [def.name, def.id, BOT_SEEDS.size()])
	var wins: int = 0
	for sd in BOT_SEEDS:
		if _scenario_run(def, sd):
			wins += 1
	print("Vundet %d/%d" % [wins, BOT_SEEDS.size()])


func _bot_coaster(sim: ParkSim, station: Vector2i) -> String:
	for p in BOT_OVAL:
		if not sim.is_unlocked(p):
			return ""
	var cost: int = sim.get_def("wooden_coaster").build_cost
	for p in BOT_OVAL:
		cost += CoasterContent.piece(p).cost
	cost += CoasterContent.piece(CoasterContent.station_id()).cost
	if sim.economy.money - cost < 2000:
		return ""
	# stationens indgang (nord) skal ligge på gaden og ikke dele celle med en forlystelses indgang
	var id: int = -1
	for dx in 30:
		id = sim.cmd_start_coaster("wooden_coaster", station + Vector2i(dx, 0), 1)
		if id < 0:
			continue
		for p in BOT_OVAL:
			if not sim.cmd_place_track_piece(id, p):
				sim.cmd_remove_attraction(id)
				id = -1
				break
		if id >= 0:
			break
	if id < 0:
		return "ingen plads"
	var errs: Array[String] = sim.cmd_finish_coaster(id)
	if not errs.is_empty():
		return "finish %s" % [errs]
	return "ok E=%.2f" % float(sim.get_attraction(id).ratings.get("excitement", 0.0))


func _scenario_run(def: ScenarioDef, p_seed: int, milestone_days: Variant = null) -> bool:
	var sim := ParkSim.new_from_scenario(def, p_seed)
	if milestone_days is Dictionary:
		var md: Dictionary = milestone_days
		sim.milestone_achieved.connect(func(id: String) -> void:
			if not md.has(id):
				md[id] = sim.scenario.days_elapsed)
	var result: Array = ["kører stadig"]
	sim.scenario_finished.connect(func(won: bool, reason: String) -> void:
		result[0] = ("VUNDET" if won else "TABT (%s)" % reason) + " dag %d" % sim.scenario.days_elapsed)
	sim.cmd_set_research_funding(1)
	sim.cmd_set_research_priority("roller_coasters")
	var c := Vector2i(def.map_size.x / 2, def.map_size.y / 2)
	var cur: Vector2i = sim.world.entrance
	while cur.y != c.y:
		cur.y += signi(c.y - cur.y)
		sim.cmd_place_path(cur)
	while cur.x != c.x:
		cur.x += signi(c.x - cur.x)
		sim.cmd_place_path(cur)
	var x0: int = maxi(1, c.x - 24)
	for x in range(x0, mini(def.map_size.x, c.x + 25)):
		sim.cmd_place_path(Vector2i(x, c.y))
	sim.cmd_hire_staff("mechanic", c)
	sim.cmd_hire_staff("cleaner", c + Vector2i(1, 0))
	sim.cmd_place_decor("bin", Vector2i(c.x - 1, c.y + 1))
	sim.cmd_place_decor("bin", Vector2i(c.x + 3, c.y + 1))
	var station := Vector2i(x0 + 2, c.y + 1)
	var coaster: String = ""
	var slot_x: Array = [x0]
	var ids: Array[String] = []
	for f in DirAccess.get_files_at(ParkSim.ATTRACTION_DIR):
		if f.ends_with(".json"):
			var ad: AttractionDef = sim.get_def(f.get_basename())
			if ad != null and ad.kind != "coaster":
				ids.append(ad.id)
	var built: Dictionary = {}
	var placed_day: Dictionary = {}  ## attraction id -> dag (T-121: sideshow-margin)
	var vomits: Array = [0]
	sim.guest_vomited.connect(func(_g: int, _c: Vector2i) -> void: vomits[0] += 1)
	var days_run: int = 0
	var day_seconds: float = sim.balance.day_ticks * SimClock.TICK_DELTA
	var limit: int = def.deadline_days if def.deadline_days > 0 else 120
	for d in limit:
		if not coaster.begins_with("ok"):
			var r: String = _bot_coaster(sim, station)
			if r != "":
				coaster = r + " (dag %d)" % d
		# T-121: når banen står, forskes butikker (impulskøb) og derefter sideshows
		if coaster.begins_with("ok"):
			if not sim.is_unlocked("souvenir_shop"):
				sim.cmd_set_research_priority("shops")
			else:
				sim.cmd_set_research_priority("sideshows")
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
			var pa: Attraction = sim.cmd_place_attraction(best.id, o)
			if pa != null:
				built[best.id] = int(built.get(best.id, 0)) + 1
				placed_day[pa.id] = d
			slot_x[0] += best.footprint.x + 1
		# T-121: impulsbutikker (ballon + souvenir), når de er låst op og ikke bygget endnu
		for sid: String in IMPULSE_SHOPS:
			var sd: AttractionDef = sim.get_def(sid)
			if sd == null or built.has(sid) or not sim.is_unlocked(sid) or sim.economy.money - sd.build_cost < 2000:
				continue
			if slot_x[0] + sd.footprint.x >= def.map_size.x:
				continue
			var sa: Attraction = sim.cmd_place_attraction(sid, Vector2i(slot_x[0], c.y - sd.footprint.y))
			if sa != null:
				built[sid] = 1
				placed_day[sa.id] = d
			slot_x[0] += sd.footprint.x + 1
		var t: float = 0.0
		while t < day_seconds - 1e-3:
			sim.update(STEP)
			t += STEP
		days_run = d + 1
		if not sim.scenario.is_running():
			break
	var st: Dictionary = sim.scenario_status()
	var parts: Array[String] = []
	for o: Dictionary in st.objectives:
		parts.append("%s %.1f/%.1f%s" % [o.type, o.current, o.value, " ok" if o.met else ""])
	print("seed %d: %s | penge %d, omdømme %.1f, gæster %d, forlystelser %d, parkværdi %d, bane: %s" % [p_seed,
		result[0], sim.economy.money, sim.reputation, sim.guests.size(), sim.rides_count(), sim.park_value(),
		coaster if coaster != "" else "ikke bygget"])
	print("   Mål: %s" % ", ".join(parts))
	_m6_report(sim, vomits[0], placed_day, days_run)
	return st.state == &"won"


## T-121: M6-målinger – opkast (antal + andel af stående affald, mål < 15 %), netto-margin pr. sideshow
## (indtægt - drift - præmier) og besøg på impulsbutikker. placed_day: attraction id -> byggedag (mangler = dag 0).
func _m6_report(sim: ParkSim, vomit_events: int, placed_day: Dictionary, days_run: int) -> void:
	var litter: int = sim.world.total_litter()
	var standing: int = sim.world.total_vomit()
	var share: float = float(standing) / litter if litter > 0 else 0.0
	print("   M6 opkast: %d i alt, stående %d/%d affald = %.1f %% (mål < %d %%)%s" % [vomit_events, standing, litter,
		share * 100.0, int(VOMIT_SHARE_MAX * 100), "" if share < VOMIT_SHARE_MAX else " OVER MÅL"])
	var side: Array[String] = []
	var shops: Array[String] = []
	for a: Attraction in sim.attractions:
		if a.def.kind == "sideshow":
			var days: int = maxi(0, days_run - int(placed_day.get(a.id, 0)))
			var running: int = a.def.running_cost_per_day * days
			side.append("%s: %d besøg, %d - drift %d - præmier %d = %d" % [a.def.id, a.total_visitors,
				a.total_revenue, running, a.prize_cost_total, a.total_revenue - running - a.prize_cost_total])
		elif IMPULSE_SHOPS.has(a.def.id):
			shops.append("%s: %d besøg, indtægt %d" % [a.def.id, a.total_visitors, a.total_revenue])
	print("   M6 sideshows: %s" % ("; ".join(side) if not side.is_empty() else "ingen bygget"))
	print("   M6 impulsbutikker: %s" % ("; ".join(shops) if not shops.is_empty() else "ingen bygget"))


## T-121: fuld park (som _run "Fuld park") + 4 sideshows, ballonbod og souvenirbutik, 5 dage.
## Scenarie-botten når sjældent at forske butikker/sideshows før sejr, så M6 måles her i sandbox.
const M6_EXTRA: Array[String] = ["coconut_shy", "shooting_gallery", "hook_a_duck", "strength_tester",
	"balloon_stand", "souvenir_shop"]


func _m6_park(p_seed: int) -> void:
	var sim := ParkSim.new(64, 64, p_seed)
	var e: Vector2i = sim.world.entrance
	var ok: bool = true
	for y in range(e.y - 1, 49, -1):
		ok = sim.cmd_place_path(Vector2i(e.x, y)) and ok
	for x in range(e.x - 12, e.x + 13):
		if x != e.x:
			ok = sim.cmd_place_path(Vector2i(x, 50)) and ok
	sim.economy.money += 10000
	ok = sim.cmd_place_attraction("carousel", Vector2i(e.x - 2, 46)) != null and ok
	ok = sim.cmd_place_attraction("burger_stand", Vector2i(e.x + 2, 49)) != null and ok
	ok = sim.cmd_place_attraction("drinks_stand", Vector2i(e.x + 4, 49)) != null and ok
	ok = sim.cmd_place_attraction("toilet", Vector2i(e.x - 4, 49)) != null and ok
	ok = sim.cmd_place_attraction("ice_cream_stand", Vector2i(e.x + 6, 49)) != null and ok
	ok = sim.cmd_hire_staff("mechanic", Vector2i(e.x, 52)) > 0 and ok
	ok = sim.cmd_hire_staff("cleaner", Vector2i(e.x, 51)) > 0 and ok
	ok = sim.cmd_place_decor("bin", Vector2i(e.x + 3, 50)) > 0 and ok
	ok = sim.cmd_place_decor("bin", Vector2i(e.x - 3, 50)) > 0 and ok
	var placed: Array[String] = []
	for id: String in M6_EXTRA:
		var a: Attraction = null
		for x in range(e.x - 12, e.x + 13):
			a = sim.cmd_place_attraction(id, Vector2i(x, 49))
			if a != null:
				break
		if a == null:
			ok = false
		else:
			placed.append(id)
	var vomits: Array = [0]
	sim.guest_vomited.connect(func(_g: int, _c: Vector2i) -> void: vomits[0] += 1)
	var day_seconds: float = sim.balance.day_ticks * SimClock.TICK_DELTA
	var t: float = 0.0
	while t < day_seconds * DAYS - 1e-3:
		sim.update(STEP)
		t += STEP
	print("\n=== T-121 M6-park seed %d (%d dage): byggeri ok %s, gæster i alt %d, penge %d ===" % [p_seed, DAYS, ok,
		sim._next_guest_id - 1, sim.economy.money])
	_m6_report(sim, vomits[0], {}, DAYS)


## T-150 / T-117: permanente M7-balancemålinger (salt, køopgivelser, ATM, milepæle).
func _m7_balance() -> void:
	print("\n=== T-117: M7-balance ===")
	var day_ticks: int = ParkSim.new(8, 8, 1).balance.day_ticks
	# 1) Salt: startpark + fritter, drikkebodens salg med/uden salt.
	var sales: Array[int] = [0, 0]
	var fries_sales: Array[int] = [0, 0]
	for salt in 2:
		for sd in [1, 2, 3, 4, 5, 12345]:
			var sim := ParkSim.new(64, 64, sd)
			_build_park(sim, false)
			var e: Vector2i = sim.world.entrance
			var fries: Attraction = sim.cmd_place_attraction("fries_stand", Vector2i(e.x - 6, 49))
			if fries == null:
				print("Salt: kunne ikke placere fries_stand")
				return
			if salt == 1:
				sim.cmd_set_recipe(fries.id, "salt", true)
			var drinks_id: int = -1
			for a in sim.attractions:
				if a.def.id == "drinks_stand":
					drinks_id = a.id
			var acc: Array = [0, 0]
			var fries_id: int = fries.id
			sim.purchase_made.connect(func(_g: int, b: int, amount: int) -> void:
				if b == drinks_id:
					acc[0] += amount
				elif b == fries_id:
					acc[1] += 1)
			for t in DAYS * day_ticks / 100:
				sim.update(STEP)
			sales[salt] += acc[0]
			fries_sales[salt] += acc[1]
	print("Salt (seeds 1-5, 12345): fritter solgt uden %d, med %d; drikkesalg uden %d, med %d (%+.1f %%)" % [
		fries_sales[0], fries_sales[1], sales[0], sales[1], 100.0 * (sales[1] - sales[0]) / maxf(1.0, sales[0])])
	# 2) Køopgivelser: fuld park med personale, tik for tik.
	var sim2 := ParkSim.new(64, 64, 12345)
	_build_park(sim2, true, -1, true, true)
	var prev: Dictionary = {}
	var entered: int = 0
	var gave_up: int = 0
	var gave_up_thought: String = ParkSim.M7_THOUGHTS["queue_gave_up"]
	for t in DAYS * day_ticks:
		sim2.update(SimClock.TICK_DELTA)
		var cur: Dictionary = {}
		for gid: int in sim2.guests:
			var g: Guest = sim2.guests[gid]
			cur[gid] = g.state
			var was: int = int(prev.get(gid, -1))
			if g.state == Guest.State.QUEUING and was != Guest.State.QUEUING:
				entered += 1
			elif was == Guest.State.QUEUING and g.state == Guest.State.WALKING and g.thought == gave_up_thought:
				gave_up += 1
		prev = cur
	print("Køopgivelser: %d af %d kø-indtrædener (%.1f %%)" % [gave_up, entered, 100.0 * gave_up / maxf(1.0, entered)])
	# 3) ATM: fuld park med/uden hæveautomat.
	var rev: Array[int] = [0, 0]
	var uses: Array = [0]
	for with_atm in 2:
		for sd in [12345, 1, 2]:
			var sim3 := ParkSim.new(64, 64, sd)
			_build_park(sim3, true)
			if with_atm == 1:
				var e3: Vector2i = sim3.world.entrance
				if sim3.cmd_place_attraction("atm", Vector2i(e3.x - 6, 49)) == null:
					print("ATM: kunne ikke placere atm")
					return
				sim3.atm_used.connect(func(_g: int, _a: int, _m: int) -> void: uses[0] += 1)
			for t in DAYS * day_ticks / 100:
				sim3.update(STEP)
			rev[with_atm] += sim3._total_revenue()
	print("ATM: omsætning uden %d, med %d (%+.1f %%), hævninger %d" % [rev[0], rev[1],
		100.0 * (rev[1] - rev[0]) / maxf(1.0, rev[0]), uses[0]])
	# 4) Milepæle: green_meadow-bot.
	var gm: ScenarioDef = null
	for d in ScenarioDef.list_all():
		if d.id == "green_meadow":
			gm = d
	if gm == null:
		print("Milepæle: green_meadow ikke fundet")
		return
	var md: Dictionary = {}
	_scenario_run(gm, BOT_SEEDS[0], md)
	var keys: Array = md.keys()
	keys.sort_custom(func(x: Variant, y: Variant) -> bool: return int(md[x]) < int(md[y]))
	for k: Variant in keys:
		print("Milepæl %s: dag %d" % [k, md[k]])
