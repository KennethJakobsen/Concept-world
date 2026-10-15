class_name TrackPiece
extends RefCounted
## Et placeret banestykke. heading: 0=N(-y), 1=Ø(+x), 2=S(+y), 3=V(-x). level = højde ved indgangen.

const DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

var def_id: String
var cell: Vector2i
var heading: int
var level: int


func _init(p_def_id: String = "", p_cell: Vector2i = Vector2i.ZERO, p_heading: int = 0, p_level: int = 0) -> void:
	def_id = p_def_id
	cell = p_cell
	heading = posmod(p_heading, 4)
	level = p_level


static func dir(h: int) -> Vector2i:
	return DIRS[posmod(h, 4)]


func to_save() -> Dictionary:
	return {"def_id": def_id, "cell": SaveCodec.v2i(cell), "heading": heading, "level": level}


func to_dict() -> Dictionary:
	return {"def_id": def_id, "cell": cell, "heading": heading, "level": level}


static func from_save(d: Dictionary) -> TrackPiece:
	return TrackPiece.new(str(d.get("def_id", "")), SaveCodec.to_v2i(d.get("cell")),
		int(d.get("heading", 0)), int(d.get("level", 0)))
