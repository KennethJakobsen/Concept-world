class_name UndoStack
extends RefCounted
## T-106 (ADR-005 §4): kommandostak med inverse kommandoer. Poster er Dictionaries
## {kind, label, args, inverse_args, money_delta, tick}. ParkSim udfører dem; stakken holder kun orden.
## Gemmes ikke.

var max_steps: int = 20
var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []


func _init(p_max_steps: int = 20) -> void:
	max_steps = maxi(1, p_max_steps)


## Ny spillerhandling: lægges øverst, og redo-stakken ryddes.
func push(entry: Dictionary) -> void:
	_undo.append(entry)
	while _undo.size() > max_steps:
		_undo.pop_front()
	_redo.clear()


func can_undo() -> bool:
	return not _undo.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()


func peek_undo() -> Dictionary:
	return _undo.back() if not _undo.is_empty() else {}


func peek_redo() -> Dictionary:
	return _redo.back() if not _redo.is_empty() else {}


## Flytter øverste undo-post til redo (kaldes efter vellykket inverse).
func commit_undo() -> void:
	if not _undo.is_empty():
		_redo.append(_undo.pop_back())


## Flytter øverste redo-post tilbage til undo (kaldes efter vellykket gentagelse).
func commit_redo() -> void:
	if not _redo.is_empty():
		_undo.append(_redo.pop_back())
		while _undo.size() > max_steps:
			_undo.pop_front()


func undo_size() -> int:
	return _undo.size()


func redo_size() -> int:
	return _redo.size()


func clear() -> void:
	_undo.clear()
	_redo.clear()
