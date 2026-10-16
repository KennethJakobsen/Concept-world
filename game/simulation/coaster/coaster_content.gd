class_name CoasterContent
extends RefCounted
## Indlæser og cacher spor-content (ADR-004): content/coaster/*.json (system "coaster")
## og content/tracks/<system>.json (flume, train, monorail, ...), tog og ratings-vægte.

const PIECES_PATH: String = "res://content/coaster/pieces.json"
const TRAINS_PATH: String = "res://content/coaster/trains.json"
const RATINGS_PATH: String = "res://content/coaster/ratings.json"
const TRACKS_DIR: String = "res://content/tracks/"

const KNOWN_TRACK_FILES: Array[String] = ["flume.json", "monorail.json", "train.json"]
const SYSTEM_COASTER: StringName = &"coaster"
## Attraktions-kind → sporsystem.
const KIND_SYSTEM: Dictionary = {
	"coaster": &"coaster", "flume": &"flume", "train": &"train", "transport": &"monorail",
}
## Default systemdefinition (rutsjebanen har ingen system-fil).
const DEFAULT_SYSTEM: Dictionary = {
	"closed_loop": true, "max_stations": 1, "clearance_levels": 2, "speed_mode": "physics",
}

static var _pieces: Dictionary = {}  ## system -> {id -> TrackPieceDef}
static var _systems: Dictionary = {}  ## system -> Dictionary
static var _trains: Dictionary = {}
static var _ratings: Dictionary = {}
static var _loaded: bool = false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	_pieces[SYSTEM_COASTER] = {}
	_systems[SYSTEM_COASTER] = DEFAULT_SYSTEM.duplicate()
	var pl: Variant = JSON.parse_string(FileAccess.get_file_as_string(PIECES_PATH))
	if pl is Array:
		_add_pieces(pl, SYSTEM_COASTER)
	# Kendte filer (web-eksport kan ikke altid liste res://) + evt. flere fra mappen.
	var files: Array = KNOWN_TRACK_FILES.duplicate()
	var da := DirAccess.open(TRACKS_DIR)
	if da != null:
		for f: String in da.get_files():
			if f.ends_with(".json") and not files.has(f):
				files.append(f)
	files.sort()
	for f: String in files:
		if not FileAccess.file_exists(TRACKS_DIR + f):
			continue
		var sys := StringName(f.get_basename())
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(TRACKS_DIR + f))
		if not data is Dictionary:
			continue
		var cfg: Dictionary = DEFAULT_SYSTEM.duplicate()
		var sd: Variant = (data as Dictionary).get("system", {})
		if sd is Dictionary:
			for k: Variant in sd:
				cfg[str(k)] = sd[k]
		_systems[sys] = cfg
		if not _pieces.has(sys):
			_pieces[sys] = {}
		var arr: Variant = (data as Dictionary).get("pieces", [])
		if arr is Array:
			_add_pieces(arr, sys)
	var tl: Variant = JSON.parse_string(FileAccess.get_file_as_string(TRAINS_PATH))
	if tl is Array:
		for e: Variant in tl:
			if e is Dictionary:
				_trains[str(e.get("id", ""))] = e
	var r: Variant = JSON.parse_string(FileAccess.get_file_as_string(RATINGS_PATH))
	if r is Dictionary:
		_ratings = r


static func _add_pieces(arr: Array, sys: StringName) -> void:
	for e: Variant in arr:
		if e is Dictionary:
			var d: Dictionary = e
			if not d.has("system"):
				d = d.duplicate()
				d["system"] = String(sys)
			var p := TrackPieceDef.from_dict(d)
			if not _pieces.has(p.system):
				_pieces[p.system] = {}
			_pieces[p.system][p.id] = p


## id -> TrackPieceDef for ét system (default rutsjebanen).
static func pieces(system: StringName = SYSTEM_COASTER) -> Dictionary:
	_load()
	return _pieces.get(system, {})


## Opslag på tværs af alle systemer.
static func piece(id: String) -> TrackPieceDef:
	_load()
	var syss: Array = _pieces.keys()
	syss.sort()
	for s: StringName in syss:
		if (_pieces[s] as Dictionary).has(id):
			return _pieces[s][id]
	return null


## Alle kendte systemer (sorteret).
static func systems() -> Array[StringName]:
	_load()
	var out: Array[StringName] = []
	for s: StringName in _pieces.keys():
		out.append(s)
	out.sort()
	return out


## Systemdefinition {closed_loop, max_stations, clearance_levels, speed_mode}.
static func system_def(system: StringName) -> Dictionary:
	_load()
	return _systems.get(system, DEFAULT_SYSTEM)


## Sporsystem for en attraktions-kind (&"" hvis kind ikke er sporbaseret).
static func system_for_kind(kind: String) -> StringName:
	return KIND_SYSTEM.get(kind, &"")


static func is_tracked_kind(kind: String) -> bool:
	return KIND_SYSTEM.has(kind)


static func train(id: String) -> Dictionary:
	_load()
	return _trains.get(id, {"cars": 3, "seats_per_car": 4, "friction": 0.02, "station_speed": 2.0, "lift_speed": 2.5})


static func ratings() -> Dictionary:
	_load()
	return _ratings


## Første stykke af kind "station" i systemet med rollen role ("" accepterer "" og "start").
static func station_id(system: StringName = SYSTEM_COASTER, role: String = "") -> String:
	_load()
	var ps: Dictionary = pieces(system)
	var ids: Array = ps.keys()
	ids.sort()
	for id: String in ids:
		var d: TrackPieceDef = ps[id]
		if d.kind != "station":
			continue
		if role == "" and (d.station_role == "" or d.station_role == "start"):
			return id
		if role != "" and d.station_role == role:
			return id
	return "coaster_station" if system == SYSTEM_COASTER else ""
