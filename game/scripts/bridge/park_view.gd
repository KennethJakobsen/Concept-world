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
var _root: Node3D                  ## alle visnings-noder (genskabes ved rebuild)


func _ready() -> void:
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
	rebuild()


func _disconnect() -> void:
	for pair: Array in [[sim.world.tile_changed, _on_tile_changed], [sim.world.attraction_placed, _on_attraction_placed],
			[sim.world.litter_changed, _on_litter_changed], [sim.attraction_removed, _on_attraction_removed],
			[sim.guest_spawned, _on_guest_spawned], [sim.guest_removed, _on_guest_removed],
			[sim.staff_hired, _on_staff_hired], [sim.staff_fired, _on_staff_fired],
			[sim.decor_placed, _on_decor_placed], [sim.decor_removed, _on_decor_removed],
			[sim.attraction_broken, _on_attraction_broken], [sim.attraction_repaired, _on_attraction_repaired]]:
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
	_attractions.clear()
	_guests.clear()
	_last_thought.clear()
	_bubbles.clear()
	_staff.clear()
	_decor.clear()
	_litter.clear()
	_litter_pool.clear()
	_smoke.clear()
	var w: ParkWorld = sim.world
	for y in w.height:
		for x in w.width:
			var c := Vector2i(x, y)
			if w.get_tile(c) == ParkWorld.Tile.PATH:
				_on_tile_changed(c, ParkWorld.Tile.PATH)
	var ent: Node3D = ENTRANCE_SCENE.instantiate()
	ent.position = cell_center(w.entrance)
	_root.add_child(ent)
	for a in w.attractions:
		_on_attraction_placed(a)
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


func _process(delta: float) -> void:
	if sim == null:
		return
	sim.update(delta)
	sync_guests()
	sync_staff()
	update_bubbles(delta)


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
	if tile == ParkWorld.Tile.PATH:
		if not _paths.has(cell):
			var n: Node3D = PATH_SCENE.instantiate()
			n.position = cell_center(cell)
			_root.add_child(n)
			_paths[cell] = n
	elif _paths.has(cell):
		(_paths[cell] as Node3D).queue_free()
		_paths.erase(cell)


func _on_attraction_placed(a: Attraction) -> void:
	var scene: PackedScene = _model_scene(a.def)
	if scene == null:
		push_warning("ParkView: ingen scene for attraktion '%s'" % a.def.id)
		return
	var n: Node3D = scene.instantiate()
	n.position = Vector3(a.origin.x + a.def.footprint.x * 0.5, 0.0, a.origin.y + a.def.footprint.y * 0.5)
	_root.add_child(n)
	_attractions[a.id] = n


func _on_attraction_removed(attraction_id: int) -> void:
	_free_in(_smoke, attraction_id)
	if _attractions.has(attraction_id):
		(_attractions[attraction_id] as Node3D).queue_free()
		_attractions.erase(attraction_id)


func _on_guest_spawned(g: Guest) -> void:
	var n: Node3D = GUEST_SCENE.instantiate()
	_root.add_child(n)
	if n.has_method("set_color"):
		n.call("set_color", Color.from_hsv(fposmod(g.id * 0.618034, 1.0), 0.55, 0.9))
	_guests[g.id] = n
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
	n.position = Vector3(a.origin.x + a.def.footprint.x * 0.5, 1.5, a.origin.y + a.def.footprint.y * 0.5)
	_root.add_child(n)
	_smoke[a.id] = n


func _on_attraction_repaired(a: Attraction) -> void:
	_free_in(_smoke, a.id)


func _on_staff_hired(st: Staff) -> void:
	var scene: PackedScene = _model_scene(st.def)
	var n: Node3D = scene.instantiate() if scene != null else GUEST_SCENE.instantiate()
	_root.add_child(n)
	_staff[st.id] = n
	_update_walker(n, st.cell, st.next_cell, st.progress, st.id)


func _on_staff_fired(staff_id: int) -> void:
	_free_in(_staff, staff_id)


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
	if n.has_method("set_on"):
		n.call("set_on", false)  # dag/nat kommer i M4
	_decor[d.id] = n


func _on_decor_removed(decor_id: int) -> void:
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


func _update_guest(n: Node3D, g: Guest) -> void:
	if g.state == Guest.State.RIDING:
		n.visible = false
		return
	n.visible = true
	if g.state == Guest.State.RESTING:
		var d: Decor = sim.get_decor(g.target_decor_id)
		var dn: Node3D = _decor.get(g.target_decor_id, null)
		if d != null and dn != null:
			n.position = dn.position + Vector3(0, -0.15, 0)  # sidder (sænket) ved bænken
			n.rotation.y = 0.0
			return
	_update_walker(n, g.cell, g.next_cell, g.progress, g.id)


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
