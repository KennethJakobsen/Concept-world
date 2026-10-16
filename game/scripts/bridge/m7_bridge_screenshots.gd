extends SceneTree
## T-111: skærmbilleder + fps-måling af M7-bridgen (gæstemasse, svævetal, bænk, spand, skrald, overlays).
## Kør (ikke headless): cd game && godot --rendering-method gl_compatibility --resolution 1280x720 \
##   --script res://scripts/bridge/m7_bridge_screenshots.gd -- ../docs/screenshots/t111

var _prefix: String = "user://t111"
var _f: int = 0
var _pv: ParkView
var _cam: ParkCamera
var _fps_frames: int = 0
var _fps_t: float = 0.0
var _shots: Array = []  ## [frame, name, callable]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.size = Vector2i(1280, 720)


func _build_park() -> void:
	var s: ParkSim = _pv.sim
	s.economy.earn(500000, "test")
	var e: Vector2i = s.world.entrance
	# Hovedgade fra porten ind i parken + tværgader.
	var dir: Vector2i = Vector2i(0, -1) if e.y > s.world.height / 2 else Vector2i(0, 1)
	var cells: Array[Vector2i] = []
	for i in range(1, 30):
		cells.append(e + dir * i)
	for row in [8, 16, 24]:
		var c0: Vector2i = e + dir * row
		for dx in range(-14, 15):
			cells.append(c0 + Vector2i(dx, 0))
	for c: Vector2i in cells:
		s.cmd_place_path(c)
	var side: Array = [["carousel", -6, 8], ["ferris_wheel", 3, 8], ["burger_stand", -3, 16],
		["drinks_stand", 2, 16], ["bumper_cars", -10, 16], ["ice_cream_stand", 6, 24], ["atm", -2, 24],
		["toilet", 9, 16]]
	for it: Array in side:
		var row_c: Vector2i = e + dir * int(it[2]) + Vector2i(int(it[1]), 0)
		for off in [1, -2, -3, -4, 2]:
			if s.cmd_place_attraction(str(it[0]), row_c + Vector2i(0, off)) != null:
				break
	for i in range(-12, 13, 3):
		s.cmd_place_decor("bench", e + dir * 8 + Vector2i(i, 0))
		s.cmd_place_decor("bin", e + dir * 16 + Vector2i(i + 1, 0))
		s.cmd_place_decor("lamp", e + dir * 24 + Vector2i(i, 0))
	s.max_guests = 500
	s.spawn_interval_ticks = 1


func _process(delta: float) -> bool:
	_f += 1
	if _f == 5:
		root.get_node("GameSession").call("start_sandbox", 11)
	elif _f == 30:
		_pv = current_scene.find_children("*", "ParkView", true, false)[0] as ParkView
		_cam = current_scene.find_children("*", "ParkCamera", true, false)[0] as ParkCamera
		_build_park()
		for i in 3000:
			_pv.sim.update(SimClock.TICK_DELTA)
		print("gæster: ", _pv.sim.guests.size())
		var e: Vector3 = ParkView.cell_center(_pv.sim.world.entrance)
		var dir: float = -1.0 if _pv.sim.world.entrance.y > _pv.sim.world.height / 2 else 1.0
		_cam.position = Vector3(e.x, 0.0, e.z + dir * 14.0)
		_cam.rotation.y = 0.0 if dir < 0 else PI
		_cam._distance = 55.0
		_cam._apply_distance()
	elif _f > 40 and _f <= 220:
		_fps_frames += 1
		_fps_t += delta
	if _f == 120:
		_shot("crowd")
	elif _f == 221:
		print("FPS med %d gæster: %.1f (individuelle noder: %d, instanser: %d)" % [_pv.sim.guests.size(),
			_fps_frames / maxf(_fps_t, 0.001), _pv.individual_guest_count(), _pv.crowd.instanced_count()])
		var e: Vector3 = ParkView.cell_center(_pv.sim.world.entrance)
		var dir: float = -1.0 if _pv.sim.world.entrance.y > _pv.sim.world.height / 2 else 1.0
		_cam.position = Vector3(e.x, 0.0, e.z + dir * 16.0)
		_cam._distance = 14.0
		_cam._apply_distance()
		for id: int in _pv._attractions:
			var a: Attraction = _pv.sim.get_attraction(id)
			if a.def.kind == "shop":
				_pv.floating.show_amount(_pv._attraction_pos(a, 2.0), 12)
		for c in range(-6, 7):
			_pv.sim.world.set_litter(_pv.sim.world.entrance + Vector2i(c, int(dir * 15)), 1 + absi(c) % 5)
	elif _f == 232:
		_shot("close")
	elif _f == 240:
		_cam._distance = 45.0
		_cam._apply_distance()
		_pv.show_overlay(&"happiness")
	elif _f == 250:
		_shot("overlay_happiness")
		_pv.show_overlay(&"queue")
	elif _f == 260:
		_shot("overlay_queue")
		_pv.show_overlay(&"coverage")
	elif _f == 270:
		_shot("overlay_coverage")
		_pv.hide_overlay()
		return true
	return false


func _shot(name: String) -> void:
	var img: Image = root.get_texture().get_image()
	var p: String = "%s_%s.png" % [_prefix, name]
	img.save_png(p)
	print("gemt ", p)
