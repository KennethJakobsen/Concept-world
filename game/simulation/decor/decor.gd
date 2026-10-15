class_name Decor
extends RefCounted
## Placeret dekoration (1×1 i M3). Skraldespande har fyldning.

var id: int
var def: DecorDef
var cell: Vector2i
var fill: int = 0  ## bin: antal stykker affald i spanden


func _init(p_id: int, p_def: DecorDef, p_cell: Vector2i) -> void:
	id = p_id
	def = p_def
	cell = p_cell


func to_save() -> Dictionary:
	return {"id": id, "def_id": def.id, "def": def.to_dict(), "cell": SaveCodec.v2i(cell), "fill": fill}


static func from_save(d: Dictionary, p_def: DecorDef) -> Decor:
	var r := Decor.new(int(d.get("id", 0)), p_def, SaveCodec.to_v2i(d.get("cell")))
	r.fill = int(d.get("fill", 0))
	return r
