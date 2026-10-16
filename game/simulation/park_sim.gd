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
## T-047 (M4)
signal phase_changed(phase: StringName)
signal warning(code: StringName, data: Dictionary)
signal purchase_made(guest_id: int, building_id: int, amount: int)
signal litter_swept(cell: Vector2i)
signal ride_cycle_started(attraction_id: int)
## T-066 (M5)
signal research_unlocked(item_id: String)
signal scenario_finished(won: bool, reason: String)
## T-068: banen er ændret (stykke lagt/fjernet, færdig).
signal coaster_changed(coaster_id: int)
## T-084 (M6): gæsten kastede op på cellen (bridge: effekt + lyd).
signal guest_vomited(guest_id: int, cell: Vector2i)
## T-085 (M6): gæsten vandt en præmie i et sideshow.
signal prize_won(guest_id: int, attraction_id: int, item_id: String)
## T-086: bærbare ting.
signal item_gained(guest_id: int, item_id: StringName)
signal item_lost(guest_id: int, item_id: StringName, cell: Vector2i)
## T-090: toget passerede et splash-stykke (udledt af ride_progress i sim-ticket).
signal ride_splash(attraction_id: int, cell: Vector2i)
## M7 (T-102): salg i dette tick, building_id -> kr (højst én gang pr. tick).
signal sales_tick(sales: Dictionary)
## M7 (T-103): køens rækkefølge/køsti er ændret (bridge: placér gæster på køpladser).
signal queue_changed(attraction_id: int)
## M7 (T-104): hæveautomat, spande, bænke og affald.
signal atm_used(guest_id: int, attraction_id: int, amount: int)
signal bin_state_changed(decor_id: int, level: int)
signal guest_sat(guest_id: int, decor_id: int, seat: int)
signal guest_stood(guest_id: int)
signal litter_changed(cell: Vector2i)
## M7 (T-105): milepæle. Backfill (gamle saves) udsender kun milestones_backfilled (ingen toast).
signal milestone_achieved(id: String)
signal milestones_backfilled(ids: Array)
## M7 (T-106): fortryd-stakken ændrede sig, og en bygning blev flyttet (også sporbaner).
signal undo_changed()
signal attraction_moved(attraction_id: int)

const PHASE_DAWN: StringName = &"dawn"
const PHASE_DAY: StringName = &"day"
const PHASE_DUSK: StringName = &"dusk"
const PHASE_NIGHT: StringName = &"night"
const WARN_BROKEN_NO_MECHANIC: StringName = &"broken_no_mechanic"
const WARN_RESEARCH_DONE: StringName = &"research_done"
const WARN_GUEST_VOMIT: StringName = &"guest_vomit"

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
## Forskning (T-066). Slået fra som default (alt låst op); scenarier slår den til.
var research: Research
var milestones_state: Milestones
## null = sandbox (også ældre saves).
var scenario: Scenario = null
var _scenario_defs: Dictionary = {}  ## id -> ScenarioDef registreret før load (tests/mods)

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
var _aura_night: Dictionary = {}  ## T-104: aura om natten (lygtens night_aura)
var _bench_seat: Dictionary = {}  ## T-104: guest_id -> sædeplads (genberegnes fra resting_on)
var _phase: StringName = &""  ## afledt af day_tick, gemmes ikke
var _sales: Dictionary = {}  ## building_id -> kr i nuværende tick (T-102)
var _queues_dirty: bool = true  ## T-103: køkæder skal genberegnes
var undo_stack: UndoStack  ## T-106: gemmes ikke
var _replaying: bool = false  ## T-106: undo/redo kører → ingen nye poster


## p_balance = null → indlæs content/economy.json + guests.json (defaults ved mangler).
func _init(width: int, height: int, p_seed: int, p_balance: Balance = null) -> void:
	balance = p_balance if p_balance != null else Balance.load_default()
	economy = Economy.new(balance.start_money)
	undo_stack = UndoStack.new(balance.undo_steps)
	entry_fee = balance.entry_fee
	spawn_interval_ticks = balance.spawn_interval_ticks
	max_guests = balance.max_guests
	fixed_spawn = not balance.has_park
	reputation = balance.reputation_start
	guest_speed = balance.speed
	world = ParkWorld.new(width, height)
	clock = SimClock.new()
	path_finder = PathFinder.new(world)
	path_finder.link_usable = link_usable
	path_finder.link_price = _link_price
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed
	clock.ticked.connect(_on_tick)
	world.attraction_placed.connect(_on_attraction_placed)
	world.tile_changed.connect(_on_tile_changed)
	world.attraction_removed.connect(_on_attraction_removed)
	world.litter_changed.connect(_on_world_litter_changed)
	research = Research.new()
	research.setup(false)
	milestones_state = Milestones.load_default()
	_phase = phase()
	_update_light()


func update(delta: float) -> void:
	clock.advance(delta)


# --- Kommandoer ---

func cmd_place_path(cell: Vector2i) -> bool:
	if not world.can_place_path(cell) or not economy.can_afford(balance.path_cost):
		return false
	economy.spend(balance.path_cost, "path")
	var ok: bool = world.place_path(cell)
	if ok:
		_record("path", "Byg sti", {"cell": cell}, -balance.path_cost)
	return ok


func cmd_remove_path(cell: Vector2i) -> bool:
	if not world.remove_path(cell):
		return false
	for did in _decor_ids_at(cell):
		_remove_decor(did)
	economy.earn(balance.path_refund, "refund")
	_record("remove_path", "Fjern sti", {"cell": cell}, balance.path_refund)
	return true


## M7 (T-103): køsti (QUEUE-celle) på græs. PathFinder følger den ikke.
func cmd_place_queue_path(cell: Vector2i) -> bool:
	if not world.can_place_path(cell) or not economy.can_afford(balance.queue_path_cost):
		return false
	economy.spend(balance.queue_path_cost, "path")
	var ok: bool = world.place_queue(cell)
	if ok:
		_record("queue_path", "Byg køsti", {"cell": cell}, -balance.queue_path_cost)
	return ok


func cmd_remove_queue_path(cell: Vector2i) -> bool:
	if not world.remove_queue(cell):
		return false
	economy.earn(balance.queue_path_refund, "refund")
	_record("remove_queue_path", "Fjern køsti", {"cell": cell}, balance.queue_path_refund)
	return true


func cmd_place_attraction(def_id: String, origin: Vector2i) -> Attraction:
	var def: AttractionDef = get_def(def_id)
	if def == null or not is_unlocked(def_id) or def.is_tracked():
		return null
	if not world.can_place_attraction(def, origin) or not economy.can_afford(def.build_cost):
		return null
	economy.spend(def.build_cost, "build")
	var a: Attraction = world.place_attraction(def, origin)
	if a != null:
		a.built_tick = clock.tick
		_record("build", "Byg " + def.name, {"attraction": a}, -def.build_cost)
	return a


## Fjerner attraktionen og refunderer sell_refund (T-106: 100 % kort efter opførelse uden kunder, ellers 50 %).
func cmd_remove_attraction(attraction_id: int) -> bool:
	var refund: int = sell_refund(attraction_id)
	var a: Attraction = world.remove_attraction(attraction_id)
	if a == null:
		return false
	economy.earn(refund, "refund")
	_record("sell", "Sælg " + a.def.name, {"attraction": a}, refund)
	return true


func cmd_set_price(attraction_id: int, price: int) -> bool:
	var a: Attraction = get_attraction(attraction_id)
	if a == null or price < 0:
		return false
	_record_setting("price", "Pris", {"id": attraction_id, "key": ""}, a.price, price)
	a.price = price
	for g: Guest in guests.values():
		g.rejected_ids.erase(attraction_id)
	return true


func cmd_set_open(attraction_id: int, open: bool) -> bool:
	var a: Attraction = get_attraction(attraction_id)
	if a == null:
		return false
	a.is_open = open
	if a.is_transport():
		path_finder.invalidate()
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
		if not is_operating(a) or a.broken:  # T-043: ødelagte tæller ikke i tiltrækning (men i max_guests)
			continue
		if a.is_ride():
			raw += _excitement(a) * balance.weight_ride
		elif not a.is_atm():
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
			var nbrs: Array[Vector2i] = []
			for d in DIRS:
				nbrs.append(c + d)
			for e: Dictionary in world.links_from(c):
				if link_usable(int(e["owner_id"])):
					nbrs.append(e["to"])
			for n in nbrs:
				if not _reachable.has(n) and world.is_walkable(n):
					_reachable[n] = true
					frontier.append(n)
	return _reachable.has(approach_cell(a))


## Åben og nåbar fra indgangen – kun disse tæller i tiltrækning og max_guests.
func is_operating(a: Attraction) -> bool:
	return a.is_open and is_reachable(a)


## Er køen fuld (queue_capacity)?
func is_queue_full(a: Attraction) -> bool:
	return a.queue.size() >= queue_capacity(a)


# --- Køer (M7, T-103, ADR-005 §2) ---

## Køstiens celler × slots. Uden køsti: virtuel kø ved indgangen som før M7,
## max(queue_default_max, kapacitet × queue_max_cycles) (queue_max_cycles <= 0 = ubegrænset).
func queue_capacity(a: Attraction) -> int:
	_ensure_queues()
	if not a.queue_cells.is_empty():
		return a.queue_cells.size() * balance.queue_slots_per_cell
	if balance.queue_max_cycles <= 0.0:
		return 1 << 30
	return maxi(balance.queue_default_max, int(ceil(a.effective_capacity() * balance.queue_max_cycles)))


## Cellen gæster går til for at stille sig i kø: sti-cellen ved køens ende, ellers indgangen.
func approach_cell(a: Attraction) -> Vector2i:
	_ensure_queues()
	if a.queue_cells.is_empty():
		return a.entrance_cell
	var end: Vector2i = a.queue_cells[a.queue_cells.size() - 1]
	for d in DIRS:
		var n: Vector2i = end + d
		if n != a.entrance_cell and world.get_tile(n) == ParkWorld.Tile.PATH:
			return n
	return a.entrance_cell


## Celle for køplads i (0 = forrest). Uden køsti: indgangscellen.
func queue_slot_cell(a: Attraction, index: int) -> Vector2i:
	_ensure_queues()
	if a.queue_cells.is_empty():
		return a.entrance_cell
	var c: int = clampi(index / balance.queue_slots_per_cell, 0, a.queue_cells.size() - 1)
	return a.queue_cells[c]


## Kontinuert position (gitterenheder, cellecentrum = celle + 0.5) for køplads i.
## Pladserne ligger på række langs køstien; uden køsti i et lille gitter ved indgangen.
func queue_slot_position(a: Attraction, index: int) -> Vector2:
	_ensure_queues()
	var i: int = maxi(0, index)
	if a.queue_cells.is_empty():
		var col: int = i % 3
		var row: int = (i / 3) % 3
		return Vector2(a.entrance_cell) + Vector2(0.5 + (col - 1) * 0.3, 0.5 + (row - 1) * 0.3)
	var slots: int = balance.queue_slots_per_cell
	var c: int = i / slots
	var k: int = i % slots
	var n: int = a.queue_cells.size()
	if c >= n:  # overløb (kapaciteten er faldet): samles ved enden
		c = n - 1
		k = slots - 1
	var cell: Vector2i = a.queue_cells[c]
	var prev: Vector2i = a.entrance_cell if c == 0 else a.queue_cells[c - 1]
	var dir: Vector2 = Vector2(prev - cell)
	var t: float = 0.5 - (float(k) + 0.5) / float(slots)  # slot 0 nærmest forrest
	return Vector2(cell) + Vector2(0.5, 0.5) + dir * t


## Deterministisk visuel sideforskydning (6 baner, ±0.3 celle) ud fra gæste-id. Påvirker ikke sim.
static func guest_lane_offset(guest_id: int) -> float:
	var lane: int = posmod(guest_id * 7, 6)
	return (float(lane) - 2.5) / 2.5 * 0.3


## Gæstens visningsposition i gitterenheder (cellecentrum = celle + 0.5): køplads, når hun står
## i kø, ellers interpoleret mellem cell og next_cell med bane-forskydning (ADR-005 §1).
func guest_position(guest_id: int) -> Vector2:
	if not guests.has(guest_id):
		return Vector2(-1, -1)
	var g: Guest = guests[guest_id]
	if g.state == Guest.State.QUEUING and g.transport_id < 0:
		var a: Attraction = get_attraction(g.target_attraction_id)
		if a != null and g.queue_index >= 0:
			return queue_slot_position(a, g.queue_index)
	var c0: Vector2 = Vector2(g.cell) + Vector2(0.5, 0.5)
	var c1: Vector2 = Vector2(g.next_cell) + Vector2(0.5, 0.5)
	var pos: Vector2 = c0.lerp(c1, clampf(g.progress, 0.0, 1.0))
	var off: float = guest_lane_offset(g.id)
	var dir: Vector2 = c1 - c0
	if dir.length_squared() > 0.0001 and dir.length_squared() < 2.5:
		var side: Vector2 = Vector2(-dir.y, dir.x).normalized()
		return pos + side * off
	return pos + Vector2(off, guest_lane_offset(g.id / 6 + 3))


## Ventetid i ticks for en ny gæst bagerst i køen.
func wait_ticks_estimate(a: Attraction) -> int:
	var cap: int = maxi(1, a.effective_capacity())
	var cycles: int = int(ceil(float(a.queue.size()) / float(cap)))
	var cur: int = a.ticks_left if a.is_running() else 0
	return cur + cycles * a.ride_ticks()


func _ensure_queues() -> void:
	if not _queues_dirty:
		return
	_queues_dirty = false
	var taken: Dictionary = {}
	var ordered: Array[Attraction] = attractions.duplicate()
	ordered.sort_custom(func(x: Attraction, y: Attraction) -> bool: return x.id < y.id)
	for a in ordered:
		var chain: Array[Vector2i] = []
		if not a.is_transport():
			chain = world.queue_chain(a.entrance_cell, taken)
		for c in chain:
			taken[c] = true
		if chain != a.queue_cells:
			a.queue_cells = chain
			a.queue_dirty = true
			queue_changed.emit(a.id)
	_reachable_dirty = true


