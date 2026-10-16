extends TestCase
## T-108: omgivelser bygges for alle temaer og ukendt tema falder tilbage til countryside.


func test_config_fallback() -> void:
	var cfg := SurroundingsRenderer.load_config("lava")
	assert_eq(str(cfg["theme"]), "countryside")
	assert_eq(int(cfg["margin_cells"]), 24)
	assert_eq(str(SurroundingsRenderer.load_config("river")["theme"]), "river")


func test_builds_all_themes() -> void:
	for theme: String in ["countryside", "river", "mountain"]:
		var r := SurroundingsRenderer.new()
		r.build(32, 24, Vector2i(16, 23), SurroundingsRenderer.load_config(theme))
		assert_true(r.get_child_count() > 10, theme + ": har props")
		assert_true(r.get_node_or_null("Gate") != null, theme + ": port")
		r._process(0.5)
		r.free()


func test_entrance_on_other_edges() -> void:
	for e: Vector2i in [Vector2i(0, 10), Vector2i(31, 5), Vector2i(8, 0)]:
		var r := SurroundingsRenderer.new()
		r.build(32, 24, e)
		assert_true(r.get_node_or_null("BusStop") != null)
		r.free()
