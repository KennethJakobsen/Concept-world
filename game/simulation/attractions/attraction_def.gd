class_name AttractionDef
extends Resource
## Statiske data for en attraktionstype (indlæses fra JSON).

@export var id: String = ""
@export var name: String = ""
@export var footprint: Vector2i = Vector2i(1, 1)
@export var capacity: int = 1
@export var ride_ticks: int = 20
@export var ticket_price: int = 0
@export var kind: String = "ride"  ## ride | shop | toilet
@export var build_cost: int = 0
@export var running_cost_per_day: int = 0
@export var excitement: int = 0
@export var satisfies: Dictionary = {}  ## behov -> ændring ved endt besøg
@export var model: String = ""


static func from_dict(d: Dictionary) -> AttractionDef:
	var def := AttractionDef.new()
	def.id = str(d.get("id", ""))
	def.name = str(d.get("name", def.id))
	var fp: Array = d.get("footprint", [1, 1])
	def.footprint = Vector2i(int(fp[0]), int(fp[1]))
	def.capacity = int(d.get("capacity", 1))
	def.ride_ticks = int(d.get("ride_ticks", 20))
	def.ticket_price = int(d.get("ticket_price", 0))
	def.kind = str(d.get("kind", "ride"))
	def.build_cost = int(d.get("build_cost", 0))
	def.running_cost_per_day = int(d.get("running_cost_per_day", 0))
	def.excitement = int(d.get("excitement", 0))
	var sat: Variant = d.get("satisfies", {})
	if sat is Dictionary:
		for k: Variant in sat:
			def.satisfies[str(k)] = float(sat[k])
	def.model = str(d.get("model", ""))
	return def


static func from_json(path: String) -> AttractionDef:
	var text: String = FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("AttractionDef: kunne ikke læse %s" % path)
		return null
	return from_dict(data)
