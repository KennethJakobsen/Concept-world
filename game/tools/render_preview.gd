extends SceneTree
## T-059: Renderer et kontrolbillede af teksturerede props i Compatibility.
## Kør (ikke headless): cd game && godot --rendering-method gl_compatibility --script res://tools/render_preview.gd -- /sti/til/out.png [prop1,prop2,...] [close]  (close = nærbillede af første prop)

const PROPS := ["haunted_house", "toilet", "burger_stand", "bench", "carousel", "go_karts", "entrance", "bin", "lamp", "tree_round"]

var _frames := 0
var _out := "user://preview.png"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	var props: Array = PROPS
	if args.size() > 1:
		props = Array(args[1].split(","))
	var root3d := Node3D.new()
	root.add_child(root3d)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(24, 24)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/ground_grid.gdshader")
	sm.set_shader_parameter("grass_tex", load("res://assets/textures/grass.png"))
	pm.material = sm
	ground.mesh = pm
	root3d.add_child(ground)
	for i in 6:
		var t: Node3D = (load("res://scenes/props/path_tile.tscn") as PackedScene).instantiate()
		t.position = Vector3(i - 3 + 0.5, 0, 2.5)
		root3d.add_child(t)
	var x := -5.0
	for id in props:
		var n: Node3D = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		n.position = Vector3(x, 0, 0 if int(x) % 2 == 0 else -2.5)
		root3d.add_child(n)
		x += 1.6 if id in ["bench", "bin", "lamp", "tree_round", "toilet", "burger_stand"] else 3.0
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.shadow_enabled = true
	root3d.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.6, 0.75, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	root3d.add_child(env)
	var cam := Camera3D.new()
	root3d.add_child(cam)
	if args.size() > 2 and args[2] == "close":
		cam.look_at_from_position(Vector3(-5 + 2.6, 2.6, 3.4), Vector3(-5, 0.6, 0))
	else:
		cam.look_at_from_position(Vector3(4, 6, 9), Vector3(4, 0.5, -1))
	root.size = Vector2i(1600, 900)


func _process(_d: float) -> bool:
	_frames += 1
	if _frames == 40:
		root.get_texture().get_image().save_png(_out)
		print("saved ", _out)
		return true
	return false
