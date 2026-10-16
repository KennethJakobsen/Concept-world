class_name ParkView
extends Node3D
## Bridge: ejer ParkSim, driver den og spejler dens state/signaler i scene-noder.
## Ingen spillogik her – kun visning.

const PATH_SCENE: PackedScene = preload("res://scenes/props/path_tile.tscn")
const ENTRANCE_SCENE: PackedScene = preload("res://scenes/props/entrance.tscn")
const GUEST_SCENE: PackedScene = preload("res://scenes/props/guest.tscn")
const LITTER_SCENE: PackedScene = preload("res://scenes/props/litter.tscn")
const SMOKE_SCENE: PackedScene = preload("res://scenes/effects/breakdown_smoke.tscn")
const BUBBLE_SCENE: PackedScene = preload("res://scenes/props/thought_bubble.tscn")
const RIG_SCENE: PackedScene = preload("res://scenes/rendering/day_night_rig.tscn")
const FX_SCENES: Dictionary = {
	&"build_dust": preload("res://scenes/effects/build_dust.tscn"),
	&"confetti": preload("res://scenes/effects/confetti.tscn"),
	&"coins": preload("res://scenes/effects/coins.tscn"),
	&"sweep_dust": preload("res://scenes/effects/sweep_dust.tscn"),
	&"repair_sparks": preload("res://scenes/effects/repair_sparks.tscn"),
	&"balloon_float": preload("res://scenes/effects/balloon_float.tscn"),
	&"vomit": preload("res://scenes/effects/vomit.tscn"),
	&"splash": preload("res://scenes/effects/splash.tscn"),
}
const COIN_INTERVAL: float = 2.5    ## T-055: højst én coins-effekt pr. 2,5 s
const RIDE_SOUND_DIST: float = 25.0 ## ride_start kun hvis kameraet er tæt på
const HAPPY_THOUGHTS: Array[String] = ["Sjovt!", "Det var godt!", "Dejligt med en pause."]
const BUBBLE_TIME: float = 3.0
const MAX_BUBBLES: int = 8
const FLOAT_TIME: float = 1.5

@export var park_width: int = 64
@export var park_height: int = 64
@export var sim_seed: int = 1

var sim: ParkSim
var _paths: Dictionary = {}        ## Vector2i -> Node3D
var _attractions: Dictionary = {}  ## attraction id -> Node3D
var _guests: Dictionary = {}       ## guest id -> Node3D
var _last_thought: Dictionary = {} ## guest id -> String
var _bubbles: Dictionary = {}      ## guest id -> [ThoughtBubble, time_left]
var _scene_cache: Dictionary = {}  ## model path -> PackedScene
var _staff: Dictionary = {}        ## staff id -> Node3D
var _decor: Dictionary = {}        ## decor id -> Node3D
var _litter: Dictionary = {}       ## Vector2i -> LitterVisual
var _litter_pool: Array[Node3D] = []
var _smoke: Dictionary = {}        ## attraction id -> Node3D
## ParkView udsender selv effekt-events (tests/UI). kind = effekt-id, fx &"build_dust".
signal fx_event(kind: StringName, pos: Vector3)

var rig: DayNightRig
var _tod_vis: float = -1.0         ## interpoleret tid på dagen (visning)
var _night: float = -1.0           ## sidst anvendte night_factor
var _running: Dictionary = {}      ## attraction id -> bool (sidst sendt set_running)
var _sparks: Dictionary = {}       ## attraction id -> ParticleFx (loop)
var _repairing: Dictionary = {}    ## staff id -> attraction id
var _coin_cd: float = 0.0
var _rebuilding: bool = false      ## undertryk effekter/lyd mens scenen genopbygges
var _root: Node3D                  ## alle visnings-noder (genskabes ved rebuild)
var _coasters: Dictionary = {}     ## coaster id -> CoasterVis (T-070)
var _piece_defs: Dictionary = {}
var _queues: Dictionary = {}       ## T-140: Vector2i -> QueuePathVisual
var _queue_refreshing: bool = false


## Visningsdata for én rutsjebane.
class CoasterVis:
	var mesh: CoasterTrackMesh
	var train: CoasterTrain
	var line: PackedVector3Array
	var acc: PackedFloat32Array
	var total: float = 0.0
	var vis_t: float = 0.0  ## interpoleret ride_progress
	var end_station: Node3D  ## T-093: svævebanens endestation
	var at_end: bool = false       ## svævebanen: kabinen holder ved endestationen
	var leg_running: bool = false
	var leg_reverse: bool = false  ## svævebanen: denne tur kører end → start
	var idle_t: float = 0.0        ## T-144: tomgangspendul mellem ture uden passagerer
	var idle_wait: float = 0.0     ## T-144: ophold (i tur-andele) ved stationen før næste tomgangstur


func _ready() -> void:
	if rig == null:
		rig = get_node_or_null("DayNightRig") as DayNightRig
	if rig == null:
		rig = RIG_SCENE.instantiate()
		rig.name = "DayNightRig"
		add_child(rig)
	if sim != null:
		return
	var session: Node = get_node_or_null("/root/GameSession")
	var pending: Dictionary = session.get("pending_save") if session != null else {}
	if not pending.is_empty():
		var loaded: ParkSim = ParkSim.from_save(pending)
		session.set("pending_save", {})
		if loaded != null:
			setup(loaded)
			return
		push_warning("ParkView: ugyldig save – starter ny park")
	var s: int = int(session.get("seed")) if session != null else sim_seed
	var scen_id: String = str(session.get("pending_scenario")) if session != null and session.get("pending_scenario") != null else ""
	if scen_id != "":
		session.set("pending_scenario", "")
		var def: ScenarioDef = ScenarioDef.find(scen_id)
		if def != null:
			setup(ParkSim.new_from_scenario(def, s))
			return
		push_warning("ParkView: ukendt scenarie '%s' – starter fri leg" % scen_id)
	setup(ParkSim.new(park_width, park_height, s))


