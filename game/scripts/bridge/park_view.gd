class_name ParkView
extends Node3D
## Bridge: ejer ParkSim, driver den og spejler dens state/signaler i scene-noder.
## Ingen spillogik her – kun visning.

const PATH_SCENE: PackedScene = preload("res://scenes/props/path_tile.tscn")
const ENTRANCE_SCENE: PackedScene = preload("res://scenes/props/entrance.tscn")
const GUEST_SCENE: PackedScene = preload("res://scenes/props/guest.tscn")
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


func _ready() -> void:
	if sim == null:
		setup(ParkSim.new(park_width, park_height, sim_seed))


func setup(p_sim: ParkSim) -> void:
	sim = p_sim
	sim.world.tile_changed.connect(_on_tile_changed)
	sim.world.attraction_placed.connect(_on_attraction_placed)
	sim.attraction_removed.connect(_on_attraction_removed)
	sim.guest_spawned.connect(_on_guest_spawned)
	sim.guest_removed.connect(_on_guest_removed)
	var ent: Node3D = ENTRANCE_SCENE.instantiate()
	ent.position = cell_center(sim.world.entrance)
	add_child(ent)


func _process(delta: float) -> void:
	if sim == null:
		return
	sim.update(delta)
	sync_guests()
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
	add_child(l)
	var tw: Tween = l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 1.5, FLOAT_TIME)
	tw.tween_property(l, "modulate:a", 0.0, FLOAT_TIME)
	tw.chain().tween_callback(l.queue_free)


func _model_scene(def: AttractionDef) -> PackedScene:
	var path: String = def.model
	if path == "":
		path = "res://scenes/props/%s.tscn" % def.id
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path) as PackedScene if ResourceLoader.exists(path) else null
	return _scene_cache[path]


# --- Signal-handlere ---

func _on_tile_changed(cell: Vector2i, tile: int) -> void:
	if tile == ParkWorld.Tile.PATH:
		if not _paths.has(cell):
			var n: Node3D = PATH_SCENE.instantiate()
			n.position = cell_center(cell)
			add_child(n)
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
	add_child(n)
	_attractions[a.id] = n


func _on_attraction_removed(attraction_id: int) -> void:
	if _attractions.has(attraction_id):
		(_attractions[attraction_id] as Node3D).queue_free()
		_attractions.erase(attraction_id)


func _on_guest_spawned(g: Guest) -> void:
	var n: Node3D = GUEST_SCENE.instantiate()
	add_child(n)
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


# --- Gæste-interpolation ---

func sync_guests() -> void:
	for gid in _guests:
		var g: Guest = sim.guests.get(gid, null)
		if g != null:
			_update_guest(_guests[gid], g)


func _update_guest(n: Node3D, g: Guest) -> void:
	if g.state == Guest.State.RIDING:
		n.visible = false
		return
	n.visible = true
	var a: Vector3 = cell_center(g.cell)
	var b: Vector3 = cell_center(g.next_cell)
	var pos: Vector3 = a.lerp(b, clampf(g.progress, 0.0, 1.0))
	# Deterministisk spredning så gæster på samme celle ikke overlapper.
	var h: int = g.id * 2654435761
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
