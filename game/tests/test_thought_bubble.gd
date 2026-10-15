extends TestCase
## T-056: tankeboblens baggrund skal dække teksten.


func test_bubble_covers_text() -> void:
	for t: String in ["Her er beskidt!", "Det var godt!", "Sulten", "Jeg er tørstig og træt!", "!"]:
		var ts: Vector2 = ThoughtBubble.text_size(t)
		var bs: Vector2 = ThoughtBubble.bubble_size(t)
		assert_true(ts.x > 0.0 and ts.y > 0.0, "tekststørrelse > 0: " + t)
		assert_true(bs.x >= ts.x + 0.1, "bred nok: " + t)
		assert_true(bs.y >= ts.y + 0.05, "høj nok: " + t)


func test_scene_scales_background() -> void:
	var scene: PackedScene = load("res://scenes/props/thought_bubble.tscn")
	var b: ThoughtBubble = scene.instantiate()
	var t := "Her er beskidt!"
	var bg: MeshInstance3D = b.get_node("Background")
	var bs: Vector2 = ThoughtBubble.bubble_size(t)
	var qs: Vector2 = (bg.mesh as QuadMesh).size
	bg.scale = Vector3(bs.x / qs.x, bs.y / qs.y, 1.0)  # samme formel som show_text
	var q: QuadMesh = bg.mesh as QuadMesh
	var ts: Vector2 = ThoughtBubble.text_size(t)
	assert_true(q.size.x * bg.scale.x >= ts.x, "quad bredde dækker tekst")
	assert_true(q.size.y * bg.scale.y >= ts.y, "quad højde dækker tekst")
	b.queue_free()
