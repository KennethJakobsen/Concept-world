extends SceneTree
## T-138: skærmbilleder af UI-temaet (hovedmenu, park med byggemenu, inspector).
## Kør (ikke headless): cd game && godot --rendering-method gl_compatibility --resolution 1280x720 \
##   --script res://scripts/ui/ui_screenshots.gd -- ../docs/screenshots/t138

var _prefix: String = "user://t138"
var _f: int = 0
var _step: int = 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.size = Vector2i(1280, 720)
	change_scene_to_file("res://scenes/main_menu.tscn")


func _shot(n: String) -> void:
	var img: Image = root.get_texture().get_image()
	img.save_png(_prefix + "_" + n + ".png")
	print("gemt ", _prefix + "_" + n + ".png ", img.get_size())


func _hud() -> Hud:
	return current_scene.find_children("*", "Hud", true, false)[0] as Hud if current_scene != null else null


func _process(_d: float) -> bool:
	_f += 1
	match _step:
		0:
			if _f == 40:
				_shot("menu")
				var gs: Node = root.get_node_or_null("GameSession")
				if gs != null and gs.has_method("start_sandbox"):
					gs.call("start_sandbox", 7)
				else:
					change_scene_to_file("res://scenes/main.tscn")
				_step = 1
				_f = 0
		1:
			if _f == 30:
				var hud: Hud = _hud()
				var sim: ParkSim = hud.sim
				sim.economy.money = 50000
				var e: Vector2i = sim.world.entrance
				var placed: Attraction = null
				var spots: Array = [["carousel", Vector2i(-5, -6)], ["burger_stand", Vector2i(2, -4)],
					["ferris_wheel", Vector2i(3, -9)], ["drinks_stand", Vector2i(-3, -3)]]
				for i in 9:
					sim.cmd_place_path(e + Vector2i(0, -1 - i))
				for s: Array in spots:
					var a: Attraction = sim.cmd_place_attraction(s[0], e + (s[1] as Vector2i))
					if a != null and placed == null:
						placed = a
				hud.set_tab("rides")
				hud.build_dock.set_selected("carousel")
				hud.alert_tray.push("Velkommen til parken!", "info")
				hud.layout(Vector2(1280, 720))
				set_meta(&"attr", placed.id if placed != null else -1)
			if _f == 60:
				_shot("build")
				var hud2: Hud = _hud()
				hud2.build_dock.close_cards()
				var id: int = get_meta(&"attr", -1)
				if id >= 0:
					hud2.show_attraction(id)
				hud2.layout(Vector2(1280, 720))
			if _f == 90:
				_shot("inspector")
				# T-146: personale-panelet med en lang liste.
				var hud3: Hud = _hud()
				hud3.clear_selection()
				for i in 14:
					hud3.sim.cmd_hire_staff(["cleaner", "mechanic", "entertainer"][i % 3], hud3.sim.world.entrance + Vector2i(0, -1))
				hud3.park_rail.toggle(&"staff")
				hud3.layout(Vector2(1280, 720))
			if _f == 120:
				_shot("staff")
				quit()
	return false
