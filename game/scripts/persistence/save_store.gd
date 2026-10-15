class_name SaveStore
extends RefCounted
## Simulation-neutral fil-I/O for savefiler: <base_dir>/<slot>.json (user:// → IndexedDB på web).

const DEFAULT_DIR: String = "user://saves/"
const AUTOSAVE_SLOT: String = "autosave"

var base_dir: String


func _init(p_base_dir: String = DEFAULT_DIR) -> void:
	base_dir = p_base_dir if p_base_dir.ends_with("/") else p_base_dir + "/"


static func is_valid_slot(slot: String) -> bool:
	return slot.is_valid_filename() and not slot.is_empty() and not slot.contains("/")


func path_for(slot: String) -> String:
	return base_dir + slot + ".json"


func save(slot: String, d: Dictionary) -> bool:
	if not is_valid_slot(slot):
		return false
	DirAccess.make_dir_recursive_absolute(base_dir)
	var f := FileAccess.open(path_for(slot), FileAccess.WRITE)
	if f == null:
		push_error("SaveStore: kan ikke skrive %s (%d)" % [path_for(slot), FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(d, "", false, true))  # fuld float-præcision
	f.close()
	return true


## Returnerer {} hvis slot ikke findes eller er ugyldig JSON.
func load(slot: String) -> Dictionary:
	if not is_valid_slot(slot) or not FileAccess.file_exists(path_for(slot)):
		return {}
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path_for(slot)))
	return v if v is Dictionary else {}


## Slot-navne sorteret alfabetisk.
func list() -> Array:
	var out: Array = []
	var dir := DirAccess.open(base_dir)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.ends_with(".json"):
			out.append(f.get_basename())
	out.sort()
	return out


func exists(slot: String) -> bool:
	return is_valid_slot(slot) and FileAccess.file_exists(path_for(slot))


func delete(slot: String) -> bool:
	if not exists(slot):
		return false
	return DirAccess.remove_absolute(path_for(slot)) == OK
