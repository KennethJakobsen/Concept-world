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
const TRACK_ERRORS: Dictionary = {
	"wrong_system": "Det stykke passer ikke til denne slags bane.",
	"too_low": "Sporet ligger for lavt - hæv det over stier og jorden.",
	"incomplete": "Banen er ikke færdig - den skal nå frem til endestationen.",
	"exit_blocked": "Endestationens indgang er blokeret.",
	"stations_too_close": "Stationerne ligger for tæt på hinanden.",
	"multiple_stations": "Banen har for mange stationer.",
	"closed": "Banen er allerede færdig.",
	"no_active_track": "Vælg den ufærdige bane og tryk 'Fortsæt byg'.",
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


## Fejlkode fra sporbygning → dansk tekst (M6-koder, ellers M5-teksterne).
static func track_error(code: String) -> String:
	if TRACK_ERRORS.has(code):
		return String(TRACK_ERRORS[code])
	return M5Texts.coaster_error(code)


## Info-linjer pr. sporsystem: plask (tømmerrende), passagerer pr. dag (svævebane).
static func track_lines(a: Attraction, stats: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if a.track == null:
		return out
	var sys: StringName = a.track.system
	if sys == &"flume":
		out.append("Plask: %d" % int(stats.get("splashes", 0)))
	elif sys == &"monorail":
		out.append("Passagerer i dag: %d" % int(stats.get("riders_today", 0)))
	if a.building and not a.track.is_complete():
		out.append("Banen er ikke færdig")
	return out
