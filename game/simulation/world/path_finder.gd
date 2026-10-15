class_name PathFinder
extends RefCounted
## A* over gåbare celler (PATH/ENTRANCE; attraktionsindgange er PATH). 4-naboskab.

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _world: ParkWorld
var _cache: Dictionary = {}


func _init(world: ParkWorld) -> void:
	_world = world
	_world.tile_changed.connect(_on_tile_changed)


func _on_tile_changed(_cell: Vector2i, _tile: int) -> void:
	_cache.clear()


func cache_size() -> int:
	return _cache.size()


func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var key := Vector4i(from.x, from.y, to.x, to.y)
	if _cache.has(key):
		var cached: Array[Vector2i] = _cache[key]
		return cached.duplicate()
	var result: Array[Vector2i] = _astar(from, to)
	_cache[key] = result
	return result.duplicate()


func _h(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _astar(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not _world.is_walkable(from) or not _world.is_walkable(to):
		return empty
	var open: Array[Vector2i] = [from]
	var came: Dictionary = {}
	var g: Dictionary = {from: 0}
	var closed: Dictionary = {}
	while not open.is_empty():
		# Find laveste f (deterministisk tie-break på indsættelsesrækkefølge).
		var best_i: int = 0
		var best_f: int = g[open[0]] + _h(open[0], to)
		for i in range(1, open.size()):
			var f: int = g[open[i]] + _h(open[i], to)
			if f < best_f:
				best_f = f
				best_i = i
		var cur: Vector2i = open[best_i]
		open.remove_at(best_i)
		if cur == to:
			var path: Array[Vector2i] = [cur]
			while came.has(cur):
				cur = came[cur]
				path.push_front(cur)
			return path
		closed[cur] = true
		for d in DIRS:
			var n: Vector2i = cur + d
			if closed.has(n) or not _world.is_walkable(n):
				continue
			var ng: int = g[cur] + 1
			if not g.has(n) or ng < g[n]:
				g[n] = ng
				came[n] = cur
				if not open.has(n):
					open.append(n)
	return empty
