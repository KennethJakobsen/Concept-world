class_name ParkSim
extends RefCounted
## Samler world, pathfinding, attraktioner og gæster. Drives af SimClock.

signal guest_spawned(guest: Guest)
signal guest_removed(guest_id: int)
signal day_passed(day: int)
signal reputation_changed(value: float)
signal attraction_removed(attraction_id: int)
signal staff_hired(s: Staff)
signal staff_fired(staff_id: int)
signal decor_placed(d: Decor)
signal decor_removed(decor_id: int)
signal attraction_broken(a: Attraction)
signal attraction_repaired(a: Attraction)

const NEED_THOUGHTS: Dictionary = {
	"hunger": "Jeg er sulten!",
	"thirst": "Jeg er tørstig!",
	"toilet": "Jeg skal tisse!",
	"energy": "Jeg er træt!",
}

const ATTRACTION_DIR: String = "res://content/attractions/"
const STAFF_DIR: String = "res://content/staff/"
const DECOR_DIR: String = "res://content/decor/"
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
var staff: Dictionary = {}  ## id -> Staff
var decor: Dictionary = {}  ## id -> Decor

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
var _reachable: Dictionary = {}  ## celle -> true, gåbare celler forbundet til indgangen
var _reachable_dirty: bool = true
var _next_staff_id: int = 1
var _next_decor_id: int = 1
var _staff_def_cache: Dictionary = {}
var _decor_def_cache: Dictionary = {}
var _aura: Dictionary = {}  ## celle -> glæde/tick fra dekoration (cache)
var _aura_dirty: bool = true


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
	world.tile_changed.connect(_on_tile_changed)
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
	for did in _decor_ids_at(cell):
		_remove_decor(did)
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
		if not is_operating(a):
			continue
		if a.def.kind == "ride":
			raw += a.def.excitement * balance.weight_ride
		else:
			raw += balance.weight_facility
	return sqrt(maxf(0.0, raw))


## Kan attraktionens indgang nås fra parkens indgang? (cachet, invalideres ved tile-ændring)
func is_reachable(a: Attraction) -> bool:
	if _reachable_dirty:
		_reachable_dirty = false
		_reachable = {}
		var frontier: Array[Vector2i] = [world.entrance]
		_reachable[world.entrance] = true
		while not frontier.is_empty():
			var c: Vector2i = frontier.pop_back()
			for d in DIRS:
				var n: Vector2i = c + d
				if not _reachable.has(n) and world.is_walkable(n):
					_reachable[n] = true
					frontier.append(n)
	return _reachable.has(a.entrance_cell)


## Åben og nåbar fra indgangen – kun disse tæller i tiltrækning og max_guests.
func is_operating(a: Attraction) -> bool:
	return a.is_open and is_reachable(a)


## Er køen fuld (capacity × queue_max_cycles)?
func is_queue_full(a: Attraction) -> bool:
	if balance.queue_max_cycles <= 0.0:
		return false
	return a.queue.size() >= int(ceil(a.def.capacity * balance.queue_max_cycles))


func _on_tile_changed(_cell: Vector2i, _tile: int) -> void:
	_reachable_dirty = true


func _has_open_ride() -> bool:
	for a in attractions:
		if is_operating(a) and a.def.kind == "ride":
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
		if is_operating(a):
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
		"staff": staff.size(),
		"broken": broken_count(),
		"litter": world.total_litter(),
	}


const LEAVE_THOUGHT: String = "Jeg vil hjem."
const TOO_EXPENSIVE_THOUGHT: String = "For dyrt!"
const QUEUE_FULL_THOUGHT: String = "Køen er for lang!"


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
	StaffAI.tick_all(self)


