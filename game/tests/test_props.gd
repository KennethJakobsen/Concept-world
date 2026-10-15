extends TestCase

const PROPS := ["carousel", "ferris_wheel", "bumper_cars", "burger_stand",
	"drinks_stand", "ice_cream_stand", "toilet", "thought_bubble"]


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
