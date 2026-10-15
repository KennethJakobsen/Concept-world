class_name ParkWorld
extends RefCounted
## Rent data-grid for parken.

signal tile_changed(cell: Vector2i, tile: int)
signal attraction_placed(attraction: Attraction)

enum Tile { GRASS, PATH, ATTRACTION, ENTRANCE }

const TILE_SIZE: float = 1.0

var width: int
var height: int
var entrance: Vector2i
var attractions: Array[Attraction] = []
var _tiles: PackedInt32Array = PackedInt32Array()
var _next_attraction_id: int = 1


func _init(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height
	_tiles.resize(width * height)
	_tiles.fill(Tile.GRASS)
	entrance = Vector2i(width / 2, height - 1)
	_tiles[_idx(entrance)] = Tile.ENTRANCE


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
	return get_tile(cell) == Tile.GRASS


func place_path(cell: Vector2i) -> bool:
	if not can_place_path(cell):
		return false
	_set_tile(cell, Tile.PATH)
	return true


## Indgangsceller til attraktioner kan ikke fjernes.
func remove_path(cell: Vector2i) -> bool:
	if get_tile(cell) != Tile.PATH or get_attraction_by_entrance(cell) != null:
		return false
	_set_tile(cell, Tile.GRASS)
	return true


func can_place_attraction(def: AttractionDef, origin: Vector2i) -> bool:
	if def == null:
		return false
	for y in def.footprint.y:
		for x in def.footprint.x:
			if get_tile(origin + Vector2i(x, y)) != Tile.GRASS:
				return false
	var ent := Vector2i(origin.x + def.footprint.x / 2, origin.y + def.footprint.y)
	var et: int = get_tile(ent)
	return (et == Tile.GRASS or et == Tile.PATH) and get_attraction_by_entrance(ent) == null


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
