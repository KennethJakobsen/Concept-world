class_name ParkSim
extends RefCounted
## Samler world, pathfinding, attraktioner og gæster. Drives af SimClock.

signal guest_spawned(guest: Guest)
signal guest_removed(guest_id: int)
signal day_passed(day: int)
signal reputation_changed(value: float)
signal attraction_removed(attraction_id: int)

const NEED_THOUGHTS: Dictionary = {
	"hunger": "Jeg er sulten!",
	"thirst": "Jeg er tørstig!",
	"toilet": "Jeg skal tisse!",
	"energy": "Jeg er træt!",
}

const ATTRACTION_DIR: String = "res://content/attractions/"
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var world: ParkWorld
var clock: SimClock
var path_finder: PathFinder
var rng: RandomNumberGenerator
var guests: Dictionary = {}  ## id -> Guest
var attractions: Array[Attraction] = []
var balance: Balance
var economy: Economy
var day: int = 1
var entry_fee: int = 0
var day_tick: int = 0  ## ticks ind i nuværende dag

## Konfiguration
## Fast spawn-interval (legacy/tests). At sætte feltet slår fast_spawn til.
var spawn_interval_ticks: int = 40:
	set(v):
		spawn_interval_ticks = v
		fixed_spawn = true
## Loft i fast_spawn-tilstand (ellers bruges current_max_guests()-formlen).
var max_guests: int = 50
## true → spawn hver spawn_interval_ticks op til max_guests; false → park.json-model.
var fixed_spawn: bool = false
## Omdømme 0..100 (T-029/T-030).
var reputation: float = 50.0
var guest_speed: float = 0.1  ## celler pr. tick
var rides_per_guest_min: int = 1
var rides_per_guest_max: int = 3
var wander_steps_max: int = 30

var _next_guest_id: int = 1
var _spawn_counter: int = 0
var _def_cache: Dictionary = {}


## p_balance = null → indlæs content/economy.json + guests.json (defaults ved mangler).
func _init(width: int, height: int, p_seed: int, p_balance: Balance = null) -> void:
	balance = p_balance if p_balance != null else Balance.load_default()
	economy = Economy.new(balance.start_money)
	entry_fee = balance.entry_fee
	spawn_interval_ticks = balance.spawn_interval_ticks
	max_guests = balance.max_guests
	fixed_spawn = not balance.has_park
	reputation = balance.reputation_start
	guest_speed = balance.speed
	world = ParkWorld.new(width, height)
	clock = SimClock.new()
	path_finder = PathFinder.new(world)
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed
	clock.ticked.connect(_on_tick)
	world.attraction_placed.connect(_on_attraction_placed)
	world.attraction_removed.connect(_on_attraction_removed)


func update(delta: float) -> void:
	clock.advance(delta)


# --- Kommandoer ---

func cmd_place_path(cell: Vector2i) -> bool:
	if not world.can_place_path(cell) or not economy.can_afford(balance.path_cost):
		return false
	economy.spend(balance.path_cost, "path")
	return world.place_path(cell)


func cmd_remove_path(cell: Vector2i) -> bool:
	if not world.remove_path(cell):
		return false
	economy.earn(balance.path_refund, "refund")
	return true


func cmd_place_attraction(def_id: String, origin: Vector2i) -> Attraction:
	var def: AttractionDef = get_def(def_id)
	if not world.can_place_attraction(def, origin) or not economy.can_afford(def.build_cost):
		return null
	economy.spend(def.build_cost, "build")
	return world.place_attraction(def, origin)


## Fjerner attraktionen og refunderer 50% af byggeprisen.
func cmd_remove_attraction(attraction_id: int) -> bool:
	var a: Attraction = world.remove_attraction(attraction_id)
	if a == null:
		return false
	economy.earn(a.def.build_cost / 2, "refund")
	return true


func cmd_set_price(attraction_id: int, price: int) -> bool:
	var a: Attraction = get_attraction(attraction_id)
	if a == null or price < 0:
		return false
	a.price = price
	for g: Guest in guests.values():
		g.rejected_ids.erase(attraction_id)
	return true


func cmd_set_open(attraction_id: int, open: bool) -> bool:
	var a: Attraction = get_attraction(attraction_id)
	if a == null:
		return false
	a.is_open = open
	if open:
		for g: Guest in guests.values():
			g.rejected_ids.erase(attraction_id)
	return true


func cmd_set_entry_fee(fee: int) -> void:
	entry_fee = maxi(0, fee)


