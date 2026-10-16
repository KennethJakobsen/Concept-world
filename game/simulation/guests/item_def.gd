class_name ItemDef
extends Resource
## Bærbar ting (content/items.json): ballon, souvenir, præmier (T-086).

@export var id: String = ""
@export var happiness_per_hour: float = 0.0
@export var aura_radius: int = 0
@export var aura_happiness: float = 0.0
@export var lose_chance_per_hour: float = 0.0
@export var duration_hours: int = 0


static func from_dict(d: Dictionary) -> ItemDef:
	var r := ItemDef.new()
	r.id = str(d.get("id", ""))
	r.happiness_per_hour = float(d.get("happiness_per_hour", 0.0))
	r.aura_radius = maxi(0, int(d.get("aura_radius", 0)))
	r.aura_happiness = float(d.get("aura_happiness", 0.0))
	r.lose_chance_per_hour = clampf(float(d.get("lose_chance_per_hour", 0.0)), 0.0, 1.0)
	r.duration_hours = maxi(0, int(d.get("duration_hours", 0)))
	return r


## Læser alle ting fra items.json → {StringName id: ItemDef}.
static func load_all(path: String = "res://content/items.json") -> Dictionary:
	var out: Dictionary = {}
	if not FileAccess.file_exists(path):
		return out
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary and data.get("items") is Array:
		for e: Variant in data["items"]:
			if e is Dictionary:
				var it: ItemDef = from_dict(e)
				if it.id != "":
					out[StringName(it.id)] = it
	return out
