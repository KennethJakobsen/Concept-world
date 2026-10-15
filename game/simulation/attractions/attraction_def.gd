class_name AttractionDef
extends Resource
## Statiske data for en attraktionstype (indlæses fra JSON).

@export var id: String = ""
@export var name: String = ""
@export var footprint: Vector2i = Vector2i(1, 1)
@export var capacity: int = 1
@export var ride_ticks: int = 20
@export var ticket_price: int = 0


static func from_dict(d: Dictionary) -> AttractionDef:
	var def := AttractionDef.new()
	def.id = str(d.get("id", ""))
	def.name = str(d.get("name", def.id))
	var fp: Array = d.get("footprint", [1, 1])
	def.footprint = Vector2i(int(fp[0]), int(fp[1]))
	def.capacity = int(d.get("capacity", 1))
	def.ride_ticks = int(d.get("ride_ticks", 20))
	def.ticket_price = int(d.get("ticket_price", 0))
	return def


static func from_json(path: String) -> AttractionDef:
	var text: String = FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("AttractionDef: kunne ikke læse %s" % path)
		return null
	return from_dict(data)