## Registrér en def direkte (tests/mods) – overskriver cache for id.
func register_def(def: AttractionDef) -> void:
	_def_cache[def.id] = def


## sqrt(Σ åbne rides excitement × weight_ride + antal åbne shops/toilets × weight_facility).
func attraction_score() -> float:
	var raw: float = 0.0
	for a in attractions:
		if not a.is_open:
			continue
		if a.def.kind == "ride":
			raw += a.def.excitement * balance.weight_ride
		else:
			raw += balance.weight_facility
	return sqrt(maxf(0.0, raw))


func _has_open_ride() -> bool:
	for a in attractions:
		if a.is_open and a.def.kind == "ride":
			return true
	return false


## Straf 0..price_penalty_max for entré over forventet.
func price_penalty() -> float:
	var expected: float = balance.expected_entry_fee_per_score * attraction_score()
	if expected <= 0.0:
		return 0.0
	return clampf((entry_fee - expected) / expected * balance.price_penalty_factor, 0.0, balance.price_penalty_max)


## Gæster pr. dag (park.json-model). 0 uden sti ved indgangen eller uden åben forlystelse.
## I fast_spawn-tilstand: day_ticks / spawn_interval_ticks.
func expected_guests_per_day() -> float:
	if not _entrance_connected() or not _has_open_ride():
		return 0.0
	if fixed_spawn:
		return float(balance.day_ticks) / maxi(1, spawn_interval_ticks)
	var rep_mult: float = balance.reputation_mult_base + reputation / 100.0
	var rate: float = balance.spawn_per_score * attraction_score() * rep_mult * (1.0 - price_penalty())
	return clampf(rate, balance.spawn_min_per_day, balance.spawn_max_per_day)


func current_max_guests() -> int:
	if fixed_spawn:
		return max_guests
	var cap: int = 0
	for a in attractions:
		if a.is_open:
			cap += a.def.capacity
	return balance.max_guests_base + int(floor(cap * balance.max_guests_per_capacity))


func get_stats() -> Dictionary:
	var total: float = 0.0
	for g: Guest in guests.values():
		total += g.happiness
	return {
		"guests": guests.size(),
		"avg_happiness": total / guests.size() if not guests.is_empty() else 0.0,
		"money": economy.money,
		"day": day,
		"reputation": reputation,
		"attraction_score": attraction_score(),
		"guests_per_day": expected_guests_per_day(),
		"max_guests": current_max_guests(),
	}


const LEAVE_THOUGHT: String = "Jeg vil hjem."
const TOO_EXPENSIVE_THOUGHT: String = "For dyrt!"


## Maks betalingsvilje (GDD). Uden gæst: glæde = happiness_start, behov = 0.
func price_value(a: Attraction, g: Guest = null) -> float:
	var happiness: float = g.happiness if g != null else balance.happiness_start
	var v: float
	if a.def.kind == "ride":
		v = balance.ride_price_base + a.def.excitement * balance.ride_price_per_excitement
	else:
		var need: float = 0.0
		if g != null:
			for k: String in a.def.satisfies:
				if a.satisfies_need(k):
					need = maxf(need, float(g.needs.get(k, 0.0)))
		v = a.def.ticket_price * (1.0 + need / 100.0)
	return v * (balance.happiness_price_base + happiness * balance.happiness_price_factor)


## Billigste pris blandt åbne bygninger (-1 hvis ingen er åbne).
func cheapest_open_price() -> int:
	var best: int = -1
	for a in attractions:
		if a.is_open and (best < 0 or a.price < best):
			best = a.price
	return best


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
	a.ride_finished.connect(_on_ride_finished.bind(a))
	a.ride_started.connect(_on_ride_started.bind(a))


func _on_attraction_removed(a: Attraction) -> void:
	attractions.erase(a)
	var affected: Array = a.queue + a.riders
	a.queue.clear()
	a.riders.clear()
	for gid in affected:
		if guests.has(gid):
			var g: Guest = guests[gid]
			g.money += g.paid
			g.paid = 0
			g.state = Guest.State.WALKING
			g.target_attraction_id = -1
			_choose_goal(g)
	attraction_removed.emit(a.id)