func _join_queue(g: Guest, a: Attraction) -> void:
	a.enqueue(g.id)
	g.queue_index = a.queue.size() - 1
	g.patience = _patience_for(g)
	g.blocked_ticks = 0


## Tålmodighed i [min, max] ud fra et hash af gæst og besøg (bruger ikke sim-RNG).
func _patience_for(g: Guest) -> float:
	var span: int = int(balance.queue_patience_max - balance.queue_patience_min)
	if span <= 0:
		return balance.queue_patience_min
	var h: int = posmod((g.id * 73856093) ^ ((g.rides_left + 1) * 19349663) ^ (g.money * 83492791), span + 1)
	return balance.queue_patience_min + float(h)


## Tålmodighed tikker ned (halvt så hurtigt med underholdning). Under 0: glæden falder og
## tanken queue_bored; når tabet når queue_abandon_happiness, opgiver gæsten (ingen refusion).
func _tick_queue_patience(g: Guest) -> void:
	if g.transport_id >= 0:
		return
	var a: Attraction = get_attraction(g.target_attraction_id)
	if a == null:
		return
	g.patience -= balance.queue_entertained_factor if _entertained(g) else 1.0
	if g.patience > 0.0:
		return
	g.happiness = clampf(g.happiness - balance.queue_impatient_decay, 0.0, 100.0)
	g.thought = M7_THOUGHTS["queue_bored"]
	var limit: float = balance.queue_abandon_happiness / maxf(1e-6, balance.queue_impatient_decay)
	if -g.patience >= limit:
		a.dequeue(g.id)
		g.queue_index = -1
		g.paid = 0
		g.state = Guest.State.WALKING
		g.rejected_ids.append(a.id)
		g.target_attraction_id = -1
		_choose_goal(g)
		g.thought = M7_THOUGHTS["queue_gave_up"]


func _entertained(g: Guest) -> bool:
	for sid in staff:
		var s: Staff = staff[sid]
		if s.def.id == StaffAI.ENTERTAINER and absi(s.cell.x - g.cell.x) + absi(s.cell.y - g.cell.y) <= s.def.work_radius:
			return true
	return false


func _sync_queue_indices() -> void:
	_ensure_queues()
	for a in attractions:
		if not a.queue_dirty:
			continue
		a.queue_dirty = false
		for i in a.queue.size():
			var gid: int = int(a.queue[i])
			if guests.has(gid):
				(guests[gid] as Guest).queue_index = i
		queue_changed.emit(a.id)


# --- Belægning (M7, T-103, ADR-005 §1) ---

func occupancy(cell: Vector2i) -> int:
	return world.occupancy(cell)


## Celler, der har været fulde længere end crowd_ticks (overlay).
func crowded_cells() -> Array[Vector2i]:
	return world.crowded_cells(balance.crowd_ticks)


func _counts_on_cell(g: Guest) -> bool:
	return g.state == Guest.State.WALKING or g.state == Guest.State.LEAVING or g.state == Guest.State.RESTING


func _rebuild_occupancy() -> void:
	world.occupancy_reset()
	_flow_built = false
	_reroute_budget = REROUTES_PER_TICK
	var ids: Array = guests.keys()
	ids.sort()
	for gid in ids:
		var g: Guest = guests[gid]
		if _counts_on_cell(g):
			world.occupancy_add(g.cell, 1)


var _flow_built: bool = false
## ADR-005 §7: højst så mange ekstra A*-omlægninger pr. tick (resten prøver ved næste interval).
const REROUTES_PER_TICK: int = 8
var _reroute_budget: int = REROUTES_PER_TICK


## Bygges først, når en gæst blokeres i et tick (billigt uden trængsel).
func _build_flow() -> void:
	if _flow_built:
		return
	_flow_built = true
	_counterflow.clear()
	_cell_guests.clear()
	var ids: Array = guests.keys()
	ids.sort()
	for gid in ids:
		var g: Guest = guests[gid]
		if not _counts_on_cell(g):
			continue
		var cl: Array = _cell_guests.get(g.cell, [])
		cl.append(g.id)
		_cell_guests[g.cell] = cl
		if g.next_cell != g.cell:
			var k: Vector4i = Vector4i(g.cell.x, g.cell.y, g.next_cell.x, g.next_cell.y)
			var l: Array = _counterflow.get(k, [])
			l.append(g.id)
			_counterflow[k] = l


## Celle -> gæste-id'er på cellen ved tickets start (id-orden).
var _cell_guests: Dictionary = {}


func _swap_any(g: Guest, cell: Vector2i) -> bool:
	_build_flow()
	for oid: int in _cell_guests.get(cell, []):
		if oid == g.id or not guests.has(oid):
			continue
		var o: Guest = guests[oid]
		if o.cell != cell or not _counts_on_cell(o) or o.state == Guest.State.RESTING:
			continue
		world.occupancy_add(cell, -1)
		world.occupancy_add(g.cell, 1)
		if o.next_cell == g.cell:
			o.next_cell = o.path.pop_front() if not o.path.is_empty() else g.cell
		else:
			if o.next_cell != o.cell:
				o.path.push_front(o.next_cell)
			o.next_cell = cell
		o.cell = g.cell
		o.progress = 0.0
		o.blocked_ticks = 0
		return true
	return false


## Gæste-id'er, der vil fra a til b (bygges pr. tick i id-orden): modgående trafik bytter plads.
var _counterflow: Dictionary = {}


## Bytter plads med en modgående gæst i `cell` (belægningen er uændret). Returnerer true ved byt.
func _swap_with_counterflow(g: Guest, cell: Vector2i) -> bool:
	_build_flow()
	var k: Vector4i = Vector4i(cell.x, cell.y, g.cell.x, g.cell.y)
	var l: Array = _counterflow.get(k, [])
	while not l.is_empty():
		var oid: int = int(l.pop_front())
		if not guests.has(oid):
			continue
		var o: Guest = guests[oid]
		if o.cell != cell or o.next_cell != g.cell or not _counts_on_cell(o):
			continue
		world.occupancy_add(cell, -1)
		world.occupancy_add(g.cell, 1)
		o.cell = g.cell
		o.progress = 0.0
		o.blocked_ticks = 0
		o.next_cell = o.cell if o.path.is_empty() else o.path.pop_front()
		return true
	return false


## Kan gæsten træde ind i cellen? Parkens indgang er undtaget; efter 3 × crowd_reroute_ticks
## presser hun sig igennem (ingen fastlåsning).
func _cell_has_room(g: Guest, cell: Vector2i) -> bool:
	if cell == world.entrance or world.occupancy(cell) < balance.max_guests_per_cell:
		return true
	# Modgående trafik: byt plads med en gæst, der vil den anden vej (belægningen er uændret).
	if _swap_with_counterflow(g, cell):
		return true
	# Efter 3 × crowd_reroute_ticks presser hun sig forbi: bytter plads med en gæst i cellen,
	# som får et skridt tilbage på sin rute. Belægningen er uændret, og ingen kan låses inde.
	if g.blocked_ticks >= 3 * balance.crowd_reroute_ticks:
		_swap_any(g, cell)
		return true
	return false


func _reroute_around(g: Guest, blocked: Vector2i) -> void:
	var dest: Vector2i = g.path[g.path.size() - 1] if not g.path.is_empty() else g.next_cell
	if dest == blocked and g.path.is_empty():
		if g.target_attraction_id < 0 and g.target_decor_id < 0 and g.state == Guest.State.WALKING:
			_wander_step(g)
		return
	if _reroute_budget <= 0:
		return
	_reroute_budget -= 1
	var route: Array[Vector2i] = path_finder.find_path_avoiding(g.cell, dest, blocked, balance.crowd_reroute_penalty)
	if not route.is_empty():
		var old_next: Vector2i = g.next_cell
		var old_progress: float = g.progress
		_set_route(g, route)
		if g.next_cell == old_next:
			g.progress = old_progress


func _on_tile_changed(_cell: Vector2i, _tile: int) -> void:
	_reachable_dirty = true
	_queues_dirty = true
	_ensure_queues()


func _has_open_ride() -> bool:
	for a in attractions:
		if is_operating(a) and a.is_ride():
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
		"vomit": world.total_vomit(),
	}


const LEAVE_THOUGHT: String = "Jeg vil hjem."
const TOO_EXPENSIVE_THOUGHT: String = "For dyrt!"
const QUEUE_FULL_THOUGHT: String = "Køen er for lang!"


## Maks betalingsvilje (GDD). Uden gæst: glæde = happiness_start, behov = 0.
func price_value(a: Attraction, g: Guest = null) -> float:
	var happiness: float = g.happiness if g != null else balance.happiness_start
	var v: float
	if a.is_ride():
		v = balance.ride_price_base + _excitement(a) * balance.ride_price_per_excitement
	else:
		var need: float = 0.0
		if g != null:
			for k: String in a.def.satisfies:
				if a.satisfies_need(k):
					need = maxf(need, float(g.needs.get(k, 0.0)))
		v = a.def.ticket_price * (1.0 + need / 100.0)
		for rid in a.recipes:
			v *= 1.0 + float(a.def.recipe(rid).get("price_tolerance", 0.0))
	return v * (balance.happiness_price_base + happiness * balance.happiness_price_factor)


## Billigste pris blandt åbne bygninger (-1 hvis ingen er åbne).
func cheapest_open_price() -> int:
	var best: int = -1
	for a in attractions:
		if a.is_open and not a.is_atm() and (best < 0 or a.price < best):
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


# --- Tid på dagen (T-047) ---

## 0 = midnat, 0.5 = middag. day_tick 0 = balance.day_start_time.
func time_of_day() -> float:
	return fposmod(balance.day_start_time + float(day_tick) / float(maxi(1, balance.day_ticks)), 1.0)


## Sand når time_of_day ∉ [dawn, dusk).
func is_night() -> bool:
	var t: float = time_of_day()
	return t < balance.dawn or t >= balance.dusk


func phase() -> StringName:
	var t: float = time_of_day()
	if t >= balance.night or t < balance.dawn:
		return PHASE_NIGHT
	if t < balance.day_phase:
		return PHASE_DAWN
	if t < balance.dusk:
		return PHASE_DAY
	return PHASE_DUSK


## "HH:MM" (ASCII).
func clock_text() -> String:
	var minutes: int = int(floor(time_of_day() * 1440.0 + 1e-6)) % 1440
	return "%02d:%02d" % [minutes / 60, minutes % 60]


func _update_phase() -> void:
	var p: StringName = phase()
	if p != _phase:
		_phase = p
		phase_changed.emit(p)


func has_mechanic() -> bool:
	for sid in staff:
		if (staff[sid] as Staff).def.id == StaffAI.MECHANIC:
			return true
	return false


## Ekstern service: kun når ingen mekaniker er ansat.
func _tick_self_repair() -> void:
	if balance.self_repair_ticks <= 0 or has_mechanic():
		return
	for a in attractions.duplicate():
		if not a.broken:
			continue
		a.self_repair_elapsed += 1
		if a.self_repair_elapsed >= balance.self_repair_ticks:
			if balance.self_repair_cost > 0:
				economy.charge(balance.self_repair_cost, "repairs")
			_repair(a)


# --- Tick ---

func _on_attraction_placed(a: Attraction) -> void:
	attractions.append(a)
	_queues_dirty = true
	_ensure_queues()
	a.ride_finished.connect(_on_ride_finished.bind(a))
	a.ride_started.connect(_on_ride_started.bind(a))


func _on_attraction_removed(a: Attraction) -> void:
	attractions.erase(a)
	for sig: Signal in [a.ride_finished, a.ride_started]:
		for c: Dictionary in sig.get_connections():
			var cb: Callable = c["callable"]
			if cb.get_object() == self:
				sig.disconnect(cb)
	_queues_dirty = true
	_ensure_queues()
	var affected: Array = a.queue + a.riders
	a.clear_queue()
	a.riders.clear()
	for gid in affected:
		if guests.has(gid):
			var g: Guest = guests[gid]
			g.money += g.paid
			g.paid = 0
			g.state = Guest.State.WALKING
			g.target_attraction_id = -1
			g.transport_id = -1
			g.queue_index = -1
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
		var tl_before: int = a.ticks_left if a.is_running() else -1
		a.tick()
		if tl_before >= 0 and a.profile != null and a.profile.splashes > 0:
			_check_splash(a, tl_before)
	_ensure_queues()
	_rebuild_occupancy()
	_update_light()
	var ids: Array = guests.keys()
	ids.sort()
	for gid in ids:
		if guests.has(gid):
			var g: Guest = guests[gid]
			if _update_needs(g):
				_tick_guest(g)
	world.update_crowd(balance.max_guests_per_cell)
	_sync_queue_indices()
	if day_tick % hour_ticks() == 0:
		_tick_items_hour()
	StaffAI.tick_all(self)
	_tick_self_repair()
	_update_phase()
	_tick_milestones()
	if not _sales.is_empty():
		var sales: Dictionary = _sales
		_sales = {}
		sales_tick.emit(sales)


## T-090: ride_splash når toget i dette tick passerer slutningen af et splash-stykke.
func _check_splash(a: Attraction, tl_before: int) -> void:
	var p0: float = a.profile.position_at(a.ride_progress_at(tl_before))
	var tl_after: int = a.ticks_left if a.is_running() else 0
	var p1: float = a.profile.position_at(a.ride_progress_at(tl_after))
	for i in a.profile.splash_s.size():
		var sp: float = a.profile.splash_s[i]
		if p0 < sp and p1 >= sp:
			var pi: int = a.profile.splash_pieces[i]
			ride_splash.emit(a.id, a.track.pieces[pi].cell if pi < a.track.pieces.size() else a.origin)


