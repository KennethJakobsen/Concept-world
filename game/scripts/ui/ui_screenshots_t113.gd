extends SceneTree
## T-113: skærmbilleder af milepæle, overlay-vælger, indstillinger og låst forskning.
## Kør (ikke headless): cd game && godot --rendering-method gl_compatibility --resolution 1280x720 \
##   --script res://scripts/ui/ui_screenshots_t113.gd -- ../docs/screenshots/t113

var _prefix: String = "user://t113"
var _f: int = 0
var _steps: Array = ["milestones", "overlay", "settings", "research", "toast"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.size = Vector2i(1280, 720)



func _hud() -> Hud:
	return current_scene.find_children("*", "Hud", true, false)[0] as Hud


func _process(_d: float) -> bool:
	_f += 1
	if _f == 2:  # autoloads findes først nu; scenarie => milepæle og låste grene er aktive
		var gs: Node = root.get_node_or_null("GameSession")
		if gs != null:
			gs.call("start_scenario", "green_meadow", 1)
		else:
			change_scene_to_file("res://scenes/main.tscn")
	elif _f == 30:
		var sim: ParkSim = _hud().sim
		sim.economy.money = 50000
		var e: Vector2i = sim.world.entrance
		for i in 9:
			sim.cmd_place_path(e + Vector2i(0, -1 - i))
		sim.cmd_place_attraction("bouncy_castle", e + Vector2i(-4, -6))
		sim.cmd_place_attraction("burger_stand", e + Vector2i(2, -4))
	elif _f > 30 and (_f - 30) % 60 == 0:
		var k: int = (_f - 30) / 60 - 1
		var hud: Hud = _hud()
		if k > 0:
			root.get_texture().get_image().save_png("%s_%s.png" % [_prefix, _steps[k - 1]])
		if k >= _steps.size():
			quit()
			return false
		hud.park_rail.close_panel()
		match String(_steps[k]):
			"milestones":
				hud.park_rail.toggle(&"milestones")
			"overlay":
				hud.park_rail.toggle(&"overlays")
				hud.overlay_picker().select(&"happiness")
			"settings":
				hud.park_rail.toggle(&"settings")
			"research":
				hud.toggle_research_panel()
			"toast":
				hud.on_milestone_achieved("guests_100")
				hud.top_bar.flash_money(1)
		hud.refresh()
		hud.layout(Vector2(1280, 720))
	return false
