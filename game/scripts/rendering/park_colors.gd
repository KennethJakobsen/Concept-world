class_name ParkColors
extends RefCounted
## (Kontraktens "ColorPalette" – omdøbt, fordi Godot har en indbygget klasse med det navn.)
## T-109: fælles farver for ghosts, overlays og UI. Overlays bruger altid viridis (farveblind-sikker).
## Gyldig/ugyldig: grøn/rød normalt, blå/orange i farveblind-tilstand (+ form-signal ✓/✗ i CellHighlight).
## Tilstanden læses fra UserSettings ([accessibility] colorblind) via `refresh_from_settings()`
## eller sættes direkte med `set_colorblind()` (fx når UI'ets indstilling ændres).

const VIRIDIS: Array[Color] = [
	Color(0.267, 0.005, 0.329), Color(0.229, 0.322, 0.546), Color(0.128, 0.567, 0.551),
	Color(0.369, 0.789, 0.383), Color(0.993, 0.906, 0.144)]
const VALID_NORMAL := Color(0.3, 0.9, 0.35)
const INVALID_NORMAL := Color(0.95, 0.25, 0.2)
const VALID_CB := Color(0.0, 0.45, 0.85)  # blå
const INVALID_CB := Color(0.95, 0.55, 0.0)  # orange
const OVERLAY_KINDS: Array[StringName] = [&"happiness", &"litter", &"queue", &"coverage", &"light"]

static var colorblind: bool = false


static func set_colorblind(on: bool) -> void:
	colorblind = on


static func refresh_from_settings(path: String = UserSettings.PATH) -> void:
	colorblind = UserSettings.load_from(path).colorblind


static func valid(alpha: float = 1.0) -> Color:
	var c := VALID_CB if colorblind else VALID_NORMAL
	c.a = alpha
	return c


static func invalid(alpha: float = 1.0) -> Color:
	var c := INVALID_CB if colorblind else INVALID_NORMAL
	c.a = alpha
	return c


static func ghost(ok: bool, alpha: float = 0.45) -> Color:
	return valid(alpha) if ok else invalid(alpha)


## t i 0..1 → viridis (mørk lilla → gul).
static func viridis(t: float) -> Color:
	t = clampf(t, 0.0, 1.0) * (VIRIDIS.size() - 1)
	var i := mini(int(t), VIRIDIS.size() - 2)
	return VIRIDIS[i].lerp(VIRIDIS[i + 1], t - i)


## Overlay-farve. `value` er altid 0..1 hvor 1 = "godt" (glæde, dækning, lys) eller
## "meget" (skrald, kø). Vi vender skalaen for skrald/kø, så gul altid betyder godt.
static func overlay_color(kind: StringName, value: float) -> Color:
	match kind:
		&"litter", &"queue":
			return viridis(1.0 - value)
		_:
			return viridis(value)


## Legende til UI (T-113): [{color: Color, label: String}], fra dårligt til godt.
static func legend(kind: StringName) -> Array[Dictionary]:
	var labels: Array = []
	match kind:
		&"happiness": labels = ["Sur", "Neutral", "Glad"]
		&"litter": labels = ["Meget skrald", "Lidt", "Rent"]
		&"queue": labels = ["Fuld kø/trængsel", "Halv", "Tom"]
		&"coverage": labels = ["Ingen dækning", "Delvis", "Dækket"]
		&"light": labels = ["Mørkt", "Dæmpet", "Oplyst"]
		_: labels = ["Lav", "Mellem", "Høj"]
	var out: Array[Dictionary] = []
	for i in labels.size():
		out.append({"color": viridis(float(i) / (labels.size() - 1)), "label": String(labels[i])})
	return out