func _end_day() -> void:
	for a in attractions:
		a.riders_today = 0
	for a in attractions:
		var upkeep: int = a.upkeep_per_day()
		if upkeep > 0:
			economy.charge(upkeep, "running")
			a.upkeep_total += upkeep
		a.revenue_days.append(a.revenue_today)
		while a.revenue_days.size() > 7:
			a.revenue_days.remove_at(0)
		a.revenue_today = 0
		a.customers_today = 0
		if a.payback_day < 0 and a.build_value() > 0 and _net_total(a) >= a.build_value():
			a.payback_day = day
	var sids: Array = staff.keys()
	sids.sort()
	for sid in sids:
		var w: int = (staff[sid] as Staff).def.wage_per_day
		if w > 0:
			economy.charge(w, "wages")
	_research_day()
	_milestones_day()
	economy.close_day(day)
	_scenario_day()
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
	if g.nausea > 0.0:
		g.nausea = maxf(0.0, g.nausea - balance.nausea_decay)
	if g.wet_ticks > 0:
		g.wet_ticks -= 1
		if phase() == PHASE_DAY:
			g.happiness = clampf(g.happiness + balance.wet_happiness_per_tick, 0.0, 100.0)
	if g.state != Guest.State.RIDING:
		_apply_surroundings(g)
	if g.state == Guest.State.QUEUING and g.happiness < balance.leave_happiness:
		# T-033: utilfredse gæster opgiver køen og går hjem (betalt billet refunderes ikke).
		var q: Attraction = get_attraction(g.transport_id if g.transport_id >= 0 else g.target_attraction_id)
		if q != null:
			q.dequeue(g.id)
		g.queue_index = -1
		g.transport_id = -1
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
	g.intensity_tolerance = rng.randf_range(balance.intensity_tolerance_min, balance.intensity_tolerance_max)
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
	if g.leaving:
		_start_leaving(g)
		return
	var leave_reason: String = _leave_reason(g)
	if leave_reason == "no_money" and _try_atm(g):
		return
	# T-149: lav saldo → hæv i forvejen (deterministisk; samme betingelser som ovenfor)
	if leave_reason == "" and g.money < balance.atm_low_money and _try_atm(g):
		return
	if leave_reason != "":
		g.thought = LEAVE_THOUGHT
		g.leave_reason = leave_reason
		_start_leaving(g)
		return
	g.target_decor_id = -1
	# 0) Træt → nærmeste bænk (T-037)
	if float(g.needs.get("energy", 0.0)) >= balance.bench_seek_energy:
		var bench: Decor = null
		var bench_route: Array[Vector2i] = []
		for did in _sorted_decor_ids():
			var d: Decor = decor[did]
			if d.def.kind != "bench" or bench_free_seats(d) <= 0:
				continue
			var route: Array[Vector2i] = _route(g, d.cell)
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
		# ADR-005 §3: score = manhattan + kølængde × queue_weight_cells; fyldte køer springes over.
		var cands: Array = []
		for a in attractions:
			if not a.satisfies_need(need) or not _usable(g, a):
				continue
			var ac: Vector2i = approach_cell(a)
			var sc: float = absi(ac.x - g.cell.x) + absi(ac.y - g.cell.y) + a.queue.size() * balance.queue_weight_cells
			cands.append([sc, a.id, a])
		cands.sort_custom(func(x: Array, y: Array) -> bool:
			return float(x[0]) < float(y[0]) or (float(x[0]) == float(y[0]) and int(x[1]) < int(y[1])))
		var best: Attraction = null
		var best_route: Array[Vector2i] = []
		for c: Array in cands:
			var route: Array[Vector2i] = _route(g, approach_cell(c[2]))
			if not route.is_empty():
				best = c[2]
				best_route = route
				break
		if best != null:
			g.seeking_need = need
			g.thought = NEED_THOUGHTS.get(need, "")
			_go_to(g, best, best_route)
			return
		if g.thought != TOO_EXPENSIVE_THOUGHT:
			g.thought = NEED_THOUGHTS.get(need, "")
	# 1b) Impulskøb (T-119): nær butik med en ting, gæsten ikke har.
	if _try_impulse(g):
		return
	# 2) Forlystelser
	if g.rides_left > 0:
		var options: Array[Attraction] = []
		for a in attractions:
			if (a.is_ride() or a.is_sideshow() or a.is_transport()) and _usable(g, a) \
					and not _route(g, approach_cell(a)).is_empty():
				options.append(a)
		if not options.is_empty():
			# Vægtet efter excitement (min. vægt 1); for tamme forlystelser vægtes ned (T-084).
			var total: int = 0
			for o in options:
				total += _ride_weight(g, o)
			var r: int = rng.randi_range(0, total - 1)
			var a: Attraction = options[options.size() - 1]
			for o in options:
				r -= _ride_weight(g, o)
				if r < 0:
					a = o
					break
			_go_to(g, a, _route(g, approach_cell(a)))
			if _too_tame(g, a):
				g.thought = TOO_TAME_THOUGHT
			return
		if g.wander_steps < wander_steps_max:
			g.state = Guest.State.WALKING
			g.target_attraction_id = -1
			_wander_step(g)
			return
	_start_leaving(g)


## T-119: impulskøb. Nærmeste brugbare shop med carry_item (som gæsten ikke har) inden for
## impulse_radius sti-celler; sandsynlighed = base × glæde/100 × (1 - pris/penge × sensitivity).
func _impulse_chance(g: Guest, a: Attraction) -> float:
	if g.happiness < balance.impulse_min_happiness or g.money <= 0:
		return 0.0
	var afford: float = 1.0 - float(a.price) / float(g.money) * balance.impulse_price_sensitivity
	return balance.impulse_base_chance * clampf(g.happiness / 100.0, 0.0, 1.0) * clampf(afford, 0.0, 1.0)


func _try_impulse(g: Guest) -> bool:
	if balance.impulse_base_chance <= 0.0 or g.happiness < balance.impulse_min_happiness:
		return false
	var best: Attraction = null
	var best_route: Array[Vector2i] = []
	for a in attractions:
		if a.def.kind != "shop" or a.def.carry_item == "" \
				or g.items.has(StringName(a.def.carry_item)):
			continue
		if not a.is_open or a.broken or g.rejected_ids.has(a.id) or a.price > g.money:
			continue
		var ac: Vector2i = approach_cell(a)
		var d: Vector2i = (ac - g.cell).abs()
		if d.x + d.y > balance.impulse_radius:
			continue
		var route: Array[Vector2i] = _route(g, ac)
		if route.is_empty() or route.size() - 1 > balance.impulse_radius:
			continue
		if best == null or route.size() < best_route.size():
			best = a
			best_route = route
	if best == null or rng.randf() >= _impulse_chance(g, best) or not _usable(g, best):
		return false
	_go_to(g, best, best_route)
	return true


## GDD: glæde < leave_happiness (unhappy), energy >= leave_energy (tired) eller
## penge < billigste åbne pris (no_money). "" = bliver.
func _leave_reason(g: Guest) -> String:
	if g.happiness < balance.leave_happiness:
		return "unhappy"
	if float(g.needs.get("energy", 0.0)) >= balance.leave_energy:
		return "tired"
	var cheapest: int = cheapest_open_price()
	if cheapest >= 0 and g.money < cheapest:
		return "no_money"
	return ""


## Åben, ikke afvist, til at betale og under betalingsvilje.
## Er prisen over betalingsviljen afvises bygningen (tanke "For dyrt!", glæde-straf).
func _usable(g: Guest, a: Attraction) -> bool:
	if not a.is_open or a.broken or g.rejected_ids.has(a.id) or a.price > g.money:
		return false
	if a.is_ride() and _too_intense(g, a):
		g.thought = TOO_INTENSE_THOUGHT
		g.rejected_ids.append(a.id)
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
	g.leaving = true
	g.seeking_need = ""
	g.target_decor_id = -1
	g.target_attraction_id = -1
	var route: Array[Vector2i] = _route(g, world.entrance)
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
	if g.state == Guest.State.QUEUING:
		_tick_queue_patience(g)
		return
	if g.state == Guest.State.RIDING:
		return
	if g.state == Guest.State.RESTING:
		g.rest_ticks_left -= 1
		if g.rest_ticks_left <= 0 or not decor.has(g.target_decor_id):
			if g.rest_ticks_left <= 0 and g.needs.has("energy"):
				g.needs["energy"] = clampf(g.needs["energy"] + balance.bench_energy_restore, 0.0, 100.0)
				g.thought = "Dejligt med en pause."
			_stand_up(g)
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
		if absi(g.next_cell.x - g.cell.x) + absi(g.next_cell.y - g.cell.y) > 1:
			_board_transport(g)
			return
		if g.progress + guest_speed >= 1.0 - 1e-6 and not _cell_has_room(g, g.next_cell):
			# ADR-005 §1: cellen er fuld – vent, og læg ruten om efter crowd_reroute_ticks.
			g.blocked_ticks += 1
			if g.blocked_ticks % balance.crowd_reroute_ticks == 0 and g.blocked_ticks < 3 * balance.crowd_reroute_ticks:
				_reroute_around(g, g.next_cell)
			return
		g.progress += guest_speed
		if g.progress < 1.0 - 1e-6:
			return
		if _counts_on_cell(g):
			world.occupancy_add(g.cell, -1)
			world.occupancy_add(g.next_cell, 1)
		g.cell = g.next_cell
		g.progress = 0.0
		g.blocked_ticks = 0
		if g.litter_steps_left > 0:
			g.litter_steps_left -= 1
			if g.litter_steps_left == 0:
				_drop_litter(g)
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
		if bench != null and bench.cell == g.cell and bench_free_seats(bench) > 0:
			_sit_down(g, bench)
			return
		g.target_decor_id = -1
	if g.target_attraction_id >= 0:
		var a: Attraction = get_attraction(g.target_attraction_id)
		if a != null and approach_cell(a) == g.cell:
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
	elif a.is_ride() and _too_intense(g, a):
		reason = TOO_INTENSE_THOUGHT
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
	_record_sale(g, a, a.price)
	a.total_visitors += 1
	a.customers_today += 1
	g.state = Guest.State.QUEUING
	_join_queue(g, a)
	return ""


## T-102: bogfører et salg (billet/vare) og samler det til sales_tick.
func _record_sale(g: Guest, a: Attraction, amount: int) -> void:
	economy.earn(amount, "tickets")
	purchase_made.emit(g.id, a.id, amount)
	a.total_revenue += amount
	a.revenue_today += amount
	if amount > 0:
		_sales[a.id] = int(_sales.get(a.id, 0)) + amount


func _net_total(a: Attraction) -> int:
	return a.total_revenue - a.upkeep_total - a.supplies_total - a.prize_cost_total


func _on_ride_started(a: Attraction) -> void:
	for gid in a.riders:
		if guests.has(gid):
			(guests[gid] as Guest).state = Guest.State.RIDING
			(guests[gid] as Guest).queue_index = -1
	if a.is_ride() or a.is_transport():
		ride_cycle_started.emit(a.id)


func _on_ride_finished(guest_ids: Array, a: Attraction) -> void:
	for gid in guest_ids:
		if not guests.has(gid):
			continue
		var g: Guest = guests[gid]
		if a.is_transport() and g.transport_id >= 0:
			_finish_transport(g, a)
			continue
		_exit_at(g, a)
		if a.is_transport():  # T-145: forlystelsestur – stig af ved den anden station
			_exit_at_other_station(g, a)
		_apply_visit(g, a)
		if a.is_atm():
			_atm_withdraw(g, a)
		if a.def.kind == "shop":
			_apply_recipes(g, a)
			_price_effects(g, a)
			if a.def.carry_item != "":
				_give_item(g, StringName(a.def.carry_item))
			g.litter_steps_left = rng.randi_range(1, maxi(1, balance.litter_carry_cells))
		if a.is_sideshow():
			_sideshow_result(g, a)
		if a.is_ride() or a.is_sideshow() or a.is_transport():
			g.rides_left -= 1
		g.target_attraction_id = -1
		_choose_goal(g)
		if a.def.wet_thirst != 0.0 or a.def.kind == "flume":
			_get_wet(g, a)
		if a.is_ride():
			_after_ride_nausea(g, a)
	if (a.is_ride() or a.is_transport()) and not guest_ids.is_empty() and a.def.reliability < 1.0 \
			and rng.randf() >= a.effective_reliability():
		_break(a)


## Udgang: indgangscellen (eller en nabosti med plads, så gæster ikke hober sig op – ADR-005 §1).
## Med køsti, hvor indgangen ikke kan nås, bliver gæsten ved køens ende.
func _exit_at(g: Guest, a: Attraction) -> void:
	var cands: Array[Vector2i] = []
	if world.is_walkable(a.entrance_cell):
		is_reachable(a)  # bygger _reachable
		if g.cell == a.entrance_cell or _reachable.has(a.entrance_cell):
			cands.append(a.entrance_cell)
			for d in DIRS:
				var n: Vector2i = a.entrance_cell + d
				if world.get_tile(n) == ParkWorld.Tile.PATH and _reachable.has(n):
					cands.append(n)
	if cands.is_empty():
		cands.append(g.cell)
	var pick: Vector2i = cands[0]
	for c in cands:
		if world.occupancy(c) < balance.max_guests_per_cell:
			pick = c
			break
	g.cell = pick
	g.next_cell = pick
	g.path.clear()
	g.progress = 0.0
	world.occupancy_add(pick, 1)


## T-090: vandbane – tørst += wet_thirst og våd i balance.wet_ticks.
func _get_wet(g: Guest, a: Attraction) -> void:
	if g.needs.has("thirst"):
		g.needs["thirst"] = clampf(g.needs["thirst"] + a.def.wet_thirst, 0.0, 100.0)
	g.wet_ticks = balance.wet_ticks


