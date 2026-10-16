extends SceneTree
## T-112: skærmbilleder af inspektørens faner (Indstillinger, Økonomi, Kø).
## Kør (ikke headless): cd game && godot --rendering-method gl_compatibility --resolution 1280x720 \
##   --script res://scripts/ui/ui_screenshots_t112.gd -- ../docs/screenshots/t112

var _prefix: String = "user://t112"
var _f: int = 0
var _ids: Array[int] = []
var _shots: Array = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.size = Vector2i(1280, 720)
	change_scene_to_file("res://scenes/main.tscn")


func _hud() -> Hud:
	return current_scene.find_children("*", "Hud", true, false)[0] as Hud


func _process(_d: float) -> bool:
	_f += 1
	if _f == 30:
		var hud: Hud = _hud()
		var sim: ParkSim = hud.sim
		sim.economy.money = 50000
		var e: Vector2i = sim.world.entrance
		for i in 9:
			sim.cmd_place_path(e + Vector2i(0, -1 - i))
		var ride: Attraction = sim.cmd_place_attraction("bouncy_castle", e + Vector2i(-4, -6))
		var shop: Attraction = sim.cmd_place_attraction("burger_stand", e + Vector2i(2, -4))
		if ride != null:
			ride.revenue_days = PackedInt32Array([30, 55, 42, 70, 64, 90, 81])
			ride.payback_day = 6
			sim.cmd_set_config(ride.id, "capacity", 13)
			_shots = [[ride.id, &"settings", "settings_ride"], [ride.id, &"economy", "economy"], [ride.id, &"queue", "queue"]]
		if shop != null:
			shop.price = 1
			sim.cmd_set_recipe(shop.id, "salt", true)
			_shots.append([shop.id, &"settings", "settings_shop"])
	elif _f > 30 and (_f - 30) % 20 == 0:
		var k: int = (_f - 30) / 20 - 1
		if k > 0:
			var img: Image = root.get_texture().get_image()
			img.save_png("%s_%s.png" % [_prefix, _shots[k - 1][2]])
		if k >= _shots.size():
			quit()
			return false
		var hud2: Hud = _hud()
		hud2.show_attraction(_shots[k][0])
		hud2.inspector.select_tab(_shots[k][1])
		hud2.refresh()
		hud2.layout(Vector2(1280, 720))
	return false
