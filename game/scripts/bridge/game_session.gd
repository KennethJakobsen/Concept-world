extends Node
## Autoload "GameSession": flow mellem hovedmenu og park + gem/indlæs/autosave.
## ParkView læser pending_save/seed i _ready.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const MENU_SCENE: String = "res://scenes/main_menu.tscn"

var pending_save: Dictionary = {}
var seed: int = 1
var store: SaveStore = SaveStore.new()
var _hooked_sim: ParkSim


func _process(_delta: float) -> void:
	# Kobl autosave til den aktuelle sim (ParkView kan skifte sim ved load).
	var s: ParkSim = current_sim()
	if s != _hooked_sim:
		_hooked_sim = s
		if s != null:
			s.day_passed.connect(_on_day_passed)


func start_new(p_seed: int = randi()) -> void:
	seed = p_seed
	pending_save = {}
	_change(MAIN_SCENE)


func start_from_save(d: Dictionary) -> void:
	pending_save = d
	_change(MAIN_SCENE)


func current_sim() -> ParkSim:
	if not is_inside_tree():
		return null
	var v: ParkView = get_tree().get_first_node_in_group("park_view") as ParkView
	return v.sim if v != null else null


func save_to(slot: String) -> bool:
	var s: ParkSim = current_sim()
	if s == null:
		return false
	return store.save(slot, s.to_save())


func load_from(slot: String) -> bool:
	var d: Dictionary = store.load(slot)
	if d.is_empty():
		return false
	start_from_save(d)
	return true


func go_to_main_menu() -> void:
	pending_save = {}
	_change(MENU_SCENE)


func _on_day_passed(_day: int) -> void:
	save_to(SaveStore.AUTOSAVE_SLOT)


func _change(path: String) -> void:
	_hooked_sim = null
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(path)
