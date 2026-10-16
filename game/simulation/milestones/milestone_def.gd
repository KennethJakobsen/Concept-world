class_name MilestoneDef
extends Resource
## En milepæl (content/milestones.json, T-105). Én betingelse {nøgle: værdi} og en belønning
## {research_points?, unlock_topic?, money?}.

const CONDITIONS: Array[String] = ["total_guests", "rides_open", "reputation", "coaster_built",
	"total_revenue", "days_clean"]
## Kan beregnes fra state (backfill ved load af gamle saves).
const BACKFILLABLE: Array[String] = ["total_guests", "rides_open", "reputation", "coaster_built", "total_revenue"]

@export var id: String = ""
@export var name: String = ""
@export var condition: String = ""
@export var target: float = 1.0
@export var reward: Dictionary = {}


static func from_dict(d: Dictionary) -> MilestoneDef:
	var r := MilestoneDef.new()
	r.id = str(d.get("id", ""))
	r.name = str(d.get("name", r.id))
	var c: Variant = d.get("condition", {})
	if c is Dictionary and not (c as Dictionary).is_empty():
		var k: Variant = (c as Dictionary).keys()[0]
		r.condition = str(k)
		var v: Variant = c[k]
		r.target = (1.0 if v else 0.0) if v is bool else maxf(0.0, float(v))
	var rw: Variant = d.get("reward", {})
	if rw is Dictionary:
		r.reward = (rw as Dictionary).duplicate(true)
	return r


func unlock_topic() -> String:
	return str(reward.get("unlock_topic", ""))


func is_backfillable() -> bool:
	return BACKFILLABLE.has(condition)
