class_name TutorialDirector
extends RefCounted
## T-115: styrer tutorial-trin. Læser steps fra rå scenarie-JSON og fuldfører trin ved
## handling (poll af sim-state + UI-events via notify). Ændrer aldrig sim'en.

signal step_changed(index: int, step: Dictionary)
signal finished(skipped: bool)

var steps: Array[Dictionary] = []
var skippable: bool = true
var index: int = -1  ## -1 = ikke startet, steps.size() = færdig
var _sim: ParkSim
var _events: Dictionary = {}  ## UI-events set siden trinstart ("overlay_opened:queue")
var _prices: Dictionary = {}  ## attraktions-id -> pris ved trinstart


## Rå JSON for scenariet, eller {} hvis det ikke er en tutorial.
static func load_raw(scenario_id: String, dir_path: String = ScenarioDef.DIR) -> Dictionary:
	if scenario_id == "":
		return {}
	var path: String = dir_path.path_join(scenario_id + ".json")
	if not FileAccess.file_exists(path):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (d is Dictionary) or not bool((d as Dictionary).get("tutorial", false)):
		return {}
	return d


## Opretter en director til scenariet (null, hvis det ikke er en tutorial).
## Bemærk: tutorial-scenariet er "sandbox-agtigt", så sim.scenario er null – id'et gives udefra.
static func for_scenario(scenario_id: String, sim: ParkSim) -> TutorialDirector:
	if sim == null:
		return null
	var raw: Dictionary = load_raw(scenario_id)
	if raw.is_empty():
		return null
	var t := TutorialDirector.new()
	t.setup(raw, sim)
	return t


func setup(raw: Dictionary, sim: ParkSim) -> void:
	_sim = sim
	skippable = bool(raw.get("skippable", true))
	steps.clear()
	for s in raw.get("steps", []):
		if s is Dictionary:
			steps.append(s)


func start() -> void:
	_enter(0)


func active() -> bool:
	return index >= 0 and index < steps.size()


func current_step() -> Dictionary:
	return steps[index] if active() else {}


func notify(event: String) -> void:
	if active():
		_events[event] = true
		poll()


func skip() -> void:
	if not active() or not skippable:
		return
	index = steps.size()
	finished.emit(true)


## Kald jævnligt (hver frame). Går videre, så længe det aktuelle trin er opfyldt.
func poll() -> void:
	while active() and is_complete(str(current_step().get("complete_when", ""))):
		_enter(index + 1)


func is_complete(cond: String) -> bool:
	if _sim == null:
		return false
	var parts: PackedStringArray = cond.split(":", true, 1)
	var arg: String = parts[1] if parts.size() > 1 else ""
	match parts[0]:
		"path_connected_to_entrance":
			for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if _sim.world.get_tile(_sim.world.entrance + d) == ParkWorld.Tile.PATH:
					return true
			return false
		"attraction_built":
			return find_attraction(arg) != null
		"price_changed":
			for a: Attraction in _sim.attractions:
				if _prices.has(a.id) and int(_prices[a.id]) != a.price:
					return true
			return false
		"staff_hired":
			for s: Variant in _sim.staff.values():
				if (s as Staff).def != null and (s as Staff).def.id == arg:
					return true
			return false
		_:
			return _events.has(cond)


func find_attraction(kind: String) -> Attraction:
	if _sim == null:
		return null
	for a: Attraction in _sim.attractions:
		if a.def != null and (a.def.kind == kind or a.def.id == kind):
			return a
	return null


## Verdenscelle for pilen ved det aktuelle trins highlight (Vector2i(-1,-1) = ingen pil).
func arrow_cell() -> Vector2i:
	var hl: String = str(current_step().get("highlight", ""))
	if hl == "entrance" and _sim != null:
		return _sim.world.entrance
	if hl.begins_with("attraction:"):
		var a: Attraction = find_attraction(hl.substr(11))
		if a != null:
			return a.origin
	return Vector2i(-1, -1)


func _enter(i: int) -> void:
	index = i
	_events.clear()
	_prices.clear()
	if _sim != null:
		for a: Attraction in _sim.attractions:
			_prices[a.id] = a.price
	if active():
		step_changed.emit(index, current_step())
	else:
		finished.emit(false)
