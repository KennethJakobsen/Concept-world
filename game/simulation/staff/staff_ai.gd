class_name StaffAI
extends RefCounted
## Personale-logik (T-037). Statisk og tilstandsløs – al state ligger i ParkSim/Staff,
## så der ikke opstår referencecykler (ParkSim ↔ system).

const MECHANIC: String = "mechanic"
const CLEANER: String = "cleaner"
const ENTERTAINER: String = "entertainer"


static func tick_all(sim: ParkSim) -> void:
	_assign_repairs(sim)
	var ids: Array = sim.staff.keys()
	ids.sort()
	for sid in ids:
		if sim.staff.has(sid):
			_tick(sim, sim.staff[sid])


# --- Tildeling af reparationer: nærmeste ledige mekaniker (ikke allerede på reparation) ---

static func _assign_repairs(sim: ParkSim) -> void:
	for a: Attraction in sim.attractions:
		if not a.broken:
			continue
		if a.mechanic_id >= 0 and sim.staff.has(a.mechanic_id):
			var m: Staff = sim.staff[a.mechanic_id]
			if m.task == Staff.TASK_REPAIR and m.task_target_id == a.id:
				continue
		a.mechanic_id = -1
		var best: Staff = null
		var best_route: Array[Vector2i] = []
		var ids: Array = sim.staff.keys()
		ids.sort()
		for sid in ids:
			var s: Staff = sim.staff[sid]
			if s.def.id != MECHANIC or s.task == Staff.TASK_REPAIR or not s.in_radius(a.entrance_cell):
				continue
			var route: Array[Vector2i] = sim.path_finder.find_path(s.cell, a.entrance_cell)
			if route.is_empty():
				continue
			if best == null or route.size() < best_route.size():
				best = s
				best_route = route
		if best != null:
			_set_task(best, Staff.TASK_REPAIR, a.id, a.entrance_cell, best_route)
			a.mechanic_id = best.id


static func _tick(sim: ParkSim, s: Staff) -> void:
	if s.def.id == MECHANIC:
		s.since_inspect += 1
	match s.state:
		Staff.State.WORKING:
			s.work_ticks_left -= 1
			if s.work_ticks_left <= 0:
				_finish(sim, s)
		Staff.State.WALKING:
			if _walk(sim, s):
				_arrive(sim, s)
		_:
			_find_task(sim, s)


## Flytter én tick. Returnerer true ved ankomst til slutningen af ruten.
static func _walk(sim: ParkSim, s: Staff) -> bool:
	if s.next_cell == s.cell:
		return true
	if not sim.world.is_walkable(s.next_cell):
		var route: Array[Vector2i] = sim.path_finder.find_path(s.cell, s.task_cell)
		if route.is_empty():
			drop_task(sim, s)
			return false
		_set_route(s, route)
		return false
	s.progress += s.def.speed
	if s.progress < 1.0 - 1e-6:
		return false
	s.cell = s.next_cell
	s.progress = 0.0
	if not s.path.is_empty():
		s.next_cell = s.path.pop_front()
		return false
	s.next_cell = s.cell
	return true


static func _set_route(s: Staff, route: Array[Vector2i]) -> void:
	s.path = route.slice(1)
	s.progress = 0.0
	s.next_cell = s.cell if s.path.is_empty() else s.path.pop_front()


static func _set_task(s: Staff, task: String, target_id: int, cell: Vector2i, route: Array[Vector2i]) -> void:
	s.task = task
	s.task_target_id = target_id
	s.task_cell = cell
	s.state = Staff.State.WALKING
	s.work_ticks_left = 0
	_set_route(s, route)


static func drop_task(sim: ParkSim, s: Staff) -> void:
	if s.task == Staff.TASK_REPAIR:
		var a: Attraction = sim.get_attraction(s.task_target_id)
		if a != null and a.mechanic_id == s.id:
			a.mechanic_id = -1
	s.task = Staff.TASK_NONE
	s.task_target_id = -1
	s.state = Staff.State.IDLE
	s.path.clear()
	s.next_cell = s.cell
	s.progress = 0.0
	s.work_ticks_left = 0


