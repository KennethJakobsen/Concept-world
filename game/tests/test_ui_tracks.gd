extends TestCase
## T-094: spor-faner, fejltekster og info.


func test_palette_filters_per_system() -> void:
	var p := CoasterPalette.new()
	p.build()
	var ok: bool = true
	for sys: StringName in [&"flume", &"train", &"monorail"]:
		p.set_system(sys)
		var ids: Array[String] = p.piece_ids()
		ok = ok and not ids.is_empty()
		for id: String in ids:
			ok = ok and CoasterContent.pieces(sys).has(id)
	p.set_system(&"monorail")
	ok = ok and p.button(CoasterContent.station_id(&"monorail", "end")) != null
	p.set_system(&"flume")
	ok = ok and CoasterPalette.end_station_id(&"flume") == ""
	p.free()
	assert_true(ok, "palet filtreret pr. system")


func test_error_texts_danish() -> void:
	for c: String in ["wrong_system", "too_low", "incomplete", "exit_blocked", "stations_too_close", "multiple_stations", "closed"]:
		assert_true(not M6Texts.track_error(c).begins_with("Fejl:"), c)
	assert_true(M6Texts.track_error("no_station") == M5Texts.coaster_error("no_station"), "fallback")


func test_system_for_build() -> void:
	assert_true(Hud.system_for_build("coaster:log_flume") == &"flume" and Hud.system_for_build("coaster:monorail") == &"monorail" and Hud.system_for_build("coaster:wooden_coaster") == &"coaster", "system_for_build")


func test_track_glyphs() -> void:
	var f: Font = ThemeDB.fallback_font
	var texts: Array[String] = ["Baner og spor", "Endestation", "Plask: 3", "Passagerer i dag: 4", "Banen er ikke færdig", "Banen er åben!"]
	texts.append_array(M6Texts.TRACK_ERRORS.values())
	for t: String in texts:
		for i: int in t.length():
			assert_true(f.has_char(t.unicode_at(i)), t)
