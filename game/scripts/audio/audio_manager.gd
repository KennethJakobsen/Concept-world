extends Node
## Autoload `AudioManager` (kontrakt M4 §4). Busser: Master → Music, SFX, Ambience, UI.
## Lyde genereres procedurelt (AudioSynth) eller hentes fra `res://content/audio.json`
## (id → {file?, volume_db?, bus?}). Headless: alle kald er no-ops.
## Web: intet afspilles før første brugerinput – ambience/musik sættes i kø.

const SETTINGS_SECTION: String = "audio"
const MAX_3D: int = 16
const CATALOG_PATH: String = "res://content/audio.json"
const BUSES: Array[StringName] = [&"Master", &"Music", &"SFX", &"Ambience", &"UI"]

var settings_path: String = "user://settings.cfg"

var _headless: bool = false
var _unlocked: bool = true
var _streams: Dictionary = {}  # StringName -> AudioStream
var _catalog: Dictionary = {}  # StringName -> Dictionary
var _warned: Dictionary = {}
var _volumes: Dictionary = {}  # StringName -> float (lineær)
var _muted: Dictionary = {}  # StringName -> bool

var _pool3d: Array[AudioStreamPlayer3D] = []
var _next3d: int = 0
var _sfx2d: Array[AudioStreamPlayer] = []
var _ui: AudioStreamPlayer
var _music: AudioStreamPlayer
var _amb: Array[AudioStreamPlayer] = []  # to afspillere til crossfade
var _amb_active: int = 0
var _amb_tween: Tween

var _pending_ambience: StringName = &""
var _pending_music: StringName = &""
var _ambience_id: StringName = &""
var _music_id: StringName = &""


func _init() -> void:
	_headless = DisplayServer.get_name() == "headless"
	_unlocked = not OS.has_feature("web")
	for b in BUSES:
		_volumes[b] = 1.0
		_muted[b] = false


func _ready() -> void:
	load_settings()
	if _headless:
		return
	_load_catalog()
	for i in MAX_3D:
		var p := AudioStreamPlayer3D.new()
		p.bus = &"SFX"
		p.unit_size = 8.0
		p.max_distance = 80.0
		add_child(p)
		_pool3d.append(p)
	for i in 4:
		var p2 := AudioStreamPlayer.new()
		p2.bus = &"SFX"
		add_child(p2)
		_sfx2d.append(p2)
	_ui = _player(&"UI")
	_music = _player(&"Music")
	_amb = [_player(&"Ambience"), _player(&"Ambience")]


