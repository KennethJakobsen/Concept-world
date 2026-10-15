extends Node3D
## Demo til visuelt check af dag/nat, forlystelser, figurer og effekter.
## Taster: T = spol tid hurtigt/normalt, R = run on/off, B = broken on/off,
## E = emotes, F = effekter. Koeres: godot res://scenes/rendering/day_night_demo.tscn

@onready var _rig: DayNightRig = $DayNightRig
var _fast: bool = false
var _running: bool = true
var _broken: bool = false
var _emote_i: int = 0
var _label: Label


func _ready() -> void:
	_rig.night_factor_changed.connect(_on_night)
	_label = Label.new()
	_label.position = Vector2(10, 10)
	add_child(_label)
	for c in $Guests.get_children():
		c.set_walking(true)


func _on_night(f: float) -> void:
	for n in get_tree().get_nodes_in_group(&"demo_lit"):
		if n.has_method("set_intensity"):
			n.set_intensity(smoothstep(0.3, 0.8, f))
		elif n.has_method("set_lights"):
			n.set_lights(smoothstep(0.3, 0.8, f))


func _process(_d: float) -> void:
	var t := _rig.time_of_day * 24.0
	_label.text = "%02d:%02d  night=%.2f  [T]ime [R]un [B]reak [E]mote [F]x" % [int(t), int(fmod(t, 1.0) * 60.0), _rig.night_factor()]


func _unhandled_key_input(e: InputEvent) -> void:
	var k := e as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_T:
			_fast = not _fast
			_rig.debug_day_seconds = 12.0 if _fast else 120.0
		KEY_R:
			_running = not _running
			for n in $Rides.get_children():
				n.set_running(_running)
		KEY_B:
			_broken = not _broken
			for n in $Rides.get_children():
				n.set_broken(_broken)
		KEY_E:
			var kinds: Array[StringName] = [&"happy", &"angry", &"sick", &"sweep", &"repair"]
			for c in $Guests.get_children():
				c.play_emote(kinds[_emote_i % kinds.size()])
			_emote_i += 1
		KEY_F:
			var i := 0
			for id in ["coins", "confetti", "build_dust", "sweep_dust", "repair_sparks"]:
				var fx: Node3D = (load("res://scenes/effects/%s.tscn" % id) as PackedScene).instantiate()
				add_child(fx)
				fx.position = Vector3(-4 + i * 2, 0.5, 4)
				fx.play()
				i += 1