func _apply_visit(g: Guest, a: Attraction) -> void:
	var relieved: bool = g.seeking_need != "" and a.satisfies_need(g.seeking_need)
	for k: String in a.def.satisfies:
		if g.needs.has(k):
			g.needs[k] = clampf(g.needs[k] + float(a.def.satisfies[k]), 0.0, 100.0)
	# Sideshow: glæden afgøres af gevinst/tab (_sideshow_result).
	var gain: float = (0.0 if a.is_sideshow() else float(_excitement(a))) \
		+ (balance.need_relief_happiness if relieved else 0.0)
	g.happiness = clampf(g.happiness + gain, 0.0, 100.0)
	g.paid = 0
	g.seeking_need = ""
	g.rejected_ids.clear()
	g.thought = "Det var godt!" if relieved else ("Sjovt!" if a.is_ride() else "")


const PRIZE_THOUGHT: String = "Jeg vandt en præmie!"
const NO_PRIZE_THOUGHT: String = "Øv, ingen præmie."


## T-085: sim-RNG afgør gevinst. Gevinst → præmieudgift, glæde og bærbar ting; tab → excitement som glæde.
func _sideshow_result(g: Guest, a: Attraction) -> void:
	if a.def.win_chance > 0.0 and rng.randf() < a.def.win_chance:
		a.prizes_won += 1
		if a.def.prize_cost > 0:
			economy.charge(a.def.prize_cost, "prizes")
			a.prize_cost_total += a.def.prize_cost
		g.happiness = clampf(g.happiness + a.def.prize_happiness, 0.0, 100.0)
		g.thought = PRIZE_THOUGHT
		if a.def.prize_item != "":
			_give_item(g, StringName(a.def.prize_item))
		prize_won.emit(g.id, a.id, a.def.prize_item)
	else:
		g.happiness = clampf(g.happiness + float(a.def.excitement), 0.0, 100.0)
		g.thought = NO_PRIZE_THOUGHT


## Giver gæsten en bærbar ting (maks. én af hver). T-086 udvider (item_gained m.m.).
func _give_item(g: Guest, item_id: StringName) -> bool:
	if g.items.has(item_id):
		return false
	g.items.append(item_id)
	item_gained.emit(g.id, item_id)
	return true


const ITEM_LOST_THOUGHT: String = "Åh nej, min ballon fløj væk!"
var _item_defs: Dictionary = {}
var _item_defs_loaded: bool = false


func item_def(item_id: StringName) -> ItemDef:
	if not _item_defs_loaded:
		_item_defs = ItemDef.load_all()
		_item_defs_loaded = true
	return _item_defs.get(item_id) as ItemDef


## Antal ticks pr. spil-time (døgnet = 24 timer).
func hour_ticks() -> int:
	return maxi(1, balance.day_ticks / 24)


## T-086: kører én gang pr. spil-time. Egen glæde, tab (sim-RNG) og aura (manhattan).
func _tick_items_hour() -> void:
	var ids: Array = guests.keys()
	ids.sort()
	var auras: Array = []  # [cell, radius, amount, guest_id]
	for gid in ids:
		var g: Guest = guests[gid]
		for item_id: StringName in g.items.duplicate():
			var d: ItemDef = item_def(item_id)
			if d == null:
				continue
			g.happiness = clampf(g.happiness + d.happiness_per_hour, 0.0, 100.0)
			if d.lose_chance_per_hour > 0.0 and rng.randf() < d.lose_chance_per_hour:
				g.items.erase(item_id)
				g.thought = ITEM_LOST_THOUGHT
				item_lost.emit(g.id, item_id, g.cell)
				continue
			if d.aura_radius > 0 and d.aura_happiness != 0.0:
				auras.append([g.cell, d.aura_radius, d.aura_happiness, g.id])
	if auras.is_empty():
		return
	for gid in ids:
		var o: Guest = guests[gid]
		var bonus: float = 0.0
		for au: Array in auras:
			if int(au[3]) == o.id:
				continue
			var c: Vector2i = au[0]
			if absi(c.x - o.cell.x) + absi(c.y - o.cell.y) <= int(au[1]):
				bonus += float(au[2])
		if bonus != 0.0:
			o.happiness = clampf(o.happiness + bonus, 0.0, 100.0)


## T-086: info om en gæst til UI ({} hvis den ikke findes).
func guest_info(guest_id: int) -> Dictionary:
	if not guests.has(guest_id):
		return {}
	var g: Guest = guests[guest_id]
	var its: Array = []
	for it in g.items:
		its.append(String(it))
	return {
		"id": g.id, "cell": g.cell, "happiness": g.happiness, "money": g.money,
		"thought": g.thought, "needs": g.needs.duplicate(), "items": its,
		"nausea": g.nausea, "intensity_tolerance": g.intensity_tolerance,
		"state": guest_state_name(g), "wet_ticks": g.wet_ticks,
		"leaving": g.leaving, "leave_reason": g.leave_reason, "atm_uses": g.atm_uses,
		"resting_on": g.resting_on,
	}


## T-085: nøgletal for en attraktion ({} hvis den ikke findes).
func attraction_stats(attraction_id: int) -> Dictionary:
	var a: Attraction = get_attraction(attraction_id)
	if a == null:
		return {}
	return {
		"id": a.id, "def_id": a.def.id, "kind": a.def.kind, "price": a.price,
		"total_visitors": a.total_visitors, "total_revenue": a.total_revenue,
		"queue": a.queue.size(), "riders": a.riders.size(), "broken": a.broken, "is_open": a.is_open,
		"intensity": a.intensity_value(_rating_scale()), "nausea": a.nausea_value(_rating_scale()),
		"excitement": _excitement(a), "win_chance": a.def.win_chance,
		"prizes_won": a.prizes_won, "prize_cost_total": a.prize_cost_total,
		"riders_today": a.riders_today,
		"splashes": a.profile.splashes if a.profile != null else 0,
		"revenue_today": a.revenue_today,
		"revenue_yesterday": a.revenue_days[a.revenue_days.size() - 1] if not a.revenue_days.is_empty() else 0,
		"revenue_total": a.total_revenue, "upkeep_total": a.upkeep_total,
		"supplies_total": a.supplies_total, "net_total": _net_total(a),
		"customers_today": a.customers_today, "revenue_days": Array(a.revenue_days),
		"payback_day": a.payback_day, "config": effective_config(a.id),
		"recipes": a.recipes.duplicate(),
		"queue_length": a.queue.size(), "queue_capacity": queue_capacity(a),
		"queue_cells": a.queue_cells.size(), "wait_ticks_estimate": wait_ticks_estimate(a),
	}


# --- M7 (T-102): config, opskrifter, prisvirkninger ---

const TOO_MUCH_THOUGHT: String = "Jeg spiste for meget."
## M7-tanke-id'er → standardtekst (UI kan oversætte via id'et).
const M7_THOUGHTS: Dictionary = {
	"too_much": TOO_MUCH_THOUGHT,
	"queue_too_long": QUEUE_FULL_THOUGHT,
	"queue_bored": "Det tager for lang tid!",
	"queue_gave_up": "Jeg gider ikke vente mere.",
	"crowded": "Her er alt for mange mennesker!",
	"tired": "Jeg er træt.",
	"no_money": "Jeg har ikke flere penge.",
	"unhappy": "Jeg keder mig her.",
	"dark": "Her er mørkt.",
}


## Sætter en config-nøgle (clamp til min/max). Gælder fra næste tur. Sporbaner har ingen config.
func cmd_set_config(attraction_id: int, key: String, value: float) -> bool:
	var a: Attraction = get_attraction(attraction_id)
	if a == null or a.is_tracked() or not a.def.config.has(key):
		return false
	var e: Dictionary = a.def.config[key]
	var v: float = clampf(value, float(e["min"]), float(e["max"]))
	if key != "speed":
		v = round(v)
	_record_setting("config", "Indstilling", {"id": attraction_id, "key": key},
		float(a.config.get(key, float(e["default"]))), v)
	if v == float(e["default"]):
		a.config.erase(key)
	else:
		a.config[key] = v
	for g: Guest in guests.values():
		g.rejected_ids.erase(attraction_id)
	return true


func cmd_set_recipe(attraction_id: int, recipe_id: String, on: bool) -> bool:
	var a: Attraction = get_attraction(attraction_id)
	if a == null or a.def.recipe(recipe_id).is_empty():
		return false
	if on != a.recipes.has(recipe_id):
		_record("recipe", "Opskrift", {"id": attraction_id, "recipe": recipe_id, "on": on}, 0)
	if on and not a.recipes.has(recipe_id):
		a.recipes.append(recipe_id)
		a.recipes.sort()
	elif not on:
		a.recipes.erase(recipe_id)
	for g: Guest in guests.values():
		g.rejected_ids.erase(attraction_id)
	return true


## {capacity, ride_ticks, speed, upkeep_per_day, excitement, intensity, nausea} ({} hvis ukendt).
func effective_config(attraction_id: int) -> Dictionary:
	var a: Attraction = get_attraction(attraction_id)
	if a == null:
		return {}
	return {
		"capacity": a.effective_capacity(),
		"ride_ticks": int(round(a.cfg_current("ride_ticks"))) if a.def.config.has("ride_ticks") else a.ride_ticks(),
		"speed": a.cfg_current("speed") if a.def.config.has("speed") else 1.0,
		"upkeep_per_day": a.upkeep_per_day(),
		"excitement": _excitement(a), "intensity": a.intensity_value(_rating_scale()),
		"nausea": a.nausea_value(_rating_scale()),
	}


## Opskrifter: ekstra behovsændring/glæde pr. salg; varekøb bogføres som "supplies".
func _apply_recipes(g: Guest, a: Attraction) -> void:
	for rid in a.recipes:
		var r: Dictionary = a.def.recipe(rid)
		if r.is_empty():
			continue
		var sat: Dictionary = r["satisfies"]
		for k: String in sat:
			if g.needs.has(k):
				g.needs[k] = clampf(g.needs[k] + float(sat[k]), 0.0, 100.0)
		g.happiness = clampf(g.happiness + float(r["happiness"]), 0.0, 100.0)
		_add_supplies(a, float(r["cost_per_sale"]))


func _add_supplies(a: Attraction, amount: float) -> void:
	a.supplies_frac += amount
	var whole: int = int(floor(a.supplies_frac + 1e-9))
	if whole > 0:
		a.supplies_frac -= whole
		a.supplies_total += whole
		economy.charge(whole, "supplies")


## Lav pris: chance (sim-RNG) for ét ekstra køb med kvalme og tanken too_much.
func _price_effects(g: Guest, a: Attraction) -> void:
	if a.def.price_effects.is_empty() or a.def.ticket_price <= 0:
		return
	var ratio: float = float(a.price) / float(a.def.ticket_price)
	for e: Dictionary in a.def.price_effects:
		if ratio >= float(e["below_ratio"]):
			continue
		if rng.randf() >= float(e["extra_purchase_chance"]) or g.money < a.price:
			continue
		g.money -= a.price
		_record_sale(g, a, a.price)
		g.nausea = clampf(g.nausea + float(e["nausea"]), 0.0, 100.0)
		var tid: String = str(e["thought"])
		g.thought = str(M7_THOUGHTS.get(tid, tid)) if tid != "" else TOO_MUCH_THOUGHT
		_apply_recipes(g, a)
		if g.nausea >= balance.vomit_threshold:
			var chance: float = (g.nausea - balance.vomit_threshold) / maxf(1e-6, 100.0 - balance.vomit_threshold)
			if rng.randf() < chance:
				_vomit(g)


## T-085: økonomi pr. kategori. Alle Economy.CATEGORIES er med (0 som default).
func finance_report() -> Dictionary:
	var today: Dictionary = {}
	for c in Economy.CATEGORIES:
		today[c] = 0
	for k: Variant in economy.today:
		today[str(k)] = int(economy.today[k])
	var hist: Array = []
	for h in economy.history:
		var t: Dictionary = {}
		for c in Economy.CATEGORIES:
			t[c] = 0
		var ht: Dictionary = h["totals"]
		for k: Variant in ht:
			t[str(k)] = int(ht[k])
		hist.append({"day": h["day"], "totals": t, "net": h["net"]})
	return {"categories": Economy.CATEGORIES.duplicate(), "money": economy.money, "today": today, "history": hist}


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
	return world.get_tile(cell) == ParkWorld.Tile.GRASS and not world.has_low_track(cell)


## Returnerer decor-id eller -1 (ugyldig celle / ikke råd).
func cmd_place_decor(def_id: String, cell: Vector2i) -> int:
	var def: DecorDef = get_decor_def(def_id)
	if not is_unlocked(def_id):
		return -1
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
	_record("decor", "Byg " + def.name, {"decor": d}, -def.build_cost)
	return d.id


## Fjerner dekoration og refunderer 50 %.
func cmd_remove_decor(decor_id: int) -> bool:
	if not decor.has(decor_id):
		return false
	var d: Decor = decor[decor_id]
	var refund: int = d.def.build_cost / 2
	economy.earn(refund, "refund")
	_remove_decor(decor_id)
	_record("remove_decor", "Fjern " + d.def.name, {"decor": d}, refund)
	return true


func _remove_decor(decor_id: int) -> void:
	var d: Decor = decor[decor_id]
	decor.erase(decor_id)
	for g: Guest in _guests_sorted():
		if g.resting_on == decor_id:
			_stand_up(g)
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
	_rebuild_decor_caches()
	var src: Dictionary = _aura_night if world.ambient_light < 0.5 else _aura
	return minf(float(src.get(cell, 0.0)), balance.decor_aura_max_per_tick)


## Aura (dag/nat) og lygternes lys. Genberegnes når dekorationen ændres.
func _rebuild_decor_caches() -> void:
	if not _aura_dirty:
		return
	_aura_dirty = false
	_aura = {}
	_aura_night = {}
	world.lamp_light = {}
	for did in _sorted_decor_ids():
		var d: Decor = decor[did]
		var r: int = d.def.aura_radius
		var day_a: float = d.def.happiness_aura
		var night_a: float = maxf(day_a, d.def.night_aura)
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) + absi(dy) > r:
					continue
				var c: Vector2i = d.cell + Vector2i(dx, dy)
				if day_a > 0.0:
					_aura[c] = float(_aura.get(c, 0.0)) + day_a * balance.aura_scale_per_tick
				if night_a > 0.0:
					_aura_night[c] = float(_aura_night.get(c, 0.0)) + night_a * balance.aura_scale_per_tick
				if d.def.kind == "lamp":
					world.lamp_light[c] = 1.0


