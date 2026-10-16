class_name Milestones
extends RefCounted
## Milepælstilstand (ejes af ParkSim.milestones, T-105). ParkSim måler betingelserne, udbetaler
## belønninger og udsender signaler; her ligger kun data og fremskridt.

const PATH: String = "res://content/milestones.json"

var defs: Array[MilestoneDef] = []
var achieved: Array[String] = []
## Sand for migrerede saves: evaluér beregnelige betingelser ved første tick (uden belønning).
var backfill: bool = false
## Antal sammenhængende rene dage (days_clean).
var days_clean: int = 0
## Maks. affald i parken ved dagens slutning, for at dagen tæller som ren.
var clean_max_litter: int = 10


static func load_default() -> Milestones:
	var m := Milestones.new()
	if FileAccess.file_exists(PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if d is Dictionary:
			m.load_defs(d)
	return m


func load_defs(d: Dictionary) -> void:
	defs.clear()
	clean_max_litter = maxi(0, int(d.get("clean_max_litter", clean_max_litter)))
	for e: Variant in d.get("milestones", []):
		if e is Dictionary and str(e.get("id", "")) != "":
			defs.append(MilestoneDef.from_dict(e))


func get_def(id: String) -> MilestoneDef:
	for m in defs:
		if m.id == id:
			return m
	return null


func is_achieved(id: String) -> bool:
	return achieved.has(id)


func mark(id: String) -> void:
	if not achieved.has(id):
		achieved.append(id)


## Emner der låses op af en milepæl (og derfor er låst, indtil den er nået).
func gated_topics() -> Dictionary:
	var out: Dictionary = {}
	for m in defs:
		if m.unlock_topic() != "":
			out[m.unlock_topic()] = m.id
	return out


## Milepælen der åbner emnet ("" hvis ingen).
func milestone_for_topic(topic_id: String) -> String:
	return str(gated_topics().get(topic_id, ""))
