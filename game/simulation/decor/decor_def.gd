class_name DecorDef
extends Resource
## Statiske data for dekoration (content/decor/<id>.json).

@export var id: String = ""
@export var name: String = ""
@export var kind: String = "tree"  ## bin | bench | tree | flowers | lamp
@export var footprint: Vector2i = Vector2i(1, 1)
@export var build_cost: int = 0
@export var on_path: bool = false
@export var happiness_aura: float = 0.0
@export var aura_radius: int = 0
@export var model: String = ""
## M7 (T-104): bænkepladser, spandens kapacitet (0 = balance.bin_capacity) og lygtens aura om natten.
@export var seats: int = 0
@export var capacity: int = 0
@export var night_aura: float = 0.0


static func from_dict(d: Dictionary) -> DecorDef:
	var r := DecorDef.new()
	r.id = str(d.get("id", ""))
	r.name = str(d.get("name", r.id))
	r.kind = str(d.get("kind", "tree"))
	var fp: Array = d.get("footprint", [1, 1])
	r.footprint = Vector2i(int(fp[0]), int(fp[1]))
	r.build_cost = int(d.get("build_cost", 0))
	r.on_path = bool(d.get("on_path", false))
	r.happiness_aura = float(d.get("happiness_aura", 0.0))
	r.aura_radius = int(d.get("aura_radius", 0))
	r.model = str(d.get("model", ""))
	r.seats = maxi(0, int(d.get("seats", 2 if r.kind == "bench" else 0)))
	r.capacity = maxi(0, int(d.get("capacity", 0)))
	r.night_aura = float(d.get("night_aura", 0.0))
	return r


static func from_json(path: String) -> DecorDef:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return from_dict(data) if data is Dictionary else null


func to_dict() -> Dictionary:
	return {"id": id, "name": name, "kind": kind, "footprint": [footprint.x, footprint.y],
		"build_cost": build_cost, "on_path": on_path, "happiness_aura": happiness_aura,
		"aura_radius": aura_radius, "model": model, "seats": seats, "capacity": capacity,
		"night_aura": night_aura}
