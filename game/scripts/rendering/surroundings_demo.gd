extends Node3D
## T-108 demo: omgivelser rundt om en tom 64x64-park. Taster 1/2/3 = tema, W = hæk/hegn.
## Koeres: godot res://scenes/rendering/surroundings_demo.tscn

const THEMES: Array[String] = ["countryside", "river", "mountain"]
var _theme: int = 0
var _wall: String = "hedge"
var _r: SurroundingsRenderer
var _cam: Camera3D


func _ready() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.6, 0.78, 0.95)
	env.environment.ambient_light_color = Color(0.7, 0.75, 0.8)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	add_child(env)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(64, 64)
	ground.mesh = pm
	ground.position = Vector3(32, 0, 32)
	add_child(ground)
	_cam = Camera3D.new()
	_cam.position = Vector3(32, 45, 120)
	add_child(_cam)
	_cam.look_at(Vector3(32, 0, 60))
	_r = SurroundingsRenderer.new()
	add_child(_r)
	var shot := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--theme="):
			_theme = int(a.trim_prefix("--theme="))
		elif a.begins_with("--shot="):
			shot = a.trim_prefix("--shot=")
	_rebuild()
	if shot != "":
		for i in 60:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(shot)
		print("fps=", Engine.get_frames_per_second())
		get_tree().quit()


func _rebuild() -> void:
	var cfg := SurroundingsRenderer.load_config(THEMES[_theme])
	cfg["wall"] = _wall
	_r.build(64, 64, Vector2i(32, 63), cfg)


func _unhandled_key_input(e: InputEvent) -> void:
	var k := e as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_1, KEY_2, KEY_3:
			_theme = k.keycode - KEY_1
			_rebuild()
		KEY_W:
			_wall = "fence" if _wall == "hedge" else "hedge"
			_rebuild()