## Tilknyt en (ny eller indlæst) sim og byg hele scenen ud fra dens state.
func setup(p_sim: ParkSim) -> void:
	if sim != null:
		_disconnect()
	sim = p_sim
	sim.world.tile_changed.connect(_on_tile_changed)
	sim.world.attraction_placed.connect(_on_attraction_placed)
	sim.world.litter_changed.connect(_on_litter_changed)
	sim.attraction_removed.connect(_on_attraction_removed)
	sim.guest_spawned.connect(_on_guest_spawned)
	sim.guest_removed.connect(_on_guest_removed)
	sim.staff_hired.connect(_on_staff_hired)
	sim.staff_fired.connect(_on_staff_fired)
	sim.decor_placed.connect(_on_decor_placed)
	sim.decor_removed.connect(_on_decor_removed)
	sim.attraction_broken.connect(_on_attraction_broken)
	sim.attraction_repaired.connect(_on_attraction_repaired)
	sim.phase_changed.connect(_on_phase_changed)
	sim.purchase_made.connect(_on_purchase_made)
	sim.litter_swept.connect(_on_litter_swept)
	sim.ride_cycle_started.connect(_on_ride_cycle_started)
	sim.coaster_changed.connect(_on_coaster_changed)
	sim.guest_vomited.connect(_on_guest_vomited)
	sim.ride_splash.connect(_on_ride_splash)
	sim.prize_won.connect(_on_prize_won)
	sim.item_gained.connect(_on_item_changed)
	sim.item_lost.connect(_on_item_lost)
	sim.queue_changed.connect(_on_queue_changed)
	_tod_vis = sim.time_of_day()
	_on_phase_changed(sim.phase())
	rebuild()


func _disconnect() -> void:
	for pair: Array in [[sim.world.tile_changed, _on_tile_changed], [sim.world.attraction_placed, _on_attraction_placed],
			[sim.world.litter_changed, _on_litter_changed], [sim.attraction_removed, _on_attraction_removed],
			[sim.guest_spawned, _on_guest_spawned], [sim.guest_removed, _on_guest_removed],
			[sim.staff_hired, _on_staff_hired], [sim.staff_fired, _on_staff_fired],
			[sim.decor_placed, _on_decor_placed], [sim.decor_removed, _on_decor_removed],
			[sim.attraction_broken, _on_attraction_broken], [sim.attraction_repaired, _on_attraction_repaired],
			[sim.phase_changed, _on_phase_changed], [sim.purchase_made, _on_purchase_made],
			[sim.litter_swept, _on_litter_swept], [sim.ride_cycle_started, _on_ride_cycle_started],
			[sim.coaster_changed, _on_coaster_changed], [sim.guest_vomited, _on_guest_vomited],
			[sim.prize_won, _on_prize_won], [sim.item_gained, _on_item_changed], [sim.item_lost, _on_item_lost],
			[sim.ride_splash, _on_ride_splash], [sim.queue_changed, _on_queue_changed]]:
		var sig: Signal = pair[0]
		if sig.is_connected(pair[1]):
			sig.disconnect(pair[1])


## Fjerner alle visnings-noder og genskaber dem fra sim'ens nuværende state.
func rebuild() -> void:
	if _root != null:
		remove_child(_root)
		_root.free()
	_root = Node3D.new()
	_root.name = "Content"
	add_child(_root)
	_paths.clear()
	_queues.clear()
	_attractions.clear()
	_guests.clear()
	_last_thought.clear()
	_bubbles.clear()
	_staff.clear()
	_decor.clear()
	_litter.clear()
	_litter_pool.clear()
	_smoke.clear()
	_sparks.clear()
	_repairing.clear()
	_running.clear()
	_coasters.clear()
	_night = -1.0
	var w: ParkWorld = sim.world
	for y in w.height:
		for x in w.width:
			var c := Vector2i(x, y)
			var t: int = w.get_tile(c)
			if t == ParkWorld.Tile.PATH:
				_on_tile_changed(c, t)
			elif t == ParkWorld.Tile.QUEUE:
				_set_queue_visual(c, true)
	refresh_queue_visuals()
	var ent: Node3D = ENTRANCE_SCENE.instantiate()
	ent.position = cell_center(w.entrance)
	_root.add_child(ent)
	_rebuilding = true
	for a in w.attractions:
		_on_attraction_placed(a)
		if a.track != null:
			_on_coaster_changed(a.id)
		if a.broken:
			_on_attraction_broken(a)
	for did: int in sim.decor:
		_on_decor_placed(sim.decor[did])
	for sid: int in sim.staff:
		_on_staff_hired(sim.staff[sid])
	for gid: int in sim.guests:
		_on_guest_spawned(sim.guests[gid])
	for cell: Vector2i in w.litter:
		_on_litter_changed(cell, int(w.litter[cell]))
	_rebuilding = false
	sync_attractions()
	_apply_night(true)


func _process(delta: float) -> void:
	if sim == null:
		return
	sim.update(delta)
	_coin_cd = maxf(0.0, _coin_cd - delta)
	sync_guests()
	sync_staff()
	sync_attractions()
	update_coasters(delta)
	update_bubbles(delta)
	update_time_of_day(delta)


# --- Dag/nat ---

