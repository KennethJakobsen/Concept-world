class_name SaveMigrations
extends RefCounted
## Versionstrin for savefiler. Tilføj et trin pr. ny save_version:
##   1) hæv CURRENT, 2) tilføj `static func _v<N>_to_v<N+1>(d) -> Dictionary`, 3) registrér i _step().

const CURRENT: int = 4


## Migrerer en (evt. ældre) save til CURRENT. Returnerer {} hvis versionen er ukendt/nyere.
static func migrate(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var v: int = int(out.get("save_version", 0))
	if v > CURRENT:
		return {}  # nyere end understøttet
	while v < CURRENT:
		out = _step(v, out)
		if out.is_empty():
			return {}
		v += 1
		out["save_version"] = v
	return out


static func _step(from_version: int, d: Dictionary) -> Dictionary:
	match from_version:
		0:
			return _v0_to_v1(d)
		1:
			return _v1_to_v2(d)
		2:
			return _v2_to_v3(d)
		3:
			return _v3_to_v4(d)
	push_error("SaveMigrations: intet trin fra v%d" % from_version)
	return {}


## v0 (præ-release dummy): park-state lå direkte i roden uden envelope, og
## gæsternes behov hed "needs_hunger"/"needs_thirst" flade felter.
static func _v0_to_v1(d: Dictionary) -> Dictionary:
	var park: Dictionary = d.duplicate(true)
	park.erase("save_version")
	var guests: Array = SaveCodec.arr(park, "guests")
	for g: Variant in guests:
		if not g is Dictionary:
			continue
		var gd: Dictionary = g
		if not gd.has("needs"):
			var needs: Dictionary = {}
			for k: Variant in gd.keys():
				if str(k).begins_with("needs_"):
					needs[str(k).trim_prefix("needs_")] = gd[k]
					gd.erase(k)
			gd["needs"] = needs
	return {"save_version": 0, "game_version": "0.2", "created": "", "park": park}


## v1 → v2 (M5): forskning (tom = slået fra, alt låst op), scenarie (null = sandbox),
## rutsjebanefelter på attraktioner.
static func _v1_to_v2(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var park: Dictionary = SaveCodec.dict(out, "park")
	if not park.has("research"):
		park["research"] = {}
	if not park.has("scenario"):
		park["scenario"] = null
	for a: Variant in SaveCodec.arr(park, "attractions"):
		if a is Dictionary:
			var ad: Dictionary = a
			if not ad.has("cells"):
				ad["cells"] = []
			if not ad.has("track"):
				ad["track"] = null
			if not ad.has("ratings"):
				ad["ratings"] = {}
	out["park"] = park
	return out


## v2 → v3 (M6, én version for hele milepælen – senere M6-tasks udvider dette trin):
## gæsters tolerance/kvalme/ting, præmier på attraktioner, affaldstype (opkast-liste).
static func _v2_to_v3(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var park: Dictionary = SaveCodec.dict(out, "park")
	for g: Variant in SaveCodec.arr(park, "guests"):
		if g is Dictionary:
			var gd: Dictionary = g
			if not gd.has("intensity_tolerance"):
				gd["intensity_tolerance"] = 50.0
			if not gd.has("nausea"):
				gd["nausea"] = 0.0
			if not gd.has("items"):
				gd["items"] = []
			if not gd.has("wet_ticks"):  # T-090
				gd["wet_ticks"] = 0
			if not gd.has("transport_id"):  # T-091
				gd["transport_id"] = -1
				gd["transport_dest"] = [0, 0]
				gd["transport_resume_state"] = 0
	for a: Variant in SaveCodec.arr(park, "attractions"):
		if a is Dictionary:
			var ad: Dictionary = a
			if not ad.has("prizes_won"):
				ad["prizes_won"] = 0
			if not ad.has("prize_cost_total"):
				ad["prize_cost_total"] = 0
			if not ad.has("riders_today"):  # T-091
				ad["riders_today"] = 0
	# Affald gemmes som [[x, y, n]] uden type; opkast ligger i en separat liste (alt gammelt = "litter").
	if park.get("world") is Dictionary:
		var wd: Dictionary = park["world"]
		if not wd.has("vomit"):
			wd["vomit"] = []
	out["park"] = park
	return out


## v3 → v4 (M7, én version for hele milepælen – senere M7-tasks (T-104..T-106) udvider dette trin):
## T-102: config/opskrifter/salgshistorik på attraktioner. T-103: køstier (QUEUE-tiles ligger i
## world.tiles, ingen ekstra felter) og gæsters tålmodighed/køplads/blokering.
static func _v3_to_v4(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var park: Dictionary = SaveCodec.dict(out, "park")
	for a: Variant in SaveCodec.arr(park, "attractions"):
		if a is Dictionary:
			var ad: Dictionary = a
			for k: String in ["config", "recipes", "customers_today", "revenue_days", "payback_day"]:
				if not ad.has(k):
					ad[k] = {"config": {}, "recipes": [], "customers_today": 0, "revenue_days": [],
						"payback_day": -1}[k]
	for g: Variant in SaveCodec.arr(park, "guests"):
		if g is Dictionary:
			var gd: Dictionary = g
			if not gd.has("patience"):
				gd["patience"] = 1050.0
			if not gd.has("queue_index"):
				gd["queue_index"] = -1
			if not gd.has("blocked_ticks"):
				gd["blocked_ticks"] = 0
			# T-104: gå hjem, hæveautomat og bænk.
			if not gd.has("leaving"):
				gd["leaving"] = int(gd.get("state", 0)) == Guest.State.LEAVING
			if not gd.has("leave_reason"):
				gd["leave_reason"] = ""
			if not gd.has("atm_uses"):
				gd["atm_uses"] = 0
			if not gd.has("resting_on"):
				gd["resting_on"] = int(gd.get("target_decor_id", -1)) if int(gd.get("state", 0)) == Guest.State.RESTING else -1
	# T-105: milepæle – gamle saves evalueres ved første tick (backfill uden belønning).
	if not park.has("milestones"):
		park["milestones"] = []
	if not park.has("milestones_backfill"):
		park["milestones_backfill"] = true
	if not park.has("milestones_days_clean"):
		park["milestones_days_clean"] = 0
	for dc: Variant in SaveCodec.arr(park, "decor"):
		if dc is Dictionary and not (dc as Dictionary).has("fill"):
			dc["fill"] = 0
	if park.get("world") is Dictionary:
		var wd: Dictionary = park["world"]
		if not wd.has("queue_paths"):
			wd["queue_paths"] = []
	out["park"] = park
	return out
