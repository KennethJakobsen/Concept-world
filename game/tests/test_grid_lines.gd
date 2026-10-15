extends TestCase
## T-063: grid-linjer kun i byggetilstand, med blød fade.


func _mat() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/ground_grid.gdshader") as Shader
	m.set_shader_parameter(&"line_strength", 0.16)
	return m


func _strength(m: ShaderMaterial) -> float:
	return float(m.get_shader_parameter(&"line_strength"))


func test_select_hides_and_build_shows_with_fade() -> void:
	var m := _mat()
	var f := GridLineFader.new(m, BuildTool.TOOL_SELECT)
	assert_true(is_equal_approx(_strength(m), 0.0), "skjult i vælg")
	f.set_tool(BuildTool.TOOL_PATH)
	f.update(0.1)
	var mid: float = _strength(m)
	assert_true(mid > 0.0 and mid < 0.16, "midt i fade: %f" % mid)
	f.update(0.15)
	assert_true(is_equal_approx(_strength(m), 0.16), "fuld styrke efter fade")
	f.set_tool(BuildTool.TOOL_SELECT)
	f.update(0.25)
	assert_true(is_equal_approx(_strength(m), 0.0), "fader ud")


func test_tool_classification() -> void:
	for t in ["path", "remove", "carousel", "decor:bench", "staff:handyman"]:
		assert_true(GridLineFader.is_build_tool(t), t)
	assert_true(not GridLineFader.is_build_tool(BuildTool.TOOL_SELECT))


func test_build_tool_drives_fader() -> void:
	var bt := BuildTool.new()
	var m := _mat()
	bt.grid_lines = GridLineFader.new(m, bt.tool)
	bt.set_tool(BuildTool.TOOL_REMOVE)
	bt.grid_lines.update(1.0)
	assert_true(is_equal_approx(_strength(m), 0.16))
	bt.free()