## Glat visningstid: fremskrives med frame-delta × hastighed og trækkes mod sim'ens tid.
func update_time_of_day(delta: float) -> void:
	var target: float = sim.time_of_day()
	if _tod_vis < 0.0 or sim.clock.paused:
		_tod_vis = target if _tod_vis < 0.0 else _tod_vis
	else:
		var per_tick: float = 1.0 / float(maxi(1, sim.balance.day_ticks))
		var adv: float = _tod_vis + delta * sim.clock.speed * SimClock.TICKS_PER_SECOND * per_tick
		var diff: float = wrapf(target - _tod_vis, -0.5, 0.5)
		if absf(diff) > per_tick * 4.0:
			_tod_vis = target  # stort spring (load, hurtig hastighed) → snap
		else:
			# Hold visningen i [target, target + 1 tick) så den aldrig løber foran sim'en.
			var lead: float = wrapf(adv - target, -0.5, 0.5)
			_tod_vis = fposmod(target + clampf(lead, 0.0, per_tick), 1.0)
	if rig != null:
		rig.set_time_of_day(_tod_vis)
	_apply_night(false)


func visual_time_of_day() -> float:
	return _tod_vis


func _apply_night(force: bool) -> void:
	var f: float = rig.night_factor() if rig != null else (1.0 if sim.is_night() else 0.0)
	if not force and absf(f - _night) < 0.01:
		return
	_night = f
	for did: int in _decor:
		_light_node(_decor[did], f)
	for aid: int in _attractions:
		_light_node(_attractions[aid], f)
	for cid: int in _coasters:
		if (_coasters[cid] as CoasterVis).train != null:
			(_coasters[cid] as CoasterVis).train.set_lights(f)


func _light_node(n: Node3D, f: float) -> void:
	if n.has_method("set_intensity"):
		n.call("set_intensity", f)
	elif n.has_method("set_on"):
		n.call("set_on", f > 0.5)
	if n.has_method("set_lights"):
		n.call("set_lights", f)


func _on_phase_changed(p: StringName) -> void:
	_audio(&"ambience", &"night" if p == ParkSim.PHASE_NIGHT or p == ParkSim.PHASE_DUSK else &"day")


# --- Effekter/lyd ---

func _fx(kind: StringName, pos: Vector3) -> Node3D:
	fx_event.emit(kind, pos)
	if _root == null or not FX_SCENES.has(kind):
		return null
	var n: Node3D = (FX_SCENES[kind] as PackedScene).instantiate()
	n.position = pos
	_root.add_child(n)
	if n.is_inside_tree() and n.has_method("play"):
		n.call("play")
	return n


func _audio(kind: StringName, id: StringName, pos: Vector3 = Vector3.INF) -> void:
	if not is_inside_tree():
		return
	var am: Node = get_node_or_null("/root/AudioManager")
	if am == null:
		return
	if kind == &"ambience":
		am.call("set_ambience", id)
	else:
		am.call("play_sfx", id, pos)


func _attraction_pos(a: Attraction, y: float = 0.0) -> Vector3:
	return Vector3(a.origin.x + a.def.footprint.x * 0.5, y, a.origin.y + a.def.footprint.y * 0.5)


func _camera_near(pos: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var cam: Camera3D = get_viewport().get_camera_3d()
	return cam != null and cam.global_position.distance_to(pos) <= RIDE_SOUND_DIST


## Forlystelser: set_running følger sim (virker også efter load).
func sync_attractions() -> void:
	for a: Attraction in sim.world.attractions:
		var n: Node3D = _attractions.get(a.id, null)
		if n == null:
			continue
		var on: bool = a.is_running() and not a.broken
		if _running.get(a.id, null) != on:
			_running[a.id] = on
			if n.has_method("set_running"):
				n.call("set_running", on)


func _on_purchase_made(_guest_id: int, building_id: int, _amount: int) -> void:
	if _coin_cd > 0.0:
		return
	var a: Attraction = sim.get_attraction(building_id)
	if a == null:
		return
	_coin_cd = COIN_INTERVAL
	var pos: Vector3 = _attraction_pos(a, 1.2)
	_fx(&"coins", pos)
	if _camera_near(pos):  # T-055: kun pling tæt på kameraet (AudioManager throttler yderligere)
		_audio(&"sfx", &"cash", pos)


func _on_litter_swept(cell: Vector2i) -> void:
	var pos: Vector3 = cell_center(cell)
	_fx(&"sweep_dust", pos)
	if _camera_near(pos):  # T-055
		_audio(&"sfx", &"sweep", pos)
	var sid: int = staff_near(pos, 0.8)
	if sid >= 0 and (_staff[sid] as Node3D).has_method("play_emote"):
		(_staff[sid] as Node3D).call("play_emote", &"sweep")


func _on_ride_cycle_started(attraction_id: int) -> void:
	var a: Attraction = sim.get_attraction(attraction_id)
	if a == null:
		return
	fx_event.emit(&"ride_start", _attraction_pos(a))
	sync_attractions()
	if _camera_near(_attraction_pos(a)):
		_audio(&"sfx", &"ride_start", _attraction_pos(a))


# --- T-093: sporsystemer ---

const STATION_SCENES: Dictionary = {
	&"flume": "res://scenes/props/flume_station.tscn",
	&"train": "res://scenes/props/train_station.tscn",
	&"monorail": "res://scenes/props/monorail_station.tscn",
}


func _on_ride_splash(_attraction_id: int, cell: Vector2i) -> void:
	var pos: Vector3 = cell_center(cell)
	_fx(&"splash", pos)
	if _camera_near(pos):
		_audio(&"sfx", &"splash", pos)


## Stationsscene for et sporsystem (null = brug def.model).
func _station_scene(system: StringName) -> PackedScene:
	var path: String = STATION_SCENES.get(system, "")
	if path == "":
		return null
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path) as PackedScene if ResourceLoader.exists(path) else null
	return _scene_cache[path]


