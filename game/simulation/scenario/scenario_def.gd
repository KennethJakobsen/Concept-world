class_name ScenarioDef
extends Resource
## Scenarie-definition (T-067), indlæst fra content/scenarios/<id>.json.
## Start-lister: paths [[x,y]], attractions [{def, origin}], decor [{def, cell}], staff [{type, cell}].
## decor/attractions accepterer også "def_id" som alias for "def".

const DIR: String = "res://content/scenarios/"

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var order: int = 0
@export var map_size: Vector2i = Vector2i(64, 64)
@export var entrance: Vector2i = Vector2i(-1, -1)  ## (-1,-1) = standard (midt på sydkanten)
@export var start_money: int = 10000
@export var start_loan: int = 0
@export var start_reputation: float = 50.0
@export var entry_fee: int = -1  ## -1 = balance-default
@export var research_enabled: bool = false
@export var unlocked: Array[String] = []
@export var paths: Array[Vector2i] = []
@export var attractions: Array[Dictionary] = []  ## {def: String, origin: Vector2i}
@export var decor: Array[Dictionary] = []  ## {def: String, cell: Vector2i}
@export var staff: Array[Dictionary] = []  ## {type: String, cell: Vector2i}
@export var objectives: Array[Dictionary] = []  ## {type: String, value: float}
@export var deadline_days: int = 0
@export var lose: Array[Dictionary] = []  ## {type: String, value: float, days: int}


static func _v2i(v: Variant, fallback: Vector2i) -> Vector2i:
	if v is Array and (v as Array).size() >= 2:
		return Vector2i(int(v[0]), int(v[1]))
	return fallback


static func from_dict(d: Dictionary) -> ScenarioDef:
	var r := ScenarioDef.new()
	r.id = str(d.get("id", ""))
	r.name = str(d.get("name", r.id))
	r.description = str(d.get("description", ""))
	r.order = int(d.get("order", 0))
	var m: Dictionary = d.get("map", {}) if d.get("map") is Dictionary else {}
	r.map_size = Vector2i(int(m.get("width", 64)), int(m.get("height", 64)))
	r.entrance = _v2i(m.get("entrance"), Vector2i(-1, -1))
	var s: Dictionary = d.get("start", {}) if d.get("start") is Dictionary else {}
	r.start_money = int(s.get("money", r.start_money))
	r.start_loan = int(s.get("loan", 0))
	r.start_reputation = float(s.get("reputation", r.start_reputation))
	r.entry_fee = int(s.get("entry_fee", -1))
	r.research_enabled = bool(s.get("research_enabled", false))
	for u: Variant in _arr(s, "unlocked"):
		r.unlocked.append(str(u))
	for p: Variant in _arr(s, "paths"):
		r.paths.append(_v2i(p, Vector2i.ZERO))
	for a: Variant in _arr(s, "attractions"):
		if a is Dictionary:
			r.attractions.append({"def": str(a.get("def", a.get("def_id", ""))), "origin": _v2i(a.get("origin"), Vector2i.ZERO)})
	for dc: Variant in _arr(s, "decor"):
		if dc is Dictionary:
			r.decor.append({"def": str(dc.get("def", dc.get("def_id", ""))), "cell": _v2i(dc.get("cell"), Vector2i.ZERO)})
	for st: Variant in _arr(s, "staff"):
		if st is Dictionary:
			r.staff.append({"type": str(st.get("type", st.get("def", ""))), "cell": _v2i(st.get("cell"), Vector2i.ZERO)})
	for o: Variant in _arr(d, "objectives"):
		if o is Dictionary:
			r.objectives.append({"type": str(o.get("type", "")), "value": float(o.get("value", 0))})
	r.deadline_days = int(d.get("deadline_days", 0))
	for l: Variant in _arr(d, "lose"):
		if l is Dictionary:
			r.lose.append({"type": str(l.get("type", "")), "value": float(l.get("value", 0)), "days": maxi(1, int(l.get("days", 1)))})
	return r


static func _arr(d: Dictionary, key: String) -> Array:
	var v: Variant = d.get(key, [])
	return v if v is Array else []


## null ved manglende/ugyldig fil.
static func from_json(path: String) -> ScenarioDef:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return null
	return from_dict(parsed)


## Alle scenarier i content/scenarios/, sorteret efter order (derefter id).
static func list_all(dir_path: String = DIR) -> Array[ScenarioDef]:
	var out: Array[ScenarioDef] = []
	for f in DirAccess.get_files_at(dir_path):
		var fname: String = f.trim_suffix(".remap")  # eksporterede builds
		if not fname.ends_with(".json"):
			continue
		var d: ScenarioDef = from_json(dir_path.path_join(fname))
		if d != null and d.id != "":
			out.append(d)
	out.sort_custom(func(a: ScenarioDef, b: ScenarioDef) -> bool:
		return a.order < b.order if a.order != b.order else a.id < b.id)
	return out


static func find(scenario_id: String, dir_path: String = DIR) -> ScenarioDef:
	return from_json(dir_path.path_join(scenario_id + ".json"))


func is_sandbox() -> bool:
	return objectives.is_empty() and lose.is_empty() and deadline_days <= 0
