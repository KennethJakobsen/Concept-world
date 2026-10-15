extends TestCase
## T-040: hovedmenu – Fortsæt kun ved autosave, afslut skjult på web, inden for 1024×600.

const DIR: String = "user://test_menu_saves/"


func _clean() -> void:
	var st := SaveStore.new(DIR)
	for s: String in st.list():
		st.delete(s)


func _menu() -> MainMenu:
	var m: MainMenu = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	m.store = SaveStore.new(DIR)
	m.build()
	return m


func test_continue_only_with_autosave() -> void:
	_clean()
	var m := _menu()
	assert_true(not m._continue_btn.visible)
	m.store.save(SaveStore.AUTOSAVE_SLOT, {"x": 1})
	m.store.save("min_park", {"x": 1})
	m.refresh()
	assert_true(m._continue_btn.visible)
	assert_eq(m._slots.slot_count(), 2)
	m.free()
	_clean()


func test_quit_hidden_on_web() -> void:
	var m := _menu()
	assert_eq(m._quit_btn.visible, not OS.has_feature("web"))
	assert_eq(MainMenu.show_quit(), not OS.has_feature("web"))
	m.free()


func test_menu_inside_1024x600() -> void:
	_clean()
	var m := _menu()
	for i in 12:
		m.store.save("park%d" % i, {"x": i})
	m.set_load_list_visible(true)
	m.refresh()
	m.layout(Vector2(1024, 600))
	assert_true(Rect2(0, 0, 1024, 600).encloses(m.panel_rect()), "menu %s" % m.panel_rect())
	m.free()
	_clean()


func test_main_scene_is_menu() -> void:
	assert_eq(str(ProjectSettings.get_setting("application/run/main_scene")), "res://scenes/main_menu.tscn")
