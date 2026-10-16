class_name PathFinder
extends RefCounted
## A* over gåbare celler (PATH/ENTRANCE; attraktionsindgange er PATH). 4-naboskab.
## T-091: transportkanter (ParkWorld links) bruges som ekstra naboer, når budget >= 0,
## link_usable(owner_id) er sand og link_price(owner_id) <= budget.

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _world: ParkWorld
var _cache: Dictionary = {}
## owner_id -> bool (åben og ikke brudt ned). Ugyldig = ingen links.
var link_usable: Callable = Callable()
## owner_id -> int (billetpris). Ugyldig = 0.
var link_price: Callable = Callable()


func _init(world: ParkWorld) -> void:
	_world = world
	_world.tile_changed.connect(_on_tile_changed)
	_world.links_changed.connect(invalidate)


## Tømmer cachen (kald ved ændret link-tilstand: åben/lukket, nedbrud, reparation).
func invalidate() -> void:
	_cache.clear()


func _on_tile_changed(_cell: Vector2i, _tile: int) -> void:
	_cache.clear()


func cache_size() -> int:
	return _cache.size()


## budget < 0 = ingen transportkanter (personale, nåbarhed uden links).
func find_path(from: Vector2i, to: Vector2i, budget: int = -1) -> Array[Vector2i]:
	if budget >= 0 and _world.has_links() and link_usable.is_valid():
		var owners: Array[int] = usable_owners(budget)
		if not owners.is_empty():
			var lkey: String = "%d,%d,%d,%d|%s" % [from.x, from.y, to.x, to.y, str(owners)]
			if _cache.has(lkey):
				var lc: Array[Vector2i] = _cache[lkey]
				return lc.duplicate()
			var lres: Array[Vector2i] = _search_links(from, to, owners)
			_cache[lkey] = lres
			return lres.duplicate()
	var key := Vector4i(from.x, from.y, to.x, to.y)
	if _cache.has(key):
		var cached: Array[Vector2i] = _cache[key]
		return cached.duplicate()
	var result: Array[Vector2i] = _astar(from, to)
	_cache[key] = result
	return result.duplicate()


func _h(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## M7 (ADR-005 §1): A* hvor `avoid` koster +penalty (ingen cache, ingen transport). Cellen er ikke forbudt.
func find_path_avoiding(from: Vector2i, to: Vector2i, avoid: Vector2i, penalty: int) -> Array[Vector2i]:
	return _astar(from, to, avoid, penalty)


func _astar(from: Vector2i, to: Vector2i, avoid: Vector2i = Vector2i(-99999, -99999), penalty: int = 0) -> Array[Vector2i]:
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
			var ng: int = g[cur] + (1 + penalty if n == avoid else 1)
			if not g.has(n) or ng < g[n]:
				g[n] = ng
				came[n] = cur
				if not open.has(n):
					open.append(n)
	return empty


## Sorterede owner_ids for kanter, der kan bruges med budget (budget < 0 = ignorér pris).
func usable_owners(budget: int) -> Array[int]:
	var seen: Dictionary = {}
	for c: Vector2i in _world._links:
		for e: Dictionary in _world._links[c]:
			seen[int(e["owner_id"])] = true
	var out: Array[int] = []
	for o: int in seen:
		if not link_usable.is_valid() or not bool(link_usable.call(o)):
			continue
		var price: int = int(link_price.call(o)) if link_price.is_valid() else 0
		if budget >= 0 and price > budget:
			continue
		out.append(o)
	out.sort()
	return out


## Dijkstra (float-vægte) med celler + transportkanter. Stabil rækkefølge: DIRS, så kanter efter owner_id.
func _search_links(from: Vector2i, to: Vector2i, owners: Array[int]) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not _world.is_walkable(from) or not _world.is_walkable(to):
		return empty
	var open: Array[Vector2i] = [from]
	var came: Dictionary = {}
	var g: Dictionary = {from: 0.0}
	var closed: Dictionary = {}
	while not open.is_empty():
		var best_i: int = 0
		var best_g: float = g[open[0]]
		for i in range(1, open.size()):
			var gi: float = g[open[i]]
			if gi < best_g:
				best_g = gi
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
		var nbrs: Array = []
		for d in DIRS:
			nbrs.append([cur + d, 1.0])
		for e: Dictionary in _world.links_from(cur):
			if owners.has(int(e["owner_id"])):
				nbrs.append([e["to"], float(e["cost"])])
		for nb: Array in nbrs:
			var n: Vector2i = nb[0]
			if closed.has(n) or not _world.is_walkable(n):
				continue
			var ng: float = float(g[cur]) + float(nb[1])
			if not g.has(n) or ng < float(g[n]):
				g[n] = ng
				came[n] = cur
				if not open.has(n):
					open.append(n)
	return empty