## Drejer en stations-node efter sporstykket og sætter niveau (svævebanen).
func _pose_station(n: Node3D, p: Dictionary) -> void:
	n.rotation.y = -PI * 0.5 * int(p["heading"])
	if n is TrackStation:
		(n as TrackStation).level = int(p["level"])


# --- T-088: opkast, præmier og ting ---

func _on_guest_vomited(guest_id: int, cell: Vector2i) -> void:
	var pos: Vector3 = cell_center(cell)
	var gn: Node3D = _guests.get(guest_id, null)
	if gn != null and gn.has_method("play_emote"):
		gn.call("play_emote", &"sick")
	_fx(&"vomit", pos)
	if _camera_near(pos):
		_audio(&"sfx", &"vomit", pos)


func _on_prize_won(guest_id: int, attraction_id: int, _item_id: String) -> void:
	var a: Attraction = sim.get_attraction(attraction_id)
	var pos: Vector3 = _attraction_pos(a, 1.0) if a != null else Vector3.ZERO
	var n: Node3D = _guests.get(guest_id, null)
	if n != null:
		pos = n.position
		if n.has_method("play_emote"):
			n.call("play_emote", &"happy")  # cheer
	fx_event.emit(&"prize", pos)
	if _camera_near(pos):
		_audio(&"sfx", &"cheer", pos)
		_audio(&"sfx", &"cash", pos)


func _on_item_changed(guest_id: int, _item_id: StringName) -> void:
	_sync_items(guest_id)


func _on_item_lost(guest_id: int, item_id: StringName, cell: Vector2i) -> void:
	_sync_items(guest_id)
	if String(item_id).contains("balloon"):
		_fx(&"balloon_float", cell_center(cell))


func _sync_items(guest_id: int) -> void:
	var n: Node3D = _guests.get(guest_id, null)
	var g: Guest = sim.guests.get(guest_id, null)
	if n != null and g != null and n.has_method("set_items"):
		n.call("set_items", g.items.duplicate())


static func cell_center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, 0.0, cell.y + 0.5)


func guest_node_count() -> int:
	return _guests.size()


func path_node_count() -> int:
	return _paths.size()


func attraction_node_count() -> int:
	return _attractions.size()


func has_attraction_node(attraction_id: int) -> bool:
	return _attractions.has(attraction_id)


func staff_node_count() -> int:
	return _staff.size()


func decor_node_count() -> int:
	return _decor.size()


func litter_node_count() -> int:
	return _litter.size()


func smoke_node_count() -> int:
	return _smoke.size()


## Alle visnings-noder pr. kategori (tests: rebuild giver samme tal).
func node_counts() -> Dictionary:
	return {"paths": _paths.size(), "attractions": _attractions.size(), "guests": _guests.size(),
		"staff": _staff.size(), "decor": _decor.size(), "litter": _litter.size(), "smoke": _smoke.size()}


## Nærmeste personale indenfor radius af et punkt på jorden (-1 = ingen).
func staff_near(p: Vector3, radius: float = 0.5) -> int:
	var best: int = -1
	var best_d: float = radius * radius
	for sid: int in _staff:
		var n: Node3D = _staff[sid]
		var d: float = Vector2(n.position.x - p.x, n.position.z - p.z).length_squared()
		if d <= best_d:
			best_d = d
			best = sid
	return best


## Decor-id på cellen (on_path foretrækkes ikke; første fundne) eller -1.
func decor_at(cell: Vector2i) -> int:
	for did: int in sim.decor:
		if (sim.decor[did] as Decor).cell == cell:
			return did
	return -1


func bubble_count() -> int:
	return _bubbles.size()


## Nærmeste synlige gæst indenfor radius af et punkt på jorden (-1 = ingen).
func guest_near(p: Vector3, radius: float = 0.5) -> int:
	var best: int = -1
	var best_d: float = radius * radius
	for gid: int in _guests:
		var n: Node3D = _guests[gid]
		if not n.visible:
			continue
		var d: float = Vector2(n.position.x - p.x, n.position.z - p.z).length_squared()
		if d <= best_d:
			best_d = d
			best = gid
	return best


## Flydende tekst (fx "-300") der stiger og fader.
func spawn_floating_text(pos: Vector3, text: String, color: Color = Color.WHITE) -> void:
	if not is_inside_tree():
		return
	var l := Label3D.new()
	l.text = text
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.01
	l.outline_size = 8
	l.position = pos + Vector3(0, 1.5, 0)
	_root.add_child(l)
	var tw: Tween = l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 1.5, FLOAT_TIME)
	tw.tween_property(l, "modulate:a", 0.0, FLOAT_TIME)
	tw.chain().tween_callback(l.queue_free)


func _model_scene(def: Resource) -> PackedScene:
	var path: String = str(def.get("model"))
	if path == "":
		path = "res://scenes/props/%s.tscn" % str(def.get("id"))
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path) as PackedScene if ResourceLoader.exists(path) else null
	return _scene_cache[path]


# --- Signal-handlere ---

