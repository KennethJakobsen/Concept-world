class_name M5Texts
extends RefCounted
## Danske tekster til M5 (mål, rutsjebane-fejl, forskning). Kun glyffer fra standardfonten.

const OBJECTIVE_NAMES: Dictionary = {
	"guests_in_park": "Gæster i parken",
	"reputation_min": "Omdømme",
	"money_min": "Penge",
	"park_value_min": "Parkværdi",
	"rides_count_min": "Forlystelser",
	"coaster_excitement_min": "Rutsjebane-spænding",
}
const LOSE_NAMES: Dictionary = {
	"money_below": "Penge under $%d i %d dage",
	"reputation_below": "Omdømme under %d i %d dage",
}
const COASTER_ERRORS: Dictionary = {
	"no_station": "Banen mangler en station.",
	"multiple_stations": "Banen må kun have én station.",
	"not_closed": "Banen er ikke lukket - den skal ende ved stationen.",
	"too_high": "Banen er for høj.",
	"below_ground": "Banen går under jorden.",
	"collision": "Banen støder ind i noget.",
	"too_slow": "Toget kan ikke gennemføre turen - tilføj en kædelift.",
	"no_money": "Ikke nok penge.",
	"locked": "Kræver forskning.",
}
const REASONS: Dictionary = {
	"deadline": "Tiden løb ud.",
	"money_below": "Parken løb tør for penge.",
	"reputation_below": "Omdømmet blev for dårligt.",
}
const LOCKED_TOOLTIP: String = "Kræver forskning"


static func objective_name(type: String) -> String:
	return String(OBJECTIVE_NAMES.get(type, type))


static func fmt_value(type: String, v: float) -> String:
	match type:
		"money_min", "park_value_min":
			return "$%d" % int(v)
		"coaster_excitement_min":
			return "%.1f" % v
	return "%d" % int(v)


## "Gæster i parken: 120/300"
static func objective_line(o: Dictionary) -> String:
	var t: String = str(o.get("type", ""))
	return "%s: %s/%s" % [objective_name(t), fmt_value(t, float(o.get("current", 0.0))),
		fmt_value(t, float(o.get("value", 0.0)))]


static func goal_line(o: Dictionary) -> String:
	var t: String = str(o.get("type", ""))
	return "%s: %s" % [objective_name(t), fmt_value(t, float(o.get("value", 0.0)))]


static func lose_line(l: Dictionary) -> String:
	var t: String = str(l.get("type", ""))
	if LOSE_NAMES.has(t):
		return String(LOSE_NAMES[t]) % [int(l.get("value", 0)), int(l.get("days", 1))]
	return t


static func coaster_error(code: String) -> String:
	return String(COASTER_ERRORS.get(code, "Fejl: " + code))


static func reason_text(reason: String) -> String:
	return String(REASONS.get(reason, reason))


static func day_line(status: Dictionary) -> String:
	var dl: int = int(status.get("deadline_days", 0))
	var d: int = int(status.get("days_elapsed", 0))
	return "Dag %d/%d" % [d, dl] if dl > 0 else "Dag %d (ingen frist)" % d


## Navn på et forsknings-item (attraktion, decor eller banestykke).
static func item_name(id: String) -> String:
	if id == "":
		return "Intet"
	for path: String in ["res://content/attractions/%s.json" % id, "res://content/decor/%s.json" % id]:
		if FileAccess.file_exists(path):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if d is Dictionary and (d as Dictionary).has("name"):
				return str(d["name"])
	var p: TrackPieceDef = CoasterContent.piece(id)
	if p != null and p.name != "":
		return "Bane: " + p.name
	return id
