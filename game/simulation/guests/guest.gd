class_name Guest
extends RefCounted
## En parkgæst. Logikken drives af ParkSim.

enum State { WALKING, QUEUING, RIDING, LEAVING }

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


func _init(p_id: int, p_cell: Vector2i) -> void:
	id = p_id
	cell = p_cell
	next_cell = p_cell