func _on_tile_changed(cell: Vector2i, tile: int) -> void:
	var had_queue: bool = _queues.has(cell)
	_set_queue_visual(cell, tile == ParkWorld.Tile.QUEUE)
	if had_queue or tile == ParkWorld.Tile.QUEUE or _queue_near(cell):
		refresh_queue_visuals()
	if tile == ParkWorld.Tile.PATH:
		if not _paths.has(cell):
			var n: Node3D = PATH_SCENE.instantiate()
			n.position = cell_center(cell)
			_root.add_child(n)
			_paths[cell] = n
	elif _paths.has(cell):
		(_paths[cell] as Node3D).queue_free()
		_paths.erase(cell)


# --- Køstier (T-140, ADR-005 §2) ---

func _set_queue_visual(cell: Vector2i, on: bool) -> void:
	if on and not _queues.has(cell):
		var q := QueuePathVisual.new()
		q.name = "Queue_%d_%d" % [cell.x, cell.y]
		q.position = cell_center(cell)
		_root.add_child(q)
		_queues[cell] = q
	elif not on and _queues.has(cell):
		(_queues[cell] as Node3D).queue_free()
		_queues.erase(cell)


func _queue_near(cell: Vector2i) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if _queues.has(cell + d):
			return true
	return false


func _on_queue_changed(_attraction_id: int) -> void:
	refresh_queue_visuals()


## Rækværkets åbninger: en køkæde åbner mod forgænger (indgangen for den forreste celle) og
## efterfølger (stien ved køens ende). Løse køceller åbner mod andre køceller.
func refresh_queue_visuals() -> void:
	if _queue_refreshing or _queues.is_empty():
		return
	_queue_refreshing = true
	var links: Dictionary = {}  ## cell -> Array[Vector2i] (forbundne naboer)
	for a: Attraction in sim.world.attractions:
		if a.is_transport():
			continue
		var approach: Vector2i = sim.approach_cell(a)
		var chain: Array[Vector2i] = a.queue_cells
		for i in chain.size():
			var nb: Array[Vector2i] = [a.entrance_cell if i == 0 else chain[i - 1]]
			if i + 1 < chain.size():
				nb.append(chain[i + 1])
			elif approach != a.entrance_cell:
				nb.append(approach)
			links[chain[i]] = nb
	for c: Vector2i in _queues:
		var mask: int
		if links.has(c):
			var nb: Array[Vector2i] = links[c]
			mask = QueuePathVisual.mask_from(c, func(n: Vector2i) -> bool: return nb.has(n))
		else:
			mask = QueuePathVisual.mask_from(c, func(n: Vector2i) -> bool: return _queues.has(n))
		var q: QueuePathVisual = _queues[c]
		if q.connections != mask or q._parts.get_child_count() == 0:
			q.set_connections(mask)
	_queue_refreshing = false


func queue_visual(cell: Vector2i) -> QueuePathVisual:
	return _queues.get(cell, null)


func _on_attraction_placed(a: Attraction) -> void:
	var scene: PackedScene = _station_scene(a.def.track_system()) if a.is_tracked() else null
	if scene == null:
		scene = _model_scene(a.def)
	if scene == null:
		push_warning("ParkView: ingen scene for attraktion '%s'" % a.def.id)
		return
	var n: Node3D = scene.instantiate()
	n.position = Vector3(a.origin.x + a.def.footprint.x * 0.5, 0.0, a.origin.y + a.def.footprint.y * 0.5)
	_root.add_child(n)
	_attractions[a.id] = n
	if _night >= 0.0:
		_light_node(n, _night)
	if not _rebuilding:
		var pos: Vector3 = _attraction_pos(a)
		_fx(&"build_dust", pos)
		if a.def.kind == "ride":
			_fx(&"confetti", _attraction_pos(a, 1.0))
		_audio(&"sfx", &"build", pos)


func _on_attraction_removed(attraction_id: int) -> void:
	if _coasters.has(attraction_id):
		var cv: CoasterVis = _coasters[attraction_id]
		cv.mesh.queue_free()
		if cv.train != null:
			cv.train.queue_free()
		if cv.end_station != null:
			cv.end_station.queue_free()
		_coasters.erase(attraction_id)
	_free_in(_smoke, attraction_id)
	_free_in(_sparks, attraction_id)
	_running.erase(attraction_id)
	if _attractions.has(attraction_id):
		var pos: Vector3 = (_attractions[attraction_id] as Node3D).position
		_fx(&"build_dust", pos)
		_audio(&"sfx", &"demolish", pos)
		(_attractions[attraction_id] as Node3D).queue_free()
		_attractions.erase(attraction_id)


func _on_guest_spawned(g: Guest) -> void:
	var n: Node3D = GUEST_SCENE.instantiate()
	_root.add_child(n)
	if n.has_method("set_color"):
		n.call("set_color", Color.from_hsv(fposmod(g.id * 0.618034, 1.0), 0.55, 0.9))
	_guests[g.id] = n
	_sync_items(g.id)
	_update_guest(n, g)


func _on_guest_removed(guest_id: int) -> void:
	if _guests.has(guest_id):
		(_guests[guest_id] as Node3D).queue_free()
		_guests.erase(guest_id)
	_bubbles.erase(guest_id)  # boblen er barn af gæst-noden
	_last_thought.erase(guest_id)


func _free_in(d: Dictionary, key: Variant) -> void:
	if d.has(key):
		(d[key] as Node).queue_free()
		d.erase(key)


func _on_attraction_broken(a: Attraction) -> void:
	if _smoke.has(a.id):
		return
	var n: Node3D = SMOKE_SCENE.instantiate()
	n.position = _attraction_pos(a, 1.5)
	_root.add_child(n)
	_smoke[a.id] = n
	if n.is_inside_tree() and n.has_method("play"):
		n.call("play")
	var v: Node3D = _attractions.get(a.id, null)
	if v != null and v.has_method("set_broken"):
		v.call("set_broken", true)
	_running.erase(a.id)
	sync_attractions()
	fx_event.emit(&"breakdown_smoke", n.position)
	if not _rebuilding:
		_audio(&"sfx", &"breakdown", n.position)


