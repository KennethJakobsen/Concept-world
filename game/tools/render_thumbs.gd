extends SceneTree
## T-137: Renderer prop-miniaturer (160x120, transparent baggrund) fra prop-scenerne,
## fast isometrisk vinkel (30° op, 45° rundt), varmt sollys, lille flise med oval skygge.
## Bygger til sidst et kontaktark med alle ikoner og miniaturer.
## Kør (IKKE headless, kræver rendering, Compatibility):
##   cd game && godot --rendering-method gl_compatibility --script res://tools/render_thumbs.gd [-- /sti/kontaktark.png]
## Output: res://assets/ui/thumbs/<content_id>.png

const SIZE := Vector2i(160, 120)
const SS := 2  # supersampling
const OUT_DIR := "res://assets/ui/thumbs"
const CONTENT_DIRS := ["res://content/attractions", "res://content/decor", "res://content/staff"]
## Ekstra miniaturer, som ikke er i content-mapperne ovenfor.
const EXTRA := {"path": "res://scenes/props/path_tile.tscn", "entrance": "res://scenes/props/entrance.tscn"}
const SMALL := ["bench", "bin", "lamp", "flowers", "tree_round", "tree_pine", "tree_blossom", "cleaner", "entertainer", "mechanic", "path"]

var _jobs: Array = []  # [id, scene_path]
var _vp: SubViewport
var _stage: Node3D
var _cam: Camera3D
var _frame := 0
var _sheet_out := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_sheet_out = args[0]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for dir: String in CONTENT_DIRS:
		var files := DirAccess.get_files_at(dir)
		for f in files:
			if not f.ends_with(".json"):
				continue
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + "/" + f))
			if data is Dictionary and data.has("model"):
				if ResourceLoader.exists(String(data["model"])):
					_jobs.append([String(data["id"]), String(data["model"])])
				else:
					print("render_thumbs: mangler scene for %s (%s) - UI bruger fallback-ikon" % [data["id"], data["model"]])
	for id: String in EXTRA:
		_jobs.append([id, EXTRA[id]])

	_vp = SubViewport.new()
	_vp.size = SIZE * SS
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.own_world_3d = true
	root.add_child(_vp)
	var world := Node3D.new()
	_vp.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 1.1
	sun.rotation_degrees = Vector3(-55, -20, 0)
	world.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.72, 0.7, 0.75)
	env.environment.ambient_light_energy = 0.9
	world.add_child(env)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(_cam)
	_stage = Node3D.new()
	world.add_child(_stage)


func _process(_d: float) -> bool:
	# Hvert job: frame 0 = byg, frame 3 = gem.
	if _jobs.is_empty():
		if _sheet_out != "":
			_make_sheet()
		print("render_thumbs: færdig")
		return true
	var job: Array = _jobs[0]
	if _frame == 0:
		_build(job[0], job[1])
	elif _frame >= 4:
		var img := _vp.get_texture().get_image()
		img.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
		img.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, job[0]]))
		_jobs.pop_front()
		_frame = 0
		return false
	_frame += 1
	return false


