class_name ParkWorld
extends RefCounted
## Rent data-grid for parken.

signal tile_changed(cell: Vector2i, tile: int)
signal attraction_placed(attraction: Attraction)
signal attraction_removed(attraction: Attraction)
signal litter_changed(cell: Vector2i, amount: int)
## T-091: transportkanter er ændret.
signal links_changed

enum Tile { GRASS, PATH, ATTRACTION, ENTRANCE, DECOR, QUEUE }  ## DECOR = græs-dekoration; QUEUE = køsti (M7)
## M7 (ADR-005 §2): alias brugt i kontrakten (ParkWorld.CellKind.QUEUE).
const CellKind = Tile

const TILE_SIZE: float = 1.0

var width: int
var height: int
var entrance: Vector2i
var attractions: Array[Attraction] = []
var _tiles: PackedInt32Array = PackedInt32Array()
var _next_attraction_id: int = 1
## Affald pr. sti-celle (kun celler med > 0).
var litter: Dictionary = {}  ## Vector2i -> int
## M6 (T-084): hvor meget af affaldet på cellen der er opkast (≤ litter[cell]).
var vomit: Dictionary = {}  ## Vector2i -> int
## T-068: banestykker pr. celle: Vector2i -> Array af [level, attraction_id]. Afledt; gemmes ikke.
var _track: Dictionary = {}

## T-091: transportkanter i stigrafen: Vector2i -> Array[{to, cost, owner_id}]. Afledt; gemmes ikke.
var _links: Dictionary = {}

## M7 (ADR-005 §1): gæster pr. celle (index = y * width + x). Afledt; gemmes ikke.
var occupancy_counts: PackedInt32Array = PackedInt32Array()
## Ticks cellen har været fuld i træk. Afledt; gemmes ikke.
var crowd_counts: PackedInt32Array = PackedInt32Array()
## Celle-index med occupancy > 0 eller crowd > 0 (til billig nulstilling).
var _occ_touched: Dictionary = {}

## Over dette niveau (>=) må banen ligge over stier/bygninger/decor.
const TRACK_CLEARANCE: int = 2


