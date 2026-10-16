extends TestCase
## T-089: intensity/kvalme-bjælker, gæsteinfo med ting, sideshow-panel, Præmier og tanker.


func _texts(n: Node, out: Array[String]) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_texts(c, out)


func _check_glyphs(texts: Array[String]) -> void:
	var font: Font = ThemeDB.fallback_font
	for t: String in texts:
		for i in t.length():
			var ch: int = t.unicode_at(i)
			if ch >= 32:
				assert_true(font.has_char(ch), "glyf U+%04X mangler i '%s'" % [ch, t])


func test_panels() -> void:
	var hud := Hud.new()
	hud.sim = ParkSim.new(30, 30, 1)
	hud._build_ui()
	var texts: Array[String] = []
	var r: Attraction = hud.sim.cmd_place_attraction("pirate_ship", Vector2i(5, 5))
	hud.show_attraction(r.id)
	hud.refresh()
	assert_true(hud._attr_bar_box.visible)
	assert_true((hud._attr_bars["intensity"] as ProgressBar).value > 0.0)
	assert_true((hud._attr_bars["nausea"] as ProgressBar).value > 0.0)
	_texts(hud, texts)
	var s: Attraction = hud.sim.cmd_place_attraction("hook_a_duck", Vector2i(15, 15))
	hud.show_attraction(s.id)
	hud.refresh()
	assert_true(not hud._attr_bar_box.visible)
	assert_true(hud._attr_label.text.contains("Gevinstchance: 50%"))
	assert_true(hud._attr_label.text.contains("Præmieudgift"))
	_texts(hud, texts)
	hud.toggle_park_panel()
	hud.refresh()
	assert_true(hud._park_label.text.contains("Præmier"))
	_texts(hud, texts)
	for k: String in M6Texts.THOUGHTS:
		texts.append(M6Texts.thought_text(k))
	for k: String in M6Texts.ITEM_NAMES:
		texts.append(M6Texts.item_name(k))
	for k: String in Economy.CATEGORIES:
		texts.append(M6Texts.category_name(k))
	texts.append(Toast.warning_text(&"guest_vomit"))
	_check_glyphs(texts)
	hud.free()


func test_guest_items() -> void:
	var hud := Hud.new()
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	var g := Guest.new(500, hud.sim.world.entrance)
	hud.sim.guests[g.id] = g
	g.items.append(&"balloon")
	g.nausea = 40.0
	hud.show_guest(g.id)
	hud.refresh()
	assert_eq(hud._guest_items.get_child_count(), 1)
	assert_eq((hud._guest_items.get_child(0) as ItemIcon).item_id, "balloon")
	assert_true(hud._guest_label.text.contains("Kvalme: 40"))
	hud.free()
