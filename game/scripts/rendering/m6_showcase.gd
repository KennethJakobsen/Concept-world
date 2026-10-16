extends Node3D
## T-083/T-099: showcase af M6-props. Én bygning vises ad gangen, centreret og indrammet efter sin størrelse.
## Kør: godot --rendering-driver opengl3 res://scenes/rendering/m6_showcase.tscn
## Taster: venstre/højre = skift bygning, Z = zoom (spil/nær), R = run, B = broken, L = lys.
## Screenshots af alle: godot --rendering-driver opengl3 res://scenes/rendering/m6_showcase.tscn -- --shots /sti/til/mappe

const IDS := ["bouncy_castle", "teacups", "trampoline", "sky_rings", "pirate_ship", "space_rocket", "drop_tower",
	"fries_stand", "coffee_stand", "balloon_stand", "souvenir_shop", "coconut_shy", "shooting_gallery",
	"hook_a_duck", "strength_tester"]

var _props: Array[Node3D] = []
var _i: int = 0
var _close: bool = false
var _running: bool = true
var _broken: bool = false
var _lights: bool = false
var _cam: Camera3D
var _label: Label
var _shots_dir: String = ""


func _ready() -> void:
	for id: String in IDS:
		var n: Node3D = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		n.visible = false
		add_child(n)
		_props.append(n)
	_cam = $Camera3D
	_label = Label.new()
	_label.position = Vector2(10, 10)
	add_child(_label)
	var args := OS.get_cmdline_user_args()
	var k := args.find("--shots")
	if k >= 0 and k + 1 < args.size():
		_shots_dir = args[k + 1]
		_label.visible = false
	_focus()
	if _shots_dir != "":
		_take_shots.call_deferred()


func _bounds(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var bb: AABB = (n.global_transform.affine_inverse() * mi.global_transform) * mi.mesh.get_aabb()
		out = bb if first else out.merge(bb)
		first = false
	return out


func _focus() -> void:
	for k in _props.size():
		_props[k].visible = k == _i
	var bb := _bounds(_props[_i])
	var c := bb.get_center()
	var r := maxf(bb.size.length() * 0.5, 0.6)
	var dist := r / tan(deg_to_rad(_cam.fov * 0.5)) * 1.1
	var dir := Vector3(0.45, 0.45, 1.0).normalized() if _close else Vector3(0.0, 1.0, 0.85).normalized()
	_cam.look_at_from_position(c + dir * dist * (0.8 if _close else 1.0), c)
	_label.text = "%d/%d %s  [<- ->] skift  [Z]oom  [R]un=%s  [B]roken=%s  [L]ys=%s" % [
		_i + 1, IDS.size(), IDS[_i], _running, _broken, _lights]


func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(_shots_dir)
	for k in IDS.size():
		for close: bool in [false, true]:
			_i = k
			_close = close
			_focus()
			for f in 4:
				await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.save_png("%s/%s_%s.png" % [_shots_dir, IDS[k], "close" if close else "game"])
	get_tree().quit()


func _unhandled_key_input(e: InputEvent) -> void:
	var k := e as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_RIGHT: _i = (_i + 1) % IDS.size()
		KEY_LEFT: _i = (_i + IDS.size() - 1) % IDS.size()
		KEY_Z: _close = not _close
		KEY_R:
			_running = not _running
			for p in _props: p.set_running(_running)
		KEY_B:
			_broken = not _broken
			for p in _props: p.set_broken(_broken)
		KEY_L:
			_lights = not _lights
			for p in _props: p.set_lights(1.0 if _lights else 0.0)
	_focus()