func _init(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height
	_tiles.resize(width * height)
	_tiles.fill(Tile.GRASS)
	occupancy_counts.resize(width * height)
	crowd_counts.resize(width * height)
	entrance = Vector2i(width / 2, height - 1)
	_tiles[_idx(entrance)] = Tile.ENTRANCE


## Flytter indgangen (bruges ved scenarie-opsætning før noget er bygget).
func set_entrance(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return false
	_set_tile(entrance, Tile.GRASS)
	entrance = cell
	_set_tile(entrance, Tile.ENTRANCE)
	return true


func _idx(cell: Vector2i) -> int:
	return cell.y * width + cell.x


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


## Returnerer -1 udenfor grid.
func get_tile(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return -1
	return _tiles[_idx(cell)]


func is_walkable(cell: Vector2i) -> bool:
	var t: int = get_tile(cell)
	return t == Tile.PATH or t == Tile.ENTRANCE


func _set_tile(cell: Vector2i, tile: int) -> void:
	_tiles[_idx(cell)] = tile
	tile_changed.emit(cell, tile)


func can_place_path(cell: Vector2i) -> bool:
	return get_tile(cell) == Tile.GRASS and not has_low_track(cell)


# --- Køstier (M7, ADR-005 §2) ---

func is_queue(cell: Vector2i) -> bool:
	return get_tile(cell) == Tile.QUEUE


func place_queue(cell: Vector2i) -> bool:
	if not can_place_path(cell):
		return false
	_set_tile(cell, Tile.QUEUE)
	return true


func remove_queue(cell: Vector2i) -> bool:
	if get_tile(cell) != Tile.QUEUE:
		return false
	_set_tile(cell, Tile.GRASS)
	return true


## Ordnet køkæde fra cellen ved indgangen og udad. Kæden stopper ved forgrening, ved
## celler i `taken` (andre attraktioners kø) og ved andre attraktioners indgange.
func queue_chain(entrance_cell: Vector2i, taken: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var cur: Vector2i = entrance_cell
	var seen: Dictionary = {entrance_cell: true}
	while true:
		var nexts: Array[Vector2i] = []
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = cur + d
			if not seen.has(n) and not taken.has(n) and get_tile(n) == Tile.QUEUE:
				nexts.append(n)
		if nexts.size() != 1 and not (out.is_empty() and nexts.size() > 0):
			break
		cur = nexts[0]
		seen[cur] = true
		out.append(cur)
	return out


# --- Belægning (M7, ADR-005 §1) ---

func occupancy(cell: Vector2i) -> int:
	return occupancy_counts[_idx(cell)] if in_bounds(cell) else 0


func occupancy_add(cell: Vector2i, n: int) -> void:
	if not in_bounds(cell):
		return
	var i: int = _idx(cell)
	occupancy_counts[i] += n
	_occ_touched[i] = true


## Nulstiller belægning (crowd-tællerne bevares).
func occupancy_reset() -> void:
	for i: int in _occ_touched:
		occupancy_counts[i] = 0


## Opdaterer crowd-tællere ud fra belægningen og rydder index-sættet for tomme celler.
func update_crowd(max_per_cell: int) -> void:
	var drop: Array = []
	for i: int in _occ_touched:
		if occupancy_counts[i] >= max_per_cell:
			crowd_counts[i] += 1
		else:
			crowd_counts[i] = 0
			if occupancy_counts[i] == 0:
				drop.append(i)
	for i: int in drop:
		_occ_touched.erase(i)


func crowd_ticks_at(cell: Vector2i) -> int:
	return crowd_counts[_idx(cell)] if in_bounds(cell) else 0


## Celler, der har været fulde i mindst min_ticks (sorteret, til overlay).
func crowded_cells(min_ticks: int = 1) -> Array[Vector2i]:
	var idx: Array = _occ_touched.keys()
	idx.sort()
	var out: Array[Vector2i] = []
	for i: int in idx:
		if crowd_counts[i] >= min_ticks:
			out.append(Vector2i(i % width, i / width))
	return out


# --- Rutsjebanespor (T-068) ---

## Niveauer (laveste niveau pr. stykke) som banestykker optager i cellen.
func occupied_by_track(cell: Vector2i) -> Array[int]:
	var out: Array[int] = []
	for e: Array in _track.get(cell, []):
		out.append(int(e[0]))
	return out


## Ligger der et stykke under TRACK_CLEARANCE i cellen?
func has_low_track(cell: Vector2i) -> bool:
	for lv in occupied_by_track(cell):
		if lv < TRACK_CLEARANCE:
			return true
	return false


func add_track_cell(cell: Vector2i, level: int, attraction_id: int) -> void:
	var l: Array = _track.get(cell, [])
	l.append([level, attraction_id])
	_track[cell] = l


func remove_track_cell(cell: Vector2i, level: int, attraction_id: int) -> void:
	var l: Array = _track.get(cell, [])
	for i in l.size():
		if int(l[i][0]) == level and int(l[i][1]) == attraction_id:
			l.remove_at(i)
			break
	if l.is_empty():
		_track.erase(cell)


func clear_track(attraction_id: int) -> void:
	for c: Vector2i in _track.keys():
		var l: Array = (_track[c] as Array).filter(func(e: Array) -> bool: return int(e[1]) != attraction_id)
		if l.is_empty():
			_track.erase(c)
		else:
			_track[c] = l


## Er cellen blokeret af jordobjekter (sti, bygning, decor, indgang) for et stykke på niveau level?
func blocks_track(cell: Vector2i, level: int) -> bool:
	if not in_bounds(cell):
		return true
	if level >= TRACK_CLEARANCE:
		return false
	if get_tile(cell) != Tile.GRASS:
		return true
	for a in attractions:
		if a.track == null and a.occupies(cell):
			return true
	return false


# --- Transportkanter (T-091, ADR-004 §4) ---

## Tovejskant mellem to gåbare celler (stationsindgange) ejet af en transport-attraktion.
func add_link(a: Vector2i, b: Vector2i, cost: float, owner_id: int) -> void:
	_add_half_link(a, b, cost, owner_id)
	_add_half_link(b, a, cost, owner_id)
	links_changed.emit()


func _add_half_link(a: Vector2i, b: Vector2i, cost: float, owner_id: int) -> void:
	var l: Array = _links.get(a, [])
	l.append({"to": b, "cost": cost, "owner_id": owner_id})
	l.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		return int(x["owner_id"]) < int(y["owner_id"]) \
			or (int(x["owner_id"]) == int(y["owner_id"]) and (x["to"] as Vector2i) < (y["to"] as Vector2i)))
	_links[a] = l


func remove_links(owner_id: int) -> void:
	var changed: bool = false
	for c: Vector2i in _links.keys():
		var l: Array = (_links[c] as Array).filter(func(e: Dictionary) -> bool: return int(e["owner_id"]) != owner_id)
		if l.size() != (_links[c] as Array).size():
			changed = true
		if l.is_empty():
			_links.erase(c)
		else:
			_links[c] = l
	if changed:
		links_changed.emit()


## Kanter fra cellen, sorteret efter owner_id (kopier).
func links_from(cell: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in _links.get(cell, []):
		out.append(e.duplicate())
	return out


func has_links() -> bool:
	return not _links.is_empty()


## Placerer en rutsjebane-attraktion (stationen lægges af kalderen). Indgangen bliver sti.
func place_coaster(def: AttractionDef, station: Vector2i, entrance_cell: Vector2i) -> Attraction:
	var a := Attraction.new(_next_attraction_id, def, station)
	_next_attraction_id += 1
	a.entrance_cell = entrance_cell
	a.cells = [station]
	attractions.append(a)
	if get_tile(entrance_cell) != Tile.PATH:
		_set_tile(entrance_cell, Tile.PATH)
	attraction_placed.emit(a)
	return a


func place_path(cell: Vector2i) -> bool:
	if not can_place_path(cell):
		return false
	_set_tile(cell, Tile.PATH)
	return true


## Indgangsceller til attraktioner kan ikke fjernes.
func remove_path(cell: Vector2i) -> bool:
	if get_tile(cell) != Tile.PATH or get_attraction_by_entrance(cell) != null:
		return false
	set_litter(cell, 0)
	_set_tile(cell, Tile.GRASS)
	return true


func can_place_attraction(def: AttractionDef, origin: Vector2i) -> bool:
	if def == null:
		return false
	for y in def.footprint.y:
		for x in def.footprint.x:
			if get_tile(origin + Vector2i(x, y)) != Tile.GRASS or has_low_track(origin + Vector2i(x, y)):
				return false
	var ent := Vector2i(origin.x + def.footprint.x / 2, origin.y + def.footprint.y)
	var et: int = get_tile(ent)
	return (et == Tile.GRASS or et == Tile.PATH) and get_attraction_by_entrance(ent) == null \
		and not has_low_track(ent)


func place_attraction(def: AttractionDef, origin: Vector2i) -> Attraction:
	if not can_place_attraction(def, origin):
		return null
	var a := Attraction.new(_next_attraction_id, def, origin)
	_next_attraction_id += 1
	for y in def.footprint.y:
		for x in def.footprint.x:
			_set_tile(origin + Vector2i(x, y), Tile.ATTRACTION)
	attractions.append(a)
	if get_tile(a.entrance_cell) != Tile.PATH:
		_set_tile(a.entrance_cell, Tile.PATH)
	attraction_placed.emit(a)
	return a


func get_attraction_by_entrance(cell: Vector2i) -> Attraction:
	for a in attractions:
		if a.entrance_cell == cell:
			return a
	return null


func get_attraction_at(cell: Vector2i) -> Attraction:
	for a in attractions:
		if a.occupies(cell):
			return a
	return null


## Fjerner attraktionen; footprint bliver græs, indgangscellen forbliver sti.
func remove_attraction(attraction_id: int) -> Attraction:
	for i in attractions.size():
		var a: Attraction = attractions[i]
		if a.id != attraction_id:
			continue
		attractions.remove_at(i)
		if a.track != null:
			clear_track(a.id)
			remove_links(a.id)
		else:
			for y in a.def.footprint.y:
				for x in a.def.footprint.x:
					_set_tile(a.origin + Vector2i(x, y), Tile.GRASS)
		attraction_removed.emit(a)
		return a
	return null


# --- Save/load (T-036) ---

## Attraktioner gemmes af ParkSim (de kræver defs); her kun grid-state.
func to_save() -> Dictionary:
	return {"width": width, "height": height, "entrance": SaveCodec.v2i(entrance),
		"tiles": Array(_tiles), "next_attraction_id": _next_attraction_id, "litter": _litter_to_save(),
		"vomit": _cells_to_save(vomit)}


## Sætter grid-state uden at udsende tile_changed (visning genopbygges af bridge efter load).
func load_save(d: Dictionary) -> void:
	entrance = SaveCodec.to_v2i(d.get("entrance"), entrance)
	var tiles: Array = SaveCodec.arr(d, "tiles")
	if tiles.size() == width * height:
		for i in tiles.size():
			_tiles[i] = int(tiles[i])
	_next_attraction_id = int(d.get("next_attraction_id", _next_attraction_id))
	litter.clear()
	for e: Variant in SaveCodec.arr(d, "litter"):
		if e is Array and (e as Array).size() >= 3 and int(e[2]) > 0:
			litter[Vector2i(int(e[0]), int(e[1]))] = int(e[2])
	vomit.clear()
	for e: Variant in SaveCodec.arr(d, "vomit"):
		if e is Array and (e as Array).size() >= 3 and int(e[2]) > 0:
			var vc := Vector2i(int(e[0]), int(e[1]))
			var n: int = mini(int(e[2]), get_litter(vc))
			if n > 0:
				vomit[vc] = n


## Tilføjer en indlæst attraktion uden at ændre tiles/udsende signaler.
func restore_attraction(a: Attraction) -> void:
	attractions.append(a)



# --- Affald (T-037) ---

func get_litter(cell: Vector2i) -> int:
	return int(litter.get(cell, 0))


func set_litter(cell: Vector2i, amount: int) -> void:
	var before: int = get_litter(cell)
	if amount <= 0:
		litter.erase(cell)
		amount = 0
	else:
		litter[cell] = amount
	if get_vomit(cell) > amount:
		if amount <= 0:
			vomit.erase(cell)
		else:
			vomit[cell] = amount
	if before != amount:
		litter_changed.emit(cell, amount)


func total_litter() -> int:
	var n: int = 0
	for c: Vector2i in litter:
		n += int(litter[c])
	return n


func get_vomit(cell: Vector2i) -> int:
	return int(vomit.get(cell, 0))


## Lægger opkast (affaldstype "vomit") på cellen; tæller også som affald. Returnerer lagt mængde.
func add_vomit(cell: Vector2i, amount: int, max_per_cell: int) -> int:
	var before: int = get_litter(cell)
	var after: int = mini(before + maxi(0, amount), maxi(max_per_cell, before))
	var added: int = after - before
	if added <= 0:
		return 0
	vomit[cell] = get_vomit(cell) + added
	set_litter(cell, after)
	return added


func total_vomit() -> int:
	var n: int = 0
	for c: Vector2i in vomit:
		n += int(vomit[c])
	return n


## Grid-sti-mål: [[x, y, n], ...] sorteret for stabil output.
func _litter_to_save() -> Array:
	return _cells_to_save(litter)


static func _cells_to_save(src: Dictionary) -> Array:
	var cells: Array = src.keys()
	cells.sort()
	var out: Array = []
	for c: Vector2i in cells:
		out.append([c.x, c.y, src[c]])
	return out


## Placering af græs-dekoration (sætter DECOR-tile).
func place_decor_tile(cell: Vector2i) -> bool:
	if get_tile(cell) != Tile.GRASS or has_low_track(cell):
		return false
	_set_tile(cell, Tile.DECOR)
	return true


func clear_decor_tile(cell: Vector2i) -> void:
	if get_tile(cell) == Tile.DECOR:
		_set_tile(cell, Tile.GRASS)