func _on_attraction_repaired(a: Attraction) -> void:
	_free_in(_smoke, a.id)
	_free_in(_sparks, a.id)
	for sid: int in _repairing.keys():
		if int(_repairing[sid]) == a.id:
			_repairing.erase(sid)
	var v: Node3D = _attractions.get(a.id, null)
	if v != null and v.has_method("set_broken"):
		v.call("set_broken", false)
	_running.erase(a.id)
	fx_event.emit(&"repaired", _attraction_pos(a))


func _on_staff_hired(st: Staff) -> void:
	var scene: PackedScene = _model_scene(st.def)
	var n: Node3D = scene.instantiate() if scene != null else GUEST_SCENE.instantiate()
	_root.add_child(n)
	_staff[st.id] = n
	_update_walker(n, st.cell, st.next_cell, st.progress, st.id)


func _on_staff_fired(staff_id: int) -> void:
	_free_in(_staff, staff_id)
	if _repairing.has(staff_id):
		var aid: int = int(_repairing[staff_id])
		_repairing.erase(staff_id)
		if not _repairing.values().has(aid):
			_free_in(_sparks, aid)


func _on_decor_placed(d: Decor) -> void:
	var scene: PackedScene = _model_scene(d.def)
	if scene == null:
		push_warning("ParkView: ingen scene for decor '%s'" % d.def.id)
		return
	var n: Node3D = scene.instantiate()
	n.position = cell_center(d.cell)
	if d.def.on_path:
		# Sti-kant: forskyd mod cellens kant (deterministisk side).
		n.position.x += 0.35 if (d.cell.x + d.cell.y) % 2 == 0 else -0.35
	_root.add_child(n)
	_decor[d.id] = n
	if _night >= 0.0:
		_light_node(n, _night)
	if not _rebuilding:
		_fx(&"build_dust", n.position)
		_audio(&"sfx", &"build", n.position)


func _on_decor_removed(decor_id: int) -> void:
	if _decor.has(decor_id):
		var pos: Vector3 = (_decor[decor_id] as Node3D).position
		_fx(&"build_dust", pos)
		_audio(&"sfx", &"demolish", pos)
	_free_in(_decor, decor_id)


func _on_litter_changed(cell: Vector2i, amount: int) -> void:
	if amount <= 0:
		if _litter.has(cell):
			var old: Node3D = _litter[cell]
			old.visible = false
			_litter.erase(cell)
			_litter_pool.append(old)
		return
	var n: Node3D = _litter.get(cell, null)
	if n == null:
		if not _litter_pool.is_empty():
			n = _litter_pool.pop_back()
		else:
			n = LITTER_SCENE.instantiate()
			_root.add_child(n)
		n.position = cell_center(cell)
		_litter[cell] = n
	n.call("set_level", amount)


# --- Gæste-interpolation ---

func sync_guests() -> void:
	for gid in _guests:
		var g: Guest = sim.guests.get(gid, null)
		if g != null:
			_update_guest(_guests[gid], g)


func sync_staff() -> void:
	for sid: int in _staff:
		var st: Staff = sim.staff.get(sid, null)
		if st != null:
			var n: Node3D = _staff[sid]
			_update_walker(n, st.cell, st.next_cell, st.progress, st.id + 7919)
			if n.has_method("set_walking"):
				n.call("set_walking", st.next_cell != st.cell)
			_sync_repair(sid, st, n)


## Mekaniker der arbejder på en reparation → gnister + emote (én gang pr. opgave).
func _sync_repair(sid: int, st: Staff, n: Node3D) -> void:
	var working: bool = st.state == Staff.State.WORKING and st.task == Staff.TASK_REPAIR
	if not working:
		if _repairing.has(sid):
			var old: int = int(_repairing[sid])
			_repairing.erase(sid)
			if not _repairing.values().has(old):
				_free_in(_sparks, old)
		return
	if _repairing.get(sid, -1) == st.task_target_id:
		return
	_repairing[sid] = st.task_target_id
	var a: Attraction = sim.get_attraction(st.task_target_id)
	if a == null:
		return
	if n.has_method("play_emote"):
		n.call("play_emote", &"repair")
	if not _sparks.has(a.id):
		var fx: Node3D = _fx(&"repair_sparks", _attraction_pos(a, 0.8))
		if fx != null:
			_sparks[a.id] = fx
	_audio(&"sfx", &"repair", _attraction_pos(a))


func _update_guest(n: Node3D, g: Guest) -> void:
	if g.state == Guest.State.RIDING or sim.guest_state_name(g) == &"riding_transport":
		n.visible = false
		return
	n.visible = true
	if n.has_method("set_walking"):
		n.call("set_walking", g.next_cell != g.cell and g.state != Guest.State.RESTING)
	if g.state == Guest.State.RESTING:
		var d: Decor = sim.get_decor(g.target_decor_id)
		var dn: Node3D = _decor.get(g.target_decor_id, null)
		if d != null and dn != null:
			n.position = dn.position + Vector3(0, -0.15, 0)  # sidder (sænket) ved bænken
			n.rotation.y = 0.0
			return
	# T-140 (ADR-005): sim'ens visningsposition – køplads langs køstien eller bane på stien.
	var p: Vector2 = sim.guest_position(g.id)
	var pos := Vector3(p.x, 0.0, p.y)
	var dir: Vector3 = Vector3.ZERO
	if g.state == Guest.State.QUEUING and g.transport_id < 0 and g.queue_index >= 0:
		var a: Attraction = sim.get_attraction(g.target_attraction_id)
		if a != null:
			var front: Vector2 = sim.queue_slot_position(a, g.queue_index - 1) if g.queue_index > 0 \
				else Vector2(a.entrance_cell) + Vector2(0.5, 0.5)
			dir = Vector3(front.x - p.x, 0.0, front.y - p.y)
	else:
		dir = cell_center(g.next_cell) - cell_center(g.cell)
	n.position = pos
	if dir.length_squared() > 0.0001:
		n.rotation.y = atan2(dir.x, dir.z)