func _end_day() -> void:
	for a in attractions:
		if a.def.running_cost_per_day > 0:
			economy.charge(a.def.running_cost_per_day, "running")
	var sids: Array = staff.keys()
	sids.sort()
	for sid in sids:
		var w: int = (staff[sid] as Staff).def.wage_per_day
		if w > 0:
			economy.charge(w, "wages")
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
	if g.state != Guest.State.RIDING:
		_apply_surroundings(g)
	if g.state == Guest.State.QUEUING and g.happiness < balance.leave_happiness:
		# T-033: utilfredse gæster opgiver køen og går hjem (betalt billet refunderes ikke).
		var q: Attraction = get_attraction(g.target_attraction_id)
		if q != null:
			q.queue.erase(g.id)
		g.paid = 0
		g.state = Guest.State.WALKING
		_choose_goal(g)
		return false
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
	g.target_decor_id = -1
	# 0) Træt → nærmeste bænk (T-037)
	if float(g.needs.get("energy", 0.0)) >= balance.bench_seek_energy:
		var bench: Decor = null
		var bench_route: Array[Vector2i] = []
		for did in _sorted_decor_ids():
			var d: Decor = decor[did]
			if d.def.kind != "bench":
				continue
			var route: Array[Vector2i] = path_finder.find_path(g.cell, d.cell)
			if route.is_empty():
				continue
			if bench == null or route.size() < bench_route.size():
				bench = d
				bench_route = route
		if bench != null:
			g.state = Guest.State.WALKING
			g.target_attraction_id = -1
			g.target_decor_id = bench.id
			g.thought = NEED_THOUGHTS.get("energy", "")
			_set_route(g, bench_route)
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
	if not a.is_open or a.broken or g.rejected_ids.has(a.id) or a.price > g.money:
		return false
	if is_queue_full(a):
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
	if g.state == Guest.State.RESTING:
		g.rest_ticks_left -= 1
		if g.rest_ticks_left <= 0 or not decor.has(g.target_decor_id):
			if g.rest_ticks_left <= 0 and g.needs.has("energy"):
				g.needs["energy"] = clampf(g.needs["energy"] + balance.bench_energy_restore, 0.0, 100.0)
				g.thought = "Dejligt med en pause."
			g.state = Guest.State.WALKING
			g.target_decor_id = -1
			_choose_goal(g)
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
	if g.target_decor_id >= 0:
		var bench: Decor = decor.get(g.target_decor_id, null)
		if bench != null and bench.cell == g.cell:
			g.state = Guest.State.RESTING
			g.rest_ticks_left = balance.bench_rest_ticks
			return
		g.target_decor_id = -1
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
	if a.broken:
		reason = balance.thought_broken
	elif not a.is_open:
		reason = "Den er lukket!"
	elif a.price > price_value(a, g):
		reason = TOO_EXPENSIVE_THOUGHT
		g.happiness = maxf(0.0, g.happiness - balance.reject_happiness_penalty)
	elif a.price > g.money:
		reason = "Jeg har ikke råd!"
	elif is_queue_full(a):
		reason = QUEUE_FULL_THOUGHT
		g.happiness = maxf(0.0, g.happiness - balance.queue_full_happiness_penalty)
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
		if a.def.kind == "shop":
			_drop_litter(g)
		if a.def.kind == "ride":
			g.rides_left -= 1
		g.target_attraction_id = -1
		_choose_goal(g)
	if a.def.kind == "ride" and not guest_ids.is_empty() and a.def.reliability < 1.0 \
			and rng.randf() >= a.effective_reliability():
		_break(a)


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


# --- Personale, nedbrud, affald, dekoration (T-037) ---

func get_staff_def(type_id: String) -> StaffDef:
	if not _staff_def_cache.has(type_id):
		var path: String = STAFF_DIR + type_id + ".json"
		if not FileAccess.file_exists(path):
			return null
		_staff_def_cache[type_id] = StaffDef.from_json(path)
	return _staff_def_cache[type_id]


func register_staff_def(def: StaffDef) -> void:
	_staff_def_cache[def.id] = def


func get_decor_def(def_id: String) -> DecorDef:
	if not _decor_def_cache.has(def_id):
		var path: String = DECOR_DIR + def_id + ".json"
		if not FileAccess.file_exists(path):
			return null
		_decor_def_cache[def_id] = DecorDef.from_json(path)
	return _decor_def_cache[def_id]


func register_decor_def(def: DecorDef) -> void:
	_decor_def_cache[def.id] = def


## Ansætter på en gåbar celle. Returnerer id eller -1.
func cmd_hire_staff(type_id: String, cell: Vector2i) -> int:
	var def: StaffDef = get_staff_def(type_id)
	if def == null or not world.is_walkable(cell):
		return -1
	var s := Staff.new(_next_staff_id, def, cell)
	_next_staff_id += 1
	staff[s.id] = s
	staff_hired.emit(s)
	return s.id


func cmd_fire_staff(staff_id: int) -> bool:
	if not staff.has(staff_id):
		return false
	StaffAI.drop_task(self, staff[staff_id])
	staff.erase(staff_id)
	staff_fired.emit(staff_id)
	return true


