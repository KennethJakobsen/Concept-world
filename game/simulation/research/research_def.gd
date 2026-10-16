class_name ResearchDef
extends Resource
## Statiske forskningsdata (content/research.json). Mangler filen, bruges kontraktens defaults.

const PATH: String = "res://content/research.json"
const DEFAULT_COST_PER_LEVEL: Array[int] = [0, 500, 1000, 2000]
const DEFAULT_START_UNLOCKED: Array[String] = [
	"carousel", "burger_stand", "drinks_stand", "toilet", "bench", "bin", "lamp",
	"tree_round", "coaster_station", "track_straight",
]

@export var points_per_day_base: float = 10.0
@export var cost_per_level: Array[int] = DEFAULT_COST_PER_LEVEL.duplicate()
## [{id, name, unlocks: Array}]
@export var topics: Array[Dictionary] = []
## [{id, topic, points}] i forskningsrækkefølge
@export var items: Array[Dictionary] = []
@export var start_unlocked: Array[String] = DEFAULT_START_UNLOCKED.duplicate()
## M7 (T-105): emner der er åbne fra start; øvrige emner, som en milepæl låser op, er låst indtil da.
@export var start_topics: Array[String] = []


static func load_default() -> ResearchDef:
	if not FileAccess.file_exists(PATH):
		return ResearchDef.new()
	var txt: String = FileAccess.get_file_as_string(PATH)
	var d: Variant = JSON.parse_string(txt)
	if not d is Dictionary:
		return ResearchDef.new()
	return from_dict(d)


static func from_dict(d: Dictionary) -> ResearchDef:
	var r := ResearchDef.new()
	r.points_per_day_base = float(d.get("points_per_day_base", r.points_per_day_base))
	if d.get("cost_per_level") is Array:
		r.cost_per_level.clear()
		for c: Variant in d["cost_per_level"]:
			r.cost_per_level.append(int(c))
	for t: Variant in d.get("topics", []):
		if t is Dictionary:
			var unl: Array[String] = []
			for u: Variant in t.get("unlocks", []):
				unl.append(str(u))
			r.topics.append({"id": str(t.get("id", "")), "name": str(t.get("name", "")), "unlocks": unl})
	for it: Variant in d.get("items", []):
		if it is Dictionary:
			r.items.append({"id": str(it.get("id", "")), "topic": str(it.get("topic", "")),
				"points": float(it.get("points", 0.0))})
	if d.get("start_unlocked") is Array:
		r.start_unlocked.clear()
		for s: Variant in d["start_unlocked"]:
			r.start_unlocked.append(str(s))
	if d.get("start_topics") is Array:
		for t: Variant in d["start_topics"]:
			r.start_topics.append(str(t))
	return r


func max_level() -> int:
	return cost_per_level.size() - 1


func cost_for(level: int) -> int:
	if level < 0 or level >= cost_per_level.size():
		return 0
	return cost_per_level[level]


func has_topic(topic_id: String) -> bool:
	for t in topics:
		if t["id"] == topic_id:
			return true
	return false


func item(item_id: String) -> Dictionary:
	for it in items:
		if it["id"] == item_id:
			return it
	return {}


## Alle id'er nævnt i filen (items, topics.unlocks, start_unlocked).
func all_ids() -> Array[String]:
	var out: Array[String] = []
	for s in start_unlocked:
		if not out.has(s):
			out.append(s)
	for it in items:
		if not out.has(it["id"]):
			out.append(it["id"])
	for t in topics:
		for u: String in t["unlocks"]:
			if not out.has(u):
				out.append(u)
	return out
