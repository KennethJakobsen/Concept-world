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