## Flytter den ansatte (og arbejdsområdets centrum) til en gåbar celle.
func cmd_move_staff(staff_id: int, cell: Vector2i) -> bool:
	if not staff.has(staff_id) or not world.is_walkable(cell):
		return false
	var s: Staff = staff[staff_id]
	StaffAI.drop_task(self, s)
	s.cell = cell
	s.next_cell = cell
	s.home_cell = cell
	return true


func get_staff(staff_id: int) -> Staff:
	return staff.get(staff_id, null)


## on_path-dekoration kræver en sti-celle uden anden dekoration; øvrige kræver græs.
func can_place_decor(def: DecorDef, cell: Vector2i) -> bool:
	if def == null:
		return false
	if def.on_path:
		return world.get_tile(cell) == ParkWorld.Tile.PATH and _decor_ids_at(cell).is_empty()
	return world.get_tile(cell) == ParkWorld.Tile.GRASS


## Returnerer decor-id eller -1 (ugyldig celle / ikke råd).
func cmd_place_decor(def_id: String, cell: Vector2i) -> int:
	var def: DecorDef = get_decor_def(def_id)
	if not can_place_decor(def, cell) or not economy.can_afford(def.build_cost):
		return -1
	economy.spend(def.build_cost, "decor")
	if not def.on_path:
		world.place_decor_tile(cell)
	var d := Decor.new(_next_decor_id, def, cell)
	_next_decor_id += 1
	decor[d.id] = d
	_aura_dirty = true
	decor_placed.emit(d)
	return d.id


## Fjerner dekoration og refunderer 50 %.
func cmd_remove_decor(decor_id: int) -> bool:
	if not decor.has(decor_id):
		return false
	economy.earn((decor[decor_id] as Decor).def.build_cost / 2, "refund")
	_remove_decor(decor_id)
	return true


func _remove_decor(decor_id: int) -> void:
	var d: Decor = decor[decor_id]
	decor.erase(decor_id)
	if not d.def.on_path:
		world.clear_decor_tile(d.cell)
	_aura_dirty = true
	decor_removed.emit(decor_id)


func _decor_ids_at(cell: Vector2i) -> Array:
	var out: Array = []
	for did in _sorted_decor_ids():
		if (decor[did] as Decor).cell == cell:
			out.append(did)
	return out


func _sorted_decor_ids() -> Array:
	var ids: Array = decor.keys()
	ids.sort()
	return ids


func get_decor(decor_id: int) -> Decor:
	return decor.get(decor_id, null)


## Glæde/tick fra dekorationers aura på cellen (loftet ved decor_aura_max_per_tick).
func aura_at(cell: Vector2i) -> float:
	if _aura_dirty:
		_aura_dirty = false
		_aura = {}
		for did in _sorted_decor_ids():
			var d: Decor = decor[did]
			if d.def.happiness_aura <= 0.0:
				continue
			var r: int = d.def.aura_radius
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if absi(dx) + absi(dy) > r:
						continue
					var c: Vector2i = d.cell + Vector2i(dx, dy)
					_aura[c] = float(_aura.get(c, 0.0)) + d.def.happiness_aura * balance.aura_scale_per_tick
	return minf(float(_aura.get(cell, 0.0)), balance.decor_aura_max_per_tick)


## Aura, underholdere og beskidte stier.
func _apply_surroundings(g: Guest) -> void:
	var delta: float = aura_at(g.cell)
	for sid in staff:
		var s: Staff = staff[sid]
		if s.def.id == StaffAI.ENTERTAINER and absi(s.cell.x - g.cell.x) + absi(s.cell.y - g.cell.y) <= s.def.work_radius:
			delta += balance.entertainer_happiness_per_tick
	if (g.state == Guest.State.WALKING or g.state == Guest.State.LEAVING) \
			and world.get_litter(g.cell) >= balance.dirty_threshold:
		delta -= balance.happiness_penalty_dirty_per_tick
		g.thought = balance.thought_dirty
	if delta != 0.0:
		g.happiness = clampf(g.happiness + delta, 0.0, 100.0)


