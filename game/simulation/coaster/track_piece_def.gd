class_name TrackPieceDef
extends Resource
## Statiske data for et banestykke (content/coaster/pieces.json).

@export var id: String = ""
@export var name: String = ""
@export var cost: int = 0
@export var length: float = 1.0  ## buelængde (m)
@export var turn: int = 0  ## -1 venstre, 0 lige, 1 højre (90° inden for cellen)
@export var rise: int = 0  ## niveauer
@export var kind: String = "track"  ## track | station | lift
@export var friction: float = -1.0  ## < 0 = togets friktion
@export var lift_speed: float = -1.0  ## < 0 = togets lift_speed
## ADR-004 (T-090): sporsystem og systemspecifikke felter (alle med default).
@export var system: StringName = &"coaster"
@export var splash: bool = false
@export var water: bool = false
@export var min_level: int = 0
@export var max_level: int = -1  ## < 0 = ingen grænse ud over attraktionens max_height
@export var station_role: String = ""  ## "" | "start" | "end"
@export var allow_rise: bool = true
@export var allow_turn: bool = true


static func from_dict(d: Dictionary) -> TrackPieceDef:
	var p := TrackPieceDef.new()
	p.id = str(d.get("id", ""))
	p.name = str(d.get("name", p.id))
	p.cost = int(d.get("cost", 0))
	p.length = float(d.get("length", 1.0))
	p.turn = clampi(int(d.get("turn", 0)), -1, 1)
	p.rise = clampi(int(d.get("rise", 0)), -2, 2)
	p.kind = str(d.get("kind", "track"))
	p.friction = float(d.get("friction", -1.0))
	p.lift_speed = float(d.get("lift_speed", -1.0))
	p.system = StringName(str(d.get("system", "coaster")))
	p.splash = bool(d.get("splash", false))
	p.water = bool(d.get("water", false))
	p.min_level = int(d.get("min_level", 0))
	p.max_level = int(d.get("max_level", -1))
	p.station_role = str(d.get("station_role", ""))
	p.allow_rise = bool(d.get("allow_rise", true))
	p.allow_turn = bool(d.get("allow_turn", true))
	return p


## Vandret længde (m) – samme som CoasterTrackMesh._horiz_len.
func horizontal_length() -> float:
	return PI * 0.25 if turn != 0 else 1.0