## Aura, underholdere og beskidte stier.
func _apply_surroundings(g: Guest) -> void:
	var delta: float = aura_at(g.cell)
	for sid in staff:
		var s: Staff = staff[sid]
		if s.def.id == StaffAI.ENTERTAINER and absi(s.cell.x - g.cell.x) + absi(s.cell.y - g.cell.y) <= s.def.work_radius:
			delta += balance.entertainer_happiness_per_tick
	if (g.state == Guest.State.WALKING or g.state == Guest.State.LEAVING) \
			and world.crowd_ticks_at(g.cell) > balance.crowd_ticks and g.cell != world.entrance:
		delta -= balance.crowd_decay
		g.thought = M7_THOUGHTS["crowded"]
	if (g.state == Guest.State.WALKING or g.state == Guest.State.LEAVING) \
			and world.get_litter(g.cell) >= balance.dirty_threshold:
		delta -= balance.happiness_penalty_dirty_per_tick
		g.thought = balance.thought_dirty
	if (g.state == Guest.State.WALKING or g.state == Guest.State.LEAVING) \
			and balance.dark_path_penalty_per_tick > 0.0 and world.get_tile(g.cell) == ParkWorld.Tile.PATH \
			and world.light_level(g.cell) < 0.5:
		delta -= balance.dark_path_penalty_per_tick
	if delta != 0.0:
		g.happiness = clampf(g.happiness + delta, 0.0, 100.0)


## Nærmeste skraldespand med plads inden for bin_radius (manhattan), ellers null.
func _bin_near(cell: Vector2i) -> Decor:
	var best: Decor = null
	var best_d: int = 0
	for did in _sorted_decor_ids():
		var d: Decor = decor[did]
		if d.def.kind != "bin" or d.fill >= bin_capacity(d):
			continue
		var dist: int = absi(d.cell.x - cell.x) + absi(d.cell.y - cell.y)
		if dist <= balance.bin_radius and (best == null or dist < best_d):
			best = d
			best_d = dist
	return best


## Når båret affald smides (T-043: på gæstens aktuelle celle efter 1..litter_carry_cells skridt):
## spand i nærheden fyldes, ellers (eller med lille sandsynlighed) affald på stien.
func _drop_litter(g: Guest) -> void:
	var bin: Decor = _bin_near(g.cell)
	if bin == null:
		var full: Decor = _full_bin_near(g.cell)
		if full != null:  # T-104: overløb – affaldet lægges ved den fulde spand
			world.set_litter(full.cell, mini(world.get_litter(full.cell) + 1, balance.litter_max_per_cell))
			return
	var chance: float = balance.litter_chance_with_bin if bin != null else balance.litter_chance_after_shop
	if rng.randf() < chance:
		if world.is_walkable(g.cell):
			world.set_litter(g.cell, mini(world.get_litter(g.cell) + 1, balance.litter_max_per_cell))
	elif bin != null:
		set_bin_fill(bin, bin.fill + 1)


func _break(a: Attraction) -> void:
	a.broken = true
	a.reliability_bonus = 0.0
	if a.is_transport():
		path_finder.invalidate()
	var q: Array = a.queue.duplicate()
	a.clear_queue()
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
		g.transport_id = -1
		g.queue_index = -1
		_choose_goal(g)
		g.thought = balance.thought_broken
	a.self_repair_elapsed = 0
	attraction_broken.emit(a)
	if not has_mechanic():
		warning.emit(WARN_BROKEN_NO_MECHANIC, {"attraction_id": a.id})


func _repair(a: Attraction) -> void:
	a.broken = false
	if a.is_transport():
		path_finder.invalidate()
	a.mechanic_id = -1
	a.self_repair_elapsed = 0
	for g: Guest in guests.values():
		g.rejected_ids.erase(a.id)
	attraction_repaired.emit(a)


func broken_count() -> int:
	var n: int = 0
	for a in attractions:
		if a.broken:
			n += 1
	return n


# --- Forskning (T-066) ---

## Altid true når forskning er slået fra.
## T-119: sporstykker fra andre systemer end træ-rutsjebanen (coaster) følger banen: de er låst op,
## når en ulåst attraktion bruger det system. Rutsjebanens stykker forskes individuelt.
func is_unlocked(id: String) -> bool:
	if research.is_unlocked(id):
		return true
	var p: TrackPieceDef = CoasterContent.piece(id)
	if p == null or p.system == CoasterContent.SYSTEM_COASTER:
		return false
	var ids: Array = research.unlocked.keys()
	ids.sort()
	for uid: String in ids:
		var d: AttractionDef = get_def(uid)
		if d != null and d.is_tracked() and d.track_system() == p.system:
			return true
	return false


func cmd_set_research_funding(level: int) -> bool:
	return research.set_funding(level)


## "" = ingen prioritet.
func cmd_set_research_priority(topic_id: String) -> bool:
	if topic_id != "" and not topic_available(topic_id):
		return false
	return research.set_priority(topic_id)


func research_status() -> Dictionary:
	return research.status()


func _research_day() -> void:
	var cost: int = research.daily_cost()
	if cost > 0:
		economy.charge(cost, "research")
	for id in research.advance_day():
		research_unlocked.emit(id)
		warning.emit(WARN_RESEARCH_DONE, {"item_id": id})


# --- Scenarier (T-067) ---

## Opretter en park ud fra et scenarie. Start-bygninger er gratis (pengene sættes bagefter).
## Mislykkede start-placeringer ignoreres med push_warning (data-fejl).
static func new_from_scenario(def: ScenarioDef, p_seed: int, p_balance: Balance = null) -> ParkSim:
	var sim := ParkSim.new(def.map_size.x, def.map_size.y, p_seed, p_balance)
	if def.entrance.x >= 0:
		sim.world.set_entrance(def.entrance)
	sim.economy.money = 1 << 40
	for c in def.paths:
		if sim.world.get_tile(c) != ParkWorld.Tile.ENTRANCE and not sim.cmd_place_path(c):
			push_warning("Scenarie %s: sti %s kunne ikke placeres" % [def.id, c])
	for a in def.attractions:
		if sim.cmd_place_attraction(a["def"], a["origin"]) == null:
			push_warning("Scenarie %s: %s ved %s kunne ikke placeres" % [def.id, a["def"], a["origin"]])
	for d in def.decor:
		if sim.cmd_place_decor(d["def"], d["cell"]) < 0:
			push_warning("Scenarie %s: decor %s ved %s kunne ikke placeres" % [def.id, d["def"], d["cell"]])
	for st in def.staff:
		if sim.cmd_hire_staff(st["type"], st["cell"]) < 0:
			push_warning("Scenarie %s: personale %s ved %s kunne ikke ansættes" % [def.id, st["type"], st["cell"]])
	sim.economy.money = def.start_money
	sim.economy.today = {}
	sim.reputation = def.start_reputation
	if def.entry_fee >= 0:
		sim.entry_fee = def.entry_fee
	sim.research.setup(def.research_enabled, def.unlocked)
	if not def.is_sandbox():
		sim.scenario = Scenario.new(def)
	sim._sync_topic_locks()
	return sim


## Bygningers (og senere banestykkers) værdi × 0,8 + penge. Der findes intet lån i M5.
func park_value() -> int:
	var built: int = 0
	for a in attractions:
		built += a.build_value()
	for did in _sorted_decor_ids():
		built += (decor[did] as Decor).def.build_cost
	return int(floor(built * 0.8)) + economy.money


func rides_count() -> int:
	var n: int = 0
	for a in attractions:
		if a.is_ride():
			n += 1
	return n


## Højeste excitement (0..10) blandt rutsjebaner. 0 indtil T-068 giver attraktioner ratings.
func max_coaster_excitement() -> float:
	var best: float = 0.0
	for a in attractions:
		if a.def.kind != "coaster":
			continue
		best = maxf(best, float(a.ratings.get("excitement", 0.0)))
	return best


## Aktuel værdi for en objective-type (også brugt af lose-betingelser).
func scenario_measure(type: String) -> float:
	match type:
		"guests_in_park":
			return float(guests.size())
		"reputation_min":
			return reputation
		"money_min":
			return float(economy.money)
		"park_value_min":
			return float(park_value())
		"rides_count_min":
			return float(rides_count())
		"coaster_excitement_min":
			return max_coaster_excitement()
	push_warning("Ukendt scenarie-måltype: %s" % type)
	return 0.0


## {} i sandbox.
func scenario_status() -> Dictionary:
	if scenario == null:
		return {}
	var objs: Array = []
	var d: ScenarioDef = scenario.def
	if d != null:
		for o in d.objectives:
			var cur: float = scenario_measure(o["type"])
			objs.append({"type": o["type"], "value": o["value"], "current": cur, "met": Scenario.is_met(o, cur)})
	return {
		"id": scenario.def_id, "name": d.name if d != null else scenario.def_id,
		"state": scenario.state, "days_elapsed": scenario.days_elapsed,
		"deadline_days": d.deadline_days if d != null else 0, "objectives": objs,
	}


func _scenario_day() -> void:
	if scenario == null or not scenario.is_running():
		return
	var res: String = scenario.evaluate_day(scenario_measure)
	if res == "won":
		scenario_finished.emit(true, scenario.reason)
	elif res != "":
		scenario_finished.emit(false, res)


# --- Rutsjebane (T-068) ---

const TOO_INTENSE_THOUGHT: String = "Den er for vild for mig!"
const SICK_THOUGHT: String = "Jeg har kvalme!"
const TOO_TAME_THOUGHT: String = "Den er for tam for mig."
const VOMIT_THOUGHT: String = "Jeg kastede op..."


## Excitement på 0..100-skala (rutsjebane: ratings × excitement_scale fra data).
func _excitement(a: Attraction) -> int:
	return a.excitement_value(float(CoasterContent.ratings().get("excitement_scale", 10.0)))


## Vægt i forlystelsesvalget: excitement (min. 1), divideret ned hvis den er for tam.
func _ride_weight(g: Guest, a: Attraction) -> int:
	var w: int = maxi(1, _excitement(a))
	if _too_tame(g, a):
		w = maxi(1, w / balance.too_tame_divisor)
	return w


func _rating_scale() -> float:
	return float(CoasterContent.ratings().get("excitement_scale", 10.0))


## Intensitet over gæstens tolerance → fravælges ("too_intense").
func _too_intense(g: Guest, a: Attraction) -> bool:
	return a.intensity_value(_rating_scale()) > g.intensity_tolerance


## Intensitet under tolerance − margin → vægtes ned ("too_tame").
func _too_tame(g: Guest, a: Attraction) -> bool:
	return a.intensity_value(_rating_scale()) < g.intensity_tolerance - balance.too_tame_margin


## Efter en tur: kvalme stiger; over tærsklen kan gæsten kaste op (sim-RNG).
func _after_ride_nausea(g: Guest, a: Attraction) -> void:
	var add: float = a.nausea_value(_rating_scale()) * balance.nausea_per_point
	if add <= 0.0:
		return
	g.nausea = clampf(g.nausea + add, 0.0, 100.0)
	if g.nausea < balance.vomit_threshold:
		return
	g.thought = SICK_THOUGHT
	var chance: float = (g.nausea - balance.vomit_threshold) / maxf(1e-6, 100.0 - balance.vomit_threshold)
	if rng.randf() < chance:
		_vomit(g)


func _vomit(g: Guest) -> void:
	var c: Vector2i = g.cell
	if balance.vomit_litter > 0 and world.is_walkable(c):
		world.add_vomit(c, balance.vomit_litter, maxi(balance.litter_max_per_cell, balance.vomit_litter))
	g.happiness = clampf(g.happiness - balance.vomit_happiness, 0.0, 100.0)
	g.nausea = 0.0
	g.thought = VOMIT_THOUGHT
	guest_vomited.emit(g.id, c)
	warning.emit(WARN_GUEST_VOMIT, {"cell": c, "guest_id": g.id})


func _train_of(a: Attraction) -> Dictionary:
	return CoasterContent.train(a.def.train if a.def.train != "" else "basic_train")


## Starter en rutsjebane med stationen i station_cell. Indgangen er cellen til venstre for stationen
## (set i kørselsretningen), så en oval med højresving kan lukkes rundt om stationen.
func cmd_start_coaster(def_id: String, station_cell: Vector2i, heading: int) -> int:
	var def: AttractionDef = get_def(def_id)
	if def == null or not def.is_tracked():
		return -1
	var sys: StringName = def.track_system()
	var sid: String = CoasterContent.station_id(sys)
	var st: TrackPieceDef = CoasterContent.pieces(sys).get(sid, null)
	if st == null or not is_unlocked(def_id) or not is_unlocked(sid) or not can_complete(def_id):
		return -1
	var cost: int = def.build_cost + st.cost
	if not economy.can_afford(cost):
		return -1
	var lvl: int = maxi(0, st.min_level)
	var clearance: int = int(CoasterContent.system_def(sys).get("clearance_levels", 2))
	if world.blocks_track(station_cell, lvl) or _track_collides(station_cell, lvl, -1, clearance):
		return -1
	var ent: Vector2i = station_cell + TrackPiece.dir(heading + 3)
	var et: int = world.get_tile(ent)
	if (et != ParkWorld.Tile.GRASS and et != ParkWorld.Tile.PATH) or world.has_low_track(ent) \
			or world.get_attraction_by_entrance(ent) != null or world.get_attraction_at(ent) != null:
		return -1
	economy.spend(cost, "build")
	var a: Attraction = world.place_coaster(def, station_cell, ent)
	a.track = CoasterTrack.new(CoasterContent.pieces(sys), def.max_height, sys)
	a.track.pieces.append(TrackPiece.new(sid, station_cell, heading, lvl))
	world.add_track_cell(station_cell, lvl, a.id)
	a.building = true
	a.is_open = false
	a.built_tick = clock.tick
	coaster_changed.emit(a.id)
	return a.id