## Nærmeste skraldespand med plads inden for bin_radius (manhattan), ellers null.
func _bin_near(cell: Vector2i) -> Decor:
	var best: Decor = null
	var best_d: int = 0
	for did in _sorted_decor_ids():
		var d: Decor = decor[did]
		if d.def.kind != "bin" or d.fill >= balance.bin_capacity:
			continue
		var dist: int = absi(d.cell.x - cell.x) + absi(d.cell.y - cell.y)
		if dist <= balance.bin_radius and (best == null or dist < best_d):
			best = d
			best_d = dist
	return best


## Efter køb i bod: spand i nærheden fyldes, ellers (eller med lille sandsynlighed) affald på stien.
func _drop_litter(g: Guest) -> void:
	var bin: Decor = _bin_near(g.cell)
	var chance: float = balance.litter_chance_with_bin if bin != null else balance.litter_chance_after_shop
	if rng.randf() < chance:
		if world.is_walkable(g.cell):
			world.set_litter(g.cell, mini(world.get_litter(g.cell) + 1, balance.litter_max_per_cell))
	elif bin != null:
		bin.fill += 1


func _break(a: Attraction) -> void:
	a.broken = true
	a.reliability_bonus = 0.0
	var q: Array = a.queue.duplicate()
	a.queue.clear()
	for gid in q:
		if not guests.has(gid):
			continue
		var g: Guest = guests[gid]
		if g.paid > 0:
			g.money += g.paid
			economy.charge(g.paid, "tickets")  # refusion
			g.paid = 0
		g.state = Guest.State.WALKING
		g.target_attraction_id = -1
		_choose_goal(g)
		g.thought = balance.thought_broken
	attraction_broken.emit(a)


func _repair(a: Attraction) -> void:
	a.broken = false
	a.mechanic_id = -1
	for g: Guest in guests.values():
		g.rejected_ids.erase(a.id)
	attraction_repaired.emit(a)


func broken_count() -> int:
	var n: int = 0
	for a in attractions:
		if a.broken:
			n += 1
	return n


# --- Save/load (T-036) ---
# Udvidelse (T-037+): tilføj en nøgle i _park_to_save() og læs den i _park_load()
# (med default hvis den mangler). Kræver det en formatændring der ikke er bagudkompatibel,
# hæv SaveMigrations.CURRENT og tilføj et migrationstrin.

const GAME_VERSION_DEFAULT: String = "0.3"


## Fuld save inkl. envelope: {save_version, game_version, created, park}.
func to_save() -> Dictionary:
	return {
		"save_version": SaveMigrations.CURRENT,
		"game_version": str(ProjectSettings.get_setting("application/config/version", GAME_VERSION_DEFAULT)),
		"created": Time.get_datetime_string_from_system(true),
		"park": _park_to_save(),
	}


## Indlæser en save (migreres først). p_balance = null → content. Returnerer null ved ugyldig save.
## p_defs: AttractionDef/StaffDef/DecorDef der registreres før load (tests/mods) og vinder over content.
## Defs der hverken er registreret eller i content, genskabes fra savefilens snapshot.
static func from_save(d: Dictionary, p_balance: Balance = null, p_defs: Array = []) -> ParkSim:
	var m: Dictionary = SaveMigrations.migrate(d)
	if m.is_empty():
		return null
	var park: Dictionary = SaveCodec.dict(m, "park")
	var wd: Dictionary = SaveCodec.dict(park, "world")
	if not wd.has("width") or not wd.has("height"):
		return null  # ugyldig save
	var rd: Dictionary = SaveCodec.dict(park, "rng")
	var sim := ParkSim.new(int(wd["width"]), int(wd["height"]), str(rd.get("seed", "0")).to_int(), p_balance)
	for def: Variant in p_defs:
		if def is AttractionDef:
			sim.register_def(def)
		elif def is StaffDef:
			sim.register_staff_def(def)
		elif def is DecorDef:
			sim.register_decor_def(def)
	sim._park_load(park)
	return sim


