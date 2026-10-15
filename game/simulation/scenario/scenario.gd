class_name Scenario
extends RefCounted
## Kørende scenarie-tilstand (T-067). Ejes af ParkSim.scenario (null = sandbox).
## Evalueringen er ren: ParkSim leverer målte værdier, Scenario afgør state.

const RUNNING: StringName = &"running"
const WON: StringName = &"won"
const LOST: StringName = &"lost"

var def_id: String = ""
var def: ScenarioDef  ## kan være null efter load, hvis filen er væk (så evalueres intet)
var state: StringName = RUNNING
var days_elapsed: int = 0
var lose_streaks: Dictionary = {}  ## str(indeks i def.lose) -> int
var reason: String = ""


func _init(p_def: ScenarioDef = null) -> void:
	def = p_def
	if def != null:
		def_id = def.id


func is_running() -> bool:
	return state == RUNNING


## measure: Callable(type: String) -> float. Returnerer "" (intet sket), "won" eller lose-reason.
## Kaldes én gang pr. afsluttet dag.
func evaluate_day(measure: Callable) -> String:
	if state != RUNNING or def == null:
		return ""
	days_elapsed += 1
	# Streaks opdateres altid, så de er korrekte selv om sejr indtræffer.
	var lost_reason: String = ""
	for i in def.lose.size():
		var l: Dictionary = def.lose[i]
		var key: String = str(i)
		var cur: float = measure.call(_lose_measure(l["type"]))
		if cur < float(l["value"]):
			lose_streaks[key] = int(lose_streaks.get(key, 0)) + 1
		else:
			lose_streaks[key] = 0
		if lost_reason == "" and int(lose_streaks[key]) >= int(l["days"]):
			lost_reason = str(l["type"])
	if not def.objectives.is_empty() and all_met(measure):
		state = WON
		reason = "objectives"
		return "won"
	if lost_reason == "" and def.deadline_days > 0 and days_elapsed >= def.deadline_days:
		lost_reason = "deadline"
	if lost_reason != "":
		state = LOST
		reason = lost_reason
		return lost_reason
	return ""


static func _lose_measure(t: String) -> String:
	match t:
		"money_below":
			return "money_min"
		"reputation_below":
			return "reputation_min"
	return t


func all_met(measure: Callable) -> bool:
	for o in def.objectives:
		if not is_met(o, measure.call(o["type"])):
			return false
	return true


static func is_met(o: Dictionary, current: float) -> bool:
	return current >= float(o["value"])


func to_save() -> Dictionary:
	return {"def_id": def_id, "state": String(state), "days_elapsed": days_elapsed,
		"lose_streaks": lose_streaks.duplicate(), "reason": reason}


static func from_save(d: Dictionary, p_def: ScenarioDef) -> Scenario:
	var s := Scenario.new(p_def)
	s.def_id = str(d.get("def_id", s.def_id))
	var st: String = str(d.get("state", "running"))
	s.state = WON if st == "won" else (LOST if st == "lost" else RUNNING)
	s.days_elapsed = int(d.get("days_elapsed", 0))
	s.reason = str(d.get("reason", ""))
	var ls: Variant = d.get("lose_streaks", {})
	if ls is Dictionary:
		for k: Variant in ls:
			s.lose_streaks[str(k)] = int(ls[k])
	return s