func _player(bus: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _input(event: InputEvent) -> void:
	if _unlocked:
		return
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch:
		_unlocked = true
		if _pending_music != &"":
			play_music(_pending_music)
		if _pending_ambience != &"":
			set_ambience(_pending_ambience, 1.0)
		_pending_music = &""
		_pending_ambience = &""


# --- Afspilning ---------------------------------------------------------------

func play_sfx(id: StringName, pos: Vector3 = Vector3.INF) -> void:
	if not _can_play():
		return
	var s := _stream(id)
	if s == null:
		return
	if pos == Vector3.INF:
		for p in _sfx2d:
			if not p.playing:
				_start(p, s, id)
				return
		_start(_sfx2d[0], s, id)
		return
	var p3 := _pool3d[_next3d]
	_next3d = (_next3d + 1) % MAX_3D
	p3.global_position = pos
	p3.stream = s
	p3.volume_db = _entry_db(id)
	p3.play()


func play_ui(id: StringName) -> void:
	if not _can_play():
		return
	var s := _stream(id)
	if s != null:
		_start(_ui, s, id)


func set_ambience(id: StringName, fade_s: float = 2.0) -> void:
	if _headless:
		return
	if not _unlocked:
		_pending_ambience = id
		return
	if id == _ambience_id and (id == &"" or _amb[_amb_active].playing):
		return
	var s: AudioStream = null
	if id != &"":
		s = _stream(id)
		if s == null:
			return
	_ambience_id = id
	if _amb_tween != null and _amb_tween.is_valid():
		_amb_tween.kill()
	var old := _amb[_amb_active]
	_amb_active = 1 - _amb_active
	var cur := _amb[_amb_active]
	var fade := maxf(fade_s, 0.01)
	_amb_tween = create_tween().set_parallel(true)
	_amb_tween.tween_property(old, "volume_db", -60.0, fade)
	if s != null:
		cur.stream = s
		cur.volume_db = -60.0
		cur.play()
		_amb_tween.tween_property(cur, "volume_db", _entry_db(id), fade)
	_amb_tween.chain().tween_callback(old.stop)


func play_music(id: StringName) -> void:
	if _headless:
		return
	if not _unlocked:
		_pending_music = id
		return
	if id == _music_id and _music.playing:
		return
	var s := _stream(id)
	if s == null:
		return
	_music_id = id
	_start(_music, s, id)


func stop_music() -> void:
	_pending_music = &""
	_music_id = &""
	if _music != null:
		_music.stop()


# --- Volumen / mute -----------------------------------------------------------

func set_bus_volume(bus: StringName, linear: float) -> void:
	if not _volumes.has(bus):
		_warn_once(&"bus:" + bus, "AudioManager: ukendt bus '%s'" % bus)
		return
	_volumes[bus] = clampf(linear, 0.0, 1.0)
	_apply_bus(bus)
	save_settings()


func get_bus_volume(bus: StringName) -> float:
	return float(_volumes.get(bus, 0.0))


func set_muted(bus: StringName, on: bool) -> void:
	if not _muted.has(bus):
		_warn_once(&"bus:" + bus, "AudioManager: ukendt bus '%s'" % bus)
		return
	_muted[bus] = on
	_apply_bus(bus)
	save_settings()


func is_muted(bus: StringName) -> bool:
	return bool(_muted.get(bus, false))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(settings_path)  # bevar andre sektioner; fejl = ny fil
	for b in BUSES:
		cfg.set_value(SETTINGS_SECTION, "%s_volume" % b, _volumes[b])
		cfg.set_value(SETTINGS_SECTION, "%s_muted" % b, _muted[b])
	cfg.save(settings_path)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) == OK:
		for b in BUSES:
			_volumes[b] = clampf(float(cfg.get_value(SETTINGS_SECTION, "%s_volume" % b, 1.0)), 0.0, 1.0)
			_muted[b] = bool(cfg.get_value(SETTINGS_SECTION, "%s_muted" % b, false))
	for b in BUSES:
		_apply_bus(b)


# --- Internt ------------------------------------------------------------------

func _can_play() -> bool:
	return not _headless and _unlocked and is_inside_tree()


func _apply_bus(bus: StringName) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	var lin: float = _volumes[bus]
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(lin, 0.0001)))
	AudioServer.set_bus_mute(idx, bool(_muted[bus]) or lin <= 0.0)


func _start(p: AudioStreamPlayer, s: AudioStream, id: StringName) -> void:
	p.stream = s
	p.volume_db = _entry_db(id)
	var e: Dictionary = _catalog.get(id, {})
	if e.has("bus"):
		p.bus = StringName(e["bus"])
	p.play()


func _entry_db(id: StringName) -> float:
	var e: Dictionary = _catalog.get(id, {})
	return float(e.get("volume_db", 0.0))


func _stream(id: StringName) -> AudioStream:
	if _streams.has(id):
		return _streams[id]
	var s: AudioStream = null
	var e: Dictionary = _catalog.get(id, {})
	var file := str(e.get("file", ""))
	if file != "" and ResourceLoader.exists(file):
		s = load(file) as AudioStream
	if s == null and AudioSynth.has(id):
		s = AudioSynth.generate(id)
	if s == null:
		_warn_once(id, "AudioManager: ukendt lyd-id '%s'" % id)
		return null
	_streams[id] = s
	return s


func _warn_once(key: StringName, msg: String) -> void:
	if _warned.has(key) or _headless:
		return
	_warned[key] = true
	push_warning(msg)


func _load_catalog() -> void:
	if not FileAccess.file_exists(CATALOG_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if data is Dictionary:
		var d: Dictionary = data
		# Tillad både {"sounds": {...}} og flad {id: {...}}
		var src: Dictionary = d.get("sounds", d) if d.get("sounds", d) is Dictionary else d
		for k: Variant in src:
			if src[k] is Dictionary:
				_catalog[StringName(str(k))] = src[k]
