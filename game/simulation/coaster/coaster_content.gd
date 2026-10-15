class_name CoasterContent
extends RefCounted
## Indlæser og cacher content/coaster/*.json (stykker, tog, ratings-vægte).

const PIECES_PATH: String = "res://content/coaster/pieces.json"
const TRAINS_PATH: String = "res://content/coaster/trains.json"
const RATINGS_PATH: String = "res://content/coaster/ratings.json"

static var _pieces: Dictionary = {}
static var _trains: Dictionary = {}
static var _ratings: Dictionary = {}
static var _loaded: bool = false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var pl: Variant = JSON.parse_string(FileAccess.get_file_as_string(PIECES_PATH))
	if pl is Array:
		for e: Variant in pl:
			if e is Dictionary:
				var p := TrackPieceDef.from_dict(e)
				_pieces[p.id] = p
	var tl: Variant = JSON.parse_string(FileAccess.get_file_as_string(TRAINS_PATH))
	if tl is Array:
		for e: Variant in tl:
			if e is Dictionary:
				_trains[str(e.get("id", ""))] = e
	var r: Variant = JSON.parse_string(FileAccess.get_file_as_string(RATINGS_PATH))
	if r is Dictionary:
		_ratings = r


## id -> TrackPieceDef
static func pieces() -> Dictionary:
	_load()
	return _pieces


static func piece(id: String) -> TrackPieceDef:
	_load()
	return _pieces.get(id, null)


static func train(id: String) -> Dictionary:
	_load()
	return _trains.get(id, {"cars": 3, "seats_per_car": 4, "friction": 0.02, "station_speed": 2.0, "lift_speed": 2.5})


static func ratings() -> Dictionary:
	_load()
	return _ratings


## Første stykke af kind "station".
static func station_id() -> String:
	_load()
	var ids: Array = _pieces.keys()
	ids.sort()
	for id: String in ids:
		if (_pieces[id] as TrackPieceDef).kind == "station":
			return id
	return "coaster_station"
