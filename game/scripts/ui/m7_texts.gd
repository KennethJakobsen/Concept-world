class_name M7Texts
extends RefCounted
## Danske tekster til M7 (T-113): nye tanker, milepæle, overlays. Kun glyffer fra standardfonten.
## Sim gemmer tanker som danske strenge (ParkSim.M7_THOUGHTS); koderne slås også op her, så UI'et
## virker, hvis sim'en en dag gemmer koden i stedet.

const THOUGHTS: Dictionary = {
	"too_much": "Det var lige i overkanten.",
	"queue_too_long": "Køen er alt for lang!",
	"queue_bored": "Det tager for lang tid!",
	"queue_gave_up": "Jeg gider ikke vente mere.",
	"crowded": "Her er alt for mange mennesker!",
	"tired": "Jeg er træt.",
	"no_money": "Jeg har ikke flere penge.",
	"unhappy": "Jeg keder mig her.",
	"dark": "Her er mørkt.",
}
const OVERLAY_NAMES: Dictionary = {
	"happiness": "Glæde", "litter": "Skrald", "queue": "Kø og trængsel",
	"coverage": "Personale-dækning", "light": "Lys",
}
const CATEGORY_NAMES: Dictionary = {"supplies": "Råvarer", "atm_fees": "Hæveautomat-gebyr"}


## Kode → dansk tekst. Sim'ens egne (danske) tekster og M6-koder håndteres også.
static func thought_text(t: String) -> String:
	if THOUGHTS.has(t):
		return String(THOUGHTS[t])
	if ParkSim.M7_THOUGHTS.has(t):
		return String(ParkSim.M7_THOUGHTS[t])
	return M6Texts.thought_text(t)


static func overlay_name(kind: StringName) -> String:
	return String(OVERLAY_NAMES.get(String(kind), String(kind)))


static func reward_text(reward: Dictionary, sim: ParkSim = null) -> String:
	var parts: Array[String] = []
	if reward.has("unlock_topic"):
		parts.append("Åbner forskning: " + topic_name(str(reward["unlock_topic"]), sim))
	if reward.has("research_points"):
		parts.append("+%d forskningspoint" % int(reward["research_points"]))
	if reward.has("money"):
		parts.append("+$%d" % int(reward["money"]))
	if reward.has("reputation"):
		parts.append("+%d omdømme" % int(reward["reputation"]))
	return ", ".join(parts)


static func topic_name(id: String, sim: ParkSim = null) -> String:
	if sim != null and sim.research != null and sim.research.def != null:
		for tp: Dictionary in sim.research.def.topics:
			if str(tp.get("id", "")) == id:
				return str(tp.get("name", id))
	return id.replace("_", " ").capitalize()


static func milestone_name(sim: ParkSim, id: String) -> String:
	if sim != null:
		for m: Dictionary in sim.milestones():
			if str(m["id"]) == id:
				return str(m["name"])
	return id


static func achieved_text(name: String) -> String:
	return "Milepæl nået: %s!" % name


static func locked_text(milestone: String) -> String:
	return "Låst - kræver milepælen '%s'" % milestone
