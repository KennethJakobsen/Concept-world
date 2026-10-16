class_name FloatingText3D
extends Node3D
## T-107: Svævetal over bygninger. show_amount(pos, amount, color) laver en Label3D der
## stiger 1,2 m og fader på 1,2 s. Pool på 32. Skjules over HIDE_DIST fra aktiv kamera.

const LIFE := 1.2
const RISE := 1.2
const POOL := 32
const HIDE_DIST := 40.0

var _labels: Array[Label3D] = []
var _age: PackedFloat32Array = PackedFloat32Array()
var _start: Array[Vector3] = []
var _next := 0


func _init() -> void:
	for i in POOL:
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.fixed_size = false
		l.pixel_size = 0.01
		l.font_size = 48
		l.outline_size = 10
		l.outline_modulate = Color(0, 0, 0, 0.8)
		l.visible = false
		add_child(l)
		_labels.append(l)
		_start.append(Vector3.ZERO)
	_age.resize(POOL)
	_age.fill(LIFE)
	set_process(false)


func show_amount(pos: Vector3, amount: int, color: Color = Color(0.4, 1.0, 0.45)) -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam != null and cam.global_position.distance_to(pos) > HIDE_DIST:
		return
	var l := _labels[_next]
	l.text = ("+%d kr" if amount >= 0 else "%d kr") % amount
	l.modulate = color
	l.visible = true
	l.position = pos
	_start[_next] = pos
	_age[_next] = 0.0
	_next = (_next + 1) % POOL
	set_process(true)


func active_count() -> int:
	var n := 0
	for a in _age:
		if a < LIFE:
			n += 1
	return n


func _process(delta: float) -> void:
	var any := false
	for i in POOL:
		if _age[i] >= LIFE:
			continue
		_age[i] += delta
		var t := clampf(_age[i] / LIFE, 0.0, 1.0)
		var l := _labels[i]
		l.position = _start[i] + Vector3(0, RISE * t, 0)
		l.modulate.a = 1.0 - t * t
		if _age[i] >= LIFE:
			l.visible = false
		else:
			any = true
	if not any:
		set_process(false)