func _coaster(coaster_id: int) -> Attraction:
	var a: Attraction = get_attraction(coaster_id)
	return a if a != null and a.track != null else null


func _track_collides(cell: Vector2i, low: int, _self_id: int, clearance: int = 2) -> bool:
	for lv in world.occupied_by_track(cell):
		if absi(lv - low) < clearance:
			return true
	return false


## Ghost-preview for næste stykke: {cell, heading, level, ok, reason}.
func preview_track_piece(coaster_id: int, piece_id: String) -> Dictionary:
	var a: Attraction = _coaster(coaster_id)
	if a == null:
		return {"cell": Vector2i.ZERO, "heading": 0, "level": 0, "ok": false, "reason": "no_coaster"}
	var e: Dictionary = a.track.next_entry()
	var out: Dictionary = {"cell": e["cell"], "heading": e["heading"], "level": e["level"], "ok": false, "reason": ""}
	var d: TrackPieceDef = a.track.defs.get(piece_id, null)
	if d == null and CoasterContent.piece(piece_id) != null:
		out["reason"] = "wrong_system"
	elif d == null:
		out["reason"] = "unknown_piece"
	elif d.system != a.track.system:
		out["reason"] = "wrong_system"
	elif not a.building:
		out["reason"] = "not_building"
	elif a.track.is_closed() or a.track.is_complete():
		out["reason"] = "closed"
	elif not is_unlocked(piece_id):
		out["reason"] = "locked"
	elif not economy.can_afford(d.cost):
		out["reason"] = "no_money"
	elif not world.in_bounds(e["cell"]):
		out["reason"] = "out_of_bounds"
	else:
		var lvl: int = e["level"]
		var low: int = mini(lvl, lvl + d.rise)
		var top: int = maxi(lvl, lvl + d.rise)
		if top > a.def.max_height or (d.max_level >= 0 and top > d.max_level):
			out["reason"] = "too_high"
		elif low < 0:
			out["reason"] = "below_ground"
		elif low < d.min_level:
			out["reason"] = "too_low"
		elif d.kind == "station" and _station_count(a) >= a.track.max_stations:
			out["reason"] = "multiple_stations"
		elif world.blocks_track(e["cell"], low) or _track_collides(e["cell"], low, a.id, a.track.clearance_levels):
			out["reason"] = "collision"
		else:
			out["ok"] = true
	return out


func _station_count(a: Attraction) -> int:
	var n: int = 0
	for p in a.track.pieces:
		var pd: TrackPieceDef = a.track.def_of(p)
		if pd != null and pd.kind == "station":
			n += 1
	return n


func can_place_track_piece(coaster_id: int, piece_id: String) -> bool:
	return bool(preview_track_piece(coaster_id, piece_id)["ok"])


func cmd_place_track_piece(coaster_id: int, piece_id: String) -> bool:
	var pv: Dictionary = preview_track_piece(coaster_id, piece_id)
	if not pv["ok"]:
		return false
	var a: Attraction = _coaster(coaster_id)
	var d: TrackPieceDef = a.track.defs[piece_id]
	economy.spend(d.cost, "build")
	var p := TrackPiece.new(piece_id, pv["cell"], pv["heading"], pv["level"])
	a.track.pieces.append(p)
	world.add_track_cell(p.cell, a.track.low_level(p), a.id)
	_sync_cells(a)
	coaster_changed.emit(a.id)
	return true


## Fjerner sidste stykke (ikke stationen) under bygning; 100 % refusion.
func cmd_remove_last_piece(coaster_id: int) -> bool:
	var a: Attraction = _coaster(coaster_id)
	if a == null or not a.building or a.track.pieces.size() <= 1:
		return false
	var p: TrackPiece = a.track.pieces[a.track.pieces.size() - 1]
	var low: int = a.track.low_level(p)
	var d: TrackPieceDef = a.track.def_of(p)
	a.track.pieces.pop_back()
	world.remove_track_cell(p.cell, low, a.id)
	if d != null:
		economy.earn(d.cost, "refund")
	_sync_cells(a)
	coaster_changed.emit(a.id)
	return true


## Validerer; ved succes beregnes fysik/ratings og banen åbner. Returnerer fejlkoder (tom = ok).
func cmd_finish_coaster(coaster_id: int) -> Array[String]:
	var a: Attraction = _coaster(coaster_id)
	if a == null:
		return ["no_coaster"] as Array[String]
	var errs: Array[String] = a.track.validate(_world_blocked.bind(a), _train_of(a))
	if errs.is_empty() and a.is_transport():
		var ex: String = _transport_exit_error(a)
		if ex != "":
			errs.append(ex)
	if not errs.is_empty():
		return errs
	a.building = false
	a.built_tick = clock.tick
	_record("build_track", "Byg " + a.def.name, {"attraction": a}, -a.build_value())
	if a.is_transport():
		var exit: Vector2i = transport_exit_cell(a)
		if world.get_tile(exit) != ParkWorld.Tile.PATH:
			world._set_tile(exit, ParkWorld.Tile.PATH)
		_register_links(a)
	_apply_profile(a)
	a.is_open = true
	for g: Guest in guests.values():
		g.rejected_ids.erase(a.id)
	coaster_changed.emit(a.id)
	return errs


func _world_blocked(i: int, a: Attraction) -> bool:
	var p: TrackPiece = a.track.pieces[i]
	return world.blocks_track(p.cell, a.track.low_level(p))


func _sync_cells(a: Attraction) -> void:
	a.cells = a.track.cells()


## Profil, ratings og ride_ticks ud fra banen (deterministisk; også ved load).
func _apply_profile(a: Attraction) -> void:
	var r: Dictionary = CoasterContent.ratings()
	a.profile = CoasterPhysics.simulate(a.track, _train_of(a), a.track.defs)
	if a.is_coaster():
		a.ratings = CoasterRatings.rate(a.profile, r)
	else:
		# ADR-004: øvrige systemer får ratings fra data (0..10-skala som rutsjebanen).
		a.ratings = {"excitement": a.def.excitement / 10.0, "intensity": a.def.intensity / 10.0,
			"nausea": a.def.nausea / 10.0}
	a.load_ticks = int(r.get("load_ticks", 0))
	a.ride_ticks_override = int(ceil(a.profile.duration_s * SimClock.TICKS_PER_SECOND)) + a.load_ticks


func _restore_coaster(a: Attraction) -> void:
	for p in a.track.pieces:
		world.add_track_cell(p.cell, a.track.low_level(p), a.id)
	if not a.building and a.track.is_complete():
		_apply_profile(a)
		if a.is_transport():
			_register_links(a)


# --- Transport (T-091) ---

const TRANSPORT_NO_MONEY_THOUGHT: String = "Jeg har ikke råd til svævebanen."


## Indgangscellen ved endestationen (venstre for stationen i kørselsretningen, som startindgangen).
func transport_exit_cell(a: Attraction) -> Vector2i:
	if a == null or a.track == null:
		return Vector2i(-1, -1)
	var p: TrackPiece = a.track.end_station()
	if p == null:
		return Vector2i(-1, -1)
	return p.cell + TrackPiece.dir(p.heading + 3)


func _transport_exit_error(a: Attraction) -> String:
	var c: Vector2i = transport_exit_cell(a)
	var t: int = world.get_tile(c)
	if (t != ParkWorld.Tile.GRASS and t != ParkWorld.Tile.PATH) or world.has_low_track(c) \
			or world.get_attraction_by_entrance(c) != null or world.get_attraction_at(c) != null:
		return "exit_blocked"
	if absi(c.x - a.entrance_cell.x) + absi(c.y - a.entrance_cell.y) <= 1:
		return "stations_too_close"
	return ""


func _register_links(a: Attraction) -> void:
	world.remove_links(a.id)
	world.add_link(a.entrance_cell, transport_exit_cell(a), a.def.transport_cost, a.id)
	_reachable_dirty = true


## T-145: gæsten flyttes fra indgangen (_exit_at) til den anden stations indgang.
func _exit_at_other_station(g: Guest, a: Attraction) -> void:
	var dest: Vector2i = transport_exit_cell(a)
	if not world.is_walkable(dest):
		return
	world.occupancy_add(g.cell, -1)
	g.cell = dest
	g.next_cell = dest
	g.path.clear()
	g.progress = 0.0
	world.occupancy_add(dest, 1)


## Kan kanten for owner_id bruges (åben, færdig, ikke brudt ned)?
func link_usable(owner_id: int) -> bool:
	var a: Attraction = get_attraction(owner_id)
	return a != null and a.is_transport() and a.is_open and not a.broken and not a.building


func _link_price(owner_id: int) -> int:
	var a: Attraction = get_attraction(owner_id)
	return a.price if a != null else 0


## Gæsterute: transportkanter bruges kun, hvis gæsten har råd til billetten.
func _route(g: Guest, to: Vector2i) -> Array[Vector2i]:
	return path_finder.find_path(g.cell, to, g.money)


## Gæsten står ved en stationsindgang og næste rute-skridt er kanten til den anden station.
func _board_transport(g: Guest) -> void:
	var a: Attraction = null
	for e: Dictionary in world.links_from(g.cell):
		if e["to"] == g.next_cell and link_usable(int(e["owner_id"])):
			a = get_attraction(int(e["owner_id"]))
			break
	if a == null or a.price > g.money or is_queue_full(a):
		if a != null and a.price > g.money:
			g.thought = TRANSPORT_NO_MONEY_THOUGHT
		g.next_cell = g.cell
		g.path.clear()
		g.progress = 0.0
		if g.state == Guest.State.LEAVING:
			_start_leaving(g)
		else:
			_choose_goal(g)
		return
	g.money -= a.price
	g.paid = a.price
	_record_sale(g, a, a.price)
	a.total_visitors += 1
	a.customers_today += 1
	a.riders_today += 1
	g.transport_id = a.id
	g.transport_dest = g.next_cell
	g.transport_resume_state = g.state
	g.progress = 0.0
	g.state = Guest.State.QUEUING
	_join_queue(g, a)


## Turen er slut: gæsten står ved den anden stations indgang og fortsætter sin rute.
func _finish_transport(g: Guest, a: Attraction) -> void:
	for k: String in a.def.satisfies:
		if g.needs.has(k):
			g.needs[k] = clampf(g.needs[k] + float(a.def.satisfies[k]), 0.0, 100.0)
	g.paid = 0
	g.cell = g.transport_dest
	g.progress = 0.0
	g.state = g.transport_resume_state
	g.transport_id = -1
	g.next_cell = g.cell if g.path.is_empty() else g.path.pop_front()


## Tilstandsnavn til bridge/UI (&"riding_transport" når gæsten sidder i svævebanen).
func guest_state_name(g: Guest) -> StringName:
	if g.transport_id >= 0:
		return &"riding_transport" if g.state == Guest.State.RIDING else &"queuing_transport"
	match g.state:
		Guest.State.QUEUING:
			return &"queuing"
		Guest.State.RIDING:
			return &"riding"
		Guest.State.LEAVING:
			return &"leaving"
		Guest.State.RESTING:
			return &"resting"
	return &"walking"


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
		elif def is ScenarioDef:
			sim._scenario_defs[(def as ScenarioDef).id] = def
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
		"research": research.to_save(),
		"milestones": milestones_state.achieved.duplicate(),
		"milestones_backfill": milestones_state.backfill,
		"milestones_days_clean": milestones_state.days_clean,
		"scenario": scenario.to_save() if scenario != null else null,
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
		if a.track != null:
			_restore_coaster(a)
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
	research.load_save(SaveCodec.dict(park, "research"))
	var sc: Variant = park.get("scenario")
	if sc is Dictionary:
		var sid: String = str(sc.get("def_id", ""))
		var sdef: ScenarioDef = _scenario_defs.get(sid, null)
		if sdef == null and sid != "":
			sdef = ScenarioDef.find(sid)
		scenario = Scenario.from_save(sc, sdef)
	milestones_state.achieved.clear()
	for mid: Variant in SaveCodec.arr(park, "milestones"):
		milestones_state.mark(str(mid))
	milestones_state.backfill = bool(park.get("milestones_backfill", false))
	milestones_state.days_clean = int(park.get("milestones_days_clean", 0))
	_sync_topic_locks()
	_aura_dirty = true
	_reachable_dirty = true
	_queues_dirty = true
	_ensure_queues()
	for a in attractions:
		a.queue_dirty = false
		for i in a.queue.size():
			if guests.has(int(a.queue[i])):
				(guests[int(a.queue[i])] as Guest).queue_index = i  # også migrerede saves
	_rebuild_bench_seats()
	_phase = phase()
	_update_light()


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


# --- M7 (T-104): hæveautomat, spande, bænke, lys og affald ---

func _on_world_litter_changed(cell: Vector2i, _amount: int) -> void:
	litter_changed.emit(cell)


func _guests_sorted() -> Array[Guest]:
	var ids: Array = guests.keys()
	ids.sort()
	var out: Array[Guest] = []
	for gid in ids:
		out.append(guests[gid])
	return out


## Nærmeste brugbare hæveautomat inden for range_cells sti-celler (gæster uden penge eller med
## saldo under balance.atm_low_money, T-149).
func _try_atm(g: Guest) -> bool:
	var best: Attraction = null
	var best_route: Array[Vector2i] = []
	for a in attractions:
		if not a.is_atm() or not a.is_open or a.broken or g.rejected_ids.has(a.id) \
				or g.atm_uses >= a.def.max_per_visit or g.happiness < a.def.min_happiness or is_queue_full(a):
			continue
		var route: Array[Vector2i] = _route(g, approach_cell(a))
		if route.is_empty() or route.size() - 1 > a.def.range_cells:
			continue
		if best == null or route.size() < best_route.size():
			best = a
			best_route = route
	if best == null:
		return false
	_go_to(g, best, best_route)
	return true


