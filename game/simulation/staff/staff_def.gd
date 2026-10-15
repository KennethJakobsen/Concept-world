class_name StaffDef
extends Resource
## Statiske data for en personaletype (content/staff/<id>.json).

@export var id: String = ""
@export var name: String = ""
@export var wage_per_day: int = 0
@export var speed: float = 0.1
@export var work_radius: int = 0  ## 0 = hele parken
@export var model: String = ""


static func from_dict(d: Dictionary) -> StaffDef:
	var s := StaffDef.new()
	s.id = str(d.get("id", ""))
	s.name = str(d.get("name", s.id))
	s.wage_per_day = int(d.get("wage_per_day", 0))
	s.speed = float(d.get("speed", 0.1))
	s.work_radius = int(d.get("work_radius", 0))
	s.model = str(d.get("model", ""))
	return s


static func from_json(path: String) -> StaffDef:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return from_dict(data) if data is Dictionary else null


func to_dict() -> Dictionary:
	return {"id": id, "name": name, "wage_per_day": wage_per_day, "speed": speed,
		"work_radius": work_radius, "model": model}
