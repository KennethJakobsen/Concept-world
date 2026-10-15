extends Node3D
## T-069: Visuel kontrol af rutsjebanen. Kør: godot res://scenes/rendering/coaster_demo.tscn
## Taster: B = broken, L = lys til/fra, G = skift ghost grøn/rød, Space = pause tog.

const LAYOUT: Array[String] = [
	"coaster_station", "track_straight", "track_lift_up", "track_lift_up", "track_lift_up",
	"track_straight", "track_turn_right", "track_turn_right", "track_down", "track_down",
	"track_down", "track_straight", "track_straight", "track_straight", "track_turn_right", "track_turn_right",
]

@onready var _track: CoasterTrackMesh = $Track
@onready var _ghost: CoasterTrackMesh = $Ghost
@onready var _train: CoasterTrain = $Train
@onready var _station: Node3D = $Station

var _line := PackedVector3Array()
var _acc := PackedFloat32Array()
var _idx := PackedInt32Array()
var _kinds: Array[String] = []
var _s: float = 0.0
var _paused: bool = false
var _ghost_ok: bool = true
var _lights: bool = false
var _label: Label


## Lægger stykker i forlængelse af hinanden ud fra start (samme regler som simulationens next_entry).
static func chain(ids: Array[String], defs: Dictionary, cell: Vector2i, heading: int, level: int) -> Array:
	var out: Array = []
	for id in ids:
		var d: Dictionary = defs[id]
		out.append({"def_id": id, "cell": cell, "heading": heading, "level": level})
		heading = posmod(heading + int(d.get("turn", 0)), 4)
		level += int(d.get("rise", 0))
		var dv := CoasterTrackMesh.heading_dir(heading)
		cell += Vector2i(int(dv.x), int(dv.z))
	return out


func _ready() -> void:
	var defs := CoasterTrackMesh.load_defs()
	var pieces := chain(LAYOUT, defs, Vector2i(-3, -1), 1, 0)
	_track.build(pieces, defs)
	_line = CoasterTrackMesh.full_centerline(pieces, defs, CoasterTrackMesh.SAMPLES, _idx)
	_acc = CoasterTrackMesh.arc_lengths(_line)
	for i in _idx:
		_kinds.append(String(defs[pieces[i]["def_id"]].get("kind", "track")))
	var st: Dictionary = pieces[0]
	_station.position = Vector3(st["cell"].x + 0.5, 0, st["cell"].y + 0.5)
	_station.rotation.y = -PI * 0.5 * int(st["heading"])
	# Ghost: et preview-stykke ved siden af banen.
	_ghost.build([{"def_id": "track_up", "cell": Vector2i(-3, 2), "heading": 1, "level": 0},
		{"def_id": "track_turn_left", "cell": Vector2i(-2, 2), "heading": 1, "level": 1}], defs)
	_ghost.set_ghost(true)
	_train.set_cars(3)
	($Camera3D as Camera3D).look_at_from_position(Vector3(3.5, 3.5, 4.5), Vector3(0.5, 1.0, 0.0))
	_label = Label.new()
	_label.position = Vector2(10, 10)
	add_child(_label)
	print("coaster_demo: %d trekanter" % _track.triangle_count())


func _process(delta: float) -> void:
	if _line.size() < 2:
		return
	var total := _acc[_acc.size() - 1]
	var pose := CoasterTrackMesh.pose_at(_line, _acc, _s)
	var k := _kind_at(_s)
	var v := 1.5
	if k == "lift":
		v = 1.2
	elif k == "track":
		v = sqrt(maxf(2.0, 2.0 * 9.81 * (3.3 - pose.origin.y))) * 0.55
	if not _paused and not _train.broken:
		_s = fposmod(_s + v * delta, total)
	var poses: Array[Transform3D] = []
	for i in _train.car_count():
		poses.append(CoasterTrackMesh.pose_at(_line, _acc, _s - i * CoasterTrain.CAR_SPACING))
	_train.set_path_pose(poses)
	_label.text = "Trekanter: %d  |  fart %.1f m/s  |  B broken, L lys, G ghost, Space pause" % [_track.triangle_count(), v]


func _kind_at(s: float) -> String:
	var total := _acc[_acc.size() - 1]
	var ss := fposmod(s, total)
	var i := _acc.bsearch(ss)
	return _kinds[clampi(i, 0, _kinds.size() - 1)]


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	match (e as InputEventKey).keycode:
		KEY_B:
			_train.set_broken(not _train.broken)
		KEY_L:
			_lights = not _lights
			_train.set_lights(1.0 if _lights else 0.0)
		KEY_G:
			_ghost_ok = not _ghost_ok
			_ghost.set_ghost(_ghost_ok)
		KEY_SPACE:
			_paused = not _paused
