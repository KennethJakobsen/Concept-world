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
## M6 (T-085): sideshow-gevinster og samlet præmieudgift.
var prizes_won: int = 0
var prize_cost_total: int = 0

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


## Rutsjebane-ratings {excitement, intensity, nausea} (T-068 udfylder; tom for andre).
var ratings: Dictionary = {}
## T-068: celler banen optager (tom = brug footprint).
var cells: Array[Vector2i] = []
## T-068: banen (null for andre attraktioner).
var track: CoasterTrack = null
## T-068: banen er under bygning (ikke færdig/valideret).
var building: bool = false
## T-068: fysikprofil (genberegnes, gemmes ikke).
var profile: CoasterProfile = null
## T-068: ride_ticks fra profilen (0 = def.ride_ticks) og ilæsningstid i starten af turen.
var ride_ticks_override: int = 0
var load_ticks: int = 0
## T-091: passagerer i dag (nulstilles ved dagsskifte).
var riders_today: int = 0


func is_coaster() -> bool:
	return def.kind == "coaster"


func is_sideshow() -> bool:
	return def.kind == "sideshow"


## ADR-004: sporbaseret (coaster, flume, train, transport).
func is_tracked() -> bool:
	return def.is_tracked()


## T-091: transport mellem to stationer (svævebane).
func is_transport() -> bool:
	return def.kind == "transport"


## Forlystelse (ride, rutsjebane, vandbane, minitog – ikke transport).
func is_ride() -> bool:
	return def.kind == "ride" or def.kind == "coaster" or def.kind == "flume" or def.kind == "train"


func ride_ticks() -> int:
	return ride_ticks_override if ride_ticks_override > 0 else def.ride_ticks


## Excitement på 0..100-skalaen (rutsjebane: ratings × scale).
func excitement_value(scale: float = 10.0) -> int:
	if is_coaster():
		return int(round(float(ratings.get("excitement", 0.0)) * scale))
	return def.excitement


## Intensitet 0..100 (rutsjebane: ratings × scale, ellers data).
func intensity_value(scale: float = 10.0) -> float:
	if is_coaster():
		return float(ratings.get("intensity", 0.0)) * scale
	return def.intensity


## Kvalme 0..100 (rutsjebane: ratings × scale, ellers data).
func nausea_value(scale: float = 10.0) -> float:
	if is_coaster():
		return float(ratings.get("nausea", 0.0)) * scale
	return def.nausea


## Byggepris inkl. banestykker.
func build_value() -> int:
	return def.build_cost + (track.total_cost() if track != null else 0)


## 0..1 for den igangværende tur (0 = station/ilæsning).
func ride_progress() -> float:
	if not is_running():
		return 0.0
	return ride_progress_at(ticks_left)


## 0..1 for ticks_left = tl (deterministisk; bruges til ride_splash).
func ride_progress_at(tl: int) -> float:
	var total: int = ride_ticks()
	var run: int = total - load_ticks
	if run <= 0:
		return 0.0
	var elapsed: int = total - tl - load_ticks
	return clampf(float(elapsed) / float(run), 0.0, 1.0)

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
	if not cells.is_empty():
		return cells.has(cell)
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
	ticks_left = ride_ticks()
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
		"cells": SaveCodec.v2i_array(cells), "track": track.to_save() if track != null else null,
		"ratings": SaveCodec.float_dict(ratings), "building": building,
		"entrance_cell": SaveCodec.v2i(entrance_cell),
		"prizes_won": prizes_won, "prize_cost_total": prize_cost_total,
		"riders_today": riders_today,
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
	a.cells = SaveCodec.to_v2i_array(d.get("cells", []))
	if d.has("entrance_cell"):
		a.entrance_cell = SaveCodec.to_v2i(d.get("entrance_cell"), a.entrance_cell)
	var tr: Variant = d.get("track")
	if tr is Array:
		var sys: StringName = p_def.track_system()
		a.track = CoasterTrack.from_save(tr, {}, p_def.max_height, sys if sys != &"" else &"coaster")
	a.ratings = SaveCodec.to_float_dict(d.get("ratings", {}))
	a.building = bool(d.get("building", false))
	a.prizes_won = int(d.get("prizes_won", 0))
	a.prize_cost_total = int(d.get("prize_cost_total", 0))
	a.riders_today = int(d.get("riders_today", 0))
	return a
