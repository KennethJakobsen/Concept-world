class_name GridLineFader
extends RefCounted
## Styrer terræn-shaderens `line_strength`: synlig i bygge-/nedrivningsværktøjer,
## næsten usynlig i vælg-værktøjet. Blød lineær fade over FADE_TIME sekunder.

const FADE_TIME: float = 0.2
const PARAM: StringName = &"line_strength"
const SELECT_STRENGTH: float = 0.0

var material: ShaderMaterial
var build_strength: float = 0.16
var current: float = 0.0
var target: float = 0.0


func _init(mat: ShaderMaterial = null, start_tool: String = BuildTool.TOOL_SELECT) -> void:
	material = mat
	if material != null:
		var v: Variant = material.get_shader_parameter(PARAM)
		if v != null:
			build_strength = float(v)
	target = target_for(start_tool)
	current = target
	_apply()


static func is_build_tool(tool: String) -> bool:
	return tool != BuildTool.TOOL_SELECT and tool != ""


func target_for(tool: String) -> float:
	return build_strength if is_build_tool(tool) else SELECT_STRENGTH


func set_tool(tool: String) -> void:
	target = target_for(tool)


func update(delta: float) -> void:
	if is_equal_approx(current, target):
		return
	var step: float = build_strength / FADE_TIME * delta
	current = move_toward(current, target, maxf(step, 0.0001))
	_apply()


func _apply() -> void:
	if material != null:
		material.set_shader_parameter(PARAM, current)
