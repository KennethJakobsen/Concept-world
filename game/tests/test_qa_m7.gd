extends TestCase
## T-118: M7-verifikation – v1/v2/v3 → v4 på en fuld park, backfill af milepæle,
## determinisme med 500 gæster og et sim-budget pr. tick.

const M6 := preload("res://tests/test_qa_m6.gd")


func _park(seed_v: int) -> ParkSim:
	var helper: Variant = M6.new()
	var s: ParkSim = helper._full_park(seed_v)
	return s


func _step(s: ParkSim, ticks: int) -> void:
	for i in ticks:
		s.update(SimClock.TICK_DELTA)


func _snap(s: ParkSim) -> String:
	return SaveCodec.stringify(s.to_save()["park"])


## Fjerner alle v4-felter, så en v4-save ligner en v3-save.
func _downgrade_to_v3(d: Dictionary) -> Dictionary:
	d["save_version"] = 3
	var park: Dictionary = d["park"]
	for k in ["milestones", "milestones_backfill", "milestones_days_clean"]:
		park.erase(k)
	for at: Dictionary in park.get("attractions", []):
		for k in ["config", "recipes", "customers_today", "revenue_days", "payback_day"]:
			at.erase(k)
	for g: Dictionary in park.get("guests", []):
		for k in ["patience", "queue_index", "blocked_ticks"]:
			g.erase(k)
	return d


func test_v3_full_park_loads_as_v4_and_runs() -> void:
	var src := _park(3)
	_step(src, 1500)
	var d := _downgrade_to_v3(SaveCodec.parse(SaveCodec.stringify(src.to_save())))
	var s := ParkSim.from_save(d)
	assert_true(s != null, "v3 indlæst")
	assert_eq(s.attractions.size(), 18)
	assert_eq(s.guests.size(), src.guests.size(), "gæster bevaret")
	assert_true(s.milestones_state.backfill, "backfill sat for migreret save")
	_step(s, 1000)
	var out: Dictionary = s.to_save()
	assert_eq(int(out["save_version"]), 4)
	assert_eq(out["park"]["milestones_backfill"], false, "backfill kørt én gang")
	var l := ParkSim.from_save(SaveCodec.parse(SaveCodec.stringify(out)))
	assert_eq(_snap(l), _snap(s), "v4 round-trip efter migration")


func test_v1_and_v2_chain_to_v4() -> void:
	var d1: Dictionary = SaveCodec.parse(FileAccess.get_file_as_string("res://tests/fixtures/save_v1.json"))
	var s1 := ParkSim.from_save(d1)
	assert_true(s1 != null)
	_step(s1, 200)
	assert_eq(int(s1.to_save()["save_version"]), 4)
	var src := _park(5)
	_step(src, 800)
	var d2 := _downgrade_to_v3(SaveCodec.parse(SaveCodec.stringify(src.to_save())))
	d2["save_version"] = 2
	for at: Dictionary in d2["park"].get("attractions", []):
		at.erase("prizes_won")
	var s2 := ParkSim.from_save(d2)
	assert_true(s2 != null)
	_step(s2, 300)
	assert_eq(int(s2.to_save()["save_version"]), 4)


func _mass_park(seed_v: int) -> ParkSim:
	var s := _park(seed_v)
	s.spawn_interval_ticks = 1
	s.max_guests = 500
	s.rides_per_guest_min = 20
	s.rides_per_guest_max = 30
	var guard: int = 0
	while s.guests.size() < 500 and guard < 20000:
		s.update(SimClock.TICK_DELTA)
		guard += 1
	return s


func test_determinism_and_budget_500_guests() -> void:
	var a := _mass_park(11)
	var b := _mass_park(11)
	assert_true(a.guests.size() >= 500, "500 gæster nået (%d)" % a.guests.size())
	assert_eq(_snap(a), _snap(b), "samme seed → samme park med 500 gæster")
	var t0: int = Time.get_ticks_usec()
	_step(a, 400)
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0 / 400.0
	_step(b, 400)
	assert_eq(_snap(a), _snap(b), "deterministisk efter 400 ticks")
	print("T-118 budget: %.2f ms/tick med %d gæster" % [ms, a.guests.size()])
	# ADR-005 §7: sim skal holde sig langt under en 33 ms frame (30 fps) ved 20 ticks/s.
	# T-157: vægur på delte CI-runnere er ustabil → kun advarsel, når CI er sat.
	if OS.get_environment("CI") != "":
		if ms >= 8.0:
			push_warning("CI: sim-budget overskredet (%.2f ms/tick) – ikke håndhævet i CI" % ms)
	else:
		assert_true(ms < 8.0, "sim-budget < 8 ms/tick (var %.2f)" % ms)