func _update_walker(n: Node3D, cell: Vector2i, next_cell: Vector2i, progress: float, seed_id: int) -> void:
	var a: Vector3 = cell_center(cell)
	var b: Vector3 = cell_center(next_cell)
	var pos: Vector3 = a.lerp(b, clampf(progress, 0.0, 1.0))
	# Deterministisk spredning så figurer på samme celle ikke overlapper.
	var h: int = seed_id * 2654435761
	pos.x += (float(h & 0xFF) / 255.0 - 0.5) * 0.5
	pos.z += (float((h >> 8) & 0xFF) / 255.0 - 0.5) * 0.5
	n.position = pos
	var dir: Vector3 = b - a
	if dir.length_squared() > 0.0001:
		n.rotation.y = atan2(dir.x, dir.z)


# --- Tankebobler ---

## Viser en boble når en gæsts tanke er ny og ikke tom; max MAX_BUBBLES samtidigt.
func update_bubbles(delta: float) -> void:
	for gid: int in _bubbles.keys():
		var e: Array = _bubbles[gid]
		e[1] = float(e[1]) - delta
		if float(e[1]) <= 0.0:
			var b: Node3D = e[0]
			if is_instance_valid(b):
				b.queue_free()
			_bubbles.erase(gid)
	for gid: int in _guests:
		var g: Guest = sim.guests.get(gid, null)
		if g == null:
			continue
		if _last_thought.get(gid, "") == g.thought:
			continue
		_last_thought[gid] = g.thought
		if g.thought == "":
			continue
		var emote: StringName = thought_emote(g.thought)
		if emote != &"" and (_guests[gid] as Node3D).has_method("play_emote"):
			(_guests[gid] as Node3D).call("play_emote", emote)
		if _bubbles.has(gid):
			var e: Array = _bubbles[gid]
			(e[0] as ThoughtBubble).show_text(g.thought)
			e[1] = BUBBLE_TIME
		elif _bubbles.size() < MAX_BUBBLES:
			var b: ThoughtBubble = BUBBLE_SCENE.instantiate()
			b.position = Vector3(0, 1.3, 0)
			(_guests[gid] as Node3D).add_child(b)
			b.show_text(g.thought)
			_bubbles[gid] = [b, BUBBLE_TIME]


## Tanke → emote: glad/syg/vred; behovs-tanker giver ingen emote.
static func thought_emote(thought: String) -> StringName:
	if thought == "" or ParkSim.NEED_THOUGHTS.values().has(thought):
		return &""
	if HAPPY_THOUGHTS.has(thought):
		return &"happy"
	var t: String = thought.to_lower()
	if t.contains("kvalm") or t.contains("syg") or t.contains("ondt"):
		return &"sick"
	return &"angry"


# --- Rutsjebaner (T-070) ---

func coaster_count() -> int:
	return _coasters.size()


func coaster_mesh(coaster_id: int) -> CoasterTrackMesh:
	return (_coasters[coaster_id] as CoasterVis).mesh if _coasters.has(coaster_id) else null


func coaster_train(coaster_id: int) -> CoasterTrain:
	return (_coasters[coaster_id] as CoasterVis).train if _coasters.has(coaster_id) else null


## Genbygger mesh (og tog, når banen er åben) for én rutsjebane.
func _on_coaster_changed(coaster_id: int) -> void:
	var a: Attraction = sim.get_attraction(coaster_id)
	if a == null or a.track == null:
		return
	if _piece_defs.is_empty():
		_piece_defs = CoasterTrackMesh.load_defs()
	var cv: CoasterVis = _coasters.get(coaster_id, null)
	if cv == null:
		cv = CoasterVis.new()
		cv.mesh = CoasterTrackMesh.new()
		cv.mesh.name = "Coaster%d" % coaster_id
		_root.add_child(cv.mesh)
		_coasters[coaster_id] = cv
	var pieces: Array = a.track.to_dicts()
	cv.mesh.build(pieces, _piece_defs)
	cv.line = CoasterTrackMesh.full_centerline(pieces, _piece_defs)
	cv.acc = CoasterTrackMesh.arc_lengths(cv.line)
	cv.total = cv.acc[cv.acc.size() - 1] if cv.acc.size() > 0 else 0.0
	if not pieces.is_empty():
		var st: Node3D = _attractions.get(coaster_id, null)
		if st != null:
			_pose_station(st, pieces[0])
	_sync_end_station(cv, a, pieces)
	var open: bool = not a.building and a.profile != null
	if open and cv.train == null:
		cv.train = CoasterTrain.new()
		cv.train.name = "Train%d" % coaster_id
		_root.add_child(cv.train)
		cv.train.set_cars(int(CoasterContent.train(a.def.train if a.def.train != "" else "basic_train").get("cars", 3)))
		cv.train.set_style(a.track.system)
		if _night >= 0.0:
			cv.train.set_lights(_night)
	elif not open and cv.train != null:
		cv.train.queue_free()
		cv.train = null
	if open:
		_pose_train(cv, a, 1.0 if a.is_transport() and cv.at_end else 0.0)


