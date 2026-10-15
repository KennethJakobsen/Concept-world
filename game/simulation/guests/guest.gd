class_name Guest
extends RefCounted
## En parkgæst. Logikken drives af ParkSim.

enum State { WALKING, QUEUING, RIDING, LEAVING, RESTING }  ## RESTING: på bænk (T-037)

var id: int
var cell: Vector2i
var next_cell: Vector2i
var progress: float = 0.0
var state: int = State.WALKING

var path: Array[Vector2i] = []      ## resterende celler efter next_cell
var target_attraction_id: int = -1  ## -1 = vandrer
var rides_left: int = 2
var wander_steps: int = 0

var money: int = 0
var happiness: float = 70.0
var needs: Dictionary = {}  ## behov-navn -> float 0..100 (100 = akut)
var thought: String = ""
## Attraktioner gæsten har afvist (pris/lukket) – vælges ikke igen.
var rejected_ids: Array[int] = []
## Behov gæsten forsøger at dække ("" = forlystelse/vandring).
var seeking_need: String = ""
## Pris betalt for igangværende besøg (refunderes hvis bygningen fjernes).
var paid: int = 0
## Bænk gæsten går mod/hviler på (-1 = ingen) og resterende hviletid.
var target_decor_id: int = -1
var rest_ticks_left: int = 0


func _init(p_id: int, p_cell: Vector2i) -> void:
	id = p_id
	cell = p_cell
	next_cell = p_cell


# --- Save/load (T-036) ---

func to_save() -> Dictionary:
	return {
		"id": id, "cell": SaveCodec.v2i(cell), "next_cell": SaveCodec.v2i(next_cell),
		"progress": SaveCodec.f(progress), "state": state, "path": SaveCodec.v2i_array(path),
		"target_attraction_id": target_attraction_id, "rides_left": rides_left,
		"wander_steps": wander_steps, "money": money, "happiness": SaveCodec.f(happiness),
		"needs": SaveCodec.float_dict(needs), "thought": thought, "rejected_ids": rejected_ids.duplicate(),
		"seeking_need": seeking_need, "paid": paid,
		"target_decor_id": target_decor_id, "rest_ticks_left": rest_ticks_left,
	}


static func from_save(d: Dictionary) -> Guest:
	var g := Guest.new(int(d.get("id", 0)), SaveCodec.to_v2i(d.get("cell")))
	g.next_cell = SaveCodec.to_v2i(d.get("next_cell"), g.cell)
	g.progress = SaveCodec.to_f(d.get("progress"), 0.0)
	g.state = int(d.get("state", State.WALKING))
	g.path = SaveCodec.to_v2i_array(d.get("path", []))
	g.target_attraction_id = int(d.get("target_attraction_id", -1))
	g.rides_left = int(d.get("rides_left", 0))
	g.wander_steps = int(d.get("wander_steps", 0))
	g.money = int(d.get("money", 0))
	g.happiness = SaveCodec.to_f(d.get("happiness"), 70.0)
	g.needs = SaveCodec.to_float_dict(d.get("needs", {}))
	g.thought = str(d.get("thought", ""))
	g.rejected_ids = SaveCodec.to_int_array(d.get("rejected_ids", []))
	g.seeking_need = str(d.get("seeking_need", ""))
	g.paid = int(d.get("paid", 0))
	g.target_decor_id = int(d.get("target_decor_id", -1))
	g.rest_ticks_left = int(d.get("rest_ticks_left", 0))
	return g