func _park_to_save() -> Dictionary:
	var gl: Array = []
	var ids: Array = guests.keys()
	ids.sort()
	for gid in ids:
		gl.append((guests[gid] as Guest).to_save())
	var al: Array = []
	for a in attractions:
		al.append(a.to_save())
	return {
		# uint64 → streng (JSON-tal er double og mister præcision)
		"rng": {"seed": str(rng.seed), "state": str(rng.state)},
		"clock": clock.to_save(),
		"world": world.to_save(),
		"economy": economy.to_save(),
		"attractions": al,
		"guests": gl,
		"day": day,
		"day_tick": day_tick,
		"entry_fee": entry_fee,
		"reputation": SaveCodec.f(reputation),
		"next_guest_id": _next_guest_id,
		"spawn_counter": _spawn_counter,
		"staff": _staff_to_save(),
		"decor": _decor_to_save(),
		"next_staff_id": _next_staff_id,
		"next_decor_id": _next_decor_id,
		"config": {
			"spawn_interval_ticks": spawn_interval_ticks, "max_guests": max_guests,
			"fixed_spawn": fixed_spawn, "guest_speed": SaveCodec.f(guest_speed),
			"rides_per_guest_min": rides_per_guest_min, "rides_per_guest_max": rides_per_guest_max,
			"wander_steps_max": wander_steps_max,
		},
	}


func _park_load(park: Dictionary) -> void:
	var rd: Dictionary = SaveCodec.dict(park, "rng")
	rng.seed = str(rd.get("seed", "0")).to_int()
	if rd.has("state"):
		rng.state = str(rd["state"]).to_int()
	clock.load_save(SaveCodec.dict(park, "clock"))
	world.load_save(SaveCodec.dict(park, "world"))
	economy.load_save(SaveCodec.dict(park, "economy"))
	for ad: Variant in SaveCodec.arr(park, "attractions"):
		if not ad is Dictionary:
			continue
		var def: AttractionDef = get_def(str(ad.get("def_id", "")))
		if def == null:
			def = AttractionDef.from_dict(SaveCodec.dict(ad, "def"))  # snapshot-fallback
			register_def(def)
		var a := Attraction.from_save(ad, def)
		world.restore_attraction(a)
		_on_attraction_placed(a)  # forbinder signaler + tilføjer til attractions
	for gd: Variant in SaveCodec.arr(park, "guests"):
		if gd is Dictionary:
			var g := Guest.from_save(gd)
			guests[g.id] = g
	day = int(park.get("day", day))
	day_tick = int(park.get("day_tick", 0))
	entry_fee = int(park.get("entry_fee", entry_fee))
	reputation = SaveCodec.to_f(park.get("reputation"), reputation)
	_next_guest_id = int(park.get("next_guest_id", 1))
	var cfg: Dictionary = SaveCodec.dict(park, "config")
	spawn_interval_ticks = int(cfg.get("spawn_interval_ticks", spawn_interval_ticks))
	max_guests = int(cfg.get("max_guests", max_guests))
	fixed_spawn = bool(cfg.get("fixed_spawn", fixed_spawn))  # efter setter ovenfor
	guest_speed = SaveCodec.to_f(cfg.get("guest_speed"), guest_speed)
	rides_per_guest_min = int(cfg.get("rides_per_guest_min", rides_per_guest_min))
	rides_per_guest_max = int(cfg.get("rides_per_guest_max", rides_per_guest_max))
	wander_steps_max = int(cfg.get("wander_steps_max", wander_steps_max))
	_spawn_counter = int(park.get("spawn_counter", 0))
	for sd: Variant in SaveCodec.arr(park, "staff"):
		if not sd is Dictionary:
			continue
		var sdef: StaffDef = get_staff_def(str(sd.get("type", "")))
		if sdef == null:
			sdef = StaffDef.from_dict(SaveCodec.dict(sd, "def"))
			register_staff_def(sdef)
		var st := Staff.from_save(sd, sdef)
		staff[st.id] = st
	for dd: Variant in SaveCodec.arr(park, "decor"):
		if not dd is Dictionary:
			continue
		var ddef: DecorDef = get_decor_def(str(dd.get("def_id", "")))
		if ddef == null:
			ddef = DecorDef.from_dict(SaveCodec.dict(dd, "def"))
			register_decor_def(ddef)
		var dc := Decor.from_save(dd, ddef)
		decor[dc.id] = dc
	_next_staff_id = int(park.get("next_staff_id", 1))
	_next_decor_id = int(park.get("next_decor_id", 1))
	_aura_dirty = true
	_reachable_dirty = true


func _staff_to_save() -> Array:
	var ids: Array = staff.keys()
	ids.sort()
	var out: Array = []
	for sid in ids:
		out.append((staff[sid] as Staff).to_save())
	return out


func _decor_to_save() -> Array:
	var out: Array = []
	for did in _sorted_decor_ids():
		out.append((decor[did] as Decor).to_save())
	return out
