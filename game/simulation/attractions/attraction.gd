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
var is_open: bool = true
var price: int = 0
var total_visitors: int = 0
var total_revenue: int = 0

enum Status { OPERATING, BROKEN, CLOSED }
## I stykker (T-037). Kører ingen nye ture før en mekaniker har repareret.
var broken: bool = false
## Midlertidig pålidelighed fra inspektioner (nulstilles ved nedbrud).
var reliability_bonus: float = 0.0
## Mekaniker tildelt reparation (-1 = ingen).
var mechanic_id: int = -1
## Tick for seneste inspektion (-1 = aldrig).
var last_inspect_tick: int = -1
## T-047: ticks i stykker uden mekaniker (ekstern service).
var self_repair_elapsed: int = 0
## OPERATING | BROKEN | CLOSED (BROKEN vinder over CLOSED).
var status: int:
	get:
		if broken:
			return Status.BROKEN
		return Status.OPERATING if is_open else Status.CLOSED


func effective_reliability() -> float:
	return minf(1.0, def.reliability + reliability_bonus)


func _init(p_id: int, p_def: AttractionDef, p_origin: Vector2i) -> void:
	id = p_id
	def = p_def
	origin = p_origin
	entrance_cell = Vector2i(origin.x + def.footprint.x / 2, origin.y + def.footprint.y)
	price = def.ticket_price


## Tilfredsstiller bygningen behovet (negativ ændring)?
func satisfies_need(need: String) -> bool:
	return float(def.satisfies.get(need, 0.0)) < 0.0


func is_running() -> bool:
	return not riders.is_empty()


func occupies(cell: Vector2i) -> bool:
	return cell.x >= origin.x and cell.y >= origin.y \
		and cell.x < origin.x + def.footprint.x and cell.y < origin.y + def.footprint.y


func enqueue(guest_id: int) -> void:
	queue.append(guest_id)


func tick() -> void:
	if broken and not is_running():
		return
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


# --- Save/load (T-036) ---

func to_save() -> Dictionary:
	return {
		"id": id, "def_id": def.id, "def": def.to_dict(), "origin": SaveCodec.v2i(origin),
		"queue": queue.duplicate(), "riders": riders.duplicate(), "ticks_left": ticks_left,
		"is_open": is_open, "price": price, "total_visitors": total_visitors,
		"total_revenue": total_revenue, "broken": broken,
		"reliability_bonus": SaveCodec.f(reliability_bonus), "mechanic_id": mechanic_id,
		"last_inspect_tick": last_inspect_tick, "self_repair_elapsed": self_repair_elapsed,
	}


## Opretter instans; p_def skal være resolvet af kalderen (content eller snapshot).
static func from_save(d: Dictionary, p_def: AttractionDef) -> Attraction:
	var a := Attraction.new(int(d.get("id", 0)), p_def, SaveCodec.to_v2i(d.get("origin")))
	a.queue = SaveCodec.to_int_list(d.get("queue", []))
	a.riders = SaveCodec.to_int_list(d.get("riders", []))
	a.ticks_left = int(d.get("ticks_left", 0))
	a.is_open = bool(d.get("is_open", true))
	a.price = int(d.get("price", p_def.ticket_price))
	a.total_visitors = int(d.get("total_visitors", 0))
	a.total_revenue = int(d.get("total_revenue", 0))
	a.broken = bool(d.get("broken", false))
	a.reliability_bonus = SaveCodec.to_f(d.get("reliability_bonus"), 0.0)
	a.mechanic_id = int(d.get("mechanic_id", -1))
	a.last_inspect_tick = int(d.get("last_inspect_tick", -1))
	a.self_repair_elapsed = int(d.get("self_repair_elapsed", 0))
	return a
