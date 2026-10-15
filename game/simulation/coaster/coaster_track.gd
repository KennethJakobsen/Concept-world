class_name CoasterTrack
extends RefCounted
## Ordnet liste af banestykker. Stykke 0 er stationen.

var pieces: Array[TrackPiece] = []
var defs: Dictionary = {}  ## id -> TrackPieceDef
var max_height: int = 8


func _init(p_defs: Dictionary = {}, p_max_height: int = 8) -> void:
	defs = p_defs if not p_defs.is_empty() else CoasterContent.pieces()
	max_height = p_max_height


func def_of(p: TrackPiece) -> TrackPieceDef:
	return defs.get(p.def_id, null)


## Hvor stykket p fører hen: {cell, heading, level}.
func exit_of(p: TrackPiece, d: TrackPieceDef = null) -> Dictionary:
	if d == null:
		d = def_of(p)
	var turn: int = d.turn if d != null else 0
	var rise: int = d.rise if d != null else 0
	var h: int = posmod(p.heading + turn, 4)
	return {"cell": p.cell + TrackPiece.dir(h), "heading": h, "level": p.level + rise}


## Indgang for næste stykke (beregnet ud fra det sidste).
func next_entry() -> Dictionary:
	if pieces.is_empty():
		return {}
	return exit_of(pieces[pieces.size() - 1])


func is_closed() -> bool:
	if pieces.size() < 2:
		return false
	var e: Dictionary = next_entry()
	var f: TrackPiece = pieces[0]
	return e["cell"] == f.cell and e["heading"] == f.heading and e["level"] == f.level


## Laveste niveau stykket optager.
func low_level(p: TrackPiece) -> int:
	var d: TrackPieceDef = def_of(p)
	return mini(p.level, p.level + (d.rise if d != null else 0))


func total_cost() -> int:
	var c: int = 0
	for p in pieces:
		var d: TrackPieceDef = def_of(p)
		if d != null:
			c += d.cost
	return c


func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for p in pieces:
		if not out.has(p.cell):
			out.append(p.cell)
	return out


## Fejlkoder (tom = gyldig). is_blocked(piece_index: int) -> bool tjekker kollision mod omverdenen.
## physics: kør fysik for "too_slow" (kun hvis ingen andre fejl).
func validate(is_blocked: Callable = Callable(), train: Dictionary = {}) -> Array[String]:
	var errs: Array[String] = []
	var stations: int = 0
	for p in pieces:
		var d: TrackPieceDef = def_of(p)
		if d != null and d.kind == "station":
			stations += 1
	if stations == 0:
		errs.append("no_station")
	elif stations > 1:
		errs.append("multiple_stations")
	if not is_closed():
		errs.append("not_closed")
	var high: bool = false
	var low: bool = false
	for p in pieces:
		var d: TrackPieceDef = def_of(p)
		var rise: int = d.rise if d != null else 0
		if maxi(p.level, p.level + rise) > max_height:
			high = true
		if mini(p.level, p.level + rise) < 0:
			low = true
	if high:
		errs.append("too_high")
	if low:
		errs.append("below_ground")
	var coll: bool = false
	for i in pieces.size():
		for j in range(i + 1, pieces.size()):
			if pieces[i].cell == pieces[j].cell and absi(low_level(pieces[i]) - low_level(pieces[j])) < 2:
				coll = true
		if is_blocked.is_valid() and is_blocked.call(i):
			coll = true
	if coll:
		errs.append("collision")
	if errs.is_empty():
		if not train.is_empty() and not CoasterPhysics.simulate(self, train, defs).ok:
			errs.append("too_slow")
	return errs


func to_save() -> Array:
	var out: Array = []
	for p in pieces:
		out.append(p.to_save())
	return out


func to_dicts() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in pieces:
		out.append(p.to_dict())
	return out


static func from_save(a: Variant, p_defs: Dictionary = {}, p_max_height: int = 8) -> CoasterTrack:
	var t := CoasterTrack.new(p_defs, p_max_height)
	if a is Array:
		for e: Variant in a:
			if e is Dictionary:
				t.pieces.append(TrackPiece.from_save(e))
	return t
