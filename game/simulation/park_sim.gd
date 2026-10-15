class_name ParkSim
extends RefCounted
## Samler world, pathfinding, attraktioner og gæster. Drives af SimClock.

signal guest_spawned(guest: Guest)
signal guest_removed(guest_id: int)

const ATTRACTION_DIR: String = "res://content/attractions/"
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var world: ParkWorld
var clock: SimClock
var path_finder: PathFinder
var rng: RandomNumberGenerator
var guests: Dictionary = {}  ## id -> Guest
var attractions: Array[Attraction] = []

## Konfiguration
var spawn_interval_ticks: int = 40
var max_guests: int = 50
var guest_speed: float = 0.1  ## celler pr. tick
var rides_per_guest_min: int = 1
var rides_per_guest_max: int = 3
var wander_steps_max: int = 30

var _next_guest_id: int = 1
var _spawn_counter: int = 0
var _def_cache: Dictionary = {}


func _init(width: int, height: int, p_seed: int) -> void:
	world = ParkWorld.new(width, height)
	clock = SimClock.new()
	path_finder = PathFinder.new(world)
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed
	clock.ticked.connect(_on_tick)
	world.attraction_placed.connect(_on_attraction_placed)


func update(delta: float) -> void:
	clock.advance(delta)


# --- Kommandoer ---

func cmd_place_path(cell: Vector2i) -> bool:
	return world.place_path(cell)


func cmd_remove_path(cell: Vector2i) -> bool:
	return world.remove_path(cell)


func cmd_place_attraction(def_id: String, origin: Vector2i) -> Attraction:
	return world.place_attraction(get_def(def_id), origin)


func get_def(def_id: String) -> AttractionDef:
	if not _def_cache.has(def_id):
		var path: String = ATTRACTION_DIR + def_id + ".json"
		if not FileAccess.file_exists(path):
			return null
		_def_cache[def_id] = AttractionDef.from_json(path)
	return _def_cache[def_id]


func get_attraction(attraction_id: int) -> Attraction:
	for a in attractions:
		if a.id == attraction_id:
			return a
	return null


# --- Tick ---

func _on_attraction_placed(a: Attraction) -> void:
	attractions.append(a)
	a.ride_finished.connect(_on_ride_finished)
	a.ride_started.connect(_on_ride_started.bind(a))


func _on_tick(_tick: int) -> void:
	_spawn_counter += 1
	if _spawn_counter >= spawn_interval_ticks:
		_spawn_counter = 0
		_try_spawn()
	for a in attractions:
		a.tick()
	var ids: Array = guests.keys()
	ids.sort()
	for gid in ids:
		if guests.has(gid):
			_tick_guest(guests[gid])


func _entrance_connected() -> bool:
	for d in DIRS:
		if world.get_tile(world.entrance + d) == ParkWorld.Tile.PATH:
			return true
	return false


func _try_spawn() -> void:
	if guests.size() >= max_guests or not _entrance_connected():
		return
	var g := Guest.new(_next_guest_id, world.entrance)
	_next_guest_id += 1
	g.rides_left = rng.randi_range(rides_per_guest_min, rides_per_guest_max)
	guests[g.id] = g
	_choose_goal(g)
	guest_spawned.emit(g)


func _set_route(g: Guest, route: Array[Vector2i]) -> void:
	# route starter i g.cell
	g.path = route.slice(1)
	g.progress = 0.0
	g.next_cell = g.cell if g.path.is_empty() else g.path.pop_front()


func _choose_goal(g: Guest) -> void:
	if g.rides_left > 0:
		var options: Array[Attraction] = []
		for a in attractions:
			if not path_finder.find_path(g.cell, a.entrance_cell).is_empty():
				options.append(a)
		if not options.is_empty():
			var a: Attraction = options[rng.randi_range(0, options.size() - 1)]
			g.state = Guest.State.WALKING
			g.target_attraction_id = a.id
			_set_route(g, path_finder.find_path(g.cell, a.entrance_cell))
			return
		if g.wander_steps < wander_steps_max:
			g.state = Guest.State.WALKING
			g.target_attraction_id = -1
			_wander_step(g)
			return
	_start_leaving(g)


func _wander_step(g: Guest) -> void:
	g.wander_steps += 1
	var opts: Array[Vector2i] = []
	for d in DIRS:
		if world.is_walkable(g.cell + d):
			opts.append(g.cell + d)
	g.path.clear()
	g.progress = 0.0
	g.next_cell = g.cell if opts.is_empty() else opts[rng.randi_range(0, opts.size() - 1)]


func _start_leaving(g: Guest) -> void:
	g.state = Guest.State.LEAVING
	g.target_attraction_id = -1
	var route: Array[Vector2i] = path_finder.find_path(g.cell, world.entrance)
	if route.is_empty() and g.cell != world.entrance:
		_remove_guest(g)  # fanget uden vej hjem – fjernes
		return
	_set_route(g, route)


func _remove_guest(g: Guest) -> void:
	guests.erase(g.id)
	guest_removed.emit(g.id)


func _tick_guest(g: Guest) -> void:
	if g.state == Guest.State.QUEUING or g.state == Guest.State.RIDING:
		return
	if g.next_cell != g.cell:
		if not world.is_walkable(g.next_cell):
			if g.state == Guest.State.WALKING:
				_choose_goal(g)
			else:
				_start_leaving(g)
			return
		g.progress += guest_speed
		if g.progress < 1.0 - 1e-6:
			return
		g.cell = g.next_cell
		g.progress = 0.0
		if not g.path.is_empty():
			g.next_cell = g.path.pop_front()
			return
		g.next_cell = g.cell
	_arrived(g)


func _arrived(g: Guest) -> void:
	if g.state == Guest.State.LEAVING:
		if g.cell == world.entrance:
			_remove_guest(g)
		else:
			_start_leaving(g)
		return
	if g.target_attraction_id >= 0:
		var a: Attraction = get_attraction(g.target_attraction_id)
		if a != null and a.entrance_cell == g.cell:
			g.state = Guest.State.QUEUING
			a.enqueue(g.id)
			return
	_choose_goal(g)


func _on_ride_started(a: Attraction) -> void:
	for gid in a.riders:
		if guests.has(gid):
			(guests[gid] as Guest).state = Guest.State.RIDING


func _on_ride_finished(guest_ids: Array) -> void:
	for gid in guest_ids:
		if not guests.has(gid):
			continue
		var g: Guest = guests[gid]
		g.rides_left -= 1
		g.target_attraction_id = -1
		_choose_goal(g)
