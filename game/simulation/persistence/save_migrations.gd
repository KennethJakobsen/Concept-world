class_name SaveMigrations
extends RefCounted
## Versionstrin for savefiler. Tilføj et trin pr. ny save_version:
##   1) hæv CURRENT, 2) tilføj `static func _v<N>_to_v<N+1>(d) -> Dictionary`, 3) registrér i _step().

const CURRENT: int = 1


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
