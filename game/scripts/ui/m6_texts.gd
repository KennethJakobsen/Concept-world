class_name M6Texts
extends RefCounted
## Danske tekster til M6 B/D/E (T-089): tanker, ting, økonomikategorier. Kun glyffer fra standardfonten.

const THOUGHTS: Dictionary = {
	"too_intense": "Den er for vild for mig!",
	"too_tame": "Den er for tam for mig.",
	"vomit": "Jeg kastede op...",
	"balloon_lost": "Åh nej, min ballon fløj væk!",
}
const ITEM_NAMES: Dictionary = {
	"balloon": "Ballon",
	"souvenir": "Souvenir",
	"prize_duck": "Præmie-and",
	"prize_bear": "Præmie-bamse",
}
const CATEGORY_NAMES: Dictionary = {
	"entry": "Entré", "tickets": "Billetter", "build": "Byggeri", "path": "Stier", "decor": "Pynt",
	"refund": "Refusion", "running": "Drift", "wages": "Løn", "repairs": "Reparationer",
	"research": "Forskning", "prizes": "Præmier",
}
const WARN_VOMIT: String = "En gæst kastede op - byg færre vilde forlystelser tæt på stierne."


## Kode → dansk tekst; ukendte (allerede danske) tanker returneres uændret.
static func thought_text(t: String) -> String:
	return String(THOUGHTS.get(t, t))


static func item_name(id: String) -> String:
	return String(ITEM_NAMES.get(id, id))


static func category_name(c: String) -> String:
	return String(CATEGORY_NAMES.get(c, c))


## 0..100 → "x.y/10"
static func rating10(v: float) -> String:
	return "%.1f/10" % (clampf(v, 0.0, 100.0) / 10.0)


static func sideshow_lines(st: Dictionary) -> Array[String]:
	return [
		"Gevinstchance: %d%%" % roundi(float(st.get("win_chance", 0.0)) * 100.0),
		"Præmier vundet: %d" % int(st.get("prizes_won", 0)),
		"Præmieudgift: $%d" % int(st.get("prize_cost_total", 0)),
	]