## Hævning (sim-RNG): gæsten får withdraw min..max og betaler gebyret til parken ("atm_fees").
func _atm_withdraw(g: Guest, a: Attraction) -> void:
	var amount: int = rng.randi_range(a.def.withdraw_min, a.def.withdraw_max)
	g.money += amount
	var fee: int = mini(a.def.fee, g.money)
	if fee > 0:
		g.money -= fee
		economy.earn(fee, "atm_fees")
		a.total_revenue += fee
		a.revenue_today += fee
	g.atm_uses += 1
	g.rejected_ids.clear()
	atm_used.emit(g.id, a.id, amount)


## Spandens kapacitet: decor-def'ens capacity, ellers balance.bin_capacity.
func bin_capacity(d: Decor) -> int:
	return d.def.capacity if d.def.capacity > 0 else balance.bin_capacity


## 0/1/2 = under 50 % / mindst 50 % / fuld.
func bin_level(d: Decor) -> int:
	var cap: int = maxi(1, bin_capacity(d))
	if d.fill >= cap:
		return 2
	return 1 if d.fill * 2 >= cap else 0


func set_bin_fill(d: Decor, value: int) -> void:
	var before: int = bin_level(d)
	d.fill = clampi(value, 0, bin_capacity(d))
	var after: int = bin_level(d)
	if after != before:
		bin_state_changed.emit(d.id, after)


## Nærmeste FULDE spand inden for bin_radius (til overløb), ellers null.
func _full_bin_near(cell: Vector2i) -> Decor:
	var best: Decor = null
	var best_d: int = 0
	for did in _sorted_decor_ids():
		var d: Decor = decor[did]
		if d.def.kind != "bin" or d.fill < bin_capacity(d):
			continue
		var dist: int = absi(d.cell.x - cell.x) + absi(d.cell.y - cell.y)
		if dist <= balance.bin_radius and (best == null or dist < best_d):
			best = d
			best_d = dist
	return best


## Gæste-id'er på bænken (sorteret).
func bench_occupants(d: Decor) -> Array[int]:
	var out: Array[int] = []
	for g in _guests_sorted():
		if g.resting_on == d.id:
			out.append(g.id)
	return out


func bench_free_seats(d: Decor) -> int:
	return maxi(0, d.def.seats - bench_occupants(d).size())


## Sædeplads for en siddende gæst (-1 hvis ikke siddende).
func bench_seat(guest_id: int) -> int:
	return int(_bench_seat.get(guest_id, -1))


func _sit_down(g: Guest, d: Decor) -> void:
	var taken: Dictionary = {}
	for gid in bench_occupants(d):
		taken[int(_bench_seat.get(gid, -1))] = true
	var seat: int = 0
	while taken.has(seat):
		seat += 1
	g.state = Guest.State.RESTING
	g.rest_ticks_left = balance.bench_rest_ticks
	g.resting_on = d.id
	g.target_decor_id = d.id
	_bench_seat[g.id] = seat
	guest_sat.emit(g.id, d.id, seat)


func _stand_up(g: Guest) -> void:
	if g.resting_on < 0:
		return
	g.resting_on = -1
	_bench_seat.erase(g.id)
	guest_stood.emit(g.id)


## Genberegner sædepladser fra resting_on (efter load).
func _rebuild_bench_seats() -> void:
	_bench_seat = {}
	var next: Dictionary = {}
	for g in _guests_sorted():
		if g.resting_on >= 0:
			var s: int = int(next.get(g.resting_on, 0))
			_bench_seat[g.id] = s
			next[g.resting_on] = s + 1


## {id, def_id, kind, cell, fill, capacity, fill_ratio, level, seats, occupants} ({} hvis ukendt).
func decor_info(decor_id: int) -> Dictionary:
	var d: Decor = decor.get(decor_id, null)
	if d == null:
		return {}
	var cap: int = bin_capacity(d) if d.def.kind == "bin" else 0
	return {
		"id": d.id, "def_id": d.def.id, "kind": d.def.kind, "cell": d.cell, "fill": d.fill,
		"capacity": cap, "fill_ratio": float(d.fill) / float(cap) if cap > 0 else 0.0,
		"level": bin_level(d) if d.def.kind == "bin" else 0,
		"seats": d.def.seats, "occupants": bench_occupants(d) if d.def.kind == "bench" else ([] as Array[int]),
	}


## Dagslys efter fase: dag 1, gry/skumring 0,5, nat 0. Lygter lyser cellerne i aura_radius op.
func _update_light() -> void:
	_rebuild_decor_caches()
	match phase():
		PHASE_DAY:
			world.ambient_light = 1.0
		PHASE_NIGHT:
			world.ambient_light = 0.0
		_:
			world.ambient_light = 0.5


func light_level(cell: Vector2i) -> float:
	return world.light_level(cell)


