extends Node3D
## T-107: showcase for køsti, crowd, skrald, spand, bænk, ATM og svævetal.
## Kør: godot --rendering-method gl_compatibility res://scenes/rendering/m7_showcase.tscn -- --shots /sti

var _crowd: GuestCrowdRenderer
var _ft: FloatingText3D


func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.75, 0.95)
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	env.environment.ambient_light_energy = 0.6
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(60, 60)
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.4, 0.65, 0.3); pm.material = gm
	g.mesh = pm
	add_child(g)
	# Almindelig sti (række z=0) og en zigzag-køsti ved siden af.
	var path_scene := load("res://scenes/props/path_tile.tscn") as PackedScene
	for x in range(-6, 7):
		var p: Node3D = path_scene.instantiate(); p.position = Vector3(x, 0, 2); add_child(p)
	var q_cells: Array[Vector2i] = []
	for x in range(-4, 3): q_cells.append(Vector2i(x, 1))
	q_cells.append(Vector2i(2, 0))
	for x in range(2, -5, -1): q_cells.append(Vector2i(x, -1))
	var has := func(c: Vector2i) -> bool: return c in q_cells
	for i in q_cells.size():
		var c := q_cells[i]
		var v := QueuePathVisual.new()
		var m := 0
		for j in [i - 1, i + 1]:
			if j < 0 or j >= q_cells.size(): continue
			var d := q_cells[j] - c
			m |= {Vector2i(0, -1): 1, Vector2i(1, 0): 2, Vector2i(0, 1): 4, Vector2i(-1, 0): 8}[d]
		if i == 0: m |= 4  # forbundet til stien
		v.set_connections(m)
		v.position = Vector3(c.x, 0, c.y)
		add_child(v)
		# Gæster i køen med baner.
		for k in 2:
			var gv: Node3D = (load("res://scenes/props/guest.tscn") as PackedScene).instantiate()
			gv.position = GuestCrowdRenderer.separate(Vector3(c.x, 0.06, c.y + (k - 0.5) * 0.4), Vector3(1, 0, 0), i * 2 + k)
			add_child(gv)
	var atm: Node3D = (load("res://scenes/props/atm.tscn") as PackedScene).instantiate()
	atm.position = Vector3(-6, 0, 3.2); add_child(atm)
	for lvl in 3:
		var b: Node3D = (load("res://scenes/props/bin.tscn") as PackedScene).instantiate()
		b.position = Vector3(-1 + lvl, 0, 3.2); add_child(b)
		AmenityVisuals.set_bin_level(b, lvl)
	var bench: Node3D = (load("res://scenes/props/bench.tscn") as PackedScene).instantiate()
	bench.position = Vector3(4, 0, 3.2); add_child(bench)
	var sitter: Node3D = (load("res://scenes/props/guest.tscn") as PackedScene).instantiate()
	bench.add_child(sitter)
	sitter.position = AmenityVisuals.bench_seat_position(0)
	AmenityVisuals.set_guest_seated.call_deferred(sitter, true)
	for x in [-3, 0, 5]:
		var ls := LitterScatter.new(); ls.cell = Vector2i(x, 2); ls.position = Vector3(x, 0, 2)
		add_child(ls)
		ls.set_items([{"kind": "wrapper", "index": 0}, {"kind": "cup", "index": 1}, {"kind": "can", "index": 2}, {"kind": "food", "index": 3}])
	# Crowd: 500 gæster på en plads bagved (MultiMesh).
	_crowd = GuestCrowdRenderer.new(); add_child(_crowd)
	var entries: Array = []
	for i in 500:
		var c := Vector2i(i % 25 - 12, -4 - i / 25)
		var pos := GuestCrowdRenderer.separate(Vector3(c.x, 0, c.y), Vector3(0, 0, 1), i)
		entries.append({"id": i, "pos": pos, "color": Color.from_hsv(fmod(i * 0.137, 1.0), 0.55, 0.9)})
	_crowd.update(entries, Vector3(0, 30, 10))
	_ft = FloatingText3D.new(); add_child(_ft)
	var cam := Camera3D.new(); add_child(cam)
	cam.look_at_from_position(Vector3(8, 9, 12), Vector3(0, 0, 0))
	cam.make_current()
	var args := OS.get_cmdline_user_args()
	var k := args.find("--shots")
	if k >= 0 and k + 1 < args.size():
		_shots.call_deferred(args[k + 1], cam)


func _shots(dir: String, cam: Camera3D) -> void:
	_ft.show_amount(Vector3(-6, 1.6, 3.2), 25, Color(0.4, 1.0, 0.45))
	_ft.show_amount(Vector3(0, 1.6, 0), 8)
	for i in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(dir + "/t107_overview.png")
	cam.look_at_from_position(Vector3(3, 3.5, 5.5), Vector3(-1, 0, 0.5))
	for i in 5: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(dir + "/t107_queue_close.png")
	cam.look_at_from_position(Vector3(0, 14, 8), Vector3(0, 0, -12))
	for i in 5: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(dir + "/t107_crowd.png")
	get_tree().quit()
