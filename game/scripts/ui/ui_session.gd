class_name UiSession
extends RefCounted
## Defensiv adgang til autoload GameSession (gameplay, T-039). Alle kald tåler at den mangler.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const MENU_SCENE: String = "res://scenes/main_menu.tscn"


static func get_session() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("GameSession")


static func call_session(method: String, args: Array = []) -> Variant:
	var s: Node = get_session()
	if s == null or not s.has_method(method):
		return null
	return s.callv(method, args)


static func has(method: String) -> bool:
	var s: Node = get_session()
	return s != null and s.has_method(method)


static func store() -> SaveStore:
	return SaveStore.new()


static func change_scene(path: String) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.change_scene_to_file(path)


static func start_new(p_seed: int) -> void:
	if has("start_new"):
		call_session("start_new", [p_seed])
	else:
		change_scene(MAIN_SCENE)


static func load_slot(slot: String) -> bool:
	if has("load_from"):
		return bool(call_session("load_from", [slot]))
	if has("start_from_save"):
		var d: Dictionary = store().load(slot)
		if d.is_empty():
			return false
		call_session("start_from_save", [d])
		return true
	return false


static func save_slot(slot: String, sim: ParkSim) -> bool:
	if has("save_to"):
		return bool(call_session("save_to", [slot]))
	if sim != null and sim.has_method("to_save"):
		return store().save(slot, sim.call("to_save"))
	return false


static func go_to_main_menu() -> void:
	if has("go_to_main_menu"):
		call_session("go_to_main_menu")
	else:
		change_scene(MENU_SCENE)
