extends TestCase

const MGR := preload("res://scripts/audio/audio_manager.gd")
const CFG := "user://test_audio_settings.cfg"


func _mgr() -> Node:
	var m: Node = MGR.new()
	m.set("settings_path", CFG)
	return m


func test_api_callable_and_unknown_id() -> void:
	DirAccess.remove_absolute(CFG)
	var m := _mgr()
	m.call("load_settings")
	m.call("play_sfx", &"build")
	m.call("play_sfx", &"cash", Vector3(1, 0, 1))
	m.call("play_ui", &"click")
	m.call("set_ambience", &"day")
	m.call("set_ambience", &"")
	m.call("play_music", &"park")
	m.call("stop_music")
	m.call("play_sfx", &"findes_ikke")
	m.call("play_ui", &"findes_ikke")
	assert_true(true)
	m.free()


func test_volume_mute_persist() -> void:
	DirAccess.remove_absolute(CFG)
	var m := _mgr()
	m.call("set_bus_volume", &"Music", 0.25)
	m.call("set_muted", &"SFX", true)
	m.free()
	var m2 := _mgr()
	m2.call("load_settings")
	assert_eq(m2.call("get_bus_volume", &"Music"), 0.25)
	assert_eq(m2.call("is_muted", &"SFX"), true)
	assert_eq(m2.call("is_muted", &"UI"), false)
	m2.free()
	DirAccess.remove_absolute(CFG)


func test_all_ids_synthesize() -> void:
	var ids: Array[StringName] = []
	ids.append_array(AudioSynth.SFX_IDS)
	ids.append_array(AudioSynth.UI_IDS)
	ids.append_array(AudioSynth.AMBIENCE_IDS)
	ids.append_array(AudioSynth.MUSIC_IDS)
	assert_eq(ids.size(), 19)
	for id in ids:
		var s := AudioSynth.generate(id)
		assert_true(s != null and s.data.size() > 0, str(id))
	assert_true(AudioSynth.generate(&"nope") == null)


## T-156: alle katalog-id'er uden "file" skal kunne genereres af AudioSynth.
func test_catalog_ids_without_file_synthesize() -> void:
	var f := FileAccess.open("res://content/audio.json", FileAccess.READ)
	assert_true(f != null)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var sounds: Dictionary = data["sounds"]
	assert_true(sounds.size() > 0)
	for id: String in sounds:
		var entry: Dictionary = sounds[id]
		if entry.has("file"):
			continue
		assert_true(AudioSynth.has(StringName(id)), "has " + id)
		var s := AudioSynth.generate(StringName(id))
		assert_true(s != null and s.data.size() > 0, "generate " + id)
