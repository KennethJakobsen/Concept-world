extends SceneTree
## T-116: skærmbilleder af tutorial-panelet. Kør (ikke headless):
## cd game && godot --rendering-method gl_compatibility --resolution 1280x720 \
##   --script res://scripts/ui/ui_screenshots_t116.gd -- ../docs/screenshots/t116

var _prefix: String = "user://t116"
var _f: int = 0
var _steps: Array = ["path", "ride", "queue", "cleaner"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.size = Vector2i(1280, 720)


func _hud() -> Hud:
	return current_scene.find_children("*", "Hud", true, false)[0] as Hud


func _process(_d: float) -> bool:
	_f += 1
	if _f == 2:
		var gs: Node = root.get_node_or_null("GameSession")
		gs.call("start_scenario", "tutorial", 1)
	elif _f > 30 and (_f - 30) % 60 == 0:
		var k: int = (_f - 30) / 60 - 1
		var hud: Hud = _hud()
		if k > 0:
			root.get_texture().get_image().save_png("%s_%s.png" % [_prefix, _steps[k - 1]])
		if k >= _steps.size():
			quit()
			return false
		var f := FileAccess.open("res://content/scenarios/tutorial.json", FileAccess.READ)
		var steps: Array = (JSON.parse_string(f.get_as_text()) as Dictionary)["steps"]
		var idx: int = {"path": 0, "ride": 1, "queue": 4, "cleaner": 5}[_steps[k]]
		hud.park_rail.close_panel()
		hud.on_tutorial_step(idx, steps[idx])
		if _steps[k] == "ride":
			hud.build_dock._on_category("rides")
		hud.refresh()
		hud.layout(Vector2(1280, 720))
	return false