## Svævebanens endestation (stykke med station_role "end") vises som egen node.
func _sync_end_station(cv: CoasterVis, a: Attraction, pieces: Array) -> void:
	var end_p: Dictionary = {}
	for i in range(1, pieces.size()):
		var d: TrackPieceDef = CoasterContent.piece(str(pieces[i]["def_id"]))
		if d != null and d.kind == "station" and d.station_role == "end":
			end_p = pieces[i]
			break
	if end_p.is_empty():
		if cv.end_station != null:
			cv.end_station.queue_free()
			cv.end_station = null
		return
	if cv.end_station == null:
		var scene: PackedScene = _station_scene(a.track.system)
		if scene == null:
			scene = _model_scene(a.def)
		if scene == null:
			return
		cv.end_station = scene.instantiate()
		cv.end_station.name = "EndStation%d" % a.id
		_root.add_child(cv.end_station)
		if _night >= 0.0:
			_light_node(cv.end_station, _night)
	var c: Vector2i = end_p["cell"]
	cv.end_station.position = cell_center(c)
	_pose_station(cv.end_station, end_p)


func end_station_node(coaster_id: int) -> Node3D:
	return (_coasters[coaster_id] as CoasterVis).end_station if _coasters.has(coaster_id) else null


## Toget følger ride_progress, interpoleret mellem ticks; står stille i stationen mellem ture.
func update_coasters(delta: float) -> void:
	for id: int in _coasters:
		var cv: CoasterVis = _coasters[id]
		var a: Attraction = sim.get_attraction(id)
		if cv.train == null or a == null or a.profile == null:
			continue
		var p: float = a.ride_progress()
		var run_ticks: int = maxi(1, a.ride_ticks() - a.load_ticks)
		var step: float = 0.0 if sim.clock.paused else delta * sim.clock.speed / (run_ticks * SimClock.TICK_DELTA)
		if p <= 0.0 or a.broken:
			cv.vis_t = p
		else:
			var tick_t: float = 1.0 / run_ticks
			# Fremskriv visningen, men højst én tick foran sim'en; spring hvis den halter.
			cv.vis_t = clampf(cv.vis_t + step, p, minf(1.0, p + tick_t)) if absf(cv.vis_t - p) <= 2.0 * tick_t else p
		if a.is_transport():
			var idle: float = step if a.is_open and not a.broken else 0.0
			_pose_train(cv, a, _transport_leg(cv, p > 0.0 and not a.broken, idle,
				float(a.load_ticks) / run_ticks))
			continue
		_pose_train(cv, a, cv.vis_t)


## Svævebanen kører pendul: hver anden tur fra endestationen tilbage til start.
## Mellem ture holder kabinen ved den station, hvor den sidst stoppede.
## T-144: simulationen kører kun banen, når gæster rider (som genvej). Uden passagerer
## pendler kabinen i tomgang (idle_step = tur-andel pr. frame, 0 = lukket/pause/i stykker),
## så en åben svævebane altid ses køre. Ren visning – ændrer ikke simulationen.
func _transport_leg(cv: CoasterVis, running: bool, idle_step: float = 0.0, dwell: float = 0.0) -> float:
	if running and not cv.leg_running:
		cv.leg_running = true
		# En tomgangstur, der er mere end halvvejs, regnes som ankommet.
		if cv.idle_t > 0.5:
			cv.at_end = not cv.at_end
		cv.idle_t = 0.0
		cv.leg_reverse = cv.at_end
	elif not running and cv.leg_running:
		cv.leg_running = false
		cv.at_end = not cv.leg_reverse
		cv.idle_wait = dwell
	if running:
		return 1.0 - cv.vis_t if cv.leg_reverse else cv.vis_t
	if idle_step > 0.0:
		if cv.idle_wait > 0.0:
			cv.idle_wait = maxf(0.0, cv.idle_wait - idle_step)
		else:
			cv.idle_t += idle_step
			if cv.idle_t >= 1.0:
				cv.idle_t = 0.0
				cv.at_end = not cv.at_end
				cv.idle_wait = dwell
	return 1.0 - cv.idle_t if cv.at_end else cv.idle_t


## Visnings-t for svævebanens kabine (0 = start, 1 = endestation). Til tests.
func transport_leg_t(coaster_id: int) -> float:
	var cv: CoasterVis = _coasters.get(coaster_id, null)
	if cv == null:
		return -1.0
	if cv.leg_running:
		return 1.0 - cv.vis_t if cv.leg_reverse else cv.vis_t
	return 1.0 - cv.idle_t if cv.at_end else cv.idle_t


func _pose_train(cv: CoasterVis, a: Attraction, t: float) -> void:
	if cv.total <= 0.0:
		return
	var n: int = cv.train.car_count()
	var scale: float = cv.total / a.profile.length if a.profile.length > 0.0 else 1.0
	# Forreste vogn ved stationens forkant, så toget står i stationen ved t = 0.
	var head: float = a.profile.position_at(t) * scale + CoasterTrain.CAR_SPACING * (n - 1) * 0.5 + 0.5
	if a.is_transport():
		# Svævebanen kører fra station til endestation og stopper der (intet loop).
		head = minf(head, cv.total - 0.5)
	var poses: Array[Transform3D] = []
	for i in n:
		poses.append(CoasterTrackMesh.pose_at(cv.line, cv.acc, head - i * CoasterTrain.CAR_SPACING))
	cv.train.set_path_pose(poses)