## Affaldsstykker på cellen [{kind: "litter"|"vomit", index}] – index 0..n-1 til deterministisk placering.
func litter_at(cell: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var total: int = world.get_litter(cell)
	var vomit: int = mini(world.get_vomit(cell), total)
	for i in total:
		out.append({"kind": "litter" if i < total - vomit else "vomit", "index": i})
	return out


# --- M7 (T-105): milepæle ---

## Aktive når et scenarie med forskning kører, og scenariet ikke har "milestones": false.
## Sandbox: alt er åbent, og der gives ingen belønning.
func milestones_enabled() -> bool:
	if scenario == null or not research.enabled:
		return false
	return scenario.def == null or scenario.def.milestones


## Er forskningsemnet åbent? (altid sandt, når milepæle er slået fra)
func topic_available(topic_id: String) -> bool:
	return not _locked_topics().has(topic_id)


## Milepælen der åbner emnet ("" hvis emnet ikke er låst af en milepæl).
func topic_locked_by(topic_id: String) -> String:
	return milestones_state.milestone_for_topic(topic_id) if not topic_available(topic_id) else ""


func _locked_topics() -> Dictionary:
	var out: Dictionary = {}
	if not milestones_enabled():
		return out
	var gated: Dictionary = milestones_state.gated_topics()
	for t: String in gated:
		if not research.def.start_topics.has(t) and not milestones_state.is_achieved(str(gated[t])):
			out[t] = true
	return out


func _sync_topic_locks() -> void:
	research.set_locked_topics(_locked_topics())


## Aktuel værdi for en milepælsbetingelse.
func milestone_measure(condition: String) -> float:
	match condition:
		"total_guests":
			return float(_next_guest_id - 1)
		"rides_open":
			var n: int = 0
			for a in attractions:
				if a.is_ride() and not a.broken and not a.building and is_operating(a):
					n += 1
			return float(n)
		"reputation":
			return reputation
		"coaster_built":
			for a in attractions:
				if a.def.kind == "coaster" and a.track != null and not a.building:
					return 1.0
			return 0.0
		"total_revenue":
			return float(_total_revenue())
		"days_clean":
			return float(milestones_state.days_clean)
	return 0.0


## Samlede indtægter (entré, billetter, hæveautomat-gebyrer) for hele parkens levetid.
func _total_revenue() -> int:
	var cats: Array[String] = ["entry", "tickets", "atm_fees"]
	var total: int = 0
	for h: Dictionary in economy.history:
		for c in cats:
			total += maxi(0, int((h["totals"] as Dictionary).get(c, 0)))
	for c in cats:
		total += maxi(0, int(economy.today.get(c, 0)))
	return total


func _milestone_progress(m: MilestoneDef) -> float:
	if milestones_state.is_achieved(m.id):
		return 1.0
	if m.target <= 0.0:
		return 1.0
	return clampf(milestone_measure(m.condition) / m.target, 0.0, 1.0)


## [{id, name, achieved, progress 0..1, reward, condition, target, enabled}].
func milestones() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var on: bool = milestones_enabled()
	for m in milestones_state.defs:
		out.append({"id": m.id, "name": m.name, "achieved": milestones_state.is_achieved(m.id),
			"progress": _milestone_progress(m), "reward": m.reward.duplicate(true),
			"condition": m.condition, "target": m.target, "enabled": on})
	return out


func _tick_milestones() -> void:
	if milestones_state.backfill:
		_backfill_milestones()
	if not milestones_enabled() or clock.tick % 20 != 0:
		return
	_evaluate_milestones()


func _evaluate_milestones() -> void:
	for m in milestones_state.defs:
		if not milestones_state.is_achieved(m.id) and _milestone_progress(m) >= 1.0:
			_achieve(m)


func _achieve(m: MilestoneDef) -> void:
	milestones_state.mark(m.id)
	var money: int = int(m.reward.get("money", 0))
	if money > 0:
		economy.earn(money, "rewards")
	if m.unlock_topic() != "":
		_sync_topic_locks()
	var pts: float = float(m.reward.get("research_points", 0.0))
	for id in research.add_points(pts):
		research_unlocked.emit(id)
	milestone_achieved.emit(m.id)


func _milestones_day() -> void:
	if world.total_litter() <= milestones_state.clean_max_litter:
		milestones_state.days_clean += 1
	else:
		milestones_state.days_clean = 0
	if milestones_enabled():
		_evaluate_milestones()


## Beslutning 7: beregnelige betingelser markeres uden penge/point; kun emner låses op.
func _backfill_milestones() -> void:
	milestones_state.backfill = false
	if not milestones_enabled():
		return
	var ids: Array = []
	for m in milestones_state.defs:
		if milestones_state.is_achieved(m.id) or not m.is_backfillable():
			continue
		if m.target <= 0.0 or milestone_measure(m.condition) >= m.target:
			milestones_state.mark(m.id)
			ids.append(m.id)
	_sync_topic_locks()
	milestones_backfilled.emit(ids)


# --- M7 (T-133): påkrævede stykker ---

## Påkrævede stykker (AttractionDef.required_pieces), der endnu ikke er låst op.
func missing_pieces(def_id: String) -> Array[String]:
	var out: Array[String] = []
	var def: AttractionDef = get_def(def_id)
	if def == null:
		return out
	for pid in def.required_pieces:
		if not is_unlocked(pid):
			out.append(pid)
	return out


## Kan sporbanen startes og lukkes med de oplåste stykker? (false for ukendte/ikke-sporbaner)
func can_complete(def_id: String) -> bool:
	var def: AttractionDef = get_def(def_id)
	return def != null and def.is_tracked() and missing_pieces(def_id).is_empty()


# --- T-106: flyt, sælg-refusion og fortryd (ADR-005 §4–5) ---

## Refusion ved salg: 100 % inden for sell_full_refund_ticks efter opførelse og uden kunder, ellers 50 %.
func sell_refund(attraction_id: int) -> int:
	var a: Attraction = get_attraction(attraction_id)
	if a == null:
		return 0
	if a.total_visitors == 0 and clock.tick - a.built_tick <= balance.sell_full_refund_ticks:
		return a.build_value()
	return a.build_value() / 2


static func _rot_cw(v: Vector2i, r: int) -> Vector2i:
	var out: Vector2i = v
	for i in posmod(r, 4):
		out = Vector2i(-out.y, out.x)
	return out


## Banestykker forskudt til station new_origin og drejet til absolut rotation new_rot (om stationen).
func _moved_pieces(a: Attraction, new_origin: Vector2i, new_rot: int) -> Array[TrackPiece]:
	var r: int = posmod(new_rot - a.rotation, 4)
	var s0: Vector2i = a.track.pieces[0].cell
	var out: Array[TrackPiece] = []
	for p in a.track.pieces:
		out.append(TrackPiece.new(p.def_id, new_origin + _rot_cw(p.cell - s0, r), p.heading + r, p.level))
	return out


## Egne sticeller (indgang/udgang), som et flyt må bygge oven på.
func _own_path_cells(a: Attraction) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var cands: Array[Vector2i] = [a.entrance_cell]
	if a.is_transport() and a.track != null and a.track.end_station() != null:
		cands.append(transport_exit_cell(a))
	for c in cands:
		var other: Attraction = world.get_attraction_by_entrance(c)
		if world.get_tile(c) == ParkWorld.Tile.PATH and _decor_ids_at(c).is_empty() \
				and (other == null or other == a):
			out.append(c)
	return out


func _low_track_other(cell: Vector2i, self_id: int) -> bool:
	for lv in world.track_levels_except(cell, self_id):
		if lv < ParkWorld.TRACK_CLEARANCE:
			return true
	return false


## Fejl for en indgangs-/udgangscelle til en bane ("" = ok).
func _track_door_error(c: Vector2i, a: Attraction, own: Array[Vector2i], piece_cells: Dictionary) -> String:
	if not world.in_bounds(c):
		return "out_of_bounds"
	var t: int = world.get_tile(c)
	if (t != ParkWorld.Tile.GRASS and t != ParkWorld.Tile.PATH) or _low_track_other(c, a.id) \
			or piece_cells.has(c):
		return "entrance_blocked"
	var other: Attraction = world.get_attraction_by_entrance(c)
	if other != null and other != a:
		return "entrance_blocked"
	var at: Attraction = world.get_attraction_at(c)
	if at != null and at != a:
		return "entrance_blocked"
	return ""


## Validerer banen a med stykkerne pieces (ignorerer egne gamle celler). {reason, cells, entrance, exit}.
func _track_layout(a: Attraction, pieces: Array[TrackPiece], entrance: Vector2i, ignore_self: bool) -> Dictionary:
	var own: Array[Vector2i] = _own_path_cells(a) if ignore_self else ([] as Array[Vector2i])
	var cells: Array[Vector2i] = []
	var low_cells: Dictionary = {}
	var reason: String = ""
	for p in pieces:
		if not cells.has(p.cell):
			cells.append(p.cell)
		var low: int = a.track.low_level(p)
		if not world.in_bounds(p.cell):
			reason = "out_of_bounds"
			break
		if low < ParkWorld.TRACK_CLEARANCE:
			low_cells[p.cell] = true
			var t: int = world.get_tile(p.cell)
			var free: bool = t == ParkWorld.Tile.GRASS or (own.has(p.cell) and t == ParkWorld.Tile.PATH)
			var flat: Attraction = world.get_attraction_at(p.cell)
			if not free or (flat != null and flat.track == null):
				reason = "occupied"
				break
		for lv in world.track_levels_except(p.cell, a.id):
			if absi(lv - low) < a.track.clearance_levels:
				reason = "collision"
				break
		if reason != "":
			break
	var exit: Vector2i = Vector2i(-1, -1)
	if reason == "":
		reason = _track_door_error(entrance, a, own, low_cells)
	if reason == "" and a.is_transport() and not a.building:
		var es: TrackPiece = null
		for i in range(pieces.size() - 1, 0, -1):
			var d: TrackPieceDef = a.track.def_of(pieces[i])
			if d != null and d.kind == "station":
				es = pieces[i]
				break
		if es != null:
			exit = es.cell + TrackPiece.dir(es.heading + 3)
			reason = _track_door_error(exit, a, own, low_cells)
	return {"reason": reason, "cells": cells, "entrance": entrance, "exit": exit}


## Ghost-validering for flyt: {ok, reason, cells, entrance}. rotation er absolut (0..3, 90° med uret).
func preview_move(attraction_id: int, origin: Vector2i, rotation: int) -> Dictionary:
	var a: Attraction = get_attraction(attraction_id)
	var out: Dictionary = {"ok": false, "reason": "", "cells": [] as Array[Vector2i], "entrance": Vector2i(-1, -1)}
	if a == null:
		out["reason"] = "no_attraction"
		return out
	var rot: int = posmod(rotation, 4)
	if origin == a.origin and rot == a.rotation:
		out["reason"] = "same"
		return out
	if a.track != null:
		var pcs: Array[TrackPiece] = _moved_pieces(a, origin, rot)
		var ent: Vector2i = origin + _rot_cw(a.entrance_cell - a.track.pieces[0].cell, rot - a.rotation)
		var lay: Dictionary = _track_layout(a, pcs, ent, true)
		out["cells"] = lay["cells"]
		out["entrance"] = ent
		out["reason"] = lay["reason"]
	else:
		out["cells"] = Attraction.cells_for(a.def, origin, rot)
		out["entrance"] = Attraction.entrance_for(a.def, origin, rot)
		var err: String = world.footprint_error(a.def, origin, rot, a)
		if err == "" and (out["cells"] as Array).has(a.entrance_cell) and not _decor_ids_at(a.entrance_cell).is_empty():
			err = "occupied"
		out["reason"] = err
	out["ok"] = out["reason"] == ""
	return out


## Flytter (og drejer) en bygning eller hel sporbane. Gratis. {ok, reason}.
func cmd_move_attraction(attraction_id: int, origin: Vector2i, rotation: int) -> Dictionary:
	var a: Attraction = get_attraction(attraction_id)
	var from_origin: Vector2i = a.origin if a != null else Vector2i.ZERO
	var from_rot: int = a.rotation if a != null else 0
	var r: String = _do_move(attraction_id, origin, rotation)
	if r == "":
		_record("move", "Flyt " + a.def.name, {"id": attraction_id, "from_origin": from_origin,
			"from_rot": from_rot, "to_origin": origin, "to_rot": posmod(rotation, 4)}, 0)
	return {"ok": r == "", "reason": r}


func _do_move(attraction_id: int, origin: Vector2i, rotation: int) -> String:
	var pv: Dictionary = preview_move(attraction_id, origin, rotation)
	if not pv["ok"]:
		return pv["reason"]
	var a: Attraction = get_attraction(attraction_id)
	var rot: int = posmod(rotation, 4)
	var own: Array[Vector2i] = _own_path_cells(a)
	var riders: Array = _eject_guests(a)
	if a.track != null:
		var pcs: Array[TrackPiece] = _moved_pieces(a, origin, rot)
		world.clear_track(a.id)
		world.remove_links(a.id)
		for p in pcs:
			if own.has(p.cell) and a.track.low_level(p) < ParkWorld.TRACK_CLEARANCE:
				world._set_tile(p.cell, ParkWorld.Tile.GRASS)
		a.track.pieces = pcs
		for p in pcs:
			world.add_track_cell(p.cell, a.track.low_level(p), a.id)
		_sync_cells(a)
		a.origin = origin
		a.rotation = rot
		a.entrance_cell = pv["entrance"]
		if world.get_tile(a.entrance_cell) != ParkWorld.Tile.PATH:
			world._set_tile(a.entrance_cell, ParkWorld.Tile.PATH)
		if a.is_transport() and not a.building and a.track.is_complete():
			var exit: Vector2i = transport_exit_cell(a)
			if world.get_tile(exit) != ParkWorld.Tile.PATH:
				world._set_tile(exit, ParkWorld.Tile.PATH)
			_register_links(a)
	else:
		for c in a.footprint_cells():
			world._set_tile(c, ParkWorld.Tile.GRASS)
		a.origin = origin
		a.rotation = rot
		a.entrance_cell = pv["entrance"]
		for c in a.footprint_cells():
			world._set_tile(c, ParkWorld.Tile.ATTRACTION)
		if world.get_tile(a.entrance_cell) != ParkWorld.Tile.PATH:
			world._set_tile(a.entrance_cell, ParkWorld.Tile.PATH)
	path_finder.invalidate()
	_reachable_dirty = true
	_queues_dirty = true
	_ensure_queues()
	if not riders.is_empty():
		_on_ride_finished(riders, a)  # passagerer sættes af ved den nye indgang (ingen refusion)
	if a.track != null:
		coaster_changed.emit(a.id)
	attraction_moved.emit(a.id)
	queue_changed.emit(a.id)
	return ""


## Tømmer køen (med refusion) og returnerer passagererne (sættes af af kalderen).
func _eject_guests(a: Attraction) -> Array:
	var q: Array = a.queue.duplicate()
	a.clear_queue()
	for gid in q:
		if guests.has(gid):
			var g: Guest = guests[gid]
			g.money += g.paid
			g.paid = 0
			g.state = Guest.State.WALKING
			g.target_attraction_id = -1
			g.queue_index = -1
			_choose_goal(g)
	var riders: Array = a.riders.duplicate()
	a.riders.clear()
	a.ticks_left = 0
	return riders


## Flytter dekoration til en ny gyldig celle (gratis).
func cmd_move_decor(decor_id: int, cell: Vector2i) -> bool:
	var d: Decor = decor.get(decor_id, null)
	if d == null:
		return false
	var from: Vector2i = d.cell
	if not _do_move_decor(d, cell):
		return false
	_record("move_decor", "Flyt " + d.def.name, {"id": decor_id, "from": from, "to": cell}, 0)
	return true


func _do_move_decor(d: Decor, cell: Vector2i) -> bool:
	if cell == d.cell or not can_place_decor(d.def, cell):
		return false
	_remove_decor(d.id)
	d.cell = cell
	_reinsert_decor(d)
	return true


func _reinsert_decor(d: Decor) -> void:
	if not d.def.on_path:
		world.place_decor_tile(d.cell)
	decor[d.id] = d
	_aura_dirty = true
	decor_placed.emit(d)


# Fortryd-stakken

func _record(kind: String, label: String, args: Dictionary, money_delta: int) -> void:
	if _replaying:
		return
	undo_stack.push({"kind": kind, "label": label, "args": args, "inverse_args": args,
		"money_delta": money_delta, "tick": clock.tick})
	undo_changed.emit()


## Pris/config: på hinanden følgende ændringer af samme felt slås sammen til én post.
func _record_setting(kind: String, label: String, args: Dictionary, from: Variant, to: Variant) -> void:
	if _replaying or from == to:
		return
	var top: Dictionary = undo_stack.peek_undo()
	if not undo_stack.can_redo() and top.get("kind", "") == kind:
		var ta: Dictionary = top["args"]
		if ta["id"] == args["id"] and ta["key"] == args["key"]:
			ta["to"] = to
			undo_changed.emit()
			return
	var a2: Dictionary = args.duplicate()
	a2["from"] = from
	a2["to"] = to
	_record(kind, label, a2, 0)


func can_undo() -> bool:
	return undo_stack.can_undo()


func can_redo() -> bool:
	return undo_stack.can_redo()


## Tekst for næste fortryd ("" hvis tom).
func undo_label() -> String:
	return str(undo_stack.peek_undo().get("label", ""))


func redo_label() -> String:
	return str(undo_stack.peek_redo().get("label", ""))


## Fortryder seneste handling. Pengene føres præcist tilbage. {ok, reason, kind}.
func cmd_undo() -> Dictionary:
	if not undo_stack.can_undo():
		return {"ok": false, "reason": "empty", "kind": ""}
	var e: Dictionary = undo_stack.peek_undo()
	_replaying = true
	var r: String = _apply_entry(e, false)
	_replaying = false
	if r == "":
		undo_stack.commit_undo()
		undo_changed.emit()
	return {"ok": r == "", "reason": r, "kind": e["kind"]}


func cmd_redo() -> Dictionary:
	if not undo_stack.can_redo():
		return {"ok": false, "reason": "empty", "kind": ""}
	var e: Dictionary = undo_stack.peek_redo()
	_replaying = true
	var r: String = _apply_entry(e, true)
	_replaying = false
	if r == "":
		undo_stack.commit_redo()
		undo_changed.emit()
	return {"ok": r == "", "reason": r, "kind": e["kind"]}


## forward = gentag handlingen, ellers udfør den inverse. "" = ok, ellers grund (intet ændret).
func _apply_entry(e: Dictionary, forward: bool) -> String:
	var args: Dictionary = e["args"]
	var md: int = int(e["money_delta"])
	match str(e["kind"]):
		"path":
			return _undo_path(args["cell"], false, forward, -md, "path")
		"remove_path":
			return _undo_path(args["cell"], false, not forward, md, "refund")
		"queue_path":
			return _undo_path(args["cell"], true, forward, -md, "path")
		"remove_queue_path":
			return _undo_path(args["cell"], true, not forward, md, "refund")
		"build", "build_track":
			return _toggle_attraction(args["attraction"], forward, -md, "build")
		"sell":
			return _toggle_attraction(args["attraction"], not forward, md, "refund")
		"decor":
			return _toggle_decor(args["decor"], forward, -md, "decor")
		"remove_decor":
			return _toggle_decor(args["decor"], not forward, md, "refund")
		"move":
			if get_attraction(int(args["id"])) == null:
				return "missing"
			if forward:
				return _do_move(int(args["id"]), args["to_origin"], int(args["to_rot"]))
			return _do_move(int(args["id"]), args["from_origin"], int(args["from_rot"]))
		"move_decor":
			var d: Decor = decor.get(int(args["id"]), null)
			if d == null:
				return "missing"
			return "" if _do_move_decor(d, args["to"] if forward else args["from"]) else "occupied"
		"price":
			if get_attraction(int(args["id"])) == null:
				return "missing"
			cmd_set_price(int(args["id"]), int(args["to"] if forward else args["from"]))
			return ""
		"config":
			if get_attraction(int(args["id"])) == null:
				return "missing"
			cmd_set_config(int(args["id"]), str(args["key"]), float(args["to"] if forward else args["from"]))
			return ""
		"recipe":
			if get_attraction(int(args["id"])) == null:
				return "missing"
			var on: bool = bool(args["on"])
			cmd_set_recipe(int(args["id"]), str(args["recipe"]), on if forward else not on)
			return ""
	return "unknown"


## add=true: læg (kø)sti og betal amount; ellers fjern og få amount retur. Samme kategori som originalen.
func _undo_path(cell: Vector2i, queue: bool, add: bool, amount: int, category: String) -> String:
	if add:
		if not world.can_place_path(cell):
			return "occupied"
		if not economy.can_afford(amount):
			return "no_money"
		economy.spend(amount, category)
		if queue:
			world.place_queue(cell)
		else:
			world.place_path(cell)
		return ""
	if queue:
		if not world.is_queue(cell):
			return "missing"
		world.remove_queue(cell)
	else:
		if world.get_tile(cell) != ParkWorld.Tile.PATH or not _decor_ids_at(cell).is_empty():
			return "occupied"
		if not world.remove_path(cell):
			return "occupied"
	economy.earn(amount, category)
	return ""


## present=true: genindsæt a og betal amount; ellers fjern a og få amount retur.
func _toggle_attraction(a: Attraction, present: bool, amount: int, category: String) -> String:
	if not present:
		if get_attraction(a.id) != a:
			return "missing"
		world.remove_attraction(a.id)
		economy.earn(amount, category)
		return ""
	if get_attraction(a.id) != null:
		return "occupied"
	var err: String = ""
	if a.track != null:
		err = _track_layout(a, a.track.pieces, a.entrance_cell, false)["reason"]
	else:
		err = world.footprint_error(a.def, a.origin, a.rotation, null)
	if err != "":
		return err
	if not economy.can_afford(amount):
		return "no_money"
	economy.spend(amount, category)
	world.reinsert_attraction(a)
	if a.track != null:
		_restore_coaster(a)
		if a.is_transport() and not a.building and a.track.is_complete():
			var exit: Vector2i = transport_exit_cell(a)
			if world.get_tile(exit) != ParkWorld.Tile.PATH:
				world._set_tile(exit, ParkWorld.Tile.PATH)
		coaster_changed.emit(a.id)
	path_finder.invalidate()
	_reachable_dirty = true
	for g: Guest in guests.values():
		g.rejected_ids.erase(a.id)
	return ""


func _toggle_decor(d: Decor, present: bool, amount: int, category: String) -> String:
	if not present:
		if decor.get(d.id, null) != d:
			return "missing"
		_remove_decor(d.id)
		economy.earn(amount, category)
		return ""
	if decor.has(d.id):
		return "occupied"
	if not can_place_decor(d.def, d.cell):
		return "occupied"
	if not economy.can_afford(amount):
		return "no_money"
	economy.spend(amount, category)
	d.fill = 0
	_reinsert_decor(d)
	return ""
