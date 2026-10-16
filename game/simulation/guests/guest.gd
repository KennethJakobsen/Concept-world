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
## T-043: antal sti-celler til affaldet smides (0 = bærer intet).
var litter_steps_left: int = 0
## M6 (T-084): maks. intensitet gæsten vil køre (0..100) og kvalme (0..100).
var intensity_tolerance: float = 50.0
var nausea: float = 0.0
## M6 (T-086): bærbare ting (maks. én af hver).
var items: Array[StringName] = []
## T-090: ticks tilbage som våd efter vandbanen.
var wet_ticks: int = 0
## T-091: transport (svævebane) – attraktion, destination og tilstand at vende tilbage til.
var transport_id: int = -1
var transport_dest: Vector2i = Vector2i.ZERO
var transport_resume_state: int = State.WALKING
## M7 (T-103): resterende tålmodighed i køen (ticks; < 0 = utålmodig), plads i køen (0 = forrest)
## og ticks blokeret af en fuld celle.
var patience: float = 1050.0
var queue_index: int = -1
var blocked_ticks: int = 0


func is_on_transport() -> bool:
	return transport_id >= 0


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
		"litter_steps_left": litter_steps_left,
		"intensity_tolerance": SaveCodec.f(intensity_tolerance), "nausea": SaveCodec.f(nausea),
		"items": _items_to_save(), "wet_ticks": wet_ticks,
		"transport_id": transport_id, "transport_dest": SaveCodec.v2i(transport_dest),
		"transport_resume_state": transport_resume_state,
		"patience": SaveCodec.f(patience), "queue_index": queue_index, "blocked_ticks": blocked_ticks,
	}


func _items_to_save() -> Array:
	var out: Array = []
	for it in items:
		out.append(str(it))
	return out


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
	g.litter_steps_left = int(d.get("litter_steps_left", 0))
	g.intensity_tolerance = SaveCodec.to_f(d.get("intensity_tolerance"), 50.0)
	g.nausea = SaveCodec.to_f(d.get("nausea"), 0.0)
	g.wet_ticks = int(d.get("wet_ticks", 0))
	g.transport_id = int(d.get("transport_id", -1))
	g.transport_dest = SaveCodec.to_v2i(d.get("transport_dest"), Vector2i.ZERO)
	g.transport_resume_state = int(d.get("transport_resume_state", State.WALKING))
	g.patience = SaveCodec.to_f(d.get("patience"), 1050.0)
	g.queue_index = int(d.get("queue_index", -1))
	g.blocked_ticks = int(d.get("blocked_ticks", 0))
	var its: Variant = d.get("items", [])
	if its is Array:
		for it: Variant in its:
			var sn := StringName(str(it))
			if not g.items.has(sn):
				g.items.append(sn)
	return g
