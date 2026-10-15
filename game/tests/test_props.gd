extends TestCase

const PROPS := ["carousel", "ferris_wheel", "bumper_cars", "burger_stand",
	"drinks_stand", "ice_cream_stand", "toilet", "thought_bubble",
	"mechanic", "cleaner", "entertainer", "bin", "bench", "tree_round", "tree_pine",
	"tree_blossom", "flowers", "lamp", "litter", "swing_ride", "haunted_house", "go_karts"]


func test_all_props_instantiate() -> void:
	for id in PROPS:
		var scene: PackedScene = load("res://scenes/props/%s.tscn" % id)
		assert_true(scene != null, id)
		var n := scene.instantiate()
		assert_true(n is Node3D, id)
		n.free()


func test_thought_bubble_api() -> void:
	var b: Node3D = (load("res://scenes/props/thought_bubble.tscn") as PackedScene).instantiate()
	assert_true(b.has_method("show_text"))
	assert_true(b.has_method("hide_bubble"))
	b.free()


func test_breakdown_smoke_instantiates() -> void:
	var n: Node = (load("res://scenes/effects/breakdown_smoke.tscn") as PackedScene).instantiate()
	assert_true(n.get_node("Smoke") is CPUParticles3D)
	n.free()


func test_staff_api() -> void:
	for id in ["mechanic", "cleaner", "entertainer"]:
		var n: Node = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		assert_true(n.has_method("set_color") and n.has_method("set_walking") and n.has_method("hop"), id)
		n.free()


func test_litter_levels() -> void:
	var n: Node3D = (load("res://scenes/props/litter.tscn") as PackedScene).instantiate()
	n.set_level(0)
	assert_true(not n.visible)
	n.set_level(2)
	assert_true(n.visible and n.get_node("L2").visible and not n.get_node("L3").visible)
	n.free()


func test_lamp_off_by_default() -> void:
	var n: Node3D = (load("res://scenes/props/lamp.tscn") as PackedScene).instantiate()
	assert_true(not n.get_node("Light").visible)
	n.set_on(true)
	assert_true(n.get_node("Light").visible)
	n.free()


const RIDES := ["carousel", "ferris_wheel", "bumper_cars", "swing_ride", "haunted_house", "go_karts"]
const FX := ["breakdown_smoke", "repair_sparks", "coins", "confetti", "build_dust", "sweep_dust"]


func test_day_night_rig_api() -> void:
	var rig: Node3D = (load("res://scenes/rendering/day_night_rig.tscn") as PackedScene).instantiate()
	assert_true(rig is DayNightRig)
	assert_true(rig.get_node("Sun") is DirectionalLight3D)
	assert_true(rig.get_node("WorldEnvironment") is WorldEnvironment)
	var got: Array[float] = []
	rig.night_factor_changed.connect(func(f: float) -> void: got.append(f))
	rig.set_time_of_day(0.5)
	assert_true(rig.night_factor() < 0.05, "middag er dag")
	rig.set_time_of_day(0.0)
	assert_true(rig.night_factor() > 0.95, "midnat er nat")
	rig.set_time_of_day(0.0)
	assert_true(got.size() == 2, "kun signal ved aendring")
	var noon_e: float = 0.0
	rig.set_time_of_day(0.5)
	noon_e = (rig.get_node("Sun") as DirectionalLight3D).light_energy
	rig.set_time_of_day(0.0)
	assert_true((rig.get_node("Sun") as DirectionalLight3D).light_energy < noon_e)
	rig.free()


func test_lamp_intensity() -> void:
	var n: Node3D = (load("res://scenes/props/lamp.tscn") as PackedScene).instantiate()
	n.set_intensity(0.5)
	assert_true(n.get_node("Light").visible)
	assert_true(not (n.get_node("Light") as OmniLight3D).shadow_enabled)
	n.set_intensity(0.0)
	assert_true(not n.get_node("Light").visible)
	n.free()


func test_ride_visual_api() -> void:
	for id in RIDES:
		var n: Node3D = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		for m in ["set_running", "set_broken", "set_lights"]:
			assert_true(n.has_method(m), "%s.%s" % [id, m])
		n.set_running(false)
		n.set_broken(true)
		n.set_lights(1.0)
		n.set_broken(false)
		n.set_running(true)
		n.free()


func test_ferris_cabs_hang_upright() -> void:
	var n: RideVisual = (load("res://scenes/props/ferris_wheel.tscn") as PackedScene).instantiate()
	n._ready()
	var wheel: Node3D = n.get_node("Wheel")
	wheel.rotate_object_local(Vector3.BACK, 1.1)
	n._process(0.016)
	var cab: Node3D = wheel.get_node("Cab3")
	var b := wheel.transform.basis * cab.transform.basis
	assert_true(b.y.is_equal_approx(Vector3.UP), "kabine lodret")
	n.free()


func test_person_anim_api() -> void:
	for id in ["guest", "mechanic", "cleaner", "entertainer"]:
		var n: Node3D = (load("res://scenes/props/%s.tscn" % id) as PackedScene).instantiate()
		n._ready()
		assert_true(n.has_method("set_walking") and n.has_method("play_emote"), id)
		n.set_walking(true)
		for k in [&"happy", &"angry", &"sick", &"sweep", &"repair"]:
			n.play_emote(k)
			n._process(0.1)
		n.set_walking(false)
		n.free()


func test_effect_scenes() -> void:
	for id in FX:
		var n: Node = (load("res://scenes/effects/%s.tscn" % id) as PackedScene).instantiate()
		assert_true(n.has_method("play"), id)
		var has_p := false
		for c in n.get_children():
			if c is CPUParticles3D:
				has_p = true
		assert_true(has_p, id)
		n.free()
