class_name TestErrorCounter
extends Logger
## Tæller script-/engine-fejl, så runneren kan se om en test crashede.

var errors: PackedStringArray = []
var _mutex := Mutex.new()


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	_mutex.lock()
	errors.append("%s (%s:%d %s)" % [rationale if rationale != "" else code, file, line, function])
	_mutex.unlock()


func take() -> PackedStringArray:
	_mutex.lock()
	var out := errors
	errors = []
	_mutex.unlock()
	return out