func _build(id: String, scene_path: String) -> void:
	for ch in _stage.get_children():
		ch.queue_free()
	var prop: Node3D = (load(scene_path) as PackedScene).instantiate()
	_stage.add_child(prop)
	_freeze(prop)
	var box := _aabb(prop, Transform3D.IDENTITY)
	if box.size == Vector3.ZERO:
		box = AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
	var rad := maxf(box.size.x, box.size.z) * 0.5
	var ctr := box.get_center()
	# Lille flise + oval skygge under prop'en.
	var tile := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = rad * 0.85 + 0.15
	cm.bottom_radius = cm.top_radius
	cm.height = 0.04
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color("#C9A877") if id in ["path", "bench", "bin", "lamp", "cleaner", "entertainer", "mechanic"] else Color("#6DB54A")
	cm.material = tm
	tile.mesh = cm
	tile.position = Vector3(ctr.x, box.position.y - 0.03, ctr.z)
	_stage.add_child(tile)
	var sh := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = cm.top_radius * 0.75
	sm.bottom_radius = sm.top_radius
	sm.height = 0.005
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0, 0, 0, 0.3)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = smat
	sh.mesh = sm
	sh.position = Vector3(ctr.x, box.position.y + 0.012, ctr.z)
	_stage.add_child(sh)
	# Kamera: 30° op, 45° rundt. Ortogonal størrelse så prop'en fylder ~80 % af højden.
	var dir := Vector3(sin(deg_to_rad(45)), 0, cos(deg_to_rad(45))) * cos(deg_to_rad(30)) + Vector3.UP * sin(deg_to_rad(30))
	var full := box.merge(AABB(Vector3(ctr.x - cm.top_radius, box.position.y - 0.05, ctr.z - cm.top_radius), Vector3(cm.top_radius * 2, 0.05, cm.top_radius * 2)))
	var fc := full.get_center()
	_cam.look_at_from_position(fc + dir * 50.0, fc, Vector3.UP)
	# Projicér hjørnerne i kamerarum for at finde udstrækning.
	var inv := _cam.global_transform.affine_inverse()
	var minp := Vector2(INF, INF)
	var maxp := Vector2(-INF, -INF)
	for i in 8:
		var v := inv * full.get_endpoint(i)
		minp = minp.min(Vector2(v.x, v.y))
		maxp = maxp.max(Vector2(v.x, v.y))
	var w := maxp.x - minp.x
	var h := maxp.y - minp.y
	var aspect := float(SIZE.x) / SIZE.y
	_cam.size = maxf(h, w / aspect) / 0.82
	# Centrér på den projicerede midte.
	var mid := (minp + maxp) * 0.5
	_cam.position += _cam.global_transform.basis.x * mid.x + _cam.global_transform.basis.y * mid.y
	_cam.near = 0.1
	_cam.far = 200.0


## Stop animationer, så miniaturen er deterministisk.
func _freeze(n: Node) -> void:
	n.process_mode = Node.PROCESS_MODE_DISABLED
	for ch in n.get_children():
		if ch is GPUParticles3D or ch is CPUParticles3D:
			(ch as Node3D).visible = false
		_freeze(ch)


func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is VisualInstance3D and not (n is Light3D) and (n as Node3D).visible:
		var b: AABB = t * (n as VisualInstance3D).get_aabb()
		out = b
		first = false
	for ch in n.get_children():
		if ch is Node3D and not (ch as Node3D).visible:
			continue
		var cb := _aabb(ch, t)
		if cb.size == Vector3.ZERO:
			continue
		out = cb if first else out.merge(cb)
		first = false
	return out


func _make_sheet() -> void:
	var icons := Array(DirAccess.get_files_at("res://assets/ui/icons")).filter(func(f: String) -> bool: return f.ends_with(".png"))
	var thumbs := Array(DirAccess.get_files_at(OUT_DIR)).filter(func(f: String) -> bool: return f.ends_with(".png"))
	var cols := 12
	var icon_rows := ceili(icons.size() / float(cols))
	var tcols := 5
	var thumb_rows := ceili(thumbs.size() / float(tcols))
	var cell := 80
	var width := cols * cell + 20
	var height := 20 + icon_rows * cell + 20 + thumb_rows * 130 + 20
	var sheet := Image.create(width, height, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#F6EBD3"))
	for i in icons.size():
		var x := 10 + (i % cols) * cell
		var y := 10 + (i / cols) * cell
		var bg := Color("#7A4E2D") if (i / cols) % 2 == 0 else Color("#E6D5B0")
		sheet.fill_rect(Rect2i(x + 2, y + 2, 76, 76), bg)
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets/ui/icons/" + String(icons[i])))
		img.convert(Image.FORMAT_RGBA8)
		sheet.blend_rect(img, Rect2i(0, 0, 64, 64), Vector2i(x + 8, y + 8))
	var ty := 30 + icon_rows * cell
	for i in thumbs.size():
		var x := 10 + (i % tcols) * 190
		var y := ty + (i / tcols) * 130
		sheet.fill_rect(Rect2i(x - 2, y - 2, 164, 124), Color("#C9B58C"))
		sheet.fill_rect(Rect2i(x, y, 160, 120), Color("#FFF8E6"))
		var img := Image.load_from_file(ProjectSettings.globalize_path(OUT_DIR + "/" + String(thumbs[i])))
		img.convert(Image.FORMAT_RGBA8)
		sheet.blend_rect(img, Rect2i(0, 0, 160, 120), Vector2i(x, y))
	sheet.save_png(_sheet_out)
	print("render_thumbs: kontaktark -> " + _sheet_out)
