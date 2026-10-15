class_name ParkView
extends Node3D
## Bridge: ejer ParkSim, driver den og spejler dens state/signaler i scene-noder.
## Ingen spillogik her – kun visning.

const PATH_SCENE: PackedScene = preload("res://scenes/props/path_tile.tscn")
const ENTRANCE_SCENE: PackedScene = preload("res://scenes/props/entrance.tscn")
const GUEST_SCENE: PackedScene = preload("res://scenes/props/guest.tscn")
const ATTRACTION_SCENES: Dictionary = {
	"carousel": preload("res://scenes/props/carousel.tscn"),
}

@export var park_width: int = 64
@export var park_height: int = 64
@export var sim_seed: int = 1

var sim: ParkSim
var _paths: Dictionary = {}        ## Vector2i -> Node3D
var _attractions: Dictionary = {}  ## attraction id -> Node3D
var _guests: Dictionary = {}       ## guest id -> Node3D


func _ready() -> void:
	if sim == null:
		setup(ParkSim.new(park_width, park_height, sim_seed))


func setup(p_sim: ParkSim) -> void:
	sim = p_sim
	sim.world.tile_changed.connect(_on_tile_changed)
	sim.world.attraction_placed.connect(_on_attraction_placed)
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


static func cell_center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, 0.0, cell.y + 0.5)


func guest_node_count() -> int:
	return _guests.size()


func path_node_count() -> int:
	return _paths.size()


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
	var scene: PackedScene = ATTRACTION_SCENES.get(a.def.id, null)
	if scene == null:
		push_warning("ParkView: ingen scene for attraktion '%s'" % a.def.id)
		return
	var n: Node3D = scene.instantiate()
	n.position = Vector3(a.origin.x + a.def.footprint.x * 0.5, 0.0, a.origin.y + a.def.footprint.y * 0.5)
	add_child(n)
	_attractions[a.id] = n


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
