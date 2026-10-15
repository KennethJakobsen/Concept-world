class_name Staff
extends RefCounted
## En ansat. Logikken drives af ParkSim/StaffAI. Går på stier ligesom gæster.

enum State { IDLE, WALKING, WORKING }

const TASK_NONE: String = ""
const TASK_REPAIR: String = "repair"
const TASK_INSPECT: String = "inspect"
const TASK_SWEEP: String = "sweep"
const TASK_EMPTY_BIN: String = "empty_bin"
const TASK_PATROL: String = "patrol"

var id: int
var def: StaffDef
var cell: Vector2i
var next_cell: Vector2i
var progress: float = 0.0
var path: Array[Vector2i] = []
var home_cell: Vector2i       ## arbejdsområdets centrum (ansættelses-/flyttecelle)
var state: int = State.IDLE
var task: String = TASK_NONE
var task_target_id: int = -1  ## attraktion/decor-id
var task_cell: Vector2i       ## celle der arbejdes på
var work_ticks_left: int = 0
var since_inspect: int = 0    ## ticks siden sidste inspektion (mekaniker)


func _init(p_id: int, p_def: StaffDef, p_cell: Vector2i) -> void:
	id = p_id
	def = p_def
	cell = p_cell
	next_cell = p_cell
	home_cell = p_cell
	task_cell = p_cell


func type_id() -> String:
	return def.id


## Er målet inden for arbejdsradius (manhattan fra home_cell)?
func in_radius(target: Vector2i) -> bool:
	if def.work_radius <= 0:
		return true
	return absi(target.x - home_cell.x) + absi(target.y - home_cell.y) <= def.work_radius


func to_save() -> Dictionary:
	return {
		"id": id, "type": def.id, "def": def.to_dict(), "cell": SaveCodec.v2i(cell),
		"next_cell": SaveCodec.v2i(next_cell), "progress": SaveCodec.f(progress),
		"path": SaveCodec.v2i_array(path), "home_cell": SaveCodec.v2i(home_cell), "state": state,
		"task": task, "task_target_id": task_target_id, "task_cell": SaveCodec.v2i(task_cell),
		"work_ticks_left": work_ticks_left, "since_inspect": since_inspect,
	}


static func from_save(d: Dictionary, p_def: StaffDef) -> Staff:
	var s := Staff.new(int(d.get("id", 0)), p_def, SaveCodec.to_v2i(d.get("cell")))
	s.next_cell = SaveCodec.to_v2i(d.get("next_cell"), s.cell)
	s.progress = SaveCodec.to_f(d.get("progress"), 0.0)
	s.path = SaveCodec.to_v2i_array(d.get("path", []))
	s.home_cell = SaveCodec.to_v2i(d.get("home_cell"), s.cell)
	s.state = int(d.get("state", State.IDLE))
	s.task = str(d.get("task", TASK_NONE))
	s.task_target_id = int(d.get("task_target_id", -1))
	s.task_cell = SaveCodec.to_v2i(d.get("task_cell"), s.cell)
	s.work_ticks_left = int(d.get("work_ticks_left", 0))
	s.since_inspect = int(d.get("since_inspect", 0))
	return s
