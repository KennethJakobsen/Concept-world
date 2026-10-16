extends SceneTree
## T-135: skærmbilleder af omgivelserne i parken for de tre temaer.
## Kør (ikke headless): cd game && godot --rendering-method gl_compatibility --resolution 1280x720 \
##   --script res://scripts/bridge/surroundings_screenshots.gd -- ../docs/screenshots/t135

const SCENARIOS: Array[String] = ["green_meadow", "river_valley", "mountain_peak"]
var _prefix: String = "user://t135"
var _f: int = 0
var _i: int = 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.size = Vector2i(1280, 720)


func _process(_d: float) -> bool:
	_f += 1
	if _f == 5:
		root.get_node("GameSession").call("start_scenario", SCENARIOS[_i], 7)
	elif _f == 40:
		var cam: ParkCamera = current_scene.find_children("*", "ParkCamera", true, false)[0] as ParkCamera
		var pv: ParkView = current_scene.find_children("*", "ParkView", true, false)[0] as ParkView
		var e: Vector3 = ParkView.cell_center(pv.sim.world.entrance)
		cam.position = Vector3(e.x, 0.0, e.z + 6.0)
		cam.rotation.y = 0.5
		cam._distance = 70.0
		cam._apply_distance()
	elif _f == 70:
		var img: Image = root.get_texture().get_image()
		var p: String = "%s_%s.png" % [_prefix, SCENARIOS[_i]]
		img.save_png(p)
		print("gemt ", p)
		_i += 1
		_f = 0
		if _i >= SCENARIOS.size():
			return true
	return false
