class_name Research
extends RefCounted
## Forskningstilstand (ejes af ParkSim.research). Ren logik; ParkSim bogfører og udsender signaler.

var def: ResearchDef
var enabled: bool = false
var unlocked: Dictionary = {}  ## id -> true
var funding_level: int = 0
var current_item: String = ""
var progress: float = 0.0
var priority: String = ""
## M7 (T-105): emner låst af milepæle (topic_id -> true). Sættes af ParkSim; gemmes ikke.
var locked_topics: Dictionary = {}


func _init(p_def: ResearchDef = null) -> void:
	def = p_def if p_def != null else ResearchDef.load_default()


## Nulstiller til start-ulåste og vælger første item.
func setup(p_enabled: bool, extra_unlocked: Array = []) -> void:
	enabled = p_enabled
	unlocked = {}
	for s in def.start_unlocked:
		unlocked[s] = true
	for s: Variant in extra_unlocked:
		unlocked[str(s)] = true
	progress = 0.0
	current_item = ""
	pick_next()


func is_unlocked(id: String) -> bool:
	return not enabled or unlocked.has(id)


func set_funding(level: int) -> bool:
	if level < 0 or level > def.max_level():
		return false
	funding_level = level
	return true


func set_priority(topic_id: String) -> bool:
	if topic_id != "" and (not def.has_topic(topic_id) or locked_topics.has(topic_id)):
		return false
	priority = topic_id
	if progress <= 0.0:
		pick_next()  # skift kun før der er brugt point på nuværende item
	return true


## Første ulåste item i prioriteret emne, ellers første ulåste.
func pick_next() -> void:
	current_item = ""
	var fallback: String = ""
	for it in def.items:
		var id: String = it["id"]
		if unlocked.has(id) or locked_topics.has(str(it["topic"])):
			continue
		if priority != "" and it["topic"] == priority:
			current_item = id
			return
		if fallback == "":
			fallback = id
	current_item = fallback


## Sætter låste emner. Peger nuværende item på et låst emne (uden brugte point), vælges et nyt.
func set_locked_topics(topics: Dictionary) -> void:
	locked_topics = topics
	if locked_topics.has(priority):
		priority = ""
	var cur_topic: String = str(def.item(current_item).get("topic", "")) if current_item != "" else ""
	if current_item == "" or (progress <= 0.0 and locked_topics.has(cur_topic)):
		pick_next()


## Ekstra forskningspoint (milepælsbelønning). Returnerer de ulåste id'er.
func add_points(points: float) -> Array[String]:
	var done: Array[String] = []
	if not enabled or current_item == "" or points <= 0.0:
		return done
	progress += points
	while current_item != "" and progress >= points_needed():
		progress -= points_needed()
		unlocked[current_item] = true
		done.append(current_item)
		pick_next()
	if current_item == "":
		progress = 0.0
	return done


func points_needed() -> float:
	return float(def.item(current_item).get("points", 0.0)) if current_item != "" else 0.0


func daily_cost() -> int:
	return def.cost_for(funding_level) if enabled else 0


## Én dags forskning. Returnerer de ulåste id'er (normalt 0 eller 1).
func advance_day() -> Array[String]:
	var done: Array[String] = []
	if not enabled or current_item == "" or funding_level <= 0:
		return done
	progress += def.points_per_day_base * funding_level
	while current_item != "" and progress >= points_needed():
		progress -= points_needed()
		unlocked[current_item] = true
		done.append(current_item)
		pick_next()
	if current_item == "":
		progress = 0.0
	return done


func unlocked_list() -> Array[String]:
	var out: Array[String] = []
	for k: Variant in unlocked.keys():
		out.append(str(k))
	out.sort()
	return out


func status() -> Dictionary:
	return {
		"enabled": enabled, "funding_level": funding_level, "current_item": current_item,
		"progress": progress, "points_needed": points_needed(), "priority": priority,
		"unlocked": unlocked_list(),
	}


func to_save() -> Dictionary:
	return {
		"enabled": enabled, "unlocked": unlocked_list(), "funding_level": funding_level,
		"current_item": current_item, "progress": SaveCodec.f(progress), "priority": priority,
	}


## Tom dict (v1-migration) => disabled, alt låst op.
func load_save(d: Dictionary) -> void:
	enabled = bool(d.get("enabled", false))
	unlocked = {}
	for s: Variant in d.get("unlocked", []):
		unlocked[str(s)] = true
	funding_level = clampi(int(d.get("funding_level", 0)), 0, maxi(0, def.max_level()))
	current_item = str(d.get("current_item", ""))
	progress = SaveCodec.to_f(d.get("progress"), 0.0)
	priority = str(d.get("priority", ""))
