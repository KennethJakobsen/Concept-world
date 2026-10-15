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


static func from_dict(d: Dictionary) -> TrackPieceDef:
	var p := TrackPieceDef.new()
	p.id = str(d.get("id", ""))
	p.name = str(d.get("name", p.id))
	p.cost = int(d.get("cost", 0))
	p.length = float(d.get("length", 1.0))
	p.turn = clampi(int(d.get("turn", 0)), -1, 1)
	p.rise = clampi(int(d.get("rise", 0)), -1, 1)
	p.kind = str(d.get("kind", "track"))
	p.friction = float(d.get("friction", -1.0))
	p.lift_speed = float(d.get("lift_speed", -1.0))
	return p


## Vandret længde (m) – samme som CoasterTrackMesh._horiz_len.
func horizontal_length() -> float:
	return PI * 0.25 if turn != 0 else 1.0