func _on_tick(_tick: int) -> void:
	day_tick += 1
	if day_tick >= balance.day_ticks:
		day_tick = 0
		_end_day()
	if fixed_spawn:
		_spawn_counter += 1
		if _spawn_counter >= spawn_interval_ticks:
			_spawn_counter = 0
			_try_spawn()
	elif guests.size() < current_max_guests():
		var rate: float = expected_guests_per_day()
		if rate > 0.0 and rng.randf() < rate / balance.day_ticks:
			_try_spawn()
	for a in attractions:
		a.tick()
	var ids: Array = guests.keys()
	ids.sort()
	for gid in ids:
		if guests.has(gid):
			var g: Guest = guests[gid]
			if _update_needs(g):
				_tick_guest(g)


func _end_day() -> void:
	for a in attractions:
		if a.def.running_cost_per_day > 0:
			economy.charge(a.def.running_cost_per_day, "running")
	economy.close_day(day)
	day += 1
	day_passed.emit(day)


## Opdaterer behov/glæde. Returnerer false hvis gæsten blev omdirigeret/fjernet denne tick.
func _update_needs(g: Guest) -> bool:
	var keys: Array = g.needs.keys()
	var over: int = 0
	var crossed: bool = false
	for k: String in keys:
		var cfg: Dictionary = balance.needs.get(k, {})
		var th: float = float(cfg.get("threshold", 100.0))
		var before: float = g.needs[k]
		var after: float = minf(100.0, before + float(cfg.get("rate", 0.0)))
		g.needs[k] = after
		if after > th:
			over += 1
			if before <= th:
				crossed = true
	g.happiness = clampf(g.happiness - over * balance.happiness_decay_when_need_over_threshold, 0.0, 100.0)
	if g.state != Guest.State.WALKING:
		return true
	if g.happiness < balance.leave_happiness or (crossed and g.seeking_need == ""):
		if g.next_cell == g.cell or g.progress <= 0.0:
			_choose_goal(g)
			return false
	return true


func _entrance_connected() -> bool:
	for d in DIRS:
		if world.get_tile(world.entrance + d) == ParkWorld.Tile.PATH:
			return true
	return false


func _try_spawn() -> void:
	if guests.size() >= current_max_guests() or not _entrance_connected():
		return
	var g := Guest.new(_next_guest_id, world.entrance)
	_next_guest_id += 1
	g.rides_left = rng.randi_range(rides_per_guest_min, rides_per_guest_max)
	g.money = rng.randi_range(balance.guest_money_min, balance.guest_money_max)
	var need_keys: Array = balance.needs.keys()
	need_keys.sort()
	for k: String in need_keys:
		g.needs[k] = rng.randf_range(0.0, balance.need_start_max)
	g.happiness = balance.happiness_start
	var fee: int = mini(entry_fee, g.money)
	g.money -= fee
	economy.earn(fee, "entry")
	guests[g.id] = g
	_choose_goal(g)
	guest_spawned.emit(g)


func _set_route(g: Guest, route: Array[Vector2i]) -> void:
	# route starter i g.cell
	g.path = route.slice(1)
	g.progress = 0.0
	g.next_cell = g.cell if g.path.is_empty() else g.path.pop_front()


func _choose_goal(g: Guest) -> void:
	g.seeking_need = ""
	var leave_reason: String = _leave_reason(g)
	if leave_reason != "":
		g.thought = leave_reason
		_start_leaving(g)
		return
	# 1) Akutte behov – mest akutte først, nærmeste åbne bygning der dækker det.
	var urgent: Array = []
	for k: String in g.needs:
		if g.needs[k] > balance.need_threshold(k):
			urgent.append(k)
	urgent.sort_custom(func(x: String, y: String) -> bool:
		return g.needs[x] > g.needs[y] or (g.needs[x] == g.needs[y] and x < y))
	for need: String in urgent:
		var best: Attraction = null
		var best_route: Array[Vector2i] = []
		for a in attractions:
			if not a.satisfies_need(need) or not _usable(g, a):
				continue
			var route: Array[Vector2i] = path_finder.find_path(g.cell, a.entrance_cell)
			if route.is_empty():
				continue
			if best == null or route.size() < best_route.size():
				best = a
				best_route = route
		if best != null:
			g.seeking_need = need
			g.thought = NEED_THOUGHTS.get(need, "")
			_go_to(g, best, best_route)
			return
		if g.thought != TOO_EXPENSIVE_THOUGHT:
			g.thought = NEED_THOUGHTS.get(need, "")
	# 2) Forlystelser
	if g.rides_left > 0:
		var options: Array[Attraction] = []
		for a in attractions:
			if a.def.kind == "ride" and _usable(g, a) \
					and not path_finder.find_path(g.cell, a.entrance_cell).is_empty():
				options.append(a)
		if not options.is_empty():
			# Vægtet efter excitement (min. vægt 1).
			var total: int = 0
			for o in options:
				total += maxi(1, o.def.excitement)
			var r: int = rng.randi_range(0, total - 1)
			var a: Attraction = options[options.size() - 1]
			for o in options:
				r -= maxi(1, o.def.excitement)
				if r < 0:
					a = o
					break
			_go_to(g, a, path_finder.find_path(g.cell, a.entrance_cell))
			return
		if g.wander_steps < wander_steps_max:
			g.state = Guest.State.WALKING
			g.target_attraction_id = -1
			_wander_step(g)
			return
	_start_leaving(g)