static func _arrive(sim: ParkSim, s: Staff) -> void:
	if s.cell != s.task_cell:
		drop_task(sim, s)
		return
	var ticks: int = 0
	match s.task:
		Staff.TASK_REPAIR:
			var a: Attraction = sim.get_attraction(s.task_target_id)
			if a != null and a.broken:
				ticks = a.def.repair_ticks
		Staff.TASK_INSPECT:
			var a: Attraction = sim.get_attraction(s.task_target_id)
			if a != null and not a.broken:
				ticks = sim.balance.inspection_ticks
		Staff.TASK_SWEEP:
			if sim.world.get_litter(s.cell) > 0:
				ticks = sim.balance.cleaner_sweep_ticks
		Staff.TASK_EMPTY_BIN:
			if sim.decor.has(s.task_target_id):
				ticks = sim.balance.cleaner_empty_bin_ticks
	if ticks <= 0:
		drop_task(sim, s)
		return
	s.state = Staff.State.WORKING
	s.work_ticks_left = ticks


static func _finish(sim: ParkSim, s: Staff) -> void:
	match s.task:
		Staff.TASK_REPAIR:
			var a: Attraction = sim.get_attraction(s.task_target_id)
			if a != null and a.broken:
				sim._repair(a)
		Staff.TASK_INSPECT:
			var a: Attraction = sim.get_attraction(s.task_target_id)
			if a != null and not a.broken:
				a.reliability_bonus = minf(a.reliability_bonus + sim.balance.inspection_reliability_bonus,
					1.0 - a.def.reliability)
				a.last_inspect_tick = sim.clock.tick
			s.since_inspect = 0
		Staff.TASK_SWEEP:
			sim.world.set_litter(s.cell, 0)
		Staff.TASK_EMPTY_BIN:
			var d: Decor = sim.decor.get(s.task_target_id, null)
			if d != null:
				d.fill = 0
	drop_task(sim, s)


static func _find_task(sim: ParkSim, s: Staff) -> void:
	match s.def.id:
		MECHANIC:
			if s.since_inspect >= sim.balance.mechanic_inspect_interval_ticks:
				_find_inspection(sim, s)
		CLEANER:
			_find_cleaning(sim, s)
		ENTERTAINER:
			_patrol(sim, s)


static func _find_inspection(sim: ParkSim, s: Staff) -> void:
	var best: Attraction = null
	for a: Attraction in sim.attractions:
		if a.def.kind != "ride" or a.broken or a.def.reliability >= 1.0 or not s.in_radius(a.entrance_cell):
			continue
		if best == null or a.last_inspect_tick < best.last_inspect_tick:
			best = a
	if best == null:
		return
	var route: Array[Vector2i] = sim.path_finder.find_path(s.cell, best.entrance_cell)
	if route.is_empty():
		s.since_inspect = 0  # prøv igen senere
		return
	_set_task(s, Staff.TASK_INSPECT, best.id, best.entrance_cell, route)


static func _dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _find_cleaning(sim: ParkSim, s: Staff) -> void:
	# 1) fulde skraldespande, 2) nærmeste affald. Manhattan-afstand, stabil tie-break.
	var bins: Array = []
	for did: int in sim.decor:
		var d: Decor = sim.decor[did]
		if d.def.kind == "bin" and d.fill >= sim.balance.bin_capacity and s.in_radius(d.cell):
			bins.append(d)
	bins.sort_custom(func(x: Decor, y: Decor) -> bool:
		var dx: int = _dist(s.cell, x.cell)
		var dy: int = _dist(s.cell, y.cell)
		return dx < dy or (dx == dy and x.id < y.id))
	for d: Decor in bins:
		var route: Array[Vector2i] = sim.path_finder.find_path(s.cell, d.cell)
		if not route.is_empty():
			_set_task(s, Staff.TASK_EMPTY_BIN, d.id, d.cell, route)
			return
	var cells: Array = []
	for c: Vector2i in sim.world.litter:
		if s.in_radius(c):
			cells.append(c)
	cells.sort_custom(func(x: Vector2i, y: Vector2i) -> bool:
		var dx: int = _dist(s.cell, x)
		var dy: int = _dist(s.cell, y)
		return dx < dy or (dx == dy and (x.x < y.x or (x.x == y.x and x.y < y.y))))
	for c: Vector2i in cells:
		var route: Array[Vector2i] = sim.path_finder.find_path(s.cell, c)
		if not route.is_empty():
			_set_task(s, Staff.TASK_SWEEP, -1, c, route)
			return


static func _patrol(sim: ParkSim, s: Staff) -> void:
	var opts: Array[Vector2i] = []
	for d in ParkSim.DIRS:
		var n: Vector2i = s.cell + d
		if sim.world.is_walkable(n) and s.in_radius(n):
			opts.append(n)
	if opts.is_empty():
		return
	var n: Vector2i = opts[sim.rng.randi_range(0, opts.size() - 1)]
	s.task = Staff.TASK_PATROL
	s.task_cell = n
	s.state = Staff.State.WALKING
	s.path.clear()
	s.progress = 0.0
	s.next_cell = n
