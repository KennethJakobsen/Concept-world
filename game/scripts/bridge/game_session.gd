extends Node
## Autoload "GameSession": flow mellem hovedmenu og park + gem/indlæs/autosave.
## ParkView læser pending_save/seed i _ready.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const MENU_SCENE: String = "res://scenes/main_menu.tscn"

var pending_save: Dictionary = {}
var pending_scenario: String = ""  ## T-070: ParkView opretter sim fra dette scenarie ("" = fri leg)
var seed: int = 1
var store: SaveStore = SaveStore.new()
var _hooked_sim: ParkSim
var _music_scene: Node  ## scenen der sidst valgte musik

## T-111: pengeblink (+1/-1) efter hvert 0,25 s-salgsvindue (ParkView videresender).
signal money_flash(sign: int)
## T-111: sim'ens milepælssignaler videresendt til UI (overlever sim-skift ved load).
signal milestone_achieved(id: String)
signal milestones_backfilled(ids: Array)


func _process(_delta: float) -> void:
	_sync_music()
	# Kobl autosave til den aktuelle sim (ParkView kan skifte sim ved load).
	var s: ParkSim = current_sim()
	if s != _hooked_sim:
		_hooked_sim = s
		if s != null:
			s.day_passed.connect(_on_day_passed)
			s.research_unlocked.connect(_on_research_unlocked)
			s.scenario_finished.connect(_on_scenario_finished)
			s.milestone_achieved.connect(func(id: String) -> void: milestone_achieved.emit(id))
			s.milestones_backfilled.connect(func(ids: Array) -> void: milestones_backfilled.emit(ids))


## Alias for start_sandbox (bagudkompatibelt).
func start_new(p_seed: int = randi()) -> void:
	start_sandbox(p_seed)


func start_sandbox(p_seed: int = randi()) -> void:
	seed = p_seed
	pending_save = {}
	pending_scenario = ""
	_change(MAIN_SCENE)


func start_scenario(scenario_id: String, p_seed: int = randi()) -> void:
	seed = p_seed
	pending_save = {}
	pending_scenario = scenario_id
	_change(MAIN_SCENE)


func start_from_save(d: Dictionary) -> void:
	pending_save = d
	pending_scenario = ""
	_change(MAIN_SCENE)


func current_sim() -> ParkSim:
	if not is_inside_tree():
		return null
	var v: ParkView = get_tree().get_first_node_in_group("park_view") as ParkView
	return v.sim if v != null else null


func save_to(slot: String) -> bool:
	var s: ParkSim = current_sim()
	if s == null:
		return false
	return store.save(slot, s.to_save())


func load_from(slot: String) -> bool:
	var d: Dictionary = store.load(slot)
	if d.is_empty():
		return false
	start_from_save(d)
	return true


func go_to_main_menu() -> void:
	pending_save = {}
	_change(MENU_SCENE)


func _on_day_passed(_day: int) -> void:
	save_to(SaveStore.AUTOSAVE_SLOT)


func _on_research_unlocked(_item_id: String) -> void:
	_sfx(&"cheer")


## Sejr/nederlag: pause (UI viser resultatet via sim.scenario_finished/scenario_status).
func _on_scenario_finished(won: bool, _reason: String) -> void:
	var s: ParkSim = current_sim()
	if s != null:
		s.clock.paused = true
	_sfx(&"cheer" if won else &"error")


func _sfx(id: StringName) -> void:
	var am: Node = get_node_or_null("/root/AudioManager")
	if am != null:
		am.call("play_sfx", id, Vector3.INF)


func _change(path: String) -> void:
	_hooked_sim = null
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(path)


## Musik følger scenen: park (main.tscn) → "park", ellers (hovedmenu) → "menu".
func _sync_music() -> void:
	var cur: Node = get_tree().current_scene if is_inside_tree() else null
	if cur == null or cur == _music_scene:
		return
	_music_scene = cur
	var am: Node = get_node_or_null("/root/AudioManager")
	if am == null:
		return
	am.call("play_music", &"park" if cur.scene_file_path == MAIN_SCENE else &"menu")


func current_view() -> ParkView:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group("park_view") as ParkView


## T-111: overlay-data til OverlayRenderer ({cells, markers}). Tom, hvis der ikke er en park.
func overlay_data(kind: StringName) -> Dictionary:
	return OverlayData.build(current_sim(), kind)


## Vis/skjul overlay i parken (kind = &"" skjuler). UI's overlay-vælger kalder disse.
func show_overlay(kind: StringName) -> void:
	var v: ParkView = current_view()
	if v != null:
		v.show_overlay(kind)


func hide_overlay() -> void:
	var v: ParkView = current_view()
	if v != null:
		v.hide_overlay()


## Kameraet glider til cellen (toast-klik i AlertTray).
func focus_cell(cell: Vector2i) -> void:
	var v: ParkView = current_view()
	if v != null:
		v.focus_cell(cell)


## Genlæs UserSettings (svævetal/farveblind) – UI kalder efter ændring i indstillinger.
func refresh_settings() -> void:
	var v: ParkView = current_view()
	if v != null:
		v.refresh_settings()
	else:
		ParkColors.refresh_from_settings()