## GDD: glæde < leave_happiness, penge < billigste åbne pris, eller energy >= leave_energy.
func _leave_reason(g: Guest) -> String:
	var cheapest: int = cheapest_open_price()
	if g.happiness < balance.leave_happiness \
			or (cheapest >= 0 and g.money < cheapest) \
			or float(g.needs.get("energy", 0.0)) >= balance.leave_energy:
		return LEAVE_THOUGHT
	return ""


## Åben, ikke afvist, til at betale og under betalingsvilje.
## Er prisen over betalingsviljen afvises bygningen (tanke "For dyrt!", glæde-straf).
func _usable(g: Guest, a: Attraction) -> bool:
	if not a.is_open or g.rejected_ids.has(a.id) or a.price > g.money:
		return false
	if a.price > price_value(a, g):
		_reject_price(g, a)
		return false
	return true


func _reject_price(g: Guest, a: Attraction) -> void:
	g.thought = TOO_EXPENSIVE_THOUGHT
	g.happiness = maxf(0.0, g.happiness - balance.reject_happiness_penalty)
	g.rejected_ids.append(a.id)


func _go_to(g: Guest, a: Attraction, route: Array[Vector2i]) -> void:
	g.state = Guest.State.WALKING
	g.target_attraction_id = a.id
	_set_route(g, route)


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
	var before: float = reputation
	reputation = clampf(reputation + (g.happiness - reputation) * balance.reputation_learn_rate, 0.0, 100.0)
	if reputation != before:
		reputation_changed.emit(reputation)
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
			var reason: String = _try_enter(g, a)
			if reason == "":
				return
			_choose_goal(g)
			g.thought = reason  # afvisningen er det seneste gæsten tænkte
			return
	_choose_goal(g)


## Betaler ved køstart. Returnerer afvisningsgrund ("" = kom ind): lukket, for dyr, for få penge.
func _try_enter(g: Guest, a: Attraction) -> String:
	var reason: String = ""
	if not a.is_open:
		reason = "Den er lukket!"
	elif a.price > price_value(a, g):
		reason = TOO_EXPENSIVE_THOUGHT
		g.happiness = maxf(0.0, g.happiness - balance.reject_happiness_penalty)
	elif a.price > g.money:
		reason = "Jeg har ikke råd!"
	if reason != "":
		g.thought = reason
		g.rejected_ids.append(a.id)
		g.target_attraction_id = -1
		return reason
	g.money -= a.price
	g.paid = a.price
	economy.earn(a.price, "tickets")
	a.total_revenue += a.price
	a.total_visitors += 1
	g.state = Guest.State.QUEUING
	a.enqueue(g.id)
	return ""


func _on_ride_started(a: Attraction) -> void:
	for gid in a.riders:
		if guests.has(gid):
			(guests[gid] as Guest).state = Guest.State.RIDING


func _on_ride_finished(guest_ids: Array, a: Attraction) -> void:
	for gid in guest_ids:
		if not guests.has(gid):
			continue
		var g: Guest = guests[gid]
		_apply_visit(g, a)
		if a.def.kind == "ride":
			g.rides_left -= 1
		g.target_attraction_id = -1
		_choose_goal(g)


func _apply_visit(g: Guest, a: Attraction) -> void:
	var relieved: bool = g.seeking_need != "" and a.satisfies_need(g.seeking_need)
	for k: String in a.def.satisfies:
		if g.needs.has(k):
			g.needs[k] = clampf(g.needs[k] + float(a.def.satisfies[k]), 0.0, 100.0)
	var gain: float = a.def.excitement + (balance.need_relief_happiness if relieved else 0.0)
	g.happiness = clampf(g.happiness + gain, 0.0, 100.0)
	g.paid = 0
	g.seeking_need = ""
	g.rejected_ids.clear()
	g.thought = "Det var godt!" if relieved else ("Sjovt!" if a.def.kind == "ride" else "")
