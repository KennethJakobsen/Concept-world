extends Node3D
## T-083: showcase af M6-props. Kør: godot --rendering-driver opengl3 res://scenes/rendering/m6_showcase.tscn
## Taster: R = run on/off, B = broken on/off, L = lys on/off, venstre/højre = skift bygning, Z = zoom (spil/nær).

const IDS := ["bouncy_castle", "teacups", "trampoline", "sky_rings", "pirate_ship", "space_rocket", "drop_tower",
	"fries_stand", "coffee_stand", "balloon_stand", "souvenir_shop", "coconut_shy", "shooting_gallery",
	"hook_a_duck", "strength_tester"]
const SPACING := 5.0

var _props: Array[Node3D] = []
var _i: int = 0
var _close: bool = false
var _running: bool = true
var _broken: bool = false
var _lights: bool = false
var _cam: Camera3D
var _label: Label


func _ready() -> void:
	for k in IDS.size():
		var n: Node3D = (load("res://scenes/props/%s.tscn" % IDS[k]) as PackedScene).instantiate()
		n.position = Vector3(k * SPACING, 0, 0)
		add_child(n)
		_props.append(n)
	_cam = $Camera3D
	_label = Label.new()
	_label.position = Vector2(10, 10)
	add_child(_label)
	_focus()


func _focus() -> void:
	var off := Vector3(1.5, 2.0, 4.5) if _close else Vector3(0, 8.0, 6.0)
	var tgt := _props[_i].position + Vector3(0, 1.0, 0)
	_cam.look_at_from_position(tgt + off, tgt)
	_label.text = "%s  [<- ->] skift  [Z]oom  [R]un=%s  [B]roken=%s  [L]ys=%s" % [IDS[_i], _running, _broken, _lights]


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
