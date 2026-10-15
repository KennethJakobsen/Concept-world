class_name Attraction
extends RefCounted
## Instans af en attraktion i parken: kø, ryttere og cyklus.

signal ride_started
signal ride_finished(guest_ids: Array)

var id: int
var def: AttractionDef
var origin: Vector2i
var entrance_cell: Vector2i
var queue: Array = []   ## guest ids (int) i kø-rækkefølge
var riders: Array = []  ## guest ids der kører nu
var ticks_left: int = 0


func _init(p_id: int, p_def: AttractionDef, p_origin: Vector2i) -> void:
	id = p_id
	def = p_def
	origin = p_origin
	entrance_cell = Vector2i(origin.x + def.footprint.x / 2, origin.y + def.footprint.y)


func is_running() -> bool:
	return not riders.is_empty()


func occupies(cell: Vector2i) -> bool:
	return cell.x >= origin.x and cell.y >= origin.y \
		and cell.x < origin.x + def.footprint.x and cell.y < origin.y + def.footprint.y


func enqueue(guest_id: int) -> void:
	queue.append(guest_id)


func tick() -> void:
	if is_running():
		ticks_left -= 1
		if ticks_left <= 0:
			var done: Array = riders.duplicate()
			riders.clear()
			ride_finished.emit(done)
		return
	if queue.is_empty():
		return
	var n: int = mini(def.capacity, queue.size())
	for i in n:
		riders.append(queue.pop_front())
	ticks_left = def.ride_ticks
	ride_started.emit()
