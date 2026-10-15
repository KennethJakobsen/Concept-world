extends TestCase
## T-042: HUD-tekster må kun bruge glyffer som standardfonten har; stjerner tegnes.


func _texts(n: Node, out: Array[String]) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_texts(c, out)


func test_hud_texts_covered_by_default_font() -> void:
	var font: Font = ThemeDB.fallback_font
	var hud := Hud.new()
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	var a: Attraction = hud.sim.cmd_place_attraction("burger_stand", Vector2i(5, 5))
	hud.refresh()
	var texts: Array[String] = [Hud.top_text({"money": 1, "day": 1, "guests": 1, "avg_happiness": 1.0,
		"reputation": 50.0, "max_guests": 9})]
	_texts(hud, texts)
	hud.show_attraction(a.id)
	_texts(hud, texts)
	hud.toggle_park_panel()
	_texts(hud, texts)
	for t: String in texts:
		for i in t.length():
			var ch: int = t.unicode_at(i)
			if ch >= 32:
				assert_true(font.has_char(ch), "glyf U+%04X mangler i '%s'" % [ch, t])
	hud.free()


func test_star_rating_fill() -> void:
	var s := StarRating.new()
	s.value = 50.0
	assert_eq(s.filled(), 2.5)
	s.value = 100.0
	assert_eq(s.filled(), 5.0)
	s.value = 0.0
	assert_eq(s.filled(), 0.0)
	assert_true(StarRating.star_points(Vector2.ZERO, 8.0).size() == 10)
	var half: PackedVector2Array = StarRating.clip_left(StarRating.star_points(Vector2.ZERO, 8.0), 0.0)
	assert_true(half.size() >= 3)
	for p in half:
		assert_true(p.x <= 0.001)
	assert_true(s.get_combined_minimum_size().x > 0.0)
	s.free()
